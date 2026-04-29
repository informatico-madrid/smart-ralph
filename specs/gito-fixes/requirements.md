---
spec: gito-fixes
basePath: /mnt/bunker_data/ai/smart-ralph/specs/gito-fixes
phase: requirements
created: 2026-04-29T00:00:00Z
---

# Requirements: Gito Automated Code Review Fixes

## Goal

Fix all 55 confirmed bugs identified by Gito automated code review across the Smart Ralph codebase. Scope: 24 HIGH, 21 MEDIUM, 10 LOW severity issues spanning plugin scripts, commands, hooks, references, schemas, spec documents, test scripts, and typographical errors.

## User Stories

### US-1: Plugin Script Bugs

**As a** developer maintaining ralph-bmad-bridge plugin,
**I want** all shell script bugs fixed (grep -c corruption, invalid regex, basename portability, eval security),
**So that** the plugin runs correctly on POSIX shells and avoids security vulnerabilities.

**Acceptance Criteria:**
- AC-1.1: `grep -c ... || echo 0` replaced with `grep -c ... || true` in all ralph-bmad-bridge scripts.
- AC-1.2: Non-portable `${f%.}` basename expansion replaced with POSIX-compatible `basename` command.
- AC-1.3: `eval` on untrusted input replaced with safe alternatives (jq or direct parsing).
- AC-1.4: All shell scripts pass `shellcheck` with zero HIGH/MEDIUM errors.

### US-2: Plugin Command Bugs

**As a** developer maintaining ralph-specum plugin commands,
**I want** command-level bugs fixed (path resolution, duplicate args, missing variable assignment),
**So that** commands resolve paths correctly and parse arguments without conflicts.

**Acceptance Criteria:**
- AC-2.1: Path resolution dirname depth corrected in ralph-bmad-bridge commands (verified by comparing computed path against actual PROJECT_ROOT).
- AC-2.2: Duplicate spec-name argument extraction removed — spec name extracted once from earliest source.
- AC-2.3: All referenced variables are assigned before first use.

### US-3: Plugin Hook Bugs

**As a** developer maintaining ralph-specum plugin hooks,
**I want** hook-level bugs fixed (unchecked cd, invalid regex, subshell exit code masking),
**So that** hooks fail visibly and detect read-only filesystems correctly.

**Acceptance Criteria:**
- AC-3.1: All `cd` commands have error handling: `cd "$path" || { echo "[error]"; return 1; }`.
- AC-3.2: Invalid `[\s]` POSIX regex replaced with `[[:space:]]` in all grep calls within checkpoint.sh and stop-watcher.sh.
- AC-3.3: Subshell exit code in write-metric.sh captured: `return $?` instead of `return 0`.

### US-4: Plugin Reference/Schema Bugs

**As a** developer maintaining ralph-specum plugin references and schemas,
**I want** reference documentation and JSON schemas fixed (contradictory denylist, wrong column, hardcoded placeholder, missing fields, internal ticket leaks),
**So that** role contracts are internally consistent and schemas are production-ready.

**Acceptance Criteria:**
- AC-4.1: spec-reviewer denylist changed from "All files" to "_(read-only)_".
- AC-4.2: qa-engineer Writes column corrected to "_(read-only)_".
- AC-4.3: Hardcoded `/path/to/mount` placeholder replaced with dynamic path reference.
- AC-4.4: Internal ticket references (SR-003, etc.) stripped from schema descriptions.
- AC-4.5: Missing field definitions added to spec.schema.json; agent docs cross-reference validated.

### US-5: Spec Index Fix

**As a** Ralph loop coordinator consuming index-state.json,
**I want** the inconsistent phase value corrected,
**So that** phase comparison logic does not break on "complete" vs "completed".

**Acceptance Criteria:**
- AC-5.1: `ralph-quality-improvements` entry in index-state.json changed from `"phase": "complete"` to `"phase": "completed"`.

### US-6: Spec Document Fixes

**As a** developer working on any spec,
**I want** all spec-level document bugs fixed (epic, research, requirements, design, plan, tasks),
**So that** spec documents are internally consistent, logically sound, and executable.

