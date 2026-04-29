---
spec: gito-fixes
basePath: /mnt/bunker_data/ai/smart-ralph/specs/gito-fixes
phase: design
created: 2026-04-29T00:00:00Z
---

# Design: Gito Automated Code Review Fixes

## Overview

Apply 55 surgical fixes identified by Gito automated code review across the Smart Ralph codebase. All fixes are targeted edits to existing files — no new components, no behavioral changes beyond bug correction. Grouped into 8 categories by file domain for efficient batch processing.

## Architecture

```
55 issues across 8 fix groups
├── Group 1: Plugin scripts (4 issues in import.sh)
├── Group 2: Plugin commands (3 issues in implement.md)
├── Group 3: Plugin hooks (7 issues in checkpoint.sh, write-metric.sh, stop-watcher.sh)
├── Group 4: Plugin references & schemas (6 issues in role-contracts.md, spec.schema.json, loop-safety.md)
├── Group 5: Spec index (1 issue in index-state.json)
├── Group 6: Spec documents (22 issues across 11 spec files)
├── Group 7: Test scripts (7 issues in test-*.sh files)
└── Group 8: Documentation/typos (8 issues in .progress.md, research.md, design.md)
```

## Fix Groups

### Group 1: Plugin Scripts (`import.sh`)

**File:** `plugins/ralph-bmad-bridge/scripts/import.sh`
**Issues:** #15, #16, #18, #19 (4 issues)

| Issue | Bug | Fix |
|-------|-----|-----|
| #15 | `grep -c ... || echo 0` produces "0\n0" under `set -euo pipefail` | Replace with `|| true` |
| #16 | `[\s]` invalid POSIX regex in grep patterns | Replace with `[[:space:]]` |
| #18 | `${f%.}` non-portable basename expansion | Replace with `basename` command |
| #19 | `eval` on untrusted input | Replace with safe jq/direct parsing |

**Fix approach:** Direct `Edit` tool — line-level replacements in a single file.

### Group 2: Plugin Commands (`implement.md`)

**File:** `plugins/ralph-specum/commands/implement.md`
**Issues:** #25, #27 (2 issues — #20 path resolution was already fixed in previous session)

| Issue | Bug | Fix |
|-------|-----|-----|
| #25 | Duplicate spec-name argument extraction | Remove duplicate extraction, use earliest source |
| #27 | Missing variable assignment (dead code) | Add the missing assignment |

**Fix approach:** Direct `Edit` tool — remove/reorder lines in markdown script.

### Group 3: Plugin Hooks

**Files:** `plugins/ralph-specum/hooks/scripts/checkpoint.sh`, `write-metric.sh`, `stop-watcher.sh`
**Issues:** #24, #29, #32, #33, #36, #37, #38 (7 issues)

| Issue | File | Bug | Fix |
|-------|------|-----|-----|
| #24 | checkpoint.sh | `[\s]` in /proc/mounts grep | Replace with `[[:space:]]` |
| #29 | checkpoint.sh | `[\s]` in mount grep | Replace with `[[:space:]]` |
| #32 | checkpoint.sh | Unchecked `cd "$git_root"` (line 97) | Add `|| { echo "[error]"; return 1; }` |
| #33 | stop-watcher.sh | `[\s]` in grep patterns | Replace with `[[:space:]]` |
| #36 | checkpoint.sh (checkpoint-rollback) | Unchecked `cd "$git_root"` (line 247) | Add error handling |
| #37 | checkpoint.sh (checkpoint-rollback) | `[\s]` in /proc/mounts grep | Replace with `[[:space:]]` |
| #38 | write-metric.sh | Subshell `return 0` ignores exit code | Use `return $?` or capture `write_exit` |

**Fix approach:** Direct `Edit` tool for regex replacements; manual verification for cd error handling.

### Group 4: Plugin References & Schemas

**Files:** `role-contracts.md`, `spec.schema.json`, `loop-safety.md`
**Issues:** #21, #22, #40, #42, #43, #46 (6 issues)

| Issue | File | Bug | Fix |
|-------|------|-----|-----|
| #21 | role-contracts.md | Schema field name mismatch in agent docs | Align names |
| #22 | spec.schema.json | Missing field definitions | Add definitions |
| #40 | loop-safety.md | Hardcoded `/path/to/mount` placeholder | Replace with dynamic path reference |
| #42 | role-contracts.md | qa-engineer Writes column has read description | Change to `_(read-only)_` |
| #43 | role-contracts.md | spec-reviewer denylist says "All files" | Change to `_(read-only)_` |
| #46 | spec.schema.json | Internal ticket refs (SR-XXX) in descriptions | Strip ticket refs |

**Fix approach:** Direct `Edit` tool — content corrections, mostly table rows and string replacements.

### Group 5: Spec Index

