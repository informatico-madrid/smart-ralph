# Git Strategy

Commit and push strategy.

Loaded for: COMMIT tasks.

## Native Task Sync - Modification

When TASK_MODIFICATION_REQUEST is processed and new tasks are inserted into tasks.md:

1. If `nativeSyncEnabled` is `false` or `nativeTaskMap` is missing: skip
2. For SPLIT_TASK:
   - `TaskUpdate` original task status: `"completed"`
   - For each new split task: `TaskCreate(subject: "<FR-11 format>", description, activeForm: "<FR-12 format>")`, add returned ID to `nativeTaskMap`
3. For ADD_PREREQUISITE:
   - `TaskCreate(subject: "<FR-11 format>", description, activeForm: "<FR-12 format>")` for prerequisite, add returned ID to `nativeTaskMap`
   - `TaskUpdate` original task with `addBlockedBy: [prerequisite task ID]`
4. For ADD_FOLLOWUP:
   - `TaskCreate(subject: "<FR-11 format>", description, activeForm: "<FR-12 format>")` for followup, add returned ID to `nativeTaskMap`
5. Update `nativeTaskMap` in .ralph-state.json with new entries
6. Re-indexing: rebuild `nativeTaskMap` to match the updated tasks.md order.
   - Parse tasks.md in order after insertion.
   - Keep existing native task IDs for unchanged task identities (match by task ID pattern `X.Y` in subject, not title alone).
   - Assign newly created IDs to inserted tasks at their actual indices.
   - Persist the fully re-keyed map to .ralph-state.json.
7. If any TaskCreate/TaskUpdate fails: log warning, continue

## PR Lifecycle Loop (Phase 5)

CRITICAL: Phase 5 is continuous autonomous PR management. Do NOT stop until all criteria met.

**Entry Conditions**:
- All Phase 1-4 tasks complete
- Phase 5 tasks detected in tasks.md

**Loop Structure**:
```text
PR Creation -> CI Monitoring -> Review Check -> Fix Issues -> Push -> Repeat
```

**Step 1: Create PR (if not exists)**

Delegate to spec-executor:
```text
Task: Create pull request

Do:
1. Verify not on default branch: git branch --show-current
2. Push branch: git push -u origin <branch>
3. Create PR: gh pr create --title "feat: <spec>" --body "<summary>"

Verify: gh pr view shows PR created
Done when: PR URL returned
Commit: None
```

**Step 2: CI Monitoring Loop**

```text
While (CI checks not all green):
  1. Wait 3 minutes (allow CI to start/complete)
  2. Check status: gh pr checks
  3. If failures:
     - Read failure details: gh run view --log-failed
     - Create new Phase 5.X task in tasks.md
     - Delegate new task to spec-executor with task index and Files list
     - Wait for TASK_COMPLETE
     - Push fixes (if not already pushed by spec-executor)
     - Restart wait cycle
  4. If pending:
     - Continue waiting
  5. If all green:
     - Proceed to Step 3
```

**Step 3: Review Comment Check**

```text
1. Fetch review states: gh pr view --json reviews
   - Parse for reviews with state "CHANGES_REQUESTED" or "PENDING"
   - For inline comments, use REST API: gh api repos/{owner}/{repo}/pulls/{number}/reviews
   - Or use review comments endpoint: gh api repos/{owner}/{repo}/pulls/{number}/comments
2. Parse for unresolved reviews/comments
3. If unresolved reviews/comments found:
   - Create tasks from reviews (add to tasks.md as Phase 5.X)
   - Delegate each to spec-executor
   - Wait for completion
   - Push fixes
   - Return to Step 2 (re-check CI)
4. If no unresolved reviews/comments:
   - Proceed to Step 4
```

**Step 4: Final Validation**

All must be true:
- All Phase 1-4 tasks complete (checked [x])
- All Phase 5 tasks complete
- CI checks all green
- No unresolved review comments
- Zero test regressions (all existing tests pass)
- Code is modular/reusable (verified in .progress.md)

**Step 5: Completion**

When all Step 4 criteria met:
1. Update .progress.md with final state
2. Delete .ralph-state.json
3. Get PR URL: `gh pr view --json url -q .url`
4. Output: ALL_TASKS_COMPLETE
5. Output: PR link

**Timeout Protection**:
- Max 48 hours in PR Lifecycle Loop
- Max 20 CI monitoring cycles
- If exceeded: Output error and STOP (do not output ALL_TASKS_COMPLETE)

**Error Handling**:
- If CI fails after 5 retry attempts: STOP with error
- If review comments cannot be addressed: STOP with error
- Document all failures in .progress.md Learnings
