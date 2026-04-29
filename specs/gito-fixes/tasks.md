# Tasks: Gito Automated Code Review Fixes

## Phase 1: Plugin Script Fixes

Focus: Fix grep -c corruption, regex, basename, and eval bugs in import.sh.

- [ ] 1.1 [RED] Fix grep -c || echo 0 corruption in import.sh
  - **Do**: Replace all instances of `grep -c ... || echo 0` with `grep -c ... || true` in import.sh. Under `set -euo pipefail`, `grep -c` outputs "0" and exits 1 when no matches; `|| echo 0` appends another "0", producing "0\n0" which breaks arithmetic comparisons.
  - **Files**:
    - plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: All `|| echo 0` after `grep -c` replaced with `|| true`; script passes `bash -n`
  - **Verify**: `bash -n /mnt/bunker_data/ai/smart-ralph/plugins/ralph-bmad-bridge/scripts/import.sh && echo PASS`
  - **Commit**: `fix(bmad-bridge): fix grep -c || echo 0 variable corruption`
  - _Requirements: FR-001, AC-1.1_
  - _Design: Group 1_

- [ ] 1.2 [RED] Fix invalid POSIX regex [\s] in import.sh grep patterns
  - **Do**: Check import.sh for any `[\s]` patterns in grep commands. If found, replace with `[[:space:]]`. If none found, confirm and document.
  - **Files**:
    - plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: No `[\s]` patterns remain in grep commands
  - **Verify**: `grep -n '\[\\\\s\]' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-bmad-bridge/scripts/import.sh; test $? -ne 0 && echo PASS`
  - **Commit**: `fix(bmad-bridge): fix POSIX regex in import.sh`
  - _Requirements: FR-009, AC-3.2_
  - _Design: Group 1_

- [ ] 1.3 [RED] Fix non-portable basename expansion in import.sh
  - **Do**: Replace `${f%.}` with `basename "$f"` where applicable in import.sh.
  - **Files**:
    - plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: No `${f%.}` patterns remain; script passes `bash -n`
  - **Verify**: `! grep -q '\${f%.}' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-bmad-bridge/scripts/import.sh && echo PASS`
  - **Commit**: `fix(bmad-bridge): fix non-portable basename expansion`
  - _Requirements: FR-002, AC-1.2_
  - _Design: Group 1_

- [ ] 1.4 [RED] Fix eval security vulnerability in import.sh
  - **Do**: Replace any `eval` on untrusted input with safe jq/direct parsing in import.sh.
  - **Files**:
    - plugins/ralph-bmad-bridge/scripts/import.sh
  - **Done when**: No `eval` on untrusted input; script passes `bash -n`
  - **Verify**: `! grep -q 'eval ' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-bmad-bridge/scripts/import.sh && echo PASS`
  - **Commit**: `fix(bmad-bridge): fix eval security vulnerability`
  - _Requirements: FR-004, AC-1.3_
  - _Design: Group 1_

- [ ] 1.5 [VERIFY] Quality Gate — Code Quality & bmad-party-mode Consensus

  **Do**: Execute comprehensive quality checks and obtain bmad-party-mode consensus.

  **Files**: plugins/ralph-bmad-bridge/scripts/import.sh

  **Done when**:
  1. All preceding tasks' verification commands pass
  2. Code passes `bash -n` syntax check (for shell scripts)
  3. Code coverage is adequate for any new/modified code
  4. Tests are well-written, not lazy (assertions are specific, not just checking for exit codes)
  5. Syntax and style rules are correct
  6. Implementation is correct and complete
  7. /bmad-party-mode achieves consensus with relevant voices

  **Quality Gate Method**: /bmad-party-mode consensus REQUIRED
  - Este quality gate debe pasar por consenso en /bmad-party-mode antes de continuar
  - Spawn 3-4 agents relevant to the fix category:
    - bmad-agent-architect: reviews technical correctness
    - bmad-agent-dev: reviews code quality and style
    - bmad-testarch-test-review: reviews test coverage and verification thoroughness
    - bmad-testarch-atdd: reviews acceptance criteria coverage
  - All agents must CONFIRM the fixes are solid, cover edge cases, and don't introduce regressions
  - If consensus is not reached (any REJECT), fix the issues and re-run party mode until consensus
  - This is a HARD BLOCK — do NOT advance to the next task until consensus is achieved

  **Verify**: `bash -n /mnt/bunker_data/ai/smart-ralph/plugins/ralph-bmad-bridge/scripts/import.sh && echo QUALITY_GATE_PASS`

  **Commit**: `quality(spec): quality gate consensus for plugin script fixes`
  - _Requirements: NFR-001, NFR-002_
  - _Design: Quality Gates_

## Phase 2: Plugin Command Fixes

Focus: Fix duplicate argument parsing, missing variable assignment, and grep -c corruption in implement.md.

- [ ] 2.1 [RED] Fix grep -c || echo 0 corruption in implement.md
  - **Do**: Replace `grep -c ... || echo 0` with `grep -c ... || true` on lines 54, 55, 196 (and any other instances) in implement.md.
  - **Files**:
    - plugins/ralph-specum/commands/implement.md
  - **Done when**: All `|| echo 0` after grep -c replaced; no grep -c with || echo 0 remains
  - **Verify**: `! grep '|| echo 0' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/commands/implement.md && echo PASS`
  - **Commit**: `fix(specum): fix grep -c || echo 0 in implement.md`
  - _Requirements: FR-001, AC-1.1_
  - _Design: Group 2_

- [ ] 2.2 [RED] Fix duplicate spec-name argument extraction in implement.md
  - **Do**: Remove duplicate spec-name argument extraction in implement.md — spec name should be extracted once from earliest source.
  - **Files**:
    - plugins/ralph-specum/commands/implement.md
  - **Done when**: Spec name extracted from single source only
  - **Verify**: `grep 'spec.name\|SPEC_NAME' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/commands/implement.md | wc -l`
  - **Commit**: `fix(specum): fix duplicate spec-name argument extraction`
  - _Requirements: FR-006, AC-2.2_
  - _Design: Group 2_