**File:** `specs/.index/index-state.json`
**Issues:** #48 (1 issue)

| Issue | Bug | Fix |
|-------|-----|-----|
| #48 | `ralph-quality-improvements` has `"phase": "complete"` | Change to `"phase": "completed"` |

**Fix approach:** `jq` command for precise JSON editing.

### Group 6: Spec Documents

**11 files, 22 issues**

| # | File | Bug | Fix |
|---|------|-----|-----|
| #49 | `specs/_epics/engine-roadmap-epic/epic.md` | Self-referential dependency (Spec 6 -> Spec 6) | Change to Spec 7 |
| #50 | `specs/_epics/engine-roadmap-epic/epic.md` | Command typo `/ralph-specum` -> `/ralph-spec` | Fix command name |
| #53 | `specs/bmad-bridge-plugin/.progress.md` | Contradictory `[x]` + PENDING_COMMIT | Replace with git hash or remove |
| #54 | `specs/bmad-bridge-plugin/design.md` | Awk `^##` exits on `###` headings | Fix to `^## [^#]` |
| #58 | `specs/bmad-bridge-plugin/plan.md` | Missing write targets for user stories | Add missing targets |
| #62 | `specs/bmad-bridge-plugin/requirements.md` | Conflicting BMAD versions (v2.11.0 vs v6.4.0) | Harmonize to single version |
| #65 | `specs/loop-safety-infra/.research-metrics-and-ci.md` | Useless `tr ',' ','` creates malformed JSON | Replace with `split(",")` in jq |
| #66 | `specs/loop-safety-infra/.research-metrics-and-ci.md` | Bash command substitution inside jq filter | Replace with pure jq syntax |
| #67 | `specs/loop-safety-infra/requirements.md` | Metrics field generation ambiguity | Clarify responsibility in text |
| #70 | `specs/loop-safety-infra/research-circuit-breaker.md` | Inconsistent data type for sessionStartTime | Harmonize type |
| #71 | `specs/loop-safety-infra/research-read-only-detection.md` | jq `//` treats `false` as falsy | Use explicit null check |
| #72 | `specs/loop-safety-infra/research-read-only-detection.md` | `exit 0` on fatal filesystem failure | Change to `exit 1` |
| #73 | `specs/loop-safety-infra/research-read-only-detection.md` | Heartbeat guard condition skips iterations | Remove guard, run every iteration |
| #74 | `specs/loop-safety-infra/research.md` | Contradictory `--no-verify` docs | Clarify consistent behavior |
| #75 | `specs/loop-safety-infra/research.md` | Incorrect categorization in Non-Modifications | Fix categorization |
| #76 | `specs/loop-safety-infra/tasks.md` | jq `-e` boolean chain fails on taskIndex=0 | Replace `and` with `has()` |
| #84 | `specs/pair-debug-auto-trigger/plan.md` | Condition count says 3, lists 4 | Harmonize count to 4 |
| #85 | `specs/role-boundaries/design.md` | Validation logic skips external_unmarks | Add external_unmarks to validation |
| #86 | `specs/role-boundaries/design.md` | Flock on fd 202 lacks lockfile | Reference lockfile backing |
| #87 | `specs/role-boundaries/final-spec-adversarial-review.md` | JSON baseline format mismatch | Harmonize flat/nested format |
| #93 | `specs/role-boundaries/tasks.md` | Regex contradicts minimum-length validation | Fix regex to enforce 2+ chars |
| #94 | `specs/role-boundaries/tasks.md` | `grep -c > 0` creates unintended file | Replace with `grep -q` |

**Fix approach:** Direct `Edit` tool for content corrections; `jq` for JSON changes; sed for regex fixes in code blocks.

### Group 7: Test Scripts

**Files:** `specs/loop-safety-infra/tests/test-*.sh`
**Issues:** #77, #78, #81, #82 (4 issues — #35, #36, #37 already fixed in previous session)

| # | File | Bug | Fix |
|---|------|-----|-----|
| #77 | `test-benchmark.sh` | `date +%s%N` fallback fails on macOS/BSD | Add portable wrapper with python3 fallback |
| #78 | `test-benchmark.sh` | Fragile sed regex ignores indentation | Anchor to `[[:space:]]*` |
| #81 | `test-integration.sh` | `grep -c ... || echo 0` corrupts variable | Replace with `|| true` |
| #82 | `test-integration.sh` | State file overwritten after creation (line 73) | Remove `echo '{}' > "$tmp/.ralph-state.json"` |

**Fix approach:** Direct `Edit` tool for each test file.

### Group 8: Documentation/Typos

**Files:** 8 files, 8 issues

