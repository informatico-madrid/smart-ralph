---
name: gito-quality-gate
description: 'Incremental code quality gate using Gito AI review with spec/task context injection and BMAD consensus-based false-positive filtering. Runs Gito review on specific files or commits, enriches Gito prompts with SDD spec context, then validates issues via bmad-review-adversarial-general and bmad-consensus-party to separate real issues from false positives. Use for PR review, code review, quality gate, gito review, incremental review, task verification, SDD quality gate, or any per-task code validation.'
---

# Gito Incremental Quality Gate

Run **scoped Gito reviews** with spec/task context injection, then **filter false positives** using BMAD adversarial review + consensus party.

## When to Use

- Running a quality gate on specific files after a task implementation
- Reviewing a PR or a set of changes before commit
- Validating incremental changes (per-task or per-commit) instead of a full-branch review
- Any `[VERIFY]` step in SDD that needs code review beyond lint/type checks
- User says: "review this code", "quality gate", "gito review", "PR review", "incremental review", "check my changes"

## When NOT to Use

- Full-branch review (use `gito review` directly without this skill)
- Writing new code (use dev story skill instead)
- Running deterministic checks only (use `quality-gate` skill instead — this skill is LLM-review-based)
- When no spec/task context exists (fall back to plain `gito review`)

## Inputs Required

| Input | Source | Required |
|-------|--------|----------|
| `CHANGED_FILES` | Files to review (from `git diff --name-only`, explicit list, or `--filter` glob) | Yes |
| `SPEC_CONTEXT` | Path to current spec (e.g., `specs/<name>/requirements.md`, `design.md`, `tasks.md`) | Recommended |
| `TASK_CONTEXT` | Current task description from `tasks.md` (the task being verified) | Recommended |
| `REVIEW_SCOPE` | `staged` (uncommitted), `last-commit` (HEAD~1..HEAD), `commits:N` (last N), or `filter:PATTERN` | Yes |
| `AGAINST_REF` | Git ref to compare against (default: `origin/main`) | No |

## Workflow

### Step 1: Determine Review Scope

Identify which files to review based on `REVIEW_SCOPE`:

| Scope | Command to get files |
|-------|---------------------|
| `staged` | `git diff --name-only HEAD` |
| `last-commit` | `git diff --name-only HEAD~1..HEAD` |
| `commits:N` | `git diff --name-only HEAD~N..HEAD` |
| `filter:PATTERN` | Use `--filter` flag directly with Gito |

If `CHANGED_FILES` was provided explicitly, use that list instead.

### Step 2: Build Context for Gito

**This is the critical step that reduces false positives.** Read [`references/gito-context-guide.md`](references/gito-context-guide.md) for full details.

Construct a context block to inject into Gito's review prompt via `.gito/config.toml` `[prompt_vars].requirements`:

1. **Read spec files** relevant to the current task:
   - `specs/<name>/requirements.md` — what the feature should do
   - `specs/<name>/design.md` — how it should be implemented
   - `specs/<name>/tasks.md` — which task is being verified

2. **Extract task-specific context** (max 300 words):
   - The current task description and its done-when criteria
   - The design decisions that apply to the changed files
   - Any constraints from requirements that are relevant

3. **Build the context injection string**:
   ```
   [SDD Context — Task: {task_id}]
   Feature: {spec_name}
   Task: {task_description}
   Done-when: {done_when_criteria}
   Design constraints: {relevant_design_decisions}
   Files changed in this task: {file_list}
   Review focus: Verify changes align with the above spec/task context. Flag only issues that conflict with stated requirements or design. Do NOT flag style preferences, naming conventions outside the spec, or pre-existing issues unrelated to this task.
   ```

4. **Temporarily update `.gito/config.toml`** `[prompt_vars].requirements` with the context block (save original to restore after review).

### Step 3: Run Gito Review

Execute the scoped review:

```bash
# For staged/uncommitted changes
gito review --filter "file1.md,file2.sh" -o /tmp/gito-qg/

# For last commit
gito review HEAD~1..HEAD --filter "file1.md,file2.sh" -o /tmp/gito-qg/

# For specific files against a ref
gito review --what HEAD --against origin/main --filter "file1.md" -o /tmp/gito-qg/
```

