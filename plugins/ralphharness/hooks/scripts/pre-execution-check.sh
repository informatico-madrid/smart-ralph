#!/usr/bin/env bash
set -euo pipefail

# ── Usage ─────────────────────────────────────────────────────────
usage() {
  cat >&2 <<EOF
Usage: $0 --agent AGENT --task TASK [--paths PATHS] [--command CMD] --spec-path PATH

Required:
  --agent      Agent name (e.g. spec-executor)
  --task       Task identifier (e.g. 1.1)
  --spec-path  Spec directory path

Optional:
  --paths      Comma-separated list of intended write paths
  --command    Verify command to inspect for dangerous patterns
EOF
  exit 1
}

# ── Argument parsing ──────────────────────────────────────────────
AGENTS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)    AGENT="$2";     shift 2 ;;
    --task)     TASK="$2";      shift 2 ;;
    --paths)    PATHS="$2";     shift 2 ;;
    --command)  COMMAND="$2";   shift 2 ;;
    --spec-path) SPEC_PATH="$2"; shift 2 ;;
    -h|--help)  usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

# ── Required-flag validation ─────────────────────────────────────
missing=""
[[ -z "${AGENT:-}" ]]     && missing+="--agent "
[[ -z "${TASK:-}" ]]      && missing+="--task "
[[ -z "${SPEC_PATH:-}" ]] && missing+="--spec-path "

if [[ -n "$missing" ]]; then
  echo "Error: missing required flag(s): ${missing}" >&2
  usage
fi

# ── Placeholder ──────────────────────────────────────────────────
exit 0