| # | File | Bug | Fix |
|---|------|-----|-----|
| #11 | `_bmad/custom/config.toml` | Inconsistent paths (cosmetic) | Harmonize paths |
| #56 | `specs/bmad-bridge-plugin/design.md` | Duplicate test strategy entries | Remove duplicates |
| #60 | `specs/bmad-bridge-plugin/requirements.md` | Typo `smart-ralsh` -> `smart-ralph` | Fix typo |
| #61 | `specs/bmad-bridge-plugin/requirements.md` | Typo `bmalph` -> `BMAD` | Fix typo |
| #63 | `specs/loop-safety-infra/.progress.md` | Typo `Bmalph` -> `BMAD` | Fix typo |
| #69 | `specs/loop-safety-infra/research-circuit-breaker.md` | Typo `excption` -> `exception` | Fix typo |
| #91 | `specs/role-boundaries/research.md` | Corrupted markdown table row | Fix table formatting |
| #92 | `specs/role-boundaries/research.md` | Sentence fragment | Expand to complete sentence |

**Fix approach:** Direct `Edit` tool — text replacements.

## Technical Decisions

| Decision | Options Considered | Choice | Rationale |
|----------|-------------------|--------|-----------|
| Fix delivery method | Single PR vs multiple PRs | Single PR | All fixes are related, one PR is cleaner for review |
| Fix granularity | Per-issue commits vs grouped commits | Grouped commits | Reduces commit noise, each group is a logical unit |
| Shell script fixes | sed in-place vs Edit tool | Edit tool | More precise, avoids regex escaping issues |
| JSON fixes | sed vs jq | jq | Safe JSON manipulation, preserves formatting |
| Quality gates | Every fix vs batched | Every 4 fixes | Balances verification frequency with efficiency |

## File Structure

### Group 1: Plugin Scripts
| File | Action | Purpose |
|------|--------|---------|
| `plugins/ralph-bmad-bridge/scripts/import.sh` | Edit | Fix grep -c, regex, basename, eval bugs |

### Group 2: Plugin Commands
| File | Action | Purpose |
|------|--------|---------|
| `plugins/ralph-specum/commands/implement.md` | Edit | Fix duplicate arg parsing, missing variable |

### Group 3: Plugin Hooks
| File | Action | Purpose |
|------|--------|---------|
| `plugins/ralph-specum/hooks/scripts/checkpoint.sh` | Edit | Fix regex [\s], unchecked cd |
| `plugins/ralph-specum/hooks/scripts/write-metric.sh` | Edit | Fix subshell exit code |
| `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` | Edit | Fix regex [\s] |

### Group 4: Plugin References & Schemas
| File | Action | Purpose |
|------|--------|---------|
| `plugins/ralph-specum/references/role-contracts.md` | Edit | Fix denylist, writes column |
| `plugins/ralph-specum/references/loop-safety.md` | Edit | Fix hardcoded placeholder |
| `plugins/ralph-specum/schemas/spec.schema.json` | Edit | Strip ticket refs, add missing fields |

### Group 5: Spec Index
| File | Action | Purpose |
|------|--------|---------|
| `specs/.index/index-state.json` | Edit | Fix phase value "complete" -> "completed" |

### Group 6: Spec Documents
| File | Action | Purpose |
|------|--------|---------|
| `specs/_epics/engine-roadmap-epic/epic.md` | Edit | Fix self-ref dep, command typo |
| `specs/bmad-bridge-plugin/.progress.md` | Edit | Fix contradictory status |
| `specs/bmad-bridge-plugin/design.md` | Edit | Fix awk regex, duplicate entries |
| `specs/bmad-bridge-plugin/plan.md` | Edit | Add missing write targets |
| `specs/bmad-bridge-plugin/requirements.md` | Edit | Fix typos, harmonize BMAD version |
| `specs/loop-safety-infra/.research-metrics-and-ci.md` | Edit | Fix tr/jq in code blocks |
| `specs/loop-safety-infra/requirements.md` | Edit | Clarify metrics responsibility |
| `specs/loop-safety-infra/research-circuit-breaker.md` | Edit | Fix typo, type inconsistency |
| `specs/loop-safety-infra/research-read-only-detection.md` | Edit | Fix jq //, exit 0, heartbeat guard |
| `specs/loop-safety-infra/research.md` | Edit | Fix --no-verify docs, categorization |
| `specs/loop-safety-infra/tasks.md` | Edit | Fix jq boolean chain |
| `specs/pair-debug-auto-trigger/plan.md` | Edit | Fix condition count |
| `specs/role-boundaries/design.md` | Edit | Fix validation logic, flock reference |
| `specs/role-boundaries/final-spec-adversarial-review.md` | Edit | Harmonize JSON format |
| `specs/role-boundaries/research.md` | Edit | Fix table, sentence fragment |
| `specs/role-boundaries/tasks.md` | Edit | Fix regex, grep -q |