- [ ] 2.3 [RED] Fix missing variable assignment in implement.md
  - **Do**: Add missing variable assignment for any unassigned variables referenced in implement.md.
  - **Files**:
    - plugins/ralph-specum/commands/implement.md
  - **Done when**: All referenced variables are assigned before first use
  - **Verify**: `grep -n '=\$' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/commands/implement.md; echo PASS`
  - **Commit**: `fix(specum): add missing variable assignment`
  - _Requirements: FR-007, AC-2.3_
  - _Design: Group 2_

- [ ] 2.4 [VERIFY] Quality Gate — Code Quality & bmad-party-mode Consensus

  **Do**: Execute comprehensive quality checks and obtain bmad-party-mode consensus.

  **Files**: plugins/ralph-specum/commands/implement.md

  **Done when**:
  1. All preceding tasks' verification commands pass
  2. No `|| echo 0` patterns remain after grep -c
  3. Spec name extraction is singular and from earliest source
  4. All referenced variables are assigned before use
  5. /bmad-party-mode achieves consensus with relevant voices

  **Quality Gate Method**: /bmad-party-mode consensus REQUIRED
  - Este quality gate debe pasar por consenso en /bmad-party-mode antes de continuar
  - Spawn 3-4 agents relevant to the fix category:
    - bmad-agent-architect: reviews technical correctness
    - bmad-agent-dev: reviews code quality and style
    - bmad-testarch-test-review: reviews test coverage and verification thoroughness
    - bmad-testarch-atdd: reviews acceptance criteria coverage
  - All agents must CONFIRM the fixes are solid, cover edge cases, and don't introduce regressions
  - If consensus is not reached (any REJECT), fix the issues and re-run party mode until consensus
  - This is a HARD BLOCK — do NOT advance to the next task until consensus is achieved

  **Verify**: `! grep '|| echo 0' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/commands/implement.md && echo QUALITY_GATE_PASS`

  **Commit**: `quality(spec): quality gate consensus for plugin command fixes`
  - _Requirements: NFR-001_
  - _Design: Quality Gates_

## Phase 3: Plugin Hook Fixes

Focus: Fix invalid regex, unchecked cd commands, and subshell exit code in hook scripts.

- [ ] 3.1 [RED] Fix invalid regex [\s] in checkpoint.sh
  - **Do**: Replace `[\s]` with `[[:space:]]` in /proc/mounts grep (lines 53-54) and mount grep (line 59) in checkpoint.sh.
  - **Files**:
    - plugins/ralph-specum/hooks/scripts/checkpoint.sh
  - **Done when**: All `[\s]` replaced with `[[:space:]]` in grep commands
  - **Verify**: `! grep -q '\[\\\\s\]' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/checkpoint.sh && echo PASS`
  - **Commit**: `fix(specum): fix regex in checkpoint.sh`
  - _Requirements: FR-009, AC-3.2_
  - _Design: Group 3_

- [ ] 3.2 [RED] Fix unchecked cd commands in checkpoint.sh
  - **Do**: Add error handling to `cd "$git_root"` on line 97 and line 247 in checkpoint.sh: `cd "$git_root" || { echo "[error] checkpoint-create: cannot cd to git_root"; return 1; }`
  - **Files**:
    - plugins/ralph-specum/hooks/scripts/checkpoint.sh
  - **Done when**: Both cd commands have error handling
  - **Verify**: `bash -n /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/checkpoint.sh && echo PASS`
  - **Commit**: `fix(specum): fix unchecked cd commands in checkpoint.sh`
  - _Requirements: FR-008, AC-3.1_
  - _Design: Group 3_

- [ ] 3.3 [RED] Fix invalid regex [\s] in stop-watcher.sh
  - **Do**: Replace `[\s]` with `[[:space:]]` in all grep patterns in stop-watcher.sh.
  - **Files**:
    - plugins/ralph-specum/hooks/scripts/stop-watcher.sh
  - **Done when**: No `[\s]` patterns remain in grep commands
  - **Verify**: `! grep -q '\[\\\\s\]' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/stop-watcher.sh && echo PASS`
  - **Commit**: `fix(specum): fix POSIX regex in stop-watcher.sh`
  - _Requirements: FR-009, AC-3.2_
  - _Design: Group 3_

- [ ] 3.4 [RED] Fix subshell exit code in write-metric.sh
  - **Do**: Replace `return 0` on line 167 with `return $?` to capture the subshell exit code. The subshell (lines 81-165) may fail (flock, jq), but the parent unconditionally returns 0, silently masking write failures.
  - **Files**:
    - plugins/ralph-specum/hooks/scripts/write-metric.sh
  - **Done when**: `return 0` replaced with `return $?` on the subshell exit
  - **Verify**: `grep -q 'return \$?' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/write-metric.sh && echo PASS`
  - **Commit**: `fix(specum): fix subshell exit code propagation in write-metric.sh`
  - _Requirements: FR-010, AC-3.3_
  - _Design: Group 3_

- [ ] 3.5 [VERIFY] Quality Gate — Code Quality & bmad-party-mode Consensus

  **Do**: Execute comprehensive quality checks and obtain bmad-party-mode consensus.

  **Files**: plugins/ralph-specum/hooks/scripts/checkpoint.sh, plugins/ralph-specum/hooks/scripts/stop-watcher.sh, plugins/ralph-specum/hooks/scripts/write-metric.sh

  **Done when**:
  1. All preceding tasks' verification commands pass
  2. All shell scripts pass `bash -n` syntax check
  3. No `[\s]` patterns remain in grep commands
  4. cd commands have error handling
  5. Subshell exit code is properly propagated
  6. /bmad-party-mode achieves consensus with relevant voices

  **Quality Gate Method**: /bmad-party-mode consensus REQUIRED
  - Este quality gate debe pasar por consenso en /bmad-party-mode antes de continuar
  - Spawn 3-4 agents relevant to the fix category:
    - bmad-agent-architect: reviews technical correctness
    - bmad-agent-dev: reviews code quality and style
    - bmad-testarch-test-review: reviews test coverage and verification thoroughness
    - bmad-testarch-atdd: reviews acceptance criteria coverage
  - All agents must CONFIRM the fixes are solid, cover edge cases, and don't introduce regressions
  - If consensus is not reached (any REJECT), fix the issues and re-run party mode until consensus
  - This is a HARD BLOCK — do NOT advance to the next task until consensus is achieved

  **Verify**: `bash -n /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/checkpoint.sh /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/stop-watcher.sh /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/write-metric.sh && echo QUALITY_GATE_PASS`

  **Commit**: `quality(spec): quality gate consensus for plugin hook fixes`
  - _Requirements: NFR-001_
  - _Design: Quality Gates_

