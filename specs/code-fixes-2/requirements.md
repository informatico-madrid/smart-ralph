# Requirements: Code Fixes 2

**Spec**: `code-fixes-2` | **Epic**: `engine-roadmap-epic` (Spec 5)

## Goal

Fix all confirmed runtime bugs, test infrastructure defects, documentation typos, naming inconsistencies, and specification gaps identified in the loop-safety-infra code review report to make the codebase more solid, consistent, and bug-free.

## User Stories

### US-1: Fix Critical Runtime Bugs

**As a** Ralph user,
**I want** all confirmed runtime bugs fixed,
**So that** the execution loop does not silently fail, block CI/CD, or corrupt config files.

**Acceptance Criteria:**
- AC-1.1: `.gitignore` no longer excludes `.github/` — `git ls-files .github/` lists all workflow files, skills, and templates.
- AC-1.2: `resolve_config.py` `_merge_by_key()` deep merges override items into base items instead of replacing them — base item fields (e.g., `version`) are preserved when only a subset of fields are overridden.
- AC-1.3: `checkpoint.sh` uses `grep -F` (fixed string) for read-only detection, not regex — paths containing `[`, `(`, `.`, `*`, `+` no longer cause false negatives.
- AC-1.4: `load-spec-context.sh` exits with error when `mkdir` fails to create the baseline directory — the error path returns non-zero.
- AC-1.5: `stop-watcher.sh` uses `sha256sum` shell command (via `echo "$cmd" | sha256sum`) instead of the invalid `jq -R -s 'sha256sum | split(" ")[0]'` — CI hashes are actual SHA-256 values.
- AC-1.6: `discover-ci.sh` stores discovered CI commands as an array of `{command, category}` objects with categories `test`, `lint`, `build`, `typecheck`.
- AC-1.7: All shell fixes pass `bash -n`.
- AC-1.8: All JSON fixes pass `jq empty`.

### US-2: Fix Test Infrastructure Bugs

**As a** test runner,
**I want** test scripts to produce complete output on failure,
**So that** test results and summaries are never lost.

**Acceptance Criteria:**
- AC-2.1: `test-benchmark.sh` does not call `exit 1` before the summary block — on assertion failure, the test records the failure and continues to the summary.
- AC-2.2: `test-checkpoint.sh` line 49 performs a real assertion (verifies SHA is non-empty with length >= 7) instead of the tautology `assert_eq "$sha" "$sha"`.
- AC-2.3: After fixes, running the test suite produces both per-test results and a summary block.

### US-3: Fix Typos and Documentation Issues

**As a** reader of documentation,
**I want** clear, correct spelling and grammar in all docs,
**So that** I am not confused by obvious errors.

**Acceptance Criteria:**
- AC-3.1: `_bmad/core/module-help.csv` line 12: `bmad-distillator` → `bmad-distiller`, `Distillator` → `Distiller` in the skill name and display name columns.
- AC-3.2: `_bmad/core/module-help.csv` line 12: description reads "Use when you need **a** token-efficient distillate" (correct grammar).
- AC-3.3: `research-read-only-detection.md` section heading: `O_TMPF` → `O_TMPFILE`.
- AC-3.4: `research-circuit-breaker.md` contradictory timestamp comment is resolved (single authoritative timestamp per event).
- AC-3.5: `loop-safety-infra/research.md`: qa-engineer file access correctly attributed to qa-engineer.md, not spec-executor.md.
- AC-3.6: `loop-safety-infra/research.md`: misplaced backtick is corrected (code spans are properly delimited).

### US-4: Fix Naming and Consistency

**As a** developer maintaining the plugin,
**I want** consistent naming across all files,
**So that** the codebase is easier to navigate and reason about.

**Acceptance Criteria:**
- AC-4.1: `external-reviewer.md` references lock files consistently — the lock file name matches the file it protects (e.g., `tasks.md.lock` for tasks.md).
- AC-4.2: `spec-executor.md` uses consistent dot notation for state.json field paths (e.g., `.chat.executor.lastReadLine` everywhere, no mixing of `→` arrow notation with dot notation).
- AC-4.3: `index-state.json` uses `"completed"` (not `"complete"`) for phase status.
- AC-4.4: `index.md` uses `"completed"` for phase status (matching `index-state.json`).