**Acceptance Criteria:**
- AC-6.1: Self-referential dependency in engine-roadmap-epic epic.md fixed (Spec 6 -> Spec 7).
- AC-6.2: jq `//` operator false handling fixed in loop-safety-infra research-read-only-detection.md (false states preserved).
- AC-6.3: `exit 0` on fatal error changed to `exit 1` in research-read-only-detection.md.
- AC-6.4: Heartbeat guard condition removed — runs every iteration per design.
- AC-6.5: Contradictory `--no-verify` docs clarified in research.md.
- AC-6.6: Malformed JSON from useless `tr ',' ','` fixed using `split(",")` in jq.
- AC-6.7: Bash command inside jq filter replaced with proper jq syntax.
- AC-6.8: Conflicting BMAD versions harmonized in bmad-bridge-plugin requirements.md.
- AC-6.9: Metrics field generation responsibility clarified (write-metric.sh vs coordinator).
- AC-6.10: Awk regex `^##` fixed to `^## [^#]` in bmad-bridge-plugin design.md.
- AC-6.11: Duplicate test strategy entries corrected in design.md.
- AC-6.12: Missing write targets added to bmad-bridge-plugin plan.md.
- AC-6.13: Condition count mismatch fixed in pair-debug-auto-trigger plan.md.
- AC-6.14: jq boolean chain `and` replaced with `has()` in loop-safety-infra tasks.md.
- AC-6.15: Regex contradicting minimum-length validation fixed in role-boundaries tasks.md.
- AC-6.16: `grep -c > 0` file creation bug replaced with `grep -q` in role-boundaries tasks.md.
- AC-6.17: JSON baseline format mismatch harmonized between producer and consumer in role-boundaries.

### US-7: Test Script Fixes

**As a** qa-engineer running spec tests,
**I want** all test script bugs fixed,
**So that** tests are functional, portable across platforms, and actually validate their intended behavior.

**Acceptance Criteria:**
- AC-7.1: `grep -c ... || echo 0` replaced with `|| true` in loop-safety-infra tests.
- AC-7.2: State file overwrite in test-integration.sh line 73 removed.
- AC-7.3: Self-comparison `assert_eq "$sha" "$sha"` removed from test-checkpoint.sh.
- AC-7.4: Erroneous `chmod 755` restoration removed from test-heartbeat.sh.
- AC-7.5: Echo quote mismatch fixed in test-write-metric.sh.
- AC-7.6: `date +%s%N` macOS/BSD portability wrapper added to test-benchmark.sh.
- AC-7.7: Fragile sed regex in test-benchmark.sh anchored to `[[:space:]]*`.

### US-8: Typographical and Formatting Fixes

**As a** reader of Smart Ralph documentation,
**I want** typos, corrupted tables, sentence fragments, and contradictory status flags corrected,
**So that** all documentation is clear and internally consistent.

**Acceptance Criteria:**
- AC-8.1: All typos corrected: Bmalph -> BMAD, excption -> exception, smart-ralsh -> smart-ralph.
- AC-8.2: Contradictory [x] + PENDING_COMMIT status flags replaced with actual git hashes.
- AC-8.3: Corrupted markdown table row in role-boundaries/research.md reformatted.
- AC-8.4: Sentence fragment "The access matrix covers ~8. ~19 fields" fixed to two complete sentences.