## Phase 4: Plugin Reference & Schema Fixes

Focus: Fix role contracts, schema fields, and loop safety reference.

- [ ] 4.1 [RED] Fix role-contracts.md denylist and writes column
  - **Do**:
    1. Change spec-reviewer denylist from "All files" to `_(read-only)_` (line 30)
    2. Change qa-engineer Writes column from read description to `_(read-only)_` (line 29)
  - **Files**:
    - plugins/ralph-specum/references/role-contracts.md
  - **Done when**: Denylist says "(read-only)", Writes column says "(read-only)"
  - **Verify**: `! grep -q 'All files' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/references/role-contracts.md && echo PASS`
  - **Commit**: `fix(specum): fix role-contracts.md denylist and writes column`
  - _Requirements: AC-4.1, AC-4.2_
  - _Design: Group 4_

- [ ] 4.2 [RED] Fix spec.schema.json — strip ticket refs
  - **Do**: Strip internal ticket references (SR-003, SR-001, SR-002, etc.) from schema descriptions in spec.schema.json.
  - **Files**:
    - plugins/ralph-specum/schemas/spec.schema.json
  - **Done when**: No SR-XXX refs in descriptions; file remains valid JSON
  - **Verify**: `jq empty /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/schemas/spec.schema.json && ! grep -q 'SR-' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/schemas/spec.schema.json && echo PASS`
  - **Commit**: `fix(specum): strip ticket refs from schema descriptions`
  - _Requirements: AC-4.4_
  - _Design: Group 4_

- [ ] 4.3 [RED] Fix spec.schema.json — add missing field definitions
  - **Do**: Add any missing field definitions that agent docs reference but schema lacks in spec.schema.json.
  - **Files**:
    - plugins/ralph-specum/schemas/spec.schema.json
  - **Done when**: All referenced fields present; file remains valid JSON
  - **Verify**: `jq empty /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/schemas/spec.schema.json && echo PASS`
  - **Commit**: `fix(specum): add missing field definitions to schema`
  - _Requirements: AC-4.5_
  - _Design: Group 4_

- [ ] 4.4 [RED] Fix hardcoded placeholder in loop-safety.md
  - **Do**: Replace hardcoded `/path/to/mount` with dynamic path reference matching the discovery command in Step 1 of the Filesystem Health Recovery section in loop-safety.md.
  - **Files**:
    - plugins/ralph-specum/references/loop-safety.md
  - **Done when**: Recovery step 2 uses same dynamic path discovery as Step 1
  - **Verify**: `! grep -q '/path/to/mount' /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/references/loop-safety.md && echo PASS`
  - **Commit**: `fix(specum): fix hardcoded placeholder in loop-safety.md`
  - _Requirements: AC-4.3_
  - _Design: Group 4_

- [ ] 4.5 [VERIFY] Quality Gate — Code Quality & bmad-party-mode Consensus

  **Do**: Execute comprehensive quality checks and obtain bmad-party-mode consensus.

  **Files**: plugins/ralph-specum/references/role-contracts.md, plugins/ralph-specum/schemas/spec.schema.json, plugins/ralph-specum/references/loop-safety.md

  **Done when**:
  1. All preceding tasks' verification commands pass
  2. role-contracts.md denylist and writes column are correct
  3. spec.schema.json is valid JSON with no ticket refs
  4. loop-safety.md has no hardcoded placeholders
  5. /bmad-party-mode achieves consensus with relevant voices

  **Quality Gate Method**: /bmad-party-mode consensus REQUIRED
  - Este quality gate debe pasar por consenso en /bmad-party-mode antes de continuar
  - Spawn 3-4 agents relevant to the fix category:
    - bmad-agent-architect: reviews technical correctness
    - bmad-agent-dev: reviews code quality and style
    - bmad-testarch-test-review: reviews test coverage and verification thoroughness
    - bmad-testarch-atdd: reviews acceptance criteria coverage
  - All agents must CONFIRM the fixes are solid, cover edge cases, and don't introduce regressions
  - If consensus is not reached (any REJECT), fix the issues and re-run party mode until consensus
  - This is a HARD BLOCK — do NOT advance to the next task until consensus is achieved

  **Verify**: `jq empty /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/schemas/spec.schema.json && echo QUALITY_GATE_PASS`

  **Commit**: `quality(spec): quality gate consensus for plugin reference/schema fixes`
  - _Requirements: NFR-001_
  - _Design: Quality Gates_

## Phase 5: Spec Index & Epic Fixes

Focus: Fix inconsistent phase value, self-referential dependencies, and epic command typo.

- [ ] 5.1 [RED] Fix index-state.json phase value
  - **Do**: Change `"phase": "complete"` to `"phase": "completed"` for `ralph-quality-improvements` in index-state.json.
  - **Files**:
    - specs/.index/index-state.json
  - **Done when**: Phase value is "completed" for ralph-quality-improvements
  - **Verify**: `jq '.specs[] | select(.name == "ralph-quality-improvements") | .phase' /mnt/bunker_data/ai/smart-ralph/specs/.index/index-state.json | grep -q '"completed"' && echo PASS`
  - **Commit**: `fix(index): fix phase value from complete to completed`
  - _Requirements: AC-5.1_
  - _Design: Group 5_

- [ ] 5.2 [RED] Fix self-referential dependency in epic.md
  - **Do**: Fix self-referential dependency in engine-roadmap-epic/epic.md: change "Spec 6 (depends on Spec 6...)" to "Spec 7 (depends on Spec 6...)".
  - **Files**:
    - specs/_epics/engine-roadmap-epic/epic.md
  - **Done when**: No self-references in epic.md; Spec 7 correctly depends on Spec 6
  - **Verify**: `! grep -q 'Spec 6 (depends on Spec 6' /mnt/bunker_data/ai/smart-ralph/specs/_epics/engine-roadmap-epic/epic.md && echo PASS`
  - **Commit**: `fix(epic): fix self-referential dependency in epic.md`
  - _Requirements: AC-6.1_
  - _Design: Group 6_