### US-5: Fix Requirements and Specification Gaps

**As a** specification reader,
**I want** clear, accurate, and complete requirements with proper cross-references,
**So that** I can understand the spec without confusion or ambiguity.

**Acceptance Criteria:**
- AC-5.1: `requirements.md` FR-002 maps to US-1 with explicit AC references (AC-1.1 through AC-1.6).
- AC-5.2: `requirements.md` FR-003 maps to US-2 with explicit AC references (AC-2.1 through AC-2.7).
- AC-5.3: `requirements.md` glossary clarifies that `jq` does NOT process YAML — it only processes JSON.
- AC-5.4: `requirements.md` glossary: no misspellings (no "bmalph" — should be "bmaj" or whatever is the correct term).
- AC-5.5: `plan.md` Interface Contracts include output file references for each contract.
- AC-5.6: `plan.md` uses distinct variable names for different metrics (no ambiguous reuse of "N").

## Functional Requirements

### FR-001: Remove `.github/` from `.gitignore`

**Priority**: High
**Maps to**: US-1
**Bug**: #4

Remove line 51 (`.github/`) from `.gitignore`. The `.github/` directory contains CI workflows, skills, issue templates, and PR templates that must be tracked by git.

**File**: `.gitignore`
**Change**: Remove line containing `.github/`
**Verification**: `git ls-files .github/` lists workflow files after removal.

### FR-002: Fix `_merge_by_key()` to Deep Merge Base Fields

**Priority**: High
**Maps to**: US-1
**Bug**: #19

Replace the shallow copy in `_merge_by_key()` with a call to `deep_merge()`. Currently, line 95 does `result[index_by_key[key]] = dict(item)` which replaces the entire base item with the override. Instead, call `deep_merge(dict(base_item), dict(override_item))` to preserve fields like `version` that exist in base but not in override.

**File**: `_bmad/scripts/resolve_config.py`
**Lines**: 80-100 (`_merge_by_key`)
**Change**: Replace `result[index_by_key[key]] = dict(item)` with `result[index_by_key[key]] = deep_merge(dict(base_item), dict(item))` where `base_item` is tracked from the base array.
**Verification**: `python3 -c "import sys; sys.path.insert(0, '_bmad/scripts'); from resolve_config import deep_merge; base = {'agents': [{'code': 'a1', 'name': 'original', 'version': '1.0'}]}; override = {'agents': [{'code': 'a1', 'name': 'updated'}]}; result = deep_merge(base, override); assert result['agents'][0]['version'] == '1.0'"` passes.

### FR-003: Fix Regex Injection in `checkpoint.sh`

**Priority**: High
**Maps to**: US-1
**Bug**: #44

Replace regex-based `grep` with `grep -F` (fixed string matching) for filesystem read-only detection. The current code uses `grep -q "^.* ${fs_check_dir}.*ro[,[[:space:]]]"` where `fs_check_dir` is a raw path — if the path contains regex metacharacters (`[`, `(`, `.`, `*`, `+`), the grep pattern is unreliable.

**File**: `plugins/ralph-specum/hooks/scripts/checkpoint.sh`
**Lines**: 53-54
**Change**: Replace `grep -q` with `grep -qF` and simplify the pattern to match the mount point and `ro` flag separately.
**Verification**: Test with a path containing `(` — `grep -F` matches, `grep` (regex) would fail or error.

### FR-004: Add Exit on `mkdir` Failure in `load-spec-context.sh`

**Priority**: High
**Maps to**: US-1
**Bug**: #45

Add `return 1` after the error echo on line 114 of `load-spec-context.sh`. Currently, the `|| { echo "..."; }` catches the error but the script continues, producing a misleading "baseline captured" message.

