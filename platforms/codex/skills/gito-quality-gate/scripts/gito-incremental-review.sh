#!/usr/bin/env bash
# gito-incremental-review.sh — Scoped Gito review with SDD context injection
# Usage: gito-incremental-review.sh --scope <scope> --spec <spec-name> --task <task-id> [--filter <glob>] [--against <ref>] [--output <dir>]
#
# Scopes:
#   staged       — uncommitted changes (git diff --name-only HEAD)
#   last-commit  — HEAD~1..HEAD
#   commits:N    — last N commits (HEAD~N..HEAD)
#   filter:PAT   — use --filter directly (no file list extraction)
#
# This script:
# 1. Backs up .gito/config.toml
# 2. Injects SDD spec/task context into [prompt_vars].requirements
# 3. Runs gito review --filter on the scoped files
# 4. Restores the original config.toml
# 5. Outputs the report path

set -euo pipefail

# ── Defaults ──
SCOPE="staged"
SPEC_NAME=""
TASK_ID=""
FILTER=""
AGAINST="origin/main"
OUTPUT_DIR="/tmp/gito-qg-$(date +%Y%m%d-%H%M%S)"
GITO_CONFIG=".gito/config.toml"
GITO_CONFIG_BAK=""
VENV_PATH=".venv/bin/activate"
CONTEXT_BLOCK=""

# ── Colors ──
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${CYAN}[gito-qg]${NC} $*"; }
warn() { echo -e "${YELLOW}[gito-qg] WARN${NC} $*" >&2; }
err()  { echo -e "${RED}[gito-qg] ERROR${NC} $*" >&2; }
ok()   { echo -e "${GREEN}[gito-qg] OK${NC} $*"; }

# ── Parse Args ──
usage() {
  cat <<EOF
Usage: $0 --scope <scope> --spec <spec-name> --task <task-id> [options]

Required:
  --scope <scope>       Review scope: staged|last-commit|commits:N|filter:PAT
  --spec <spec-name>    SDD spec name (e.g., ralphharness-rename)
  --task <task-id>      Task ID being verified (e.g., 3.2)

Optional:
  --filter <glob>       Additional file filter glob (comma-separated)
  --against <ref>       Git ref to compare against (default: origin/main)
  --output <dir>        Output directory for report (default: /tmp/gito-qg-<timestamp>)
  --context <text>      Pre-built context block (skips auto-build)
  --venv <path>         Path to venv activate script (default: .venv/bin/activate)

Examples:
  $0 --scope staged --spec ralphharness-rename --task 3.2
  $0 --scope last-commit --spec my-feature --task 5.1 --filter "src/**/*.py"
  $0 --scope commits:3 --spec my-feature --task 2.0 --against HEAD~3
  $0 --scope filter:"plugins/**/*.md" --spec my-feature --task 1.1
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope)    SCOPE="$2"; shift 2 ;;
    --spec)     SPEC_NAME="$2"; shift 2 ;;
    --task)     TASK_ID="$2"; shift 2 ;;
    --filter)   FILTER="$2"; shift 2 ;;
    --against)  AGAINST="$2"; shift 2 ;;
    --output)   OUTPUT_DIR="$2"; shift 2 ;;
    --context)  CONTEXT_BLOCK="$2"; shift 2 ;;
    --venv)     VENV_PATH="$2"; shift 2 ;;
    -h|--help)  usage ;;
    *) err "Unknown argument: $1"; usage ;;
  esac
done

# ── Validate ──
if [[ -z "$SPEC_NAME" ]]; then
  err "--spec is required"
  usage
fi

if [[ -z "$TASK_ID" ]]; then
  err "--task is required"
  usage
fi

# ── Activate venv ──
if [[ -f "$VENV_PATH" ]]; then
  # shellcheck disable=SC1090
  . "$VENV_PATH"
  log "Activated venv: $VENV_PATH"
else
  warn "Venv not found at $VENV_PATH — assuming gito is on PATH"
fi

# Verify gito is available
if ! command -v gito &>/dev/null; then
  err "gito not found. Activate venv or install: pip install gito.bot"
  exit 1
fi

# ── Resolve Changed Files ──
resolve_files() {
  local scope="$1"
  case "$scope" in
    staged)
      git diff --name-only HEAD 2>/dev/null || git diff --name-only --cached HEAD 2>/dev/null
      ;;
    last-commit)
      git diff --name-only HEAD~1..HEAD 2>/dev/null
      ;;
    commits:*)
      local n="${scope#commits:}"
      git diff --name-only "HEAD~${n}"..HEAD 2>/dev/null
      ;;
    filter:*)
      # No file list needed — use --filter directly
      echo ""
      ;;
    *)
      err "Unknown scope: $scope"
      exit 1
      ;;
  esac
}