- [ ] 5.3 [RED] Fix command typo in epic.md
  - **Do**: Fix command typo `/ralph-specum` to correct command name in engine-roadmap-epic/epic.md.
  - **Files**:
    - specs/_epics/engine-roadmap-epic/epic.md
  - **Done when**: Correct command names used in epic.md
  - **Verify**: `grep -q 'ralph-specum' /mnt/bunker_data/ai/smart-ralph/specs/_epics/engine-roadmap-epic/epic.md && echo PASS`
  - **Commit**: `fix(epic): fix command typo in epic.md`
  - _Requirements: AC-6.2_
  - _Design: Group 6_

- [ ] 5.4 [VERIFY] Quality Gate — Code Quality & bmad-party-mode Consensus

  **Do**: Execute comprehensive quality checks and obtain bmad-party-mode consensus.

  **Files**: specs/.index/index-state.json, specs/_epics/engine-roadmap-epic/epic.md

  **Done when**:
  1. All preceding tasks' verification commands pass
  2. JSON files pass `jq empty` validation
  3. Phase value is "completed" in index
  4. No self-references in epic.md
  5. /bmad-party-mode achieves consensus with relevant voices

  **Quality Gate Method**: /bmad-party-mode consensus REQUIRED
  - Este quality gate debe pasar por consenso en /bmad-party-mode antes de continuar
  - Spawn 3-4 agents relevant to the fix category:
    - bmad-agent-architect: reviews technical correctness
    - bmad-agent-dev: reviews code quality and style
    - bmad-testarch-test-review: reviews test coverage and verification thoroughness
    - bmad-testarch-atdd: reviews acceptance criteria coverage
  - All agents must CONFIRM the fixes are solid, cover edge cases, and don't introduce regressions
  - If consensus is not reached (any REJECT), fix the issues and re-run party mode until consensus
  - This is a HARD BLOCK — do NOT advance to the next task until consensus is achieved

  **Verify**: `jq empty /mnt/bunker_data/ai/smart-ralph/specs/.index/index-state.json /mnt/bunker_data/ai/smart-ralph/specs/_epics/engine-roadmap-epic/epic.md && echo QUALITY_GATE_PASS`

  **Commit**: `quality(spec): quality gate consensus for spec index/epic fixes`
  - _Requirements: NFR-001_
  - _Design: Quality Gates_

## Phase 6: jq Semantics & Research Docs

Focus: Fix jq `//` false handling, exit codes, heartbeat guard, contradictory docs, and malformed JSON in loop-safety-infra research docs.

- [ ] 6.1 [RED] Fix jq // operator false handling in research-read-only-detection.md
  - **Do**: Replace `.filesystemHealthy // true` with explicit null check in research-read-only-detection.md.
  - **Files**:
    - specs/loop-safety-infra/research-read-only-detection.md
  - **Done when**: jq `//` replaced with explicit null check
  - **Verify**: `! grep -q 'filesystemHealthy // true' /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/research-read-only-detection.md && echo PASS`
  - **Commit**: `fix(loop-safety): fix jq // false handling`
  - _Requirements: AC-6.2_
  - _Design: Group 6_

- [ ] 6.2 [RED] Fix exit 0 on fatal filesystem failure in research-read-only-detection.md
  - **Do**: Change `exit 0` to `exit 1` on fatal filesystem failure in research-read-only-detection.md.
  - **Files**:
    - specs/loop-safety-infra/research-read-only-detection.md
  - **Done when**: Exit code is 1 on fatal filesystem failure
  - **Verify**: `! grep -q 'exit 0.*fatal\|exit 0.*filesystem' /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/research-read-only-detection.md && echo PASS`
  - **Commit**: `fix(loop-safety): fix exit code on fatal filesystem failure`
  - _Requirements: AC-6.3_
  - _Design: Group 6_

- [ ] 6.3 [RED] Remove heartbeat guard condition in research-read-only-detection.md
  - **Do**: Remove heartbeat guard condition so it runs every iteration in research-read-only-detection.md.
  - **Files**:
    - specs/loop-safety-infra/research-read-only-detection.md
  - **Done when**: Heartbeat runs every iteration unconditionally
  - **Verify**: `echo PASS`
  - **Commit**: `fix(loop-safety): remove heartbeat guard condition`
  - _Requirements: AC-6.4_
  - _Design: Group 6_

- [ ] 6.4 [RED] Fix contradictory --no-verify docs and tr/jq issues
  - **Do**:
    1. Clarify `--no-verify` docs in research.md — remove contradictory statement about hooks
    2. Fix useless `tr ',' ','` to use `split(",")` in jq (research-metrics-and-ci.md)
    3. Fix bash command substitution inside jq filter (research-metrics-and-ci.md)
  - **Files**:
    - specs/loop-safety-infra/research.md
    - specs/loop-safety-infra/.research-metrics-and-ci.md
  - **Done when**: Contradictory docs removed; tr removed and split(",") used; jq syntax is pure
  - **Verify**: `echo PASS`
  - **Commit**: `fix(loop-safety): fix contradictory docs, tr, and jq syntax`
  - _Requirements: AC-6.5, AC-6.6, AC-6.7_
  - _Design: Group 6_

- [ ] 6.5 [RED] Fix incorrect categorization in research.md
  - **Do**: Fix incorrect categorization in Non-Modifications section in research.md.
  - **Files**:
    - specs/loop-safety-infra/research.md
  - **Done when**: Categorization corrected
  - **Verify**: `echo PASS`
  - **Commit**: `fix(loop-safety): fix incorrect categorization in research.md`
  - _Requirements: AC-6.8_
  - _Design: Group 6_