**File**: `plugins/ralph-specum/hooks/scripts/load-spec-context.sh`
**Lines**: 114
**Change**: Add `return 1` (or `exit 1`) after the error echo in the `|| { ... }` block.
**Verification**: Create a non-writable parent directory — the script should fail with an error rather than silently continuing.

### FR-005: Fix CI Command Hashing

**Priority**: High
**Maps to**: US-1
**Bug**: #46

Replace the invalid `jq -R -s 'sha256sum | split(" ")[0]'` with a proper SHA-256 hash computation. `sha256sum` is not a jq function — it produces incorrect results (empty string or wrong value).

**File**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
**Lines**: 942
**Change**: Replace `cmd_hash=$(echo "$cmd" | jq -R -s 'sha256sum | split(" ")[0]')` with `cmd_hash=$(echo -n "$cmd" | sha256sum | cut -d' ' -f1)` or equivalent using the `sha256sum` shell command.
**Verification**: `echo -n "test" | sha256sum` produces a 64-character hex string.

### FR-006: Implement CI Command Categories in `discover-ci.sh`

**Priority**: Medium
**Maps to**: US-1
**Bug**: #85

Add category classification logic to `discover_ci_commands()`. Currently, `requirements.md` defines categories (`test`, `lint`, `build`, `typecheck`) but the implementation does not categorize commands. The function should return an array of `{command, category}` objects.

**File**: `plugins/ralph-specum/hooks/scripts/discover-ci.sh`
**Lines**: 7-56
**Change**: After collecting commands, classify each by grepping for category keywords. Return JSON array of `{command, category}` objects.
**Verification**: Run `discover_ci_commands` and verify each command has a `category` field.

### FR-007: Fix `test-benchmark.sh` Exit-on-Failure

**Priority**: Medium
**Maps to**: US-2
**Bug**: #94

Replace `exit 1` on line 48 with a non-exiting failure path (`assert_fail` + `continue` or simply remove the `exit 1`). The current code exits before the summary block (lines 77-83), losing test results on failure.

**File**: `specs/loop-safety-infra/tests/test-benchmark.sh`
**Lines**: 48
**Change**: Remove `exit 1` from the failure path. Let the test continue to the summary block.
**Verification**: Run the test with a artificially low threshold to trigger failure — the summary should still print.

### FR-008: Fix `test-checkpoint.sh` Tautology

**Priority**: Medium
**Maps to**: US-2
**Bug**: #96

Replace the tautological assertion `assert_eq "$sha" "$sha"` on line 49 with a real assertion. The current code always passes because it compares a variable with itself.

**File**: `specs/loop-safety-infra/tests/test-checkpoint.sh`
**Lines**: 49
**Change**: Replace `assert_eq "$sha" "$sha" "sha is non-empty..."` with `assert_eq "true" "$(if [ ${#sha} -ge 7 ]; then echo true; else echo false; fi)" "sha length >= 7 characters"`.
**Verification**: Run the test — if SHA is empty, the assertion should fail.

### FR-009: Fix Typos in Documentation

**Priority**: Medium
**Maps to**: US-3
**Bugs**: #11, #13, #18, #90, #93, #99, #100, #101, #102

Fix clear typos across documentation files:

| File | Change |
|------|--------|
| `_bmad/core/module-help.csv` line 12 | `bmad-distillator` → `bmad-distiller`, `Distillator` → `Distiller` |
| `_bmad/core/module-help.csv` line 12 description | Add missing article: "Use when you need token-efficient" → "Use when you need **a** token-efficient" |
| `research-read-only-detection.md` heading | `O_TMPF` → `O_TMPFILE` |
| `research-circuit-breaker.md` | Resolve contradictory timestamp comment |
| `loop-safety-infra/research.md` | Fix qa-engineer file access attribution |
| `loop-safety-infra/research.md` | Fix misplaced backtick |

**Verification**: Spot-check each file after changes — no remaining typos of the listed types.

### FR-010: Fix Naming and Consistency Issues