CHANGED_FILES=$(resolve_files "$SCOPE")
if [[ -n "$CHANGED_FILES" && "$SCOPE" != filter:* ]]; then
  FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l)
  log "Found $FILE_COUNT changed files in scope '$SCOPE'"
else
  FILE_COUNT=0
  log "Using filter-based scope (files resolved by Gito)"
fi

# ── Build Context Block ──
build_context() {
  local spec_name="$1"
  local task_id="$2"
  local spec_dir="specs/${spec_name}"
  local context=""

  # Extract task description from tasks.md
  local task_desc=""
  local done_when=""
  if [[ -f "${spec_dir}/tasks.md" ]]; then
    # Find the task block containing the task ID
    task_desc=$(grep -A5 "Task ${task_id}:" "${spec_dir}/tasks.md" 2>/dev/null | head -3 | tr '\n' ' ' | sed 's/^[[:space:]]*//' || echo "Task not found")
    done_when=$(grep -A2 "Done-when\|Done when" "${spec_dir}/tasks.md" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//' || echo "")
  fi

  # Extract relevant requirements
  local requirements=""
  if [[ -f "${spec_dir}/requirements.md" ]]; then
    requirements=$(grep -E "^- \*\*AC-" "${spec_dir}/requirements.md" 2>/dev/null | head -5 | tr '\n' '; ' || echo "")
  fi

  # Extract relevant design decisions
  local design=""
  if [[ -f "${spec_dir}/design.md" ]]; then
    design=$(head -30 "${spec_dir}/design.md" 2>/dev/null | grep -E "^-|^##" | head -5 | tr '\n' '; ' || echo "")
  fi

  # Build the context block
  context="[SDD Context — Task ${task_id}]
Feature: ${spec_name}
Task: ${task_desc}
Done-when: ${done_when}
Requirements: ${requirements}
Design: ${design}
Files: ${CHANGED_FILES//$'\n'/, }
Review focus: Verify changes align with the above spec/task context. Flag only issues that conflict with stated requirements or design. Do NOT flag style preferences, naming conventions outside the spec, or pre-existing issues unrelated to this task."

  echo "$context"
}

if [[ -z "$CONTEXT_BLOCK" ]]; then
  log "Building context from spec: $SPEC_NAME, task: $TASK_ID"
  CONTEXT_BLOCK=$(build_context "$SPEC_NAME" "$TASK_ID")
fi

log "Context block (${#CONTEXT_BLOCK} chars):
---
${CONTEXT_BLOCK}
---"

# ── Backup and Inject Config ──
backup_config() {
  if [[ ! -f "$GITO_CONFIG" ]]; then
    warn "No .gito/config.toml found — creating minimal config"
    mkdir -p .gito
    cat > "$GITO_CONFIG" <<TOML
# Gito project configuration (auto-generated by gito-quality-gate)
exclude_files = [".*", ".*/**", "_*", "_*/**", "specs/**", "*.lock", "**/.gitkeep"]
mention_triggers = ["gito", "/review"]
collapse_previous_code_review_comments = true

[prompt_vars]
requirements = ""
TOML
  fi
  GITO_CONFIG_BAK=$(mktemp "${GITO_CONFIG}.bak.XXXXXX")
  cp "$GITO_CONFIG" "$GITO_CONFIG_BAK"
  log "Backed up config to $GITO_CONFIG_BAK"
}

inject_context() {
  # Use python via heredoc + env var to avoid shell injection (CONTEXT_BLOCK may contain quotes/backslashes)
  GITO_CONFIG_PATH="$GITO_CONFIG" \
  GITO_CONTEXT_BLOCK="$CONTEXT_BLOCK" \
  python3 <<'PYEOF'
import re, os, sys

config_path = os.environ['GITO_CONFIG_PATH']
context = os.environ['GITO_CONTEXT_BLOCK']

with open(config_path, 'r') as f:
    content = f.read()

# Replace or add requirements in [prompt_vars]
pattern = r'(requirements\s*=\s*""")[\s\S]*?(""")'
replacement = 'requirements = """' + context + '"""'

if re.search(pattern, content):
    new_content = re.sub(pattern, replacement, content, count=1)
else:
    # Add [prompt_vars] section if missing
    if '[prompt_vars]' not in content:
        new_content = content + '\n[prompt_vars]\nrequirements = """' + context + '"""\n'
    else:
        new_content = content.replace('[prompt_vars]', '[prompt_vars]\nrequirements = """' + context + '"""\n', 1)

with open(config_path, 'w') as f:
    f.write(new_content)
PYEOF
  if [[ $? -ne 0 ]]; then
    warn "Context injection failed — config unchanged"
    return 1
  fi
  log "Injected context into $GITO_CONFIG"
}

restore_config() {
  if [[ -n "$GITO_CONFIG_BAK" && -f "$GITO_CONFIG_BAK" ]]; then
    cp "$GITO_CONFIG_BAK" "$GITO_CONFIG"
    rm -f "$GITO_CONFIG_BAK"
    log "Restored original config"
  fi
}

# Ensure cleanup on exit
trap restore_config EXIT

backup_config
inject_context

# ── Run Gito Review ──
mkdir -p "$OUTPUT_DIR"
log "Running Gito review (scope: $SCOPE, against: $AGAINST, output: $OUTPUT_DIR)"

# Use bash array to avoid eval / word-splitting / injection risks (#2, #3)
GIT_CMD=("gito" "review" "--against" "$AGAINST" "-o" "$OUTPUT_DIR")

# Add filter if we have changed files or a filter pattern
if [[ "${SCOPE}" == filter:* ]]; then
  local_filter="${SCOPE#filter:}"
  GIT_CMD+=("--filter" "$local_filter")
elif [[ -n "$CHANGED_FILES" ]]; then
  # Build comma-separated filter from file list
  local_filter=$(echo "$CHANGED_FILES" | tr '\n' ',' | sed 's/,$//')
  GIT_CMD+=("--filter" "$local_filter")
fi

# Add user-provided filter if specified
if [[ -n "$FILTER" ]]; then
  GIT_CMD+=("--filter" "$FILTER")
fi

# Add refs for commit-based scopes
if [[ "$SCOPE" == "last-commit" ]]; then
  GIT_CMD+=("HEAD~1..HEAD")
elif [[ "${SCOPE}" == commits:* ]]; then
  local n="${SCOPE#commits:}"
  GIT_CMD+=("HEAD~${n}..HEAD")
fi

log "Executing: ${GIT_CMD[*]}"
"${GIT_CMD[@]}" 2>&1 || {
  err "Gito review failed (exit code: $?)"
  exit 1
}

# ── Parse Results ──
REPORT_JSON="${OUTPUT_DIR}/code-review-report.json"
REPORT_MD="${OUTPUT_DIR}/code-review-report.md"

if [[ ! -f "$REPORT_JSON" ]]; then
  warn "No report JSON found at $REPORT_JSON"
  # Check if report was generated in current directory
  if [[ -f "code-review-report.json" ]]; then
    cp code-review-report.json "$REPORT_JSON"
    cp code-review-report.md "$REPORT_MD" 2>/dev/null || true
    log "Copied report from working directory"
  else
    err "No Gito report generated"
    exit 1
  fi
fi

# Count issues
ISSUE_COUNT=$(python3 -c "
import json, sys
try:
    with open('$REPORT_JSON') as f:
        data = json.load(f)
    total = sum(len(issues) for issues in data.get('issues', {}).values())
    print(total)
except:
    print(0)
" 2>/dev/null || echo "0")

log "Review complete: $ISSUE_COUNT issues found"
log "Report: $REPORT_JSON"
log "Markdown: $REPORT_MD"

# ── Output Summary ──
echo ""
echo "═══════════════════════════════════════════════"
echo "  GITO QUALITY GATE — INCREMENTAL REVIEW"
echo "═══════════════════════════════════════════════"
echo "  Scope:      $SCOPE"
echo "  Spec:       $SPEC_NAME"
echo "  Task:       $TASK_ID"
echo "  Against:    $AGAINST"
echo "  Files:      $FILE_COUNT"
echo "  Issues:     $ISSUE_COUNT"
echo "  Report:     $REPORT_JSON"
echo "═══════════════════════════════════════════════"
echo ""

if [[ "$ISSUE_COUNT" -eq 0 ]]; then
  ok "PASS — No issues found by Gito"
  echo "GITO_QUALITY_GATE_PASS" > "${OUTPUT_DIR}/verdict.txt"
  exit 0
else
  warn "ISSUES FOUND — $ISSUE_COUNT issues require BMAD adversarial filtering"
  echo "GITO_QUALITY_GATE_ISSUES_FOUND" > "${OUTPUT_DIR}/verdict.txt"
  echo "$ISSUE_COUNT" > "${OUTPUT_DIR}/issue_count.txt"
  exit 0
fi