- [ ] 6.6 [VERIFY] Quality Gate — Code Quality & bmad-party-mode Consensus

  **Do**: Execute comprehensive quality checks and obtain bmad-party-mode consensus.

  **Files**: specs/loop-safety-infra/research-read-only-detection.md, specs/loop-safety-infra/research.md, specs/loop-safety-infra/.research-metrics-and-ci.md

  **Done when**:
  1. All preceding tasks' verification commands pass
  2. jq // replaced with null check; exit 1 on fatal; heartbeat runs every iteration
  3. Contradictory docs clarified; tr replaced with split(","); jq syntax pure
  4. /bmad-party-mode achieves consensus with relevant voices

  **Quality Gate Method**: /bmad-party-mode consensus REQUIRED
  - Este quality gate debe pasar por consenso en /bmad-party-mode antes de continuar
  - Spawn 3-4 agents relevant to the fix category:
    - bmad-agent-architect: reviews technical correctness
    - bmad-agent-dev: reviews code quality and style
    - bmad-testarch-test-review: reviews test coverage and verification thoroughness
    - bmad-testarch-atdd: reviews acceptance criteria coverage
  - All agents must CONFIRM the fixes are solid, cover edge cases, and don't introduce regressions
  - If consensus is not reached (any REJECT), fix the issues and re-run party mode until consensus
  - This is a HARD BLOCK — do NOT advance to the next task until consensus is achieved

  **Verify**: `echo QUALITY_GATE_PASS`

  **Commit**: `quality(spec): quality gate consensus for jq semantics and research doc fixes`
  - _Requirements: NFR-001_
  - _Design: Quality Gates_

## Phase 7: bmad-bridge Plugin Docs

Focus: Fix awk regex, duplicate test entries, write targets, BMAD version, and contradictory status in bmad-bridge-plugin spec.

- [ ] 7.1 [RED] Fix awk regex premature exit in bmad-bridge-plugin design.md
  - **Do**: Fix awk regex `^##` to `^## [^#]` in design.md (line 103) — matches only ## not ###.
  - **Files**:
    - specs/bmad-bridge-plugin/design.md
  - **Done when**: Awk regex matches only ## not ###
  - **Verify**: `grep -q '\^## \[^#\]' /mnt/bunker_data/ai/smart-ralph/specs/bmad-bridge-plugin/design.md && echo PASS`
  - **Commit**: `fix(bmad-bridge): fix awk regex premature exit`
  - _Requirements: AC-6.10_
  - _Design: Group 6_

- [ ] 7.2 [RED] Remove duplicate test strategy entries in bmad-bridge-plugin design.md
  - **Do**: Remove duplicate test strategy entries in design.md (lines 222-223).
  - **Files**:
    - specs/bmad-bridge-plugin/design.md
  - **Done when**: No duplicate test strategy entries
  - **Verify**: `! awk '/\|.*Unit test.*\|.*Integration test.*\|/{count++} END{print count}' /mnt/bunker_data/ai/smart-ralph/specs/bmad-bridge-plugin/design.md | grep -q '^2$' && echo PASS`
  - **Commit**: `fix(bmad-bridge): remove duplicate test strategy entries`
  - _Requirements: AC-6.11_
  - _Design: Group 6_

- [ ] 7.3 [RED] Add missing write targets in bmad-bridge-plugin plan.md
  - **Do**: Add missing write targets for user stories and test scenarios in plan.md.
  - **Files**:
    - specs/bmad-bridge-plugin/plan.md
  - **Done when**: Write targets include user stories and test scenarios
  - **Verify**: `echo PASS`
  - **Commit**: `fix(bmad-bridge): add missing write targets to plan.md`
  - _Requirements: AC-6.12_
  - _Design: Group 6_

- [ ] 7.4 [RED] Harmonize BMAD version in bmad-bridge-plugin requirements.md
  - **Do**: Harmonize BMAD version references (v2.11.0 vs v6.4.0) in requirements.md to a single consistent version.
  - **Files**:
    - specs/bmad-bridge-plugin/requirements.md
  - **Done when**: Single BMAD version throughout document
  - **Verify**: `grep -o 'v[0-9]*\\.[0-9]*\\.[0-9]*' /mnt/bunker_data/ai/smart-ralph/specs/bmad-bridge-plugin/requirements.md | sort -u | wc -l`
  - **Commit**: `fix(bmad-bridge): harmonize BMAD version references`
  - _Requirements: AC-6.8_
  - _Design: Group 6_

- [ ] 7.5 [RED] Fix contradictory progress status in bmad-bridge-plugin .progress.md
  - **Do**: Replace contradictory `[x]` + `PENDING_COMMIT` status flags with actual git hashes or remove the conflicting flag entirely in .progress.md.
  - **Files**:
    - specs/bmad-bridge-plugin/.progress.md
  - **Done when**: No contradictory `[x]` + `PENDING_COMMIT` pairs remain
  - **Verify**: `! grep -A2 '\[x\]' /mnt/bunker_data/ai/smart-ralph/specs/bmad-bridge-plugin/.progress.md | grep -q 'PENDING_COMMIT' && echo PASS`
  - **Commit**: `fix(bmad-bridge): fix contradictory progress status flags`
  - _Requirements: AC-8.2_
  - _Design: Group 6_

- [ ] 7.6 [VERIFY] Quality Gate — Code Quality & bmad-party-mode Consensus

  **Do**: Execute comprehensive quality checks and obtain bmad-party-mode consensus.

  **Files**: specs/bmad-bridge-plugin/{design.md,plan.md,requirements.md,.progress.md}

  **Done when**:
  1. All preceding tasks' verification commands pass
  2. Awk regex matches only ##; no duplicate entries; write targets added; single BMAD version
  3. No contradictory status flags remain
  4. /bmad-party-mode achieves consensus with relevant voices

  **Quality Gate Method**: /bmad-party-mode consensus REQUIRED
  - Este quality gate debe pasar por consenso en /bmad-party-mode antes de continuar
  - Spawn 3-4 agents relevant to the fix category:
    - bmad-agent-architect: reviews technical correctness
    - bmad-agent-dev: reviews code quality and style
    - bmad-testarch-test-review: reviews test coverage and verification thoroughness
    - bmad-testarch-atdd: reviews acceptance criteria coverage
  - All agents must CONFIRM the fixes are solid, cover edge cases, and don't introduce regressions
  - If consensus is not reached (any REJECT), fix the issues and re-run party mode until consensus
  - This is a HARD BLOCK — do NOT advance to the next task until consensus is achieved

  **Verify**: `echo QUALITY_GATE_PASS`

  **Commit**: `quality(spec): quality gate consensus for bmad-bridge-plugin doc fixes`
  - _Requirements: NFR-004_
  - _Design: Quality Gates_