**Priority**: Medium
**Maps to**: US-4
**Bugs**: #35, #38, #50, #51

Fix naming inconsistencies across plugin files:

| File | Change |
|------|--------|
| `external-reviewer.md` | Ensure lock file name matches the file it protects |
| `spec-executor.md` | Use consistent dot notation for state.json field paths |
| `index-state.json` | Change `"complete"` → `"completed"` |
| `index.md` | Change `"complete"` → `"completed"` in phase status references |

**Verification**: After changes, grep for `"complete"` (not followed by `d`) returns no matches in phase status contexts.

### FR-011: Fix Requirements and Specification Gaps

**Priority**: Medium
**Maps to**: US-5
**Bugs**: #57, #58, #59

Fix gaps in the loop-safety-infra requirements and spec documentation:

| File | Change |
|------|--------|
| `requirements.md` FR-002 | Add explicit AC references (AC-1.1 through AC-1.6) |
| `requirements.md` FR-003 | Add explicit AC references (AC-2.1 through AC-2.7) |
| `requirements.md` glossary | Clarify jq only processes JSON, not YAML |
| `requirements.md` glossary | Fix any misspellings |

**Verification**: FR-002 and FR-003 both reference specific AC numbers in the `Maps to` column.

## Non-Functional Requirements

### NFR-001: Shell Syntax

All modified shell scripts pass `bash -n <file>` with zero errors.

**Category**: Syntax
**Verification**: `bash -n <file>` exits 0 for all modified `.sh` files.

### NFR-002: JSON Validity

All modified JSON files pass `jq empty <file>`.

**Category**: Syntax
**Verification**: `jq empty <file>` exits 0 for `.ralph-state.json` and any modified `.json` files.

### NFR-003: Python Syntax

All modified Python files pass `python3 -m py_compile <file>`.

**Category**: Syntax
**Verification**: `python3 -m py_compile _bmad/scripts/resolve_config.py` exits 0.

### NFR-004: CSV Validity

All modified CSV files parse correctly with `python3 -c "import csv; list(csv.reader(open('<file>')))"`.

**Category**: Syntax
**Verification**: No CSV parse errors after changes.

### NFR-005: No Pre-existing Errors Blamed

No pre-existing code errors are introduced or blamed on these fixes.