**Important**: Always use `--filter` to scope the review to only the changed files. Without it, Gito reviews the entire branch diff.

### Step 4: Parse Gito Report

Read the generated `code-review-report.json` from the output folder:

1. Extract the list of issues with their `id`, `title`, `details`, `severity`, `tags`, and `affected_lines`
2. Count total issues and categorize by severity
3. If **0 issues found** → output `GITO_QUALITY_GATE_PASS` and stop (no need for BMAD filtering)

### Step 5: Filter False Positives with BMAD Adversarial Review

For each issue found by Gito, run `bmad-review-adversarial-general` to cynically evaluate whether the issue is **real** or a **false positive**:

1. **Prepare the review content**: For each issue, compose:
   - The Gito issue title, details, and proposed change
   - The affected code lines
   - The spec/task context from Step 2
   - The question: "Is this a genuine issue that must be fixed for this task, or a false positive?"

2. **Invoke `bmad-review-adversarial-general`** with:
   - `content` = the Gito issue + affected code + spec context
   - `also_consider` = "Whether this issue is relevant to the current task's scope and spec requirements"

3. **Collect adversarial findings**: The reviewer will flag issues as:
   - **REAL** — genuinely impacts correctness, security, or spec compliance
   - **FALSE POSITIVE** — stylistic, out-of-scope, or incorrect suggestion
   - **NEEDS DEBATE** — unclear, requires multi-agent consensus

### Step 6: Resolve Debated Issues with BMAD Consensus Party

For any issues marked **NEEDS DEBATE** by the adversarial reviewer:

1. **Invoke `bmad-consensus-party`** with:
   - The debated issue details
   - The adversarial reviewer's analysis
   - The spec/task context
   - Question: "Is issue #{id} a real problem that must be fixed, or a false positive that should be dismissed?"

2. **Consensus outcome** determines final classification:
   - Consensus = real issue → classify as **REAL**
   - Consensus = false positive → classify as **FALSE POSITIVE**
   - Timeout → classify as **LOW CONFIDENCE** (flag for human review)

### Step 7: Produce Quality Gate Verdict

Generate the final report:

```markdown
## Gito Quality Gate Result

**Scope**: {REVIEW_SCOPE} | **Files**: {file_count} | **Against**: {AGAINST_REF}

### Summary
| Category | Count |
|----------|-------|
| Total Gito issues | {total} |
| Real issues (must fix) | {real_count} |
| False positives (dismissed) | {fp_count} |
| Low confidence (human review) | {lc_count} |

### Real Issues (Must Fix)
{list of real issues with id, title, severity, and fix guidance}

### False Positives (Dismissed)
{list of dismissed issues with id, title, and dismissal reason}

### Low Confidence (Human Review Needed)
{list of uncertain issues}

### Verdict
- **PASS** — 0 real issues, 0 low-confidence issues
- **PASS_WITH_WARNINGS** — 0 real issues, some low-confidence items
- **FAIL** — 1+ real issues that must be fixed before commit
```

### Step 8: Restore Config and Cleanup

1. Restore the original `.gito/config.toml` `[prompt_vars].requirements`
2. Clean up temporary output files if no longer needed
3. If verdict is **FAIL**, list the real issues that must be resolved

## Files

| File | Purpose | When to read |
|------|---------|-------------|
| [`references/gito-context-guide.md`](references/gito-context-guide.md) | How to build spec/task context for Gito injection | Before Step 2 |
| [`scripts/gito-incremental-review.sh`](scripts/gito-incremental-review.sh) | Wrapper script for scoped Gito review with context | Execute in Step 3 |

## Integration with SDD Task Planner

When generating `tasks.md`, the task planner can insert quality gate tasks like:

```markdown
- [ ] [VERIFY] Run gito-quality-gate on changed files (scope: staged, spec: {spec_name})
```

This ensures every task has an incremental review checkpoint instead of one massive review at the end.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Gito reviews entire branch instead of specific files | Always use `--filter` with explicit file list |
| Too many false positives | Enrich context in Step 2 with more spec/task detail |
| BMAD consensus takes too long | Set `max_iterations: 2` for non-critical issues |
| `.gito/config.toml` not restored after review | Step 8 must always restore — add trap in script |
| Gito can't find venv | Ensure `.venv/bin/activate` is sourced before running |
