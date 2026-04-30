# Tasks: Code Fixes 2

## Phase 1: Fix Critical Runtime Bugs

Focus: 8 confirmed runtime bugs that cause silent failures, CI blocks, or config corruption.

- [x] 1.1 [P] Remove `.github/` from `.gitignore` (Bug #4)
  - **Do**: Read `.gitignore` line 51, remove the line containing `.github/`
  - **Files**: `.gitignore`
  - **Done when**: Line 51 no longer contains `.github/`
  - **Verify**: `! grep -q '^\s*\.github/\s*$' /mnt/bunker_data/ai/smart-ralph/.gitignore && echo T1.1_PASS`
  - **Commit**: `fix: remove .github/ from .gitignore (Bug #4)`
  - _Requirements: FR-001, AC-1.1_
  - _Design: Fix 1_

- [x] 1.2 [P] Deep merge in `_merge_by_key()` (Bug #19) - already fixed, verified
  - **Do**: Read `_bmad/scripts/resolve_config.py` line 95, replace `result[index_by_key[key]] = dict(item)` with `result[index_by_key[key]] = deep_merge(dict(base_item), dict(item))` where base_item comes from the base array
  - **Files**: `_bmad/scripts/resolve_config.py`
  - **Done when**: `_merge_by_key` calls `deep_merge` instead of `dict(item)` replacement
  - **Verify**: `python3 -c "import sys; sys.path.insert(0, '_bmad/scripts'); from resolve_config import deep_merge; base = {'agents': [{'code': 'a1', 'name': 'original', 'version': '1.0'}]}; override = {'agents': [{'code': 'a1', 'name': 'updated'}]}; result = deep_merge(base, override); assert result['agents'][0]['version'] == '1.0'; print('T1.2_PASS')" && echo T1.2_PASS`
  - **Commit**: `fix: deep merge base fields in _merge_by_key (Bug #19)`
  - _Requirements: FR-002, AC-1.2_
  - _Design: Fix 2_

- [ ] 1.3 [P] Fixed-string grep in `checkpoint.sh` (Bug #44)
  - **Do**: Read `plugins/ralph-specum/hooks/scripts/checkpoint.sh` lines 53-54. Replace the two `grep -q` calls that use regex with unescaped `${fs_check_dir}`. Use `grep -F` for fixed-string matching, then pipe to `grep -E` for the `ro` check on filtered results.
  - **Files**: `plugins/ralph-specum/hooks/scripts/checkpoint.sh`
  - **Done when**: Lines 53-54 use `grep -F` for the path, `grep -E` for the `ro` flag on filtered output
  - **Verify**: `bash -n /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/checkpoint.sh && echo T1.3_PASS`
  - **Commit**: `fix: use grep -F in checkpoint.sh read-only detection (Bug #44)`
  - _Requirements: FR-003, AC-1.3_
  - _Design: Fix 3_

- [ ] 1.4 [VERIFY] Quality gate: shell syntax, JSON validity, python syntax, SOLID check
  - **Do**: Run `/bmad-party-mode` with voices architect, dev, test architect, pm
    - Ask each agent to validate:
      1. SRP: Each function/file has single responsibility
      2. OCP: Open for extension, closed for modification
      3. LSP compliance (no subtype violations)
      4. ISP compliance (no fat interfaces)
      5. DIP compliance (depend on abstractions)
    - Run ALL syntax/format validation commands:
      - `bash -n plugins/ralph-specum/hooks/scripts/checkpoint.sh`
      - `bash -n plugins/ralph-specum/hooks/scripts/load-spec-context.sh`
      - `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
      - `bash -n plugins/ralph-specum/hooks/scripts/discover-ci.sh`
      - `bash -n plugins/ralph-specum/hooks/scripts/resolve_config.py`
      - `jq empty specs/.index/index-state.json` (if modified)
      - `python3 -m py_compile _bmad/scripts/resolve_config.py`
    - Confirm NO pre-existing errors blamed as test failures
    - Confirm NO @ng-no-cover pragmas
    - Confirm NO shortcut tests
  - **Verify**: All commands above exit 0
  - **Done when**: All syntax checks pass, SOLID consensus achieved
  - **Commit**: `quality(gate): quality gate consensus for tasks 1.1-1.3`
  - _Design: All fixes in Phase 1_

- [ ] 1.5 [P] Exit on `mkdir` failure in `load-spec-context.sh` (Bug #45)
  - **Do**: Read `plugins/ralph-specum/hooks/scripts/load-spec-context.sh` line 114, add `return 1;` after the error echo in the `|| { ... }` block
  - **Files**: `plugins/ralph-specum/hooks/scripts/load-spec-context.sh`
  - **Done when**: Line 114 block includes `return 1;` after the error echo
  - **Verify**: `bash -n /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/load-spec-context.sh && echo T1.5_PASS`
  - **Commit**: `fix: exit on mkdir failure in load-spec-context.sh (Bug #45)`
  - _Requirements: FR-004, AC-1.4_
  - _Design: Fix 4_

- [ ] 1.6 [P] Fix CI command hash computation (Bug #46)
  - **Do**: Read `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` line 942. Replace `cmd_hash=$(echo "$cmd" | jq -R -s 'sha256sum | split(" ")[0]')` with `cmd_hash=$(echo -n "$cmd" | sha256sum | cut -d' ' -f1)`
  - **Files**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
  - **Done when**: Line 942 uses `sha256sum` shell command instead of invalid jq
  - **Verify**: `bash -n /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo -n "test" | sha256sum | cut -d' ' -f1 | wc -c | grep -q '^65$' && echo T1.6_PASS`
  - **Commit**: `fix: use sha256sum shell command for CI hash (Bug #46)`
  - _Requirements: FR-005, AC-1.5_
  - _Design: Fix 5_

- [ ] 1.7 [P] Add CI command categories in `discover-ci.sh` (Bug #85)
  - **Do**: Read `plugins/ralph-specum/hooks/scripts/discover-ci.sh` lines 48-53. Replace the `jq -R -n '[inputs | select(length > 0)] | unique'` output with a jq expression that maps each command to a `{command, category}` object using regex classification (test, lint, build, typecheck). Unknown commands default to `"test"` category.
  - **Files**: `plugins/ralph-specum/hooks/scripts/discover-ci.sh`
  - **Done when**: Each output object has `command` + `category` keys, category is one of {test, lint, build, typecheck}
  - **Verify**: `bash -n /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/discover-ci.sh && echo T1.7_PASS`
  - **Commit**: `fix: add CI command categories to discover-ci.sh (Bug #85)`
  - _Requirements: FR-006, AC-1.6_
  - _Design: Fix 6_

- [ ] 1.8 [VERIFY] Quality gate: shell syntax, JSON validity, python syntax, SOLID check
  - **Do**: Run `/bmad-party-mode` with voices architect, dev, test architect, pm
    - Ask each agent to validate:
      1. SRP: Each function/file has single responsibility
      2. OCP: Open for extension, closed for modification
      3. LSP compliance (no subtype violations)
      4. ISP compliance (no fat interfaces)
      5. DIP compliance (depend on abstractions)
    - Run ALL syntax/format validation commands:
      - `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
      - `bash -n plugins/ralph-specum/hooks/scripts/discover-ci.sh`
      - `python3 -m py_compile _bmad/scripts/resolve_config.py`
      - `jq empty specs/.index/index-state.json` (if modified)
    - Confirm NO pre-existing errors blamed as test failures
    - Confirm NO @ng-no-cover pragmas
    - Confirm NO shortcut tests
  - **Verify**: All commands above exit 0
  - **Done when**: All syntax checks pass, SOLID consensus achieved
  - **Commit**: `quality(gate): quality gate consensus for tasks 1.5-1.7`
  - _Design: All fixes in Phase 1_

## Phase 2: Fix Test Infrastructure Bugs

Focus: 2 test script bugs that cause test results to be lost.

- [ ] 2.1 [P] Remove `exit 1` from `test-benchmark.sh` (Bug #94)
  - **Do**: Read `specs/loop-safety-infra/tests/test-benchmark.sh` line 48. Replace `[ "$avg_ms" -lt 10 ] || { assert_fail "Average ${avg_ms}ms exceeds 10ms threshold"; exit 1; }` with `[ "$avg_ms" -lt 10 ] || assert_fail "Average ${avg_ms}ms exceeds 10ms threshold"`
  - **Files**: `specs/loop-safety-infra/tests/test-benchmark.sh`
  - **Done when**: Line 48 no longer calls `exit 1`, test continues to summary block on failure
  - **Verify**: `bash -n /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/tests/test-benchmark.sh && ! grep -q 'exit 1' /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/tests/test-benchmark.sh && echo T2.1_PASS`
  - **Commit**: `fix: remove exit 1 from test-benchmark.sh (Bug #94)`
  - _Requirements: FR-007, AC-2.1_
  - _Design: Fix 7_

- [ ] 2.2 [P] Fix tautology in `test-checkpoint.sh` (Bug #96)
  - **Do**: Read `specs/loop-safety-infra/tests/test-checkpoint.sh` line 49. Replace `assert_eq "$sha" "$sha" "sha is non-empty (${#sha} chars)" || true` with `assert_eq "true" "$(if [ ${#sha} -ge 7 ]; then echo true; else echo false; fi)" "sha length >= 7 characters" || true`
  - **Files**: `specs/loop-safety-infra/tests/test-checkpoint.sh`
  - **Done when**: Line 49 performs a real assertion (SHA length >= 7) instead of comparing variable with itself
  - **Verify**: `bash -n /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/tests/test-checkpoint.sh && echo T2.2_PASS`
  - **Commit**: `fix: replace tautology with real SHA assertion in test-checkpoint.sh (Bug #96)`
  - _Requirements: FR-008, AC-2.2_
  - _Design: Fix 8_

- [ ] 2.3 [VERIFY] Quality gate: shell syntax, test files, SOLID check
  - **Do**: Run `/bmad-party-mode` with voices architect, dev, test architect, pm
    - Ask each agent to validate:
      1. SRP: Each test function has single responsibility
      2. OCP: Test extensions don't require modifying existing tests
      3. LSP compliance (no subtype violations)
      4. ISP compliance (no fat interfaces)
      5. DIP compliance (depend on abstractions)
    - Run ALL syntax/format validation commands:
      - `bash -n specs/loop-safety-infra/tests/test-benchmark.sh`
      - `bash -n specs/loop-safety-infra/tests/test-checkpoint.sh`
    - Confirm NO pre-existing errors blamed as test failures
    - Confirm NO @ng-no-cover pragmas
    - Confirm NO shortcut tests
  - **Verify**: All commands above exit 0
  - **Done when**: All syntax checks pass, SOLID consensus achieved
  - **Commit**: `quality(gate): quality gate consensus for tasks 2.1-2.2`
  - _Design: All fixes in Phase 2_

## Phase 3: Fix Typos and Documentation

Focus: 3 documentation typos and contradictory comments.

- [ ] 3.1 [P] Fix `distillator` typos in `module-help.csv` (Bugs #11, #18, #13)
  - **Do**: Read `_bmad/core/module-help.csv` line 12. Change `bmad-distillator` to `bmad-distiller`, `Distillator` to `Distiller`, and add missing article: `"Use when you need token-efficient distillates"` to `"Use when you need **a** token-efficient distillate"`
  - **Files**: `_bmad/core/module-help.csv`
  - **Done when**: Line 12 uses `bmad-distiller` and `Distiller`, has article `**a**`, singular `distillate`
  - **Verify**: `python3 -c "import csv; list(csv.reader(open('/mnt/bunker_data/ai/smart-ralph/_bmad/core/module-help.csv')))" && ! grep -q 'distillator' /mnt/bunker_data/ai/smart-ralph/_bmad/core/module-help.csv && grep -q 'bmad-distiller' /mnt/bunker_data/ai/smart-ralph/_bmad/core/module-help.csv && echo T3.1_PASS`
  - **Commit**: `fix: distillator to distiller in module-help.csv (Bugs #11, #18, #13)`
  - _Requirements: US-3, AC-3.1, AC-3.2_
  - _Design: Fix 9_

- [ ] 3.2 [P] Fix `O_TMPF` heading and circuit-breaker timestamp comment (Bugs #93, #90)
  - **Do**: Read `specs/loop-safety-infra/research-read-only-detection.md` line 210, change `### 3.5 Alternative: O_TMPF (Linux 3.11+)` to `### 3.5 Alternative: O_TMPFILE (Linux 3.11+)`. Read `specs/loop-safety-infra/research-circuit-breaker.md` line 267, remove the contradictory comment `(ISO in human-readable output)` from the `// epoch seconds` comment.
  - **Files**: `specs/loop-safety-infra/research-read-only-detection.md`, `specs/loop-safety-infra/research-circuit-breaker.md`
  - **Done when**: Heading uses `O_TMPFILE`, contradictory comment removed from circuit-breaker
  - **Verify**: `grep -q 'O_TMPFILE' /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/research-read-only-detection.md && ! grep -q 'epoch seconds (ISO in human-readable' /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/research-circuit-breaker.md && echo T3.2_PASS`
  - **Commit**: `fix: O_TMPFILE heading and circuit-breaker timestamp (Bugs #93, #90)`
  - _Requirements: US-3, AC-3.3, AC-3.4_
  - _Design: Fix 10_

- [ ] 3.3 [P] Fix epic.md self-reference (Bug #52)
  - **Do**: Read `specs/_epics/engine-roadmap-epic/epic.md` line 138. Change `Spec 7 (depends on Spec 6's collaboration signals...` to `This spec (depends on Spec 6's collaboration signals...` to avoid self-reference.
  - **Files**: `specs/_epics/engine-roadmap-epic/epic.md`
  - **Done when**: Line 138 says `This spec` instead of `Spec 7` in its own dependency section
  - **Verify**: `sed -n '138p' /mnt/bunker_data/ai/smart-ralph/specs/_epics/engine-roadmap-epic/epic.md | grep -q 'This spec (depends' && echo T3.3_PASS`
  - **Commit**: `fix: remove self-reference in epic.md (Bug #52)`
  - _Requirements: US-5, AC-5.1_
  - _Design: Fix 15_

- [ ] 3.4 [VERIFY] Quality gate: CSV validity, syntax, SOLID check
  - **Do**: Run `/bmad-party-mode` with voices architect, dev, test architect, pm
    - Ask each agent to validate:
      1. SRP: Each doc change has single purpose
      2. OCP: Documentation changes don't block future extensions
      3. LSP compliance (no subtype violations)
      4. ISP compliance (no fat interfaces)
      5. DIP compliance (depend on abstractions)
    - Run ALL syntax/format validation commands:
      - `python3 -c "import csv; list(csv.reader(open('/mnt/bunker_data/ai/smart-ralph/_bmad/core/module-help.csv')))"`
      - `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
      - `bash -n plugins/ralph-specum/hooks/scripts/discover-ci.sh`
    - Confirm NO pre-existing errors blamed as test failures
    - Confirm NO @ng-no-cover pragmas
    - Confirm NO shortcut tests
  - **Verify**: All commands above exit 0
  - **Done when**: CSV parses correctly, SOLID consensus achieved
  - **Commit**: `quality(gate): quality gate consensus for tasks 3.1-3.3`
  - _Design: All fixes in Phase 3_

## Phase 4: Fix Naming and Consistency

Focus: 4 naming inconsistencies across plugin agent prompts and spec files.

- [ ] 4.1 [P] Fix lock file naming in `external-reviewer.md` (Bug #35)
  - **Do**: Read `plugins/ralph-specum/agents/external-reviewer.md` lines 479 and 514. Replace `${basePath}/tasks.md.lock` with `${basePath}/.tasks.lock` to match the canonical naming convention.
  - **Files**: `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: Lines 479 and 514 use `.tasks.lock` instead of `tasks.md.lock`
  - **Verify**: `! grep -q 'tasks.md.lock' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/agents/external-reviewer.md && grep -q '.tasks.lock' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/agents/external-reviewer.md && echo T4.1_PASS`
  - **Commit**: `fix: canonical lock file name in external-reviewer.md (Bug #35)`
  - _Requirements: US-4, AC-4.1_
  - _Design: Fix 12_

- [ ] 4.2 [P] Normalize arrow notation in `spec-executor.md` (Bug #38)
  - **Do**: Read `plugins/ralph-specum/agents/spec-executor.md` line 91. Replace the arrow notation `.ralph-state.json → clarificationRequested[taskId]` with dot notation `.ralph-state.json.clarificationRequested[taskId]`. Also normalize shorthand `chat.lastReadLine` to full path `chat.executor.lastReadLine` where applicable.
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: All state.json field paths use consistent dot notation (no `→` for field paths)
  - **Verify**: `! grep -q 'state.json →' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/agents/spec-executor.md && echo T4.2_PASS`
  - **Commit**: `fix: consistent dot notation in spec-executor.md (Bug #38)`
  - _Requirements: US-4, AC-4.2_
  - _Design: Fix 13_

- [ ] 4.3 [P] Fix header casing and phase status (Bugs #47, #50)
  - **Do**: Read `plugins/ralph-specum/references/loop-safety.md` line 85, change `### filesystem Health` to `### filesystemHealth`. Read `specs/.index/index-state.json` line 239, change `"phase": "complete"` to `"phase": "completed"`.
  - **Files**: `plugins/ralph-specum/references/loop-safety.md`, `specs/.index/index-state.json`
  - **Done when**: Header uses camelCase `filesystemHealth`, phase status uses `"completed"`
  - **Verify**: `grep -q '### filesystemHealth' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/references/loop-safety.md && grep -q '"phase": "completed"' /mnt/bunker_data/ai/smart-ralph/specs/.index/index-state.json && ! grep -q '"phase": "complete"' /mnt/bunker_data/ai/smart-ralph/specs/.index/index-state.json && echo T4.3_PASS`
  - **Commit**: `fix: header casing and phase status (Bugs #47, #50)`
  - _Requirements: US-4, AC-4.3, AC-4.4_
  - _Design: Fix 14_

- [ ] 4.4 [VERIFY] Quality gate: JSON validity, syntax, SOLID check
  - **Do**: Run `/bmad-party-mode` with voices architect, dev, test architect, pm
    - Ask each agent to validate:
      1. SRP: Each naming change has single purpose
      2. OCP: Consistent naming allows extension without modification
      3. LSP compliance (no subtype violations)
      4. ISP compliance (no fat interfaces)
      5. DIP compliance (depend on abstractions)
    - Run ALL syntax/format validation commands:
      - `jq empty specs/.index/index-state.json`
      - `python3 -c "import csv; list(csv.reader(open('/mnt/bunker_data/ai/smart-ralph/_bmad/core/module-help.csv')))"`
      - `python3 -m py_compile _bmad/scripts/resolve_config.py`
    - Confirm NO pre-existing errors blamed as test failures
    - Confirm NO @ng-no-cover pragmas
    - Confirm NO shortcut tests
  - **Verify**: All commands above exit 0
  - **Done when**: JSON parses correctly, SOLID consensus achieved
  - **Commit**: `quality(gate): quality gate consensus for tasks 4.1-4.3`
  - _Design: All fixes in Phase 4_

## Phase 5: Fix Requirements and Specification Gaps

Focus: 5 requirements gaps including missing references, ambiguous terminology, and typos in spec documents.

- [ ] 5.1 [P] Fix `bmalph` typo and epic self-reference (Bug #59, Bug #52)
  - **Do**: Read `specs/bmad-bridge-plugin/requirements.md` line 131. Replace `bmalph` with `BMAD` in the glossary entry: `"BMAD -- a BMAD Method agent framework (v6.4.0)..."`.
  - **Files**: `specs/bmad-bridge-plugin/requirements.md`
  - **Done when**: Line 131 uses `BMAD` instead of `bmalph`
  - **Verify**: `! grep -q 'bmalph' /mnt/bunker_data/ai/smart-ralph/specs/bmad-bridge-plugin/requirements.md && echo T5.1_PASS`
  - **Commit**: `fix: bmalph to BMAD in glossary (Bug #59)`
  - _Requirements: US-5, AC-5.4_
  - _Design: Fix 15_

- [ ] 5.2 [P] Add AC references and glossary clarification to `requirements.md` (Bugs #57, #58)
  - **Do**: Read `specs/loop-safety-infra/requirements.md`. Add explicit AC references to the Maps to lines:
    - FR-002 (line ~114): Change `**Maps to**: US-1` to `**Maps to**: US-1 (AC-1.1, AC-1.2, AC-1.3)`
    - FR-003 (line ~127): Change `**Maps to**: US-2` to `**Maps to**: US-2 (AC-2.1, AC-2.2, AC-2.3, AC-2.4, AC-2.5, AC-2.6, AC-2.7)`
    - Add expanded `jq` glossary entry: `| **jq** | A command-line JSON processor. Processes JSON only — NOT YAML. YAML files must be converted to JSON first (e.g., with yq) before jq processing. |`
  - **Files**: `specs/loop-safety-infra/requirements.md`
  - **Done when**: FR-002 and FR-003 have explicit AC references, glossary has expanded jq entry
  - **Verify**: `grep -q 'AC-1.1, AC-1.2, AC-1.3' /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/requirements.md && grep -q 'AC-2.1' /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/requirements.md && grep -q 'NOT YAML' /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/requirements.md && echo T5.2_PASS`
  - **Commit**: `fix: add AC references and jq glossary clarification (Bugs #57, #58)`
  - _Requirements: US-5, AC-5.1, AC-5.2, AC-5.3_
  - _Design: Fix 15 (AC-5.1, AC-5.2, AC-5.3/AC-5.4)_

- [ ] 5.3 [P] Add output file references to `plan.md` Interface Contracts (Bug #83)
  - **Do**: Read `specs/loop-safety-infra/plan.md` lines 21-26 (Writes section). Add output file references:
    - `references/loop-safety.md` — adds to `.ralph-state.json` (checkpoint.sha, checkpoint.timestamp, circuitBreaker.state)
    - `hooks/scripts/checkpoint.sh` — writes to `.ralph-state.json` (checkpoint.sha, checkpoint.timestamp)
    - `hooks/scripts/stop-watcher.sh` — writes to `.metrics.jsonl` (per-task metric entries)
    - `schemas/spec.schema.json` — adds ciCommands: string[] field
    - `commands/implement.md` — adds pre-loop git checkpoint step
  - **Files**: `specs/loop-safety-infra/plan.md`
  - **Done when**: Writes section includes output file references for each contract entry
  - **Verify**: `grep -q '.ralph-state.json' /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/plan.md && grep -q '.metrics.jsonl' /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/plan.md && echo T5.3_PASS`
  - **Commit**: `fix: add output file references to plan.md Interface Contracts (Bug #83)`
  - _Requirements: US-5, AC-5.5_
  - _Design: Fix 15 (AC-5.5)_

- [ ] 5.4 [P] Fix ambiguous `N` variable in `plan.md` (Bug #84)
  - **Do**: Read `specs/loop-safety-infra/plan.md` line 10. Replace `"Circuit breaker stops after N consecutive failures (default 5) or N hours (default 48h)"` with `"Circuit breaker stops after max_failures (default 5) consecutive failures or max_duration_hours (default 48) hours"`.
  - **Files**: `specs/loop-safety-infra/plan.md`
  - **Done when**: Line 10 uses distinct variable names `max_failures` and `max_duration_hours`
  - **Verify**: `grep -q 'max_failures' /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/plan.md && ! grep -q 'or N hours' /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/plan.md && echo T5.4_PASS`
  - **Commit**: `fix: distinct variable names for circuit breaker metrics (Bug #84)`
  - _Requirements: US-5, AC-5.6_
  - _Design: Fix 15 (AC-5.6)_

- [ ] 5.5 [VERIFY] Quality gate: JSON validity, syntax, SOLID check
  - **Do**: Run `/bmad-party-mode` with voices architect, dev, test architect, pm
    - Ask each agent to validate:
      1. SRP: Each requirements fix has single purpose
      2. OCP: Spec changes allow future extensions
      3. LSP compliance (no subtype violations)
      4. ISP compliance (no fat interfaces)
      5. DIP compliance (depend on abstractions)
    - Run ALL syntax/format validation commands:
      - `jq empty specs/.index/index-state.json`
      - `python3 -m py_compile _bmad/scripts/resolve_config.py`
      - `bash -n plugins/ralph-specum/hooks/scripts/checkpoint.sh`
      - `bash -n plugins/ralph-specum/hooks/scripts/load-spec-context.sh`
      - `bash -n plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
      - `bash -n plugins/ralph-specum/hooks/scripts/discover-ci.sh`
      - `bash -n specs/loop-safety-infra/tests/test-benchmark.sh`
      - `bash -n specs/loop-safety-infra/tests/test-checkpoint.sh`
      - `python3 -c "import csv; list(csv.reader(open('/mnt/bunker_data/ai/smart-ralph/_bmad/core/module-help.csv')))"`
    - Confirm NO pre-existing errors blamed as test failures
    - Confirm NO @ng-no-cover pragmas
    - Confirm NO shortcut tests
  - **Verify**: All commands above exit 0
  - **Done when**: All syntax checks pass, SOLID consensus achieved
  - **Commit**: `quality(gate): quality gate consensus for tasks 5.1-5.4`
  - _Design: All fixes in Phase 5_

## Phase 6: Verification Final

Focus: Prove all fixes resolve original issues and no regressions introduced.

- [ ] VF [VERIFY] Goal verification: all bugs resolved, no regressions
  - **Do**:
    1. Verify each original bug is fixed:
       - `.gitignore` no longer contains `.github/` — `! grep -q '^\s*\.github/\s*$' /mnt/bunker_data/ai/smart-ralph/.gitignore`
       - `resolve_config.py` deep merge preserves base fields — `python3 -c "import sys; sys.path.insert(0, '_bmad/scripts'); from resolve_config import deep_merge; base = {'agents': [{'code': 'a1', 'name': 'original', 'version': '1.0'}]}; override = {'agents': [{'code': 'a1', 'name': 'updated'}]}; result = deep_merge(base, override); assert result['agents'][0]['version'] == '1.0'; print('PASS')"`
       - `checkpoint.sh` uses `grep -F` — `grep -q 'grep -qF' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/checkpoint.sh`
       - `load-spec-context.sh` exits on mkdir failure — `grep -q 'return 1' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/load-spec-context.sh`
       - `stop-watcher.sh` uses sha256sum — `grep -q 'sha256sum | cut' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/stop-watcher.sh`
       - `discover-ci.sh` has categories — `grep -q 'category' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/discover-ci.sh`
       - `test-benchmark.sh` no exit 1 — `! grep -q 'exit 1' /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/tests/test-benchmark.sh`
       - `test-checkpoint.sh` has real assertion — `grep -q 'sha length >= 7' /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/tests/test-checkpoint.sh`
       - All typos fixed (distillator, O_TMPF, bmalph, filesystem Health, complete)
       - All naming fixes applied (lock file, dot notation, phase status)
       - All requirements gaps filled (AC refs, glossary, output refs, N variable)
    2. Verify no pre-existing functionality broken:
       - All `.sh` files pass `bash -n`
       - All `.json` files pass `jq empty`
       - `resolve_config.py` passes `py_compile`
       - `module-help.csv` parses correctly
    3. Verify minimal scope: `git diff --stat` shows changes only in listed target files
  - **Verify**: All verification commands exit 0
  - **Done when**: All 22 fixes verified, no regressions detected
  - **Commit**: `chore(code-fixes-2): verify fix resolves all 22 confirmed bugs`
  - _Requirements: All AC_, _NFR-001 through NFR-007_

## Notes

- **POC shortcuts taken**: None — all fixes are surgical, inline changes only
- **Production TODOs**: None — all fixes are complete by design
- **Notable decisions**:
  - BMAD distillator directory name NOT changed (deferred per requirements — requires ~40 file rename)
  - test-benchmark.sh: only line 48 `exit 1` removed per design spec (line 68 unchanged as not in scope)
  - `→` arrow notation: only line 91 fixed (state.json field path context); other `→` uses are text direction markers
- **Scope boundary**: Only the 17 files listed in design.md File Structure are modified. No refactoring, no new files.