**Category**: Safety
**Verification**: No new errors in files not listed as targets. Pre-existing issues in disputed bugs (#10, #40, #41, #43, #86-89, #92, #95, #97, #103-105) are not modified.

### NFR-006: Minimal Scope

Only the files explicitly listed in the bug report are modified. No refactoring of adjacent code.

**Category**: Safety
**Verification**: `git diff` shows changes only in the listed target files.

### NFR-007: SOLID Compliance

Changes follow SOLID principles: SRP (single responsibility), OCP (open/closed), LSP (Liskov substitution), ISP (interface segregation), DIP (dependency inversion).

**Category**: Quality
**Verification**: No new classes/functions that violate these principles. Small surgical changes minimize risk.

## Glossary

| Term | Definition |
|------|-----------|
| **`jq`** | A command-line JSON processor. Processes JSON only — NOT YAML. |
| **`sha256sum`** | A shell utility that computes SHA-256 hashes. NOT a jq function. |
| **`grep -F`** | Fixed-string grep, treats the pattern as a literal string (no regex). |
| **`deep_merge`** | Recursive merge of two data structures, preserving fields from the base that are not in the override. |
| **checkpoint** | A git commit snapshot taken before task execution to enable rollback. |
| **circuit breaker** | A fault-tolerance pattern that stops execution after repeated failures. |
| **`.ralph-state.json`** | The per-spec state file tracking execution progress, safety mechanisms, and metrics. |
| **`_bmad/`** | The BMad module root directory containing configs, scripts, and module definitions. |

## Out of Scope

| Item | Reason |
|------|--------|
| Already-fixed bugs (#5, #6, #7, #8, #9, #41) | Resolved in prior commits |
| Disputed bugs (#10, #40, #43, #86, #87, #88, #89, #92, #95, #97, #103-105) | Review report classified as disputed or not code bugs |
| `bmad-distillator` skill renaming | Requires skill directory rename, manifest updates, and CSV changes across many files — low risk/reward |
| `external-reviewer.md` → `spec-reviewer.md` file rename | Would require updating all references across 10+ files — stylistic, not functional |
| Loop-safety-infra design/doc alignment (#86-89) | Design decisions, not code bugs |
| Rollback `$spec_name` variable (#43) | Markdown instruction to coordinator, not executable bash |
| Epic roadmap typos (#52-#55) | Doc-only, no code impact |

## Dependencies

| Dependency | Status | Impact |
|------------|--------|--------|
| `loop-safety-infra` spec | Reference | All fixed files originate from this spec's codebase audit |
| `engine-roadmap-epic` | Reference | This spec is Spec 5 in the epic chain |
| `role-boundaries` spec | Partial | VOLATION typo fix was already done in this spec (#99 resolved) |

## Success Criteria

- [ ] All 8 confirmed bugs are fixed (verified by running the bug-specific test commands from research.md)
- [ ] All documentation typos in scope are corrected (spot-check 5+ files)
- [ ] All shell files pass `bash -n`
- [ ] All Python files pass `py_compile`
- [ ] No pre-existing functionality is broken (existing tests still pass)
- [ ] `.github/` files are tracked by git (`git ls-files .github/` returns results)

## Verification Contract

**Project type**: cli

**Entry points**:
- Shell scripts: `checkpoint.sh`, `load-spec-context.sh`, `discover-ci.sh`, `stop-watcher.sh`, `resolve_config.py`
- Test scripts: `test-benchmark.sh`, `test-checkpoint.sh`
- Config files: `.gitignore`, `index-state.json`
- Docs: `research-read-only-detection.md`, `research-circuit-breaker.md`, `research.md`, `module-help.csv`

**Observable signals**:
- PASS: `.gitignore` no longer contains `.github/` — `git ls-files .github/` lists files
- PASS: `resolve_config.py` preserves base item fields after merge — test script returns exit 0
- PASS: `checkpoint.sh` with a path containing `(` — grep does not error, correctly detects read-only
- PASS: `load-spec-context.sh` — mkdir failure returns non-zero exit code
- PASS: `stop-watcher.sh` — CI hash is a 64-character hex string, not empty
- PASS: `discover-ci.sh` — output includes `category` field for each command
- PASS: `test-benchmark.sh` — summary block prints even when assertions fail
- PASS: `test-checkpoint.sh` — assertion fails when SHA is empty
- PASS: All `.sh` files pass `bash -n`
- PASS: `resolve_config.py` passes `py_compile`

**Hard invariants**:
- Auth/session validity: No changes to authentication or session management
- Permissions: No changes to file permission handling
- Adjacent flows: Checkpoint create/rollback must still work after regex fix
- Metrics: CI hash change does not break existing metrics format
- Config merge: Existing config files must still parse correctly after deep merge fix

**Seed data**:
- A git repo with `.github/workflows/` directory containing at least one `.yml` file
- A `_bmad/scripts/resolve_config.py` with existing TOML config files
- A test spec directory with `.ralph-state.json` containing checkpoint data
- `/proc/mounts` containing at least one entry with `ro` flag

**Dependency map**:
- `loop-safety-infra` spec — all fixed files originate from this spec
- `engine-roadmap-epic` — this spec is part of the epic chain
- `role-boundaries` spec — shared files (VOLATION typo already fixed)
- `codebase-indexing` spec — shares `resolve_config.py`

**Escalate if**:
- CI hash change breaks existing CI drift detection (regression sweep required)
- Deep merge change corrupts existing config files (regression sweep required)
- `.gitignore` change causes CI/CD to expose secrets (verify `.github/` contents)
- `grep -F` change in checkpoint.sh misses valid read-only mounts (regression sweep required)
- Test fix changes cause previously-passing tests to fail (verify no pre-existing errors)
