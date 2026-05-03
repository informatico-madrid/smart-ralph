# Task Review Log

<!--
Workflow: External reviewer agent writes review entries to this file after completing tasks.
Status values: FAIL, WARNING, PASS, PENDING
- FAIL: Task failed reviewer's criteria - requires fix
- WARNING: Task passed but with concerns - note in .progress.md
- PASS: Task passed external review - mark complete
- PENDING: reviewer is working on it, spec-executor should not re-mark this task until status changes. spec-executor: skip this task and move to the next unchecked one.

reviewer-config
principles: auto-detect
codebase-conventions: auto-detect
-->

## Reviews

<!--
Review entry template:
- status: FAIL | WARNING | PASS | PENDING
- severity: critical | major | minor (optional)
- reviewed_at: ISO timestamp
- criterion_failed: Which requirement/criterion failed (for FAIL status)
- evidence: Brief description of what was observed
- fix_hint: Suggested fix or direction (for FAIL/WARNING)
- resolved_at: ISO timestamp (only for resolved entries)
-->

| status | severity | reviewed_at | task_id | criterion_failed | evidence | fix_hint | resolved_at |
|--------|----------|-------------|---------|------------------|----------|----------|-------------|
| FAIL | critical | 2026-05-03T06:22:00Z | 0.1 | File at wrong path | `.pre-change-counts.txt` placed at `specs/ralphharness-rename/.pre-change-counts.txt` instead of repo root. Spec says `**Files**: .pre-change-counts.txt (new file)`. Verify cmd `test -f .pre-change-counts.txt` FAILS at root. | Move file to repo root: `git mv specs/ralphharness-rename/.pre-change-counts.txt .pre-change-counts.txt` | |
| FAIL | critical | 2026-05-03T06:22:00Z | 0.2 | Verify command broken | Two issues: (1) File at wrong path so grep fails, (2) Even at correct path, `grep -c` counts LINES not matches. File has all 3 patterns on ONE line → returns 1, not 3. `grep -c "ralph-specum\|tzachbon\|smart-ralph" .pre-change-counts.txt \| grep -q "3"` always fails. | Fix verify command to: `grep -E "ralph-specum|tzachbon|smart-ralph" .pre-change-counts.txt \| wc -l \| grep -q "3"` OR reformat file to have one pattern per line. | |
| FAIL | major | 2026-05-03T06:22:00Z | 1.1 | Commit message misleading | Commit c536041 titled "rename(plugin): git mv plugins/ralph-specum -> plugins/ralphharness" only contains tasks.md change (marking 1.1 [x]). Actual git mv was in commit 063762c. | No action needed if commit 063762c is amended/split. Otherwise document deviation. | |
| FAIL | major | 2026-05-03T06:22:00Z | 1.2 | Task not marked complete | Speckit directory rename IS done (confirmed: `plugins/ralphharness-speckit/` exists, git shows rename in 063762c). But task 1.2 is still `[ ]` in tasks.md. | Mark task 1.2 as `[x]` in tasks.md. | |
| FAIL | major | 2026-05-03T06:22:00Z | 1.2 | Missing dedicated commit | Speckit rename was bundled into commit 063762c (codex commit). Spec requires separate commit: `rename(plugin): git mv plugins/ralph-speckit -> plugins/ralphharness-speckit`. | If possible, split commit 063762c into 3 separate commits. If not, document deviation. | |
| FAIL | major | 2026-05-03T06:22:00Z | 1.3 | Commit contains unrelated renames | Commit 063762c titled for codex rename contains ALL THREE directory renames (main plugin + speckit + codex = 206 files). Violates task isolation: cannot revert one rename independently. | Split into 3 commits, one per directory rename. Or accept with documented deviation. | |