## Phase 8: Role Boundaries, Pair-Debug, & Loop-Safety Docs

Focus: Fix metrics responsibility, sessionStartTime type, jq boolean chain, regex contradictions, grep file creation, JSON format, condition count, validation logic, and flock backing.

- [ ] 8.1 [RED] Clarify metrics responsibility and sessionStartTime type
  - **Do**:
    1. Clarify metrics field generation responsibility in requirements.md (write-metric.sh vs coordinator)
    2. Harmonize data type for sessionStartTime in research-circuit-breaker.md
  - **Files**:
    - specs/loop-safety-infra/requirements.md
    - specs/loop-safety-infra/research-circuit-breaker.md
  - **Done when**: Metrics field responsibility clear; sessionStartTime type consistent
  - **Verify**: `grep -q 'write-metric.sh' /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/requirements.md && echo PASS`
  - **Commit**: `fix(loop-safety): clarify metrics responsibility and sessionStartTime type`
  - _Requirements: AC-6.9, AC-6.10_
  - _Design: Group 6_

- [ ] 8.2 [RED] Fix jq boolean chain in loop-safety-infra tasks.md
  - **Do**: Fix jq boolean chain in loop-safety-infra/tasks.md: replace `and` with `has()` (fails on taskIndex=0).
  - **Files**:
    - specs/loop-safety-infra/tasks.md
  - **Done when**: `has()` used instead of `and` in jq boolean chain
  - **Verify**: `grep -q 'has(' /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/tasks.md && echo PASS`
  - **Commit**: `fix(loop-safety): fix jq boolean chain`
  - _Requirements: AC-6.14_
  - _Design: Group 6_

- [ ] 8.3 [RED] Fix regex contradicting minimum-length in role-boundaries tasks.md
  - **Do**: Fix regex contradicting minimum-length in role-boundaries/tasks.md: `^[a-z](-?[a-z0-9]+)*$` -> `^[a-z][a-z0-9]*(-[a-z0-9]+)*$`.
  - **Files**:
    - specs/role-boundaries/tasks.md
  - **Done when**: Regex enforces 2+ chars
  - **Verify**: `grep -q '\[a-z\]\[a-z0-9\]\*' /mnt/bunker_data/ai/smart-ralph/specs/role-boundaries/tasks.md && echo PASS`
  - **Commit**: `fix(role-boundaries): fix regex to enforce minimum length`
  - _Requirements: AC-6.15_
  - _Design: Group 6_

- [ ] 8.4 [RED] Fix grep -c file creation bug in role-boundaries tasks.md
  - **Do**: Fix `grep -c > 0` file creation bug in role-boundaries/tasks.md: replace with `grep -q`.
  - **Files**:
    - specs/role-boundaries/tasks.md
  - **Done when**: `grep -q` used instead of `>` redirection
  - **Verify**: `! grep -q 'grep.*> 0' /mnt/bunker_data/ai/smart-ralph/specs/role-boundaries/tasks.md && echo PASS`
  - **Commit**: `fix(role-boundaries): fix grep -c redirection to grep -q`
  - _Requirements: AC-6.16_
  - _Design: Group 6_

- [ ] 8.5 [RED] Harmonize JSON baseline format in role-boundaries
  - **Do**: Harmonize JSON baseline format between producer and consumer in role-boundaries/final-spec-adversarial-review.md.
  - **Files**:
    - specs/role-boundaries/final-spec-adversarial-review.md
  - **Done when**: Producer/consumer use same nested format
  - **Verify**: `echo PASS`
  - **Commit**: `fix(role-boundaries): harmonize JSON baseline format`
  - _Requirements: AC-6.17_
  - _Design: Group 6_

- [ ] 8.6 [RED] Fix condition count mismatch in pair-debug-auto-trigger plan.md
  - **Do**: Fix condition count mismatch in pair-debug-auto-trigger/plan.md — text says 3, lists 4 conditions. Harmonize to 4.
  - **Files**:
    - specs/pair-debug-auto-trigger/plan.md
  - **Done when**: Text matches actual condition count
  - **Verify**: `echo PASS`
  - **Commit**: `fix(pair-debug): fix condition count mismatch`
  - _Requirements: AC-6.13_
  - _Design: Group 6_

- [ ] 8.7 [RED] Fix validation logic and flock backing in role-boundaries design.md
  - **Do**:
    1. Fix validation logic that skips external_unmarks in role-boundaries/design.md — validate object structure instead of skipping
    2. Add lockfile backing to flock on fd 202: `exec 202>"${SPEC_PATH}/references/.ralph-baseline.lock" && flock -x 202`
  - **Files**:
    - specs/role-boundaries/design.md
  - **Done when**: External unmarks validated; flock has lockfile backing
  - **Verify**: `grep -q 'external_unmarks' /mnt/bunker_data/ai/smart-ralph/specs/role-boundaries/design.md && echo PASS`
  - **Commit**: `fix(role-boundaries): fix validation logic and flock backing`
  - _Requirements: AC-6.17_
  - _Design: Group 6_

- [ ] 8.8 [VERIFY] Quality Gate — Code Quality & bmad-party-mode Consensus

  **Do**: Execute comprehensive quality checks and obtain bmad-party-mode consensus.

  **Files**: specs/loop-safety-infra/{requirements.md,research-circuit-breaker.md,tasks.md}, specs/role-boundaries/{tasks.md,design.md,final-spec-adversarial-review.md}, specs/pair-debug-auto-trigger/plan.md

  **Done when**:
  1. All preceding tasks' verification commands pass
  2. All modified documents parse correctly
  3. jq boolean chain uses has(); regex enforces 2+ chars; grep -q used; format harmonized
  4. /bmad-party-mode achieves consensus with relevant voices

  **Quality Gate Method**: /bmad-party-mode consensus REQUIRED
  - Este quality gate debe pasar por consenso en /bmad-party-mode antes de continuar
  - Spawn 3-4 agents relevant to the fix category:
    - bmad-agent-architect: reviews technical correctness
    - bmad-agent-dev: reviews code quality and style
    - bmad-testarch-test-review: reviews test coverage and verification thoroughness
    - bmad-testarch-atdd: reviews acceptance criteria coverage
  - All agents must CONFIRM the fixes are solid, cover edge cases, and don't introduce regressions
  - If consensus is not reached (any REJECT), fix the issues and re-run party mode until consensus
  - This is a HARD BLOCK — do NOT advance to the next task until consensus is achieved

  **Verify**: `echo QUALITY_GATE_PASS`

  **Commit**: `quality(spec): quality gate consensus for role-boundaries and pair-debug fixes`
  - _Requirements: NFR-004_
  - _Design: Quality Gates_

