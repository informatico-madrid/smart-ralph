---
name: spec-workflow
description: This skill should be used when the user asks to "build a feature", "create a spec", "start spec-driven development", "run research phase", "generate requirements", "create design", "plan tasks", "implement spec", "check spec status", "triage a feature", "create an epic", "decompose a large feature", or needs guidance on spec-driven development workflow, phase ordering, or epic orchestration.
version: 0.2.0
---

# Spec Workflow

Spec-driven development transforms feature requests into structured specs through sequential phases, then executes them task-by-task.

## Decision Tree: Where to Start

| Situation | Command |
|-----------|---------|
| New feature, want guidance | `/ralph-harness:start <name> <goal>` |
| New feature, skip interviews | `/ralph-harness:start <name> <goal> --quick` |
| Large feature needing decomposition | `/ralph-harness:triage <goal>` |
| Resume existing spec | `/ralph-harness:start` (auto-detects) |
| Jump to specific phase | `/ralph-harness:<phase>` |
| Restart a phase from scratch | `/ralph-harness:<phase> --fresh` |

## Single Spec Flow

```
start/new -> research -> requirements -> design -> tasks -> implement
```

Each phase produces a markdown artifact in `./specs/<name>/`. Normal mode pauses for approval between phases. Quick mode runs all phases then auto-starts execution.

### Phase Commands

| Command | Agent | Output | Purpose |
|---------|-------|--------|---------|
| `/ralph-harness:research` | research-analyst | research.md | Explore feasibility, patterns, context |
| `/ralph-harness:requirements` | product-manager | requirements.md | User stories, acceptance criteria, **project type** |
| `/ralph-harness:design` | architect-reviewer | design.md | Architecture, components, interfaces |
| `/ralph-harness:tasks` | task-planner | tasks.md | POC-first task breakdown, VE task numbering |
| `/ralph-harness:implement` | spec-executor | commits | Autonomous task-by-task execution |

### Requirements Phase — Project Type (MANDATORY)

The `product-manager` agent MUST include a `Project type` field in `requirements.md`
under the Verification Contract section. This field gates all downstream VE task
generation and e2e skill loading:

```markdown
## Verification Contract

**Project type**: fullstack | frontend | api-only | cli | library
**Entry points**: <list of routes/endpoints/commands to verify>
```

- `fullstack` / `frontend` → UI entry points valid → VE0 (ui-map-init) + VE tasks with Playwright
- `api-only` → HTTP entry points only → VE tasks with WebFetch/curl, no Playwright
- `cli` / `library` → no network entry points → VE tasks via test commands and build checks only

If the product-manager cannot determine the project type from the goal and codebase,
they must ask the user before completing the requirements phase.

### Tasks Phase — VE Task Generation Rules

The `task-planner` agent MUST follow these rules when generating VE tasks:

1. Read `Project type` from `requirements.md → Verification Contract` before generating tasks
2. For `fullstack` / `frontend`:
   - Always include `VE0` (ui-map-init) as the first VE task
   - Number subsequent UI verification tasks as `VE1`, `VE2`, etc.
   - Load skills: `playwright-env` → `mcp-playwright` → `playwright-session` → `ui-map-init`
3. For `api-only` / `cli` / `library`:
   - Do NOT generate VE0 or any VE tasks with UI entry points
   - Use `curl`/WebFetch for API tasks, test commands for others
   - Do NOT reference any e2e skills
4. For fix-type specs (any project type): add task `4.3` (VF task) after PR creation

### Implement Phase — e2e Skill Loading

During task execution, the `spec-executor` subagent loads e2e skills only when:

- The current task is a VE task (VE0, VE1..N)
- AND `requirements.md → Verification Contract → Project type` is `fullstack` or `frontend`

Loading order for UI VE tasks:
```
1. playwright-env.skill.md    — resolve app URL, auth, seed, write state
2. mcp-playwright.skill.md    — dependency check, lock recovery, writes mcpPlaywright to state
3. playwright-session.skill.md — session lifecycle, auth flow, reads mcpPlaywright from state
4. ui-map-init.skill.md       — VE0 only: build selector map before VE1+
```

> ⚠️ Steps 2 and 3 must be loaded **sequentially, not concurrently**.
> `playwright-session` reads `.ralph-state.json → mcpPlaywright` which is written
> by `mcp-playwright` Step 0. Loading `playwright-session` before or in parallel
> with `mcp-playwright` causes it to find the key absent and fall into degraded
> mode incorrectly.

### Domain-Specific Skill Loading

For projects targeting specific platforms, the task-planner and spec-executor must
also load the domain-specific selector map skill:

| Platform | Detection signal | Additional skill |
|---|---|---|
| Home Assistant | `hass`, `home-assistant`, `lovelace`, `ha-` in project files or goal | `skills/e2e/examples/homeassistant-selector-map.skill.md` |
| Generic web app | No platform-specific signals | `skills/e2e/selector-map.skill.md` (base selector utilities) |

These skills contain navigation patterns and anti-patterns that prevent common
E2E failures (e.g., HA sidebar requires `data-panel-id` clicks, not `page.goto()`).

For API VE tasks (api-only projects): use WebFetch or `curl` directly — no e2e skills needed.

## Epic Flow (Multi-Spec)

For features too large for a single spec, use epic triage to decompose into dependency-aware specs.

```
triage -> [spec-1, spec-2, spec-3...] -> implement each in order
```

**Entry points:**
- `/ralph-harness:triage <goal>` -- create or resume an epic
- `/ralph-harness:start` -- detects active epics, suggests next unblocked spec

**File structure:**
```
specs/
  _epics/<epic-name>/
    epic.md            # Triage output (vision, specs, dependency graph)
    research.md        # Exploration + validation research
    .epic-state.json   # Progress tracking across specs
    .progress.md       # Learnings and decisions
```

## Management Commands

| Command | Purpose |
|---------|---------|
| `/ralph-harness:status` | Show all specs and progress |
| `/ralph-harness:switch <name>` | Change active spec |
| `/ralph-harness:cancel` | Cancel active execution |
| `/ralph-harness:refactor` | Update spec files after execution |

## Common Workflows

### Quick prototype
```bash
/ralph-harness:start my-feature "Build X" --quick
# Runs all phases automatically, starts execution
```

### Guided development
```bash
/ralph-harness:start my-feature "Build X"
# Interactive interviews at each phase
# Review and approve each artifact
/ralph-harness:implement
```

### Large feature
```bash
/ralph-harness:triage "Build entire auth system"
# Decomposes into: auth-core, auth-oauth, auth-rbac
/ralph-harness:start  # Picks next unblocked spec
```

### Restart a phase
```bash
/ralph-harness:design --fresh
# Discards current design.md and reruns the design phase from scratch
# Warning: skipping requirements means Project type may be missing
```

## Quick Mode — How Validation Works

With `--quick`:
- All phases run automatically without pausing for `awaitingApproval`
- Each artifact is validated by the **same agent that produced it** (self-review pass, max 3 iterations)
- architect-reviewer validates design.md; task-planner validates tasks.md; etc.
- There is no separate `spec-reviewer` agent — validation is done inline by the phase agent
- Project type must be inferable from the codebase — if not, quick mode pauses and asks the user
- Auto-transitions to execution after tasks phase

## References

- **`references/phase-transitions.md`** -- Detailed phase flow, state transitions, quick mode behavior, phase skipping
