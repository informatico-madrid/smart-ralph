# VE Verification Contract

VE task delegation and skills loading.

Loaded for: VERIFY tasks only.

See ve-skip-forward.md for VE-cleanup pseudocode

---

## VE Task Detection

Before standard delegation, check if current task has [VERIFY] marker.
Look for `[VERIFY]` in task description line (e.g., `- [ ] 1.4 [VERIFY] Quality checkpoint`).

If [VERIFY] marker present:
1. Do NOT delegate to spec-executor
2. Delegate to qa-engineer via Task tool instead
3. [VERIFY] tasks are ALWAYS sequential (break parallel groups)

Delegate [VERIFY] task to qa-engineer:

```text
Task: Execute verification task $taskIndex for spec $spec

Spec: $spec
Path: $SPEC_PATH/

Task: [Full task description]

Task Body:
[Include Do, Verify, Done when sections]

## Delegation Contract

### Design Decisions
[Extract relevant design decisions from design.md for the verification scope.
For E2E verification: include Test Strategy section and any framework-specific decisions.]

### Anti-Patterns (DO NOT) — MANDATORY for ALL VE tasks
ALWAYS load and include the full Navigation and Selector anti-pattern sections from:
  `${CLAUDE_PLUGIN_ROOT}/references/e2e-anti-patterns.md`

Critical rules (non-negotiable):
- NEVER use `page.goto()` for internal app routes — navigate via UI elements (sidebar, menu clicks)
- NEVER invent selectors — read `ui-map.local.md` or use `browser_generate_locator` from live snapshot
- If you land on a 404, login page, or unexpected URL: run Unexpected Page Recovery (see playwright-session.skill.md)
  DO NOT assume the element does not exist. The wrong navigation is the bug, not the missing element.
- NEVER simplify a test to remove the user flow — a passing test that bypasses the real flow is worthless

Plus project-specific anti-patterns from .progress.md Learnings.

### Required Skills (ALL VE tasks — load BEFORE writing any browser code)

Load these base skills in order — they are mandatory for every VE task regardless of platform:
1. `${CLAUDE_PLUGIN_ROOT}/skills/e2e/playwright-env.skill.md`
2. `${CLAUDE_PLUGIN_ROOT}/skills/e2e/mcp-playwright.skill.md`
3. `${CLAUDE_PLUGIN_ROOT}/skills/e2e/playwright-session.skill.md`

Then load any **platform-specific skills** listed in the task's `Skills:` metadata field
(the task-planner writes those during planning, based on what it discovered in research.md).

**CRITICAL**: Do NOT start writing browser interactions before loading ALL listed skills.
The Navigation Anti-Patterns section of playwright-session.skill.md is MANDATORY reading.

### Source of Truth
Point to the authoritative files the qa-engineer MUST read before writing any code:
 - design.md → ## Test Strategy (mock boundaries, test conventions, runner)
 - requirements.md → ## Verification Contract (project type, entry points)
 - .progress.md → Learnings (what failed before and why)
 - ui-map.local.md → selectors to use (never invent selectors not in this file)
 - Any platform-specific skill files listed in the task's `Skills:` metadata

Instructions:
1. Execute the verification as specified
2. If issues found, attempt to fix them
3. Output VERIFICATION_PASS if verification succeeds
4. Output VERIFICATION_FAIL if verification fails and cannot be fixed
```

Handle qa-engineer response:

**Step 1 — Check for TASK_MODIFICATION_REQUEST** (before checking verification signal):
- Scan qa-engineer output for `TASK_MODIFICATION_REQUEST` JSON block.
- If found with `type: SPEC_ADJUSTMENT`: process it using the same SPEC_ADJUSTMENT handler
  used for spec-executor (validate scope, auto-approve or escalate to SPEC-DEFICIENCY).
- Continue to Step 2 regardless of whether a modification was processed.

**Step 2 — Handle verification signal**:
- VERIFICATION_PASS: Treat as TASK_COMPLETE, mark task [x], update .progress.md
- VERIFICATION_FAIL: Do NOT mark complete, increment taskIteration, retry or error if max reached
- VERIFICATION_DEGRADED: Do NOT increment taskIteration, do NOT attempt fix. ESCALATE with
  `reason: verification-degraded`.

### VE Recovery Mode
VE tasks (description contains "E2E") have recovery mode always enabled regardless of the state file `recoveryMode` flag. The coordinator should treat VE tasks as if `recoveryMode=true` for fix task generation purposes. VE failures are expected and recoverable — the verify-fix-reverify loop handles them automatically via `fixTaskMap` and `maxFixTasksPerOriginal`.

---

## Native Task Sync - Pre-Delegation

Before delegating the current task:

1. If `nativeSyncEnabled` is `false` or `nativeTaskMap` is missing: skip
2. Look up native task ID: `nativeTaskMap[taskIndex]`
3. If ID exists:
   - Format activeForm per FR-12: "Executing 1.1 Task title", "Executing [P] 2.1 Task title", or "Verifying 1.4 Quality checkpoint"
   - `TaskUpdate(taskId, status: "in_progress", activeForm: "<FR-12 format>")`
4. If TaskUpdate fails: log warning, continue

---

## Native Task Sync - Parallel

When parallel [P] group starts:

1. If `nativeSyncEnabled` is `false` or `nativeTaskMap` is missing: skip
2. For each taskIndex in `parallelGroup.taskIndices`:
   - Look up native task ID from `nativeTaskMap`
   - Format activeForm per FR-12: "Executing [P] 2.1 Task title"
   - `TaskUpdate(taskId: nativeTaskMap[taskIndex], status: "in_progress", activeForm: "<FR-12 format>")`
3. ALL TaskUpdate calls in ONE message (parallel tool calls)
4. If any TaskUpdate fails: log warning, continue

---

## Native Task Sync - Failure

On task failure (any task type):

1. If `nativeSyncEnabled` is `false` or `nativeTaskMap` is missing: skip
2. Look up native task ID: `nativeTaskMap[taskIndex]`
3. If ID exists: `TaskUpdate(taskId, status: "todo")`
4. If TaskUpdate fails: log warning, continue

---

## Graceful Degradation Pattern

For all Native Task Sync operations:

```
On success: reset nativeSyncFailureCount to 0
On failure: increment nativeSyncFailureCount
If count >= 3: set nativeSyncEnabled = false, log warning
```

This pattern prevents cascading failures when native task sync is unavailable or broken.