### Group 7: Test Scripts
| File | Action | Purpose |
|------|--------|---------|
| `specs/loop-safety-infra/tests/test-benchmark.sh` | Edit | Fix date portability, sed regex |
| `specs/loop-safety-infra/tests/test-integration.sh` | Edit | Fix grep -c, state file overwrite |

### Group 8: Documentation/Typos
| File | Action | Purpose |
|------|--------|---------|
| `_bmad/custom/config.toml` | Edit | Harmonize paths |
| `specs/bmad-bridge-plugin/requirements.md` | Edit | Fix typos (already listed above) |
| `specs/loop-safety-infra/.progress.md` | Edit | Fix typo Bmalph -> BMAD |

## Quality Gates

Quality gate tasks inserted every 4 implementation tasks. Each gate must pass via `/bmad-party-mode` consensus.

| Gate | After Fix Group | Checks |
|------|-----------------|--------|
| Gate 1 | Group 1 (plugin scripts) | bash -n on import.sh, shellcheck on fixed patterns |
| Gate 2 | Group 3 (plugin hooks) | bash -n on checkpoint.sh, write-metric.sh, stop-watcher.sh |
| Gate 3 | Group 6 (spec documents) | jq validation on JSON files, markdown renders correctly |
| Gate 4 | Group 7 (test scripts) | bash -n on test scripts, verify test logic is sound |
| Gate 5 | Group 8 (typos) | Spot-check all typo fixes for correctness |

Quality gate checklist:
- Code is solid (no new bugs introduced)
- Code coverage is adequate
- Tests are well-written, not lazy
- Syntax and style rules are correct
- Implementation is correct
- MUST pass via `/bmad-party-mode` by consensus

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Fix introduces regression in shell script | Low | Medium | bash -n syntax check after each group |
| jq edit corrupts JSON structure | Low | Medium | Use jq for all JSON edits, validate with jq empty |
| Spec document edit changes executable behavior | Very low | Medium | All spec docs are reference only, not executed |
| Test fix breaks existing test assumptions | Low | Low | Verify test logic is correct before applying |
| Missing a file that Gito identified | Low | Low | Classification report is the authoritative source |

**Overall risk:** LOW. All fixes are surgical, targeted edits. No new components, no behavioral changes beyond bug correction.

## Testing Strategy

### Test Double Policy

Not applicable — this spec involves direct bug fixes, not new code. No test doubles needed.

### Verification Methods

| Method | Used For | Command |
|--------|----------|---------|
| `bash -n` syntax check | All shell scripts | `bash -n file.sh` |
| `jq empty` validation | JSON files | `jq empty file.json` |
| `shellcheck` (best effort) | Shell scripts | `shellcheck file.sh` |
| Manual review | Spec documents, typos | Human visual verification |

### Test Coverage

| Component | Verification Method | What to verify |
|-----------|-------------------|----------------|
| import.sh fixes | `bash -n` + manual review | Syntax correct, no syntax errors, patterns match intent |
| checkpoint.sh fixes | `bash -n` + manual review | Regex `[[:space:]]` matches whitespace, cd has error handling |
| write-metric.sh fixes | `bash -n` + manual review | Subshell exit code propagated |
| stop-watcher.sh fixes | `bash -n` + manual review | Regex `[[:space:]]` matches whitespace |
| index-state.json | `jq empty` | Valid JSON, phase value is "completed" |
| spec.schema.json | `jq empty` | Valid JSON, no SR-XXX refs in descriptions |
| Test script fixes | `bash -n` + manual review | Syntax correct, logic matches intent |
| Spec documents | Manual review | Typos corrected, contradictions resolved |

## Test File Conventions

- Test runner: None for shell scripts (plain bash test files)
- Test file location: `specs/<name>/tests/test-*.sh`
- Test execution: `bash tests/test-*.sh` (no framework)
- Syntax check: `bash -n tests/test-*.sh`
- JSON validation: `jq empty file.json`

## Performance Considerations

All fixes are one-time edits. No performance impact on runtime. Shell script fixes (regex, grep patterns) may slightly improve performance by using correct POSIX patterns.

## Security Considerations

- #19 eval fix: Removing eval on untrusted input is a security improvement. No new security risks introduced.
- No authentication, permissions, or data handling changes.
- All fixes maintain existing security posture.

## Existing Patterns to Follow

Based on codebase analysis:
- Shell scripts use `set -euo pipefail` — all fixes must be compatible
- Shell scripts use `jq -n --arg` for string escaping — don't break this pattern
- Plugin scripts use `BASH_SOURCE[0]` self-execution guard — don't change
- Spec documents use YAML frontmatter (`---` delimiters) — don't modify frontmatter unless the issue is in frontmatter
- Shell scripts use `[[:space:]]` for POSIX-compatible whitespace — align fixes to this pattern