## Phase 9: Test Script Fixes

Focus: Fix grep -c corruption, state file overwrite, date portability, and fragile sed in test scripts.

- [ ] 9.1 [RED] Fix grep -c corruption in test-integration.sh
  - **Do**: Replace `grep -c ... || echo 0` with `grep -c ... || true` on lines 25, 26, 27, 35, 36, 37 in test-integration.sh.
  - **Files**:
    - specs/loop-safety-infra/tests/test-integration.sh
  - **Done when**: No `|| echo 0` after grep -c
  - **Verify**: `! grep -q '|| echo 0' /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/tests/test-integration.sh && echo PASS`
  - **Commit**: `fix(loop-safety): fix grep -c corruption in test-integration.sh`
  - _Requirements: AC-7.1_
  - _Design: Group 7_

- [ ] 9.2 [RED] Fix state file overwrite in test-integration.sh
  - **Do**: Remove `echo '{}' > "$tmp/.ralph-state.json"` on line 73 that overwrites circuit breaker state in test-integration.sh.
  - **Files**:
    - specs/loop-safety-infra/tests/test-integration.sh
  - **Done when**: State file not overwritten after circuit breaker config
  - **Verify**: `! grep -q "echo '{}' > .*/.ralph-state.json" /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/tests/test-integration.sh && echo PASS`
  - **Commit**: `fix(loop-safety): fix state file overwrite in test-integration.sh`
  - _Requirements: AC-7.2_
  - _Design: Group 7_

- [ ] 9.3 [RED] Fix date portability in test-benchmark.sh
  - **Do**: Add portable date wrapper: `if date +%s%N >/dev/null 2>&1; then date +%s%N; else echo "$(date +%s)000000000"; fi` replacing direct `date +%s%N` on lines 36, 40, 59, 63.
  - **Files**:
    - specs/loop-safety-infra/tests/test-benchmark.sh
  - **Done when**: Portable date fallback works on macOS/BSD
  - **Verify**: `bash -n /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/tests/test-benchmark.sh && echo PASS`
  - **Commit**: `fix(loop-safety): fix date portability in test-benchmark.sh`
  - _Requirements: AC-7.6_
  - _Design: Group 7_

- [ ] 9.4 [RED] Fix fragile sed regex in test-benchmark.sh
  - **Do**: Fix fragile sed regex on line 26: anchor to `[[:space:]]*` for indented functions.
  - **Files**:
    - specs/loop-safety-infra/tests/test-benchmark.sh
  - **Done when**: Sed regex handles indented functions
  - **Verify**: `bash -n /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/tests/test-benchmark.sh && echo PASS`
  - **Commit**: `fix(loop-safety): fix fragile sed regex in test-benchmark.sh`
  - _Requirements: AC-7.7_
  - _Design: Group 7_

- [ ] 9.5 [VERIFY] Quality Gate — Code Quality & bmad-party-mode Consensus

  **Do**: Execute comprehensive quality checks and obtain bmad-party-mode consensus.

  **Files**: specs/loop-safety-infra/tests/test-integration.sh, specs/loop-safety-infra/tests/test-benchmark.sh

  **Done when**:
  1. All preceding tasks' verification commands pass
  2. All test scripts pass `bash -n` syntax check
  3. grep -c patterns corrected; state file not overwritten
  4. Date portability wrapper works on macOS
  5. /bmad-party-mode achieves consensus with relevant voices

  **Quality Gate Method**: /bmad-party-mode consensus REQUIRED
  - Este quality gate debe pasar por consenso en /bmad-party-mode antes de continuar
  - Spawn 3-4 agents relevant to the fix category:
    - bmad-agent-architect: reviews technical correctness
    - bmad-agent-dev: reviews code quality and style
    - bmad-testarch-test-review: reviews test coverage and verification thoroughness
    - bmad-testarch-atdd: reviews acceptance criteria coverage
  - All agents must CONFIRM the fixes are solid, cover edge cases, and don't introduce regressions
  - If consensus is not reached (any REJECT), fix the issues and re-run party mode until consensus
  - This is a HARD BLOCK — do NOT advance to the next task until consensus is achieved

  **Verify**: `bash -n /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/tests/test-integration.sh /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/tests/test-benchmark.sh && echo QUALITY_GATE_PASS`

  **Commit**: `quality(spec): quality gate consensus for test script fixes`
  - _Requirements: NFR-001_
  - _Design: Quality Gates_

## Phase 10: Documentation & Typo Fixes

Focus: Fix typos, corrupted tables, sentence fragments, and path harmonization.

- [ ] 10.1 [RED] Fix typo Bmalph -> BMAD in .progress.md
  - **Do**: Fix `Bmalph` -> `BMAD` in loop-safety-infra/.progress.md (line 4).
  - **Files**:
    - specs/loop-safety-infra/.progress.md
  - **Done when**: Typo corrected
  - **Verify**: `! grep -q 'Bmalph' /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/.progress.md && echo PASS`
  - **Commit**: `fix(loop-safety): fix typo Bmalph -> BMAD`
  - _Requirements: AC-8.1_
  - _Design: Group 8_

- [ ] 10.2 [RED] Fix typo excption -> exception in research-circuit-breaker.md
  - **Do**: Fix `excption` -> `exception` in loop-safety-infra/research-circuit-breaker.md (line 16).
  - **Files**:
    - specs/loop-safety-infra/research-circuit-breaker.md
  - **Done when**: Typo corrected
  - **Verify**: `! grep -q 'excption' /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/research-circuit-breaker.md && echo PASS`
  - **Commit**: `fix(loop-safety): fix typo excption -> exception`
  - _Requirements: AC-8.1_
  - _Design: Group 8_

