# Spec: pair-debug-auto-trigger

Epic: specs/_epics/engine-roadmap-epic/epic.md

## Goal
Add automatic pair-debug mode trigger (3-condition check) and Driver/Navigator role split so agents collaborate on hard bugs without human push.

## Acceptance Criteria
1. `references/pair-debug.md` exists with 3-condition trigger and Driver/Navigator roles
2. Auto-trigger fires when: pre-existing test fails + test unchanged + first fix attempt failed (taskIteration >= 2) + reviewer didn't mark FAIL
3. Debug logging listed as first-class investigation technique in spec-executor.md
4. Failure-recovery.md announces pair-debug mode before fix task (pre-existing test failures)
5. Coordinator writes PAIR-DEBUG MODE ACTIVATED to chat.md with Driver/Navigator roles

## Interface Contracts
### Reads
- `references/failure-recovery.md` — current content (after Spec 6 changes)
- `agents/spec-executor.md` — current content (after Spec 3 changes)
- `references/coordinator-pattern.md` — current content for context

### Writes
- `references/pair-debug.md` — NEW FILE
- `references/failure-recovery.md` — append pair-debug announcement pattern
- `agents/spec-executor.md` — append debug logging section
- `references/coordinator-pattern.md` — add pair-debug announcement to signal handling

## Dependencies
Spec 3 (reads role restriction additions to spec-executor.md), Spec 6 (depends on collaboration signals and BUG_DISCOVERY pattern)