---

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-001 | Fix grep -c \|\| echo 0 corruption in plugin scripts | High | AC-1.1: Variable contains single "0", not "0\n0" |
| FR-002 | Fix grep -c \|\| echo 0 corruption in test scripts | High | AC-7.1: test-integration.sh arithmetic comparison works |
| FR-003 | Replace non-portable basename expansion with POSIX basename | High | AC-1.2: Works on sh, bash, dash |
| FR-004 | Replace eval with safe parsing | High | AC-1.3: No eval calls on untrusted input |
| FR-005 | Fix dirname depth off-by-one in path resolution | High | AC-2.1: Computed ROOT_DIR points to correct directory |
| FR-006 | Remove duplicate spec-name argument extraction | Medium | AC-2.2: Spec name extracted from single source |
| FR-007 | Assign all previously-unassigned variables | Medium | AC-2.3: No unassigned variable references |
| FR-008 | Add error handling to all cd commands | High | AC-3.1: cd failure outputs error message and returns 1 |
| FR-009 | Replace invalid [\s] POSIX regex with [[:space:]] | High | AC-3.2: grep matches whitespace, not literal \s |
| FR-010 | Capture subshell exit code in write-metric.sh | High | AC-3.3: return $? propagates subshell failure |
| FR-011 | Fix spec-reviewer denylist contradiction | Medium | AC-4.1: Denylist says "(read-only)", not "All files" |
| FR-012 | Fix qa-engineer Writes column content | Medium | AC-4.2: Writes column says "(read-only)", not read description |
| FR-013 | Replace hardcoded /path/to/mount with dynamic path | Low | AC-4.3: Step 2 references same discovery command as Step 1 |
| FR-014 | Strip internal ticket refs from schema descriptions | Low | AC-4.4: No SR-XXX or date-format strings in descriptions |
| FR-015 | Add missing field definitions to spec.schema.json | Medium | AC-4.5: All agent-doc-referenced fields present in schema |
| FR-016 | Correct phase value from "complete" to "completed" | Medium | AC-5.1: All finished specs use "completed" |
| FR-017 | Fix self-referential dependency in epic.md | High | AC-6.1: Spec 7 depends on Spec 6 (not itself) |
| FR-018 | Fix jq // operator false handling | High | AC-6.2: Explicit false state preserved in JSON |
| FR-019 | Change exit 0 to exit 1 on fatal error | High | AC-6.3: Caller sees non-zero exit on filesystem failure |
| FR-020 | Remove heartbeat guard condition | High | AC-6.4: Heartbeat runs every iteration unconditionally |
| FR-021 | Clarify --no-verify docs | High | AC-6.5: No contradictory statements about hook behavior |
| FR-022 | Fix malformed JSON from useless tr | High | AC-6.6: jq split(",") produces correct array |
| FR-023 | Fix bash inside jq filter | High | AC-6.7: Pure jq syntax, no bash constructs |
| FR-024 | Harmonize BMAD version references | Medium | AC-6.8: Single version number throughout document |
| FR-025 | Clarify metrics field generation responsibility | Medium | AC-6.9: write-metric.sh owns field population |
| FR-026 | Fix awk regex premature exit | Medium | AC-6.10: Only matches ## not ### headings |
| FR-027 | Remove duplicate test strategy entries | Low | AC-6.11: Each test type has unique entry |
| FR-028 | Add missing write targets to plan.md | Medium | AC-6.12: user stories and test scenarios listed |
| FR-029 | Fix condition count mismatch | Medium | AC-6.13: Text matches actual condition count |
| FR-030 | Fix jq boolean chain fails on taskIndex=0 | High | AC-6.14: has() used instead of boolean and |
| FR-031 | Fix regex contradicting minimum-length requirement | High | AC-6.15: Regex enforces 2+ character names |
| FR-032 | Fix grep -c > 0 file creation bug | High | AC-6.16: grep -q used instead of > redirection |
| FR-033 | Harmonize JSON baseline format | Medium | AC-6.17: Producer/consumer use same nested format |
| FR-034 | Fix state file overwrite in test-integration.sh | High | AC-7.2: Circuit breaker state survives to test 5 |
| FR-035 | Remove redundant assert_eq self-comparison | High | AC-7.3: Assertion removed, length check remains |
| FR-036 | Remove erroneous chmod restoration in test-heartbeat.sh | High | AC-7.4: Both failure iterations see unwritable state |
| FR-037 | Fix echo quote mismatch in test-write-metric.sh | High | AC-7.5: bash syntax error gone |
| FR-038 | Fix date +%s%N macOS/BSD portability | High | AC-7.6: Fallback to date +%s with zero-padding works |
| FR-039 | Fix fragile sed regex anchoring | High | AC-7.7: sed handles indented function definitions |
| FR-040 | Correct all typos (Bmalph, excption, smart-ralsh) | Low | AC-8.1: All instances corrected |
| FR-041 | Fix contradictory [x] + PENDING_COMMIT flags | Medium | AC-8.2: Git hashes or removed |
| FR-042 | Fix corrupted markdown table row | Low | AC-8.3: Table parses correctly |
| FR-043 | Fix sentence fragment | Low | AC-8.4: Two complete sentences |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-001 | Shellcheck compliance | HIGH/MEDIUM errors | 0 in all fixed scripts |
| NFR-002 | POSIX shell compatibility | Script execution on sh/dash/bash | All scripts pass on sh |
| NFR-003 | Test functionality | Test scripts actually validate intended behavior | All 7 test script fixes verified |
| NFR-004 | Documentation consistency | Internal contradictions in spec docs | 0 contradictions in fixed docs |
| NFR-005 | bmad-party-mode consensus | Quality gate tasks pass by consensus | Every quality gate passes |

## Glossary