- [ ] 10.3 [RED] Fix typo smart-ralsh -> smart-ralph in requirements.md
  - **Do**: Fix `smart-ralsh` -> `smart-ralph` in bmad-bridge-plugin/requirements.md.
  - **Files**:
    - specs/bmad-bridge-plugin/requirements.md
  - **Done when**: Typo corrected
  - **Verify**: `! grep -q 'smart-ralsh' /mnt/bunker_data/ai/smart-ralph/specs/bmad-bridge-plugin/requirements.md && echo PASS`
  - **Commit**: `fix(bmad-bridge): fix typo smart-ralsh -> smart-ralph`
  - _Requirements: AC-8.1_
  - _Design: Group 8_

- [ ] 10.4 [RED] Fix corrupted table in role-boundaries research.md
  - **Do**: Fix corrupted markdown table row in role-boundaries/research.md (line 161).
  - **Files**:
    - specs/role-boundaries/research.md
  - **Done when**: Table renders correctly
  - **Verify**: `echo PASS`
  - **Commit**: `fix(role-boundaries): fix corrupted markdown table row`
  - _Requirements: AC-8.3_
  - _Design: Group 8_

- [ ] 10.5 [RED] Fix sentence fragment in role-boundaries research.md
  - **Do**: Fix sentence fragment "The access matrix covers ~8. ~19 fields are undocumented." -> "The access matrix covers ~8 fields. ~19 fields are undocumented."
  - **Files**:
    - specs/role-boundaries/research.md
  - **Done when**: Fragment expanded to two complete sentences
  - **Verify**: `grep -q 'covers ~8 fields' /mnt/bunker_data/ai/smart-ralph/specs/role-boundaries/research.md && echo PASS`
  - **Commit**: `fix(role-boundaries): fix sentence fragment`
  - _Requirements: AC-8.4_
  - _Design: Group 8_

- [ ] 10.6 [RED] Harmonize paths in _bmad/custom/config.toml
  - **Do**: Review and harmonize inconsistent paths in _bmad/custom/config.toml for consistency.
  - **Files**:
    - _bmad/custom/config.toml
  - **Done when**: Paths are consistent throughout the config file
  - **Verify**: `echo PASS`
  - **Commit**: `fix(config): harmonize paths in config.toml`
  - _Requirements: AC-8.1_
  - _Design: Group 8_

- [ ] 10.7 [VERIFY] Quality Gate — Code Quality & bmad-party-mode Consensus

  **Do**: Execute comprehensive quality checks and obtain bmad-party-mode consensus.

  **Files**: specs/loop-safety-infra/.progress.md, specs/loop-safety-infra/research-circuit-breaker.md, specs/bmad-bridge-plugin/requirements.md, specs/role-boundaries/research.md, _bmad/custom/config.toml

  **Done when**:
  1. All preceding tasks' verification commands pass
  2. All typos corrected
  3. Table renders correctly; sentence fragment fixed
  4. Paths harmonized
  5. /bmad-party-mode achieves consensus with relevant voices

  **Quality Gate Method**: /bmad-party-mode consensus REQUIRED
  - Este quality gate debe pasar por consenso en /bmad-party-mode antes de continuar
  - Spawn 3-4 agents relevant to the fix category:
    - bmad-agent-architect: reviews technical correctness
    - bmad-agent-dev: reviews code quality and style
    - bmad-testarch-test-review: reviews test coverage and verification thoroughness
    - bmad-testarch-atdd: reviews acceptance criteria coverage
  - All agents must CONFIRM the fixes are solid, cover edge cases, and don't introduce regressions
  - If consensus is not reached (any REJECT), fix the issues and re-run party mode until consensus
  - This is a HARD BLOCK — do NOT advance to the next task until consensus is achieved

  **Verify**: `echo QUALITY_GATE_PASS`

  **Commit**: `quality(spec): quality gate consensus for documentation/typo fixes`
  - _Requirements: NFR-004_
  - _Design: Quality Gates_

## Phase 11: Verification Final (VF)

- [ ] VF [VERIFY] Goal verification: all 55 issues now resolved
  - **Do**:
    1. Verify all shell scripts pass `bash -n`: find all .sh files modified and run syntax check
    2. Verify all JSON files pass `jq empty`: index-state.json, spec.schema.json
    3. Verify key fixes are present: grep for corrected patterns in each file
    4. Confirm no `|| echo 0` after grep -c remains in any modified file
    5. Confirm no `[\s]` in grep patterns of any modified script
    6. Confirm no `eval` on untrusted input in import.sh
    7. Confirm cd commands have error handling in checkpoint.sh
    8. Confirm subshell exit code captured in write-metric.sh
    9. Verify index-state.json has "completed" phase for ralph-quality-improvements
    10. Verify no SR-XXX refs remain in schema
    11. Verify all typos corrected
  - **Files**: All files modified in preceding tasks
  - **Done when**: All verification checks pass; no remaining Gito issues
  - **Verify**: `bash -n /mnt/bunker_data/ai/smart-ralph/plugins/ralph-bmad-bridge/scripts/import.sh /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/checkpoint.sh /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/write-metric.sh /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/stop-watcher.sh /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/tests/test-benchmark.sh /mnt/bunker_data/ai/smart-ralph/specs/loop-safety-infra/tests/test-integration.sh && jq empty /mnt/bunker_data/ai/smart-ralph/specs/.index/index-state.json /mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/schemas/spec.schema.json && echo ALL_VERIFY_PASS`
  - **Done when**: Command exits 0 with ALL_VERIFY_PASS
  - **Commit**: `chore(spec): verify fix resolves original issue`

## Notes

- POC shortcuts: N/A — all fixes are direct surgical edits
- Production TODOs: None — all fixes are complete bug corrections
- All fixes are independent — no inter-task dependencies
- shellcheck is NOT installed — NFR-001 (shellcheck compliance) cannot be automated; manual verification required
- BMAD version harmonization: both v2.11.0 and v6.4.0 appear in requirements.md — the fix harmonizes to the version actually used in code
- Quality gates every 4-5 tasks with bmad-party-mode consensus as a hard block
- No VE tasks needed: this is a codebase cleanup spec, not a new feature with UI/infrastructure
