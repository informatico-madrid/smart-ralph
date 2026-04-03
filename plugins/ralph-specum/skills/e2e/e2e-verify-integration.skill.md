# Skill: e2e-verify-integration

> How to integrate Playwright E2E tests within the ralph-specum loop.
> Describes the contract between `tasks.md` tasks, the `qa-engineer` agent,
> and the `stop-watcher.sh` hook. This is not a substitute for `selector-map.skill.md`
> — both are used together in E2E tasks.

---

## How the verification loop works in ralph-specum

The engine is not an external script. It is the **Claude Code Stop Hook**:

```
Claude finishes a task
       ↓
stop-watcher.sh runs (Stop hook in hooks.json)
       ↓
Reads .ralph-state.json → are there pending tasks?
       ↓
  YES → blocks the stop, injects continuation prompt
  NO  → allows stop
       ↓ (NO case)
Searches for ALL_TASKS_COMPLETE in transcript → cleans state and terminates
```

**Source**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` and
`plugins/ralph-specum/hooks/hooks.json` in this repository.

---

## The three real signals

### 1. `TASK_COMPLETE`

Emitted by `spec-executor` at the end of each successful task.

```
TASK_COMPLETE
  spec: <specName>
  task: <taskIndex — task title>
  status: pass
  summary: verify: all tests passed (5/5)
```

`stop-watcher` does not search for this signal in the transcript — it reads
`.ralph-state.json` to determine if tasks remain. `TASK_COMPLETE` is for the
internal coordinator.

### 2. `VERIFICATION_PASS` / `VERIFICATION_FAIL`

Emitted **exclusively** by the `qa-engineer` agent when `spec-executor`
delegates a `[VERIFY]`-tagged task to it.

```
# Success
VERIFICATION_PASS

# Failure
VERIFICATION_FAIL
```

Behavior by result:

| Signal | `spec-executor` does | `stop-watcher` does |
|---|---|---|
| `VERIFICATION_PASS` | Marks `[x]` in tasks.md, emits `TASK_COMPLETE` | Reads state, continues if more tasks remain |
| `VERIFICATION_FAIL` | Does NOT mark `[x]`, does NOT emit `TASK_COMPLETE`, logs in `.progress.md` | Blocks stop, retries the task in next iteration |

**Source**: `plugins/ralph-specum/agents/qa-engineer.md` (section `<verify_tasks>`) and
`plugins/ralph-specum/agents/spec-executor.md`.

### 3. `ALL_TASKS_COMPLETE`

Emitted by the coordinator when all tasks are finished.
`stop-watcher` searches for it in the transcript with:

```bash
grep -qE '(^|\W)ALL_TASKS_COMPLETE(\W|$)'
```

When detected: cleans state, updates epic if applicable, allows stop.

**Source**: `plugins/ralph-specum/hooks/scripts/stop-watcher.sh` (~line 60).

---

## Correct E2E task format in `tasks.md`

Each task is **a single checkbox**. The `Do`, `Files`, `Done when`,
`Verify`, and `Commit` sections are task metadata, not additional checkboxes.
User stories (`US-*`, `AC-*`) are in `requirements.md`,
never in `tasks.md`.

### E2E implementation task

```markdown
- [ ] 2.1 E2E test: [flow description]
  - **Do**: Create Playwright test in `tests/e2e/[name].spec.ts`
    following `skills/e2e/selector-map.skill.md`
  - **Files**: `tests/e2e/[name].spec.ts`
  - **Done when**: Test passes with `npx playwright test [name].spec.ts`
  - **Verify**: `npx playwright test [name].spec.ts --reporter=line`
  - **Commit**: `test(e2e): add [name] flow test`
  - _Requirements: US-X, AC-X.Y_
```

### E2E verification task (Quality Gate)

```markdown
- [ ] VE1 [VERIFY] E2E startup: launch dev server and verify health
  - **Do**: Start server: `pnpm dev &` (save PID to /tmp/ve-pids.txt),
    wait for health endpoint on port `{{port}}`
  - **Verify**: `curl -sf http://localhost:{{port}}/health -o /dev/null && echo PASS`
  - **Done when**: Server running and health endpoint returns 200
  - **Commit**: None

- [ ] VE2 [VERIFY] E2E check: run critical flow verification
  - **Do**: Run E2E suite against running server
  - **Verify**: `npx playwright test --reporter=line`
  - **Done when**: All tests pass
  - **Commit**: None

- [ ] VE3 [VERIFY] E2E cleanup: stop server and release resources
  - **Do**: Kill process by PID and release port
  - **Verify**: `! lsof -ti :{{port}} && echo PASS`
  - **Done when**: Port free, PID file removed
  - **Commit**: None
```

**Important**: `[VERIFY]` tasks are never executed by `spec-executor` directly.
They are always delegated to `qa-engineer` via Task delegation.

---

## Full flow of a [VERIFY] E2E task

```
stop-watcher detects pending tasks
       ↓
spec-executor reads the VE2 task
       ↓
Detects [VERIFY] tag → delegates to qa-engineer via Task tool
       ↓
qa-engineer runs: npx playwright test --reporter=line
       ↓
  All pass (exit 0)  →  emits VERIFICATION_PASS
  Some fail (exit ≠ 0) →  emits VERIFICATION_FAIL
       ↓
spec-executor receives result:
  PASS → marks [x] in tasks.md, commit, emits TASK_COMPLETE
  FAIL → logs in .progress.md, does NOT emit TASK_COMPLETE
       ↓
stop-watcher.sh:
  Tasks remain → blocks stop, next iteration
  No tasks remain → searches for ALL_TASKS_COMPLETE in transcript → terminates
```

---

## What this system does NOT do

- Does not use `ralph-loop.sh` — that file is legacy from another repo
- Does not use `state_match`, `verification_ok`, `TASK_COMPLETE` signals in the transcript
  (those signals were from the external bash loop, they do not apply here)
- Does not read user stories from `tasks.md` — reads them from `requirements.md`
- Does not support `waitForTimeout` in tests (see `selector-map.skill.md`)

---

## Integration checklist

- [ ] Each E2E test has its own implementation task (a single `- [ ]`)
- [ ] Verification tasks use the VE1/VE2/VE3 pattern
- [ ] `[VERIFY]` tasks have a concrete command in `Verify:`
  with exit code 0/1 as the pass/fail signal
- [ ] User story references (`US-X`, `AC-X.Y`) are on the
  `_Requirements:_` line, not as checkboxes
- [ ] Test selectors follow `skills/e2e/selector-map.skill.md`
- [ ] No legacy signals (`state_match`, `TASK_COMPLETE` in transcript) in prompts