- **Gito**: Automated code review tool that identified 94 issues in the Smart Ralph codebase
- **POSIX**: Portable Operating System Interface — Unix standard ensuring shell script portability
- **`[\s]` regex**: Invalid POSIX regex — grep does not recognize `\s` in character classes
- **`//` jq operator**: Alternative operator in jq — treats `false` as falsy, causing `false // true` to yield `true`
- **`|| echo 0` corruption**: Pattern where `grep -c` returns "0" (exit 1) and `|| echo 0` appends another "0", producing "0\n0"
- **Quality Gate**: Task inserted every 3-4 implementation tasks that requires bmad-party-mode consensus before proceeding
- **bmad-party-mode**: Consensus verification mechanism requiring relevant voices to agree before marking tasks complete
- **SPEC_PATH**: Environment variable pointing to the active spec directory
- **PROJECT_ROOT**: Root directory of the Smart Ralph project

## Out of Scope

- Already-fixed issues from previous session (7 items in classification report)
- Confirmed false positives / cosmetic items (34 items: intentional design, subjective preferences, correct-by-design patterns)
- _bmad config data (CSV typos, TOML metadata, user config files)
- docs/ README grammar and heading hierarchy (subjective)
- plans/ typos (documentation only)
- Schema missing `format: date-time` (nice-to-have, not required)
- Numbering re-ordering in loop-safety.md (subjective)
- Mixed Spanish/English in adversarial review document

## Dependencies

- Gito classification report must be authoritative (`gito-review-classification.md`)
- BMAD version reference must be confirmed before harmonization
- Shellcheck must be available for NFR-001 compliance verification
- bmad-party-mode voices must be configured and available for quality gates

## Success Criteria

- All 55 confirmed issues resolved (tracked in PR commits)
- Zero HIGH/MEDIUM shellcheck errors in fixed scripts
- All test scripts pass after fixes
- No regressions in existing functionality (verified by bmad-party-mode consensus)

## Verification Contract

**Project type**: fullstack

**Entry points**:
- `plugins/ralph-bmad-bridge/scripts/` — shell scripts (grep, eval, basename fixes)
- `plugins/ralph-bmad-bridge/commands/` — path resolution fix
- `plugins/ralph-specum/hooks/scripts/checkpoint.sh` — cd error handling, regex fix
- `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` — regex fix
- `plugins/ralph-specum/hooks/scripts/write-metric.sh` — subshell exit code fix
- `plugins/ralph-specum/commands/implement.md` — argument parsing fix
- `plugins/ralph-specum/references/role-contracts.md` — denylist and column fixes
- `plugins/ralph-specum/references/loop-safety.md` — placeholder fix
- `plugins/ralph-specum/schemas/spec.schema.json` — ticket refs and missing fields
- `specs/.index/index-state.json` — phase value fix
- `specs/_epics/engine-roadmap-epic/epic.md` — self-ref and typo fixes
- `specs/loop-safety-infra/` — research docs, test scripts, tasks.md, .progress.md
- `specs/bmad-bridge-plugin/` — requirements.md, design.md, plan.md, .progress.md
- `specs/pair-debug-auto-trigger/plan.md` — condition count fix
- `specs/role-boundaries/` — design.md, research.md, tasks.md, adversarial-review
- `specs/role-boundaries/research.md` — table and fragment fixes

**Observable signals**:
- PASS: All shell scripts execute without errors under `set -euo pipefail`; shellcheck reports 0 HIGH/MEDIUM; test scripts produce expected output; spec documents parse correctly; JSON schema validates; index-state.json uses consistent "completed" phase
- FAIL: Script exits non-zero unexpectedly; grep matches literal `\s` instead of whitespace; variable contains "0\n0"; cd silently fails; subshell writes fail silently; schema validation error; test produces wrong output

**Hard invariants**:
- Auth/session: Not applicable (internal codebase, no auth)
- Permissions: Do not change file permissions beyond fixing test scripts
- Adjacent flows: Do not modify files outside the listed entry points
- Plugin commands: `ralph-specum:implement` command signature must remain unchanged
- Loop execution: stop-watcher.sh must still produce ALL_TASKS_COMPLETE when loop finishes

**Seed data**:
- Valid git repo at project root
- At least one existing spec in specs/ directory for testing
- BMAD voices configured and available for quality gates
- shellcheck installed for NFR-001 verification

**Dependency map**:
- engine-roadmap-epic (parent epic containing affected specs)
- loop-safety-infra spec (largest affected spec, 14 issues)
- bmad-bridge-plugin spec (7 issues, shares plugin with bmad-bridge)
- ralph-specum plugin (19 issues, core plugin)
- role-boundaries spec (6 issues)

**Escalate if**:
- BMAD version number conflict cannot be resolved without user decision
- Any fix breaks an existing test that was not identified by Gito
- shellcheck introduces new errors not identified by Gito
- Fix scope discovered during implementation exceeds original 55 issues
