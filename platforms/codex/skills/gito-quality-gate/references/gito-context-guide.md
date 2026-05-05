# Gito Context Injection Guide

## Table of Contents

1. [Why Context Matters](#why-context-matters)
2. [Context Sources](#context-sources)
3. [Building the Context Block](#building-the-context-block)
4. [Injecting Context into Gito](#injecting-context-into-gito)
5. [Context Templates by Review Type](#context-templates-by-review-type)
6. [Anti-Patterns](#anti-patterns)

---

## Why Context Matters

Gito's LLM reviews code diffs without knowing **why** the code was changed. Without spec/task context, the LLM:

- Flags pre-existing issues unrelated to the current change
- Suggests refactoring that contradicts the design decisions
- Misses spec violations because it doesn't know the requirements
- Reports false positives on naming/style that are intentional

**Context injection reduces false positives by 40-60%** and increases detection of real spec violations.

## Context Sources

### Primary Sources (always include if available)

| Source | File | What to extract |
|--------|------|-----------------|
| Requirements | `specs/<name>/requirements.md` | User stories, acceptance criteria, constraints |
| Design | `specs/<name>/design.md` | Architecture decisions, component boundaries, data models |
| Tasks | `specs/<name>/tasks.md` | Current task description, done-when criteria, verify commands |
| Project context | `AGENTS.md` or `CLAUDE.md` | Project principles, coding rules, architecture overview |

### Secondary Sources (include when relevant)

| Source | File | What to extract |
|--------|------|-----------------|
| Research | `specs/<name>/research.md` | Technology choices, constraints discovered |
| Epic | `specs/_epics/<name>/epic.md` | Cross-spec dependencies, epic-level goals |
| Architecture doc | `docs/ARCHITECTURE.md` | System-level design, component relationships |
| Progress | `specs/<name>/.progress.md` | Learnings from previous tasks, known issues |

## Building the Context Block

### Step 1: Identify the Current Task

From `tasks.md`, find the task being verified:

```markdown
## Task 3.2: Add input validation to switch command
- [x] Add empty name check
- [x] Add feature-not-found error handling
- [ ] [VERIFY] Run gito-quality-gate
**Done-when**: `switch.md` rejects empty input and missing features with clear error messages
```

Extract:
- **Task ID**: `3.2`
- **Task description**: "Add input validation to switch command"
- **Done-when**: "switch.md rejects empty input and missing features with clear error messages"
- **Files changed**: `plugins/ralphharness-speckit/commands/switch.md`

### Step 2: Extract Relevant Spec Context

From `requirements.md`, extract only the requirements that apply to the changed files:

```
AC-5.1: All commands must validate input before processing
AC-5.2: Error messages must be actionable (tell user what to do)
```

From `design.md`, extract only the design decisions that apply:

```
Error handling pattern: Use bash stderr (>&2) for errors, exit 1 on failure
```

### Step 3: Compose the Context Block

Keep the total context under **300 words** to avoid token bloat:

```
[SDD Context — Task 3.2]
Feature: ralphharness-speckit
Task: Add input validation to switch command
Done-when: switch.md rejects empty input and missing features with clear error messages
Requirements: AC-5.1 (validate input before processing), AC-5.2 (actionable error messages)
Design: Error handling uses bash stderr (>&2) + exit 1
Files: plugins/ralphharness-speckit/commands/switch.md
Review focus: Verify changes align with AC-5.1 and AC-5.2. Flag only issues that conflict with these requirements. Do NOT flag pre-existing code outside the validation logic, naming conventions, or style preferences.
```

## Injecting Context into Gito

### Method: Update `.gito/config.toml` `[prompt_vars].requirements`

```toml
[prompt_vars]
requirements = """
[SDD Context — Task 3.2]
Feature: ralphharness-speckit
Task: Add input validation to switch command
...
"""
```

**Important**: Save the original `requirements` value before overwriting, and restore it after the review completes.

### Programmatic Injection (via script)

The [`scripts/gito-incremental-review.sh`](scripts/gito-incremental-review.sh) script handles this automatically:

```bash
# The script:
# 1. Backs up .gito/config.toml
# 2. Injects the context block into [prompt_vars].requirements
# 3. Runs gito review with --filter
# 4. Restores the original config.toml
# 5. Outputs the report path
```

## Context Templates by Review Type

### Per-Task Review (most common)

```
[SDD Context — Task {task_id}]
Feature: {spec_name}
Task: {task_description}
Done-when: {done_when}
Requirements: {relevant_acceptance_criteria}
Design: {relevant_design_decisions}
Files: {changed_file_list}
Review focus: Verify changes align with the above. Flag only issues conflicting with stated requirements or design. Do NOT flag style, naming, or pre-existing issues outside this task's scope.
```

### Per-Commit Review

```
[SDD Context — Commit Review]
Feature: {spec_name}
Commit: {commit_message}
Related tasks: {task_ids}
Spec summary: {one_paragraph_spec_overview}
Review focus: Verify commit implements what the message claims, aligned with spec. Flag regressions or spec violations only.
```

### PR Review

```
[SDD Context — PR Review]
Feature: {spec_name}
PR goal: {pr_description}
Tasks covered: {task_id_list}
Key requirements: {top_5_acceptance_criteria}
Architecture constraints: {relevant_design_decisions}
Review focus: Verify PR fulfills stated goals. Flag spec violations, regressions, and missing test coverage. Do NOT re-review pre-existing code.
```

### Single-File Review

```
[SDD Context — File Review]
File: {file_path}
Purpose: {why_this_file_was_changed}
Related task: {task_id}
Constraint: {specific_constraint_or_pattern}
Review focus: Verify this file's changes are correct and consistent with the constraint. Do NOT flag issues in other files.
```

## Anti-Patterns

### ❌ Too much context

```
# BAD: Pasting the entire requirements.md (2000+ words)
requirements = """
## Full Requirements Document
...entire 50-page spec...
"""
```

The LLM will lose focus. Keep it under 300 words.

### ❌ Vague context

```
# BAD: No specific guidance
requirements = "Review this code for quality issues."
```

This is equivalent to no context at all.

### ❌ Over-constraining

```
# BAD: Telling the LLM what to ignore too aggressively
requirements = "Only check for security issues. Ignore everything else."
```

This can hide real bugs. Let the LLM flag issues, then filter with BMAD.

### ✅ Right-sized context

```
# GOOD: Specific, scoped, actionable
requirements = """
[SDD Context — Task 3.2]
Feature: ralphharness-speckit
Task: Add input validation to switch command
Done-when: switch.md rejects empty input and missing features
Requirements: AC-5.1 (validate input), AC-5.2 (actionable errors)
Design: bash stderr + exit 1 for errors
Files: plugins/ralphharness-speckit/commands/switch.md
Review focus: Verify validation logic meets AC-5.1/5.2. Do NOT flag pre-existing code or style.
"""
```
