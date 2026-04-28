# Spec: collaboration-resolution

Epic: specs/_epics/engine-roadmap-epic/epic.md

## Goal
Encode the ad-hoc agent collaboration pattern into explicit, repeatable rules: cross-branch regression workflow, experiment-propose-validate chat pattern, BUG_DISCOVERY-triggered fix tasks, and new chat signals.

## Acceptance Criteria
1. `references/collaboration-resolution.md` exists with cross-branch regression workflow
2. New chat signals (HYPOTHESIS, EXPERIMENT, FINDING, ROOT_CAUSE, FIX_PROPOSAL, BUG_DISCOVERY) in templates/chat.md
3. `references/failure-recovery.md` extended: BUG_DISCOVERY in task_review.md triggers fix task
4. Spec-executor.md references collaboration-resolution for cross-branch investigation
5. External-reviewer.md has "before modifying tests, check baseline" hard rule

## Interface Contracts
### Reads
- `references/failure-recovery.md` — current content for context
- `templates/chat.md` — current content for context
- `agents/spec-executor.md` — current content (after Spec 3 changes)
- `agents/external-reviewer.md` — current content (after Spec 3 changes)

### Writes
- `references/collaboration-resolution.md` — NEW FILE
- `templates/chat.md` — add signals to legend table
- `references/failure-recovery.md` — extend fix task trigger
- `agents/spec-executor.md` — append collaboration reference
- `agents/external-reviewer.md` — append baseline rule + collaboration reference

## Dependencies
Spec 3 (modifies the same agent files with additive changes in different sections)
