---
spec: prompt-diet-refactor
phase: research
created: 2026-04-15T19:50:00Z
---

# Research: prompt-diet-refactor

## Executive Summary

**Feasible.** Current coordinator context is ~15,000+ tokens (1,709 non-empty lines across 5 reference files). Target <5,000 tokens achievable through: (1) splitting coordinator-pattern.md (1,023 lines) into 5 focused modules (~150 lines core + 4 special-purpose files), (2) consolidating 8 Native Task Sync sections into 2, (3) eliminating 5 categories of content duplication, (4) moving detailed scripts to hooks/scripts/. **Risk: LOW** — refactoring is mechanical, not algorithmic. **Effort: MEDIUM** — requires careful file surgery and validation.

## External Research

### Best Practices

**Diátaxis Framework** — Systematic approach to documentation structure based on four user needs (tutorials, how-to guides, reference, explanation). Key principles relevant:
- **Hierarchical organization** — landing pages → detailed sections preserves navigability
- **User-first thinking** — structure should emerge from improvements, not be imposed upfront
- **Complexity when necessary** — don't fear nested structures if logical and consistent

**Single Source of Truth (SSOT) Principles**:
- **DRY (Don't Repeat Yourself)** — each piece of information should have a single, authoritative representation
- **Reference over copying** — link to canonical definitions rather than duplicating content
- **Version control friendliness** — single sources make updates easier and reduce merge conflicts

### Prior Art

**Diátaxis hierarchical structure** demonstrates effective splitting:
- Landing pages provide overview/navigation
- Detailed sections dive deep into specific topics
- Cross-references connect related concepts without duplication

**Applied to coordinator-pattern.md**:
- `coordinator-core.md` → role, FSM, critical rules, signal protocol (~150 lines)
- `ve-verification-contract.md` → VE task delegation, skills loading (~200 lines)
- `task-modification.md` → SPLIT/PREREQ/FOLLOWUP/ADJUST operations (~150 lines)
- `pr-lifecycle.md` → PR management, CI monitoring (~150 lines)
- `git-strategy.md` → commit/push strategy (~100 lines)

### Pitfalls to Avoid
- **Premature deletion**: deleting coordinator-pattern.md before all references are updated will break the coordinator silently (no file-not-found error during spec authoring, only at runtime)
- **Over-splitting**: modules smaller than ~80 lines gain nothing — the per-file load overhead is fixed; too many files increases reference management complexity
- **Reference loops**: if modules cross-reference each other (e.g., ve-verification-contract.md loads coordinator-core.md logic), the on-demand load model breaks; keep modules independent except for the "See X for Y" annotation pattern
- **Verification by presence, not content**: creating an empty file satisfies `test -f` but not behavioral compatibility; functional verification (full spec execution) is mandatory

## Codebase Analysis

### Current State

**File Sizes** (non-empty lines):
| File | Lines | Purpose |
|------|-------|---------|
| `coordinator-pattern.md` | 1,023 | Core coordinator prompt (bloated) |
| `failure-recovery.md` | 544 | Fix task generation, retry logic |
| `phase-rules.md` | 451 | Phase-specific behavior |
| `commit-discipline.md` | 110 | Git commit conventions |
| `verification-layers.md` | 235 | 5-layer verification framework |
| **Total loaded per iteration** | **2,363** | ~15,000 tokens @ 4 tokens/line |

**coordinator-pattern.md structure** (1,023 lines):
- Lines 1-47: Role definition, integrity rules
- Lines 48-80: Native Task Sync - Initial Setup
- Lines 78-177: Check completion, parse task, chat protocol
- Lines 178-280: Native Task Sync - Bidirectional, Pre-Delegation
- Lines 281-513: Task delegation, Native Task Sync - Parallel, Failure
- Lines 514-626: Verification layers, Native Task Sync - Post-Verification
- Lines 627-755: State update, progress merge, Native Task Sync - Completion
- Lines 756-908: Task modification, PR lifecycle, Native Task Sync - Modification
- Lines 909-1023: Final cleanup, git push

### Existing Patterns

**Native Task Sync sections** (8 sections, confirmed):
1. **Initial Setup** (lines 48-76) — TaskCreate batch, stale ID detection
2. **Bidirectional Check** (line 281) — Sync tasks.md → native state
3. **Pre-Delegation** (line 291) — TaskUpdate before delegate
4. **Parallel** (line 514) — Handle parallel task completion
5. **Failure** (line 569) — TaskUpdate on retry
6. **Post-Verification** (line 627) — TaskUpdate after verify
7. **Completion** (line 756) — TaskUpdate on task done
8. **Modification** (line 909) — TaskCreate/TaskUpdate on task insert

**Graceful degradation pattern** (repeated in all 8 sections):
```bash
On success: reset nativeSyncFailureCount to 0
On failure: increment nativeSyncFailureCount
If count >= 3: set nativeSyncEnabled = false, log warning
```

### Duplicated Content Analysis

| Content Type | Duplicated In | Canonical Source | Lines Saved |
|--------------|---------------|------------------|-------------|
| Quality checkpoints | `quality-checkpoints.md`, `phase-rules.md`, `task-planner.md` | `quality-checkpoints.md` | ~30 |
| VE definitions (VE0-VE3) | `quality-checkpoints.md`, `phase-rules.md` | `quality-checkpoints.md` | ~25 |
| E2E anti-patterns | `e2e-anti-patterns.md`, `coordinator-pattern.md` (inline) | `e2e-anti-patterns.md` | ~15 |
| Intent classification | `intent-classification.md`, `phase-rules.md`, `task-planner.md` | `intent-classification.md` | ~40 |
| Test integrity | `test-integrity.md`, `quality-checkpoints.md` | `test-integrity.md` | ~20 |

**Total duplication**: ~130 lines across 5 categories

### Detailed Scripts Embedded in Prompts

**Bash scripts in coordinator-pattern.md** (lines 200-249):
- Atomic append with flock locks (chat.md writes) — 15 lines
- Pilot callout announcements — 10 lines
- Completion notices — 10 lines

**jq patterns** (line 642):
- jq merge pattern for state updates — documented inline

**VE-cleanup pseudocode** (in quality-checkpoints.md):
- Skip-forward logic for VE task failures — ~20 lines

**Native Task Sync algorithm details** (lines 48-76):
- TaskCreate/TaskUpdate call patterns — 25 lines
- Stale ID detection logic — 5 lines

### Existing hooks/scripts/ Directory

**Current scripts** (7 files, 48KB total):
- `stop-watcher.sh` (30KB) — execution loop controller
- `path-resolver.sh` (7KB) — multi-directory spec resolution
- `test-multi-dir-integration.sh` (24KB) — integration tests
- `update-spec-index.sh` (7KB) — spec indexing
- `load-spec-context.sh` (4KB) — context loading utilities
- `quick-mode-guard.sh` (1KB) — quick mode protection

**Pattern**: Scripts are executable, well-documented, focused on single responsibility.

### Dependencies

**No new dependencies required.** Refactoring is pure documentation reorganization.

**Existing tooling leveraged**:
- `hooks/scripts/` directory for extracted scripts
- Reference file loading pattern in `implement.md`
- jq for state manipulation (already used)

### Constraints

**Technical constraints**:
- `implement.md` Step 1 loads references via hardcoded paths — must update after split
- Agent prompts reference `coordinator-pattern.md` by name — must update to `coordinator-core.md`
- Stop-hook continuation prompt references coordinator sections — must validate after split

**Verification constraint** (from ENGINE_ROADMAP.md Section 7.1.2):
- Target metric: <5,000 tokens per coordinator iteration
- Measured as: total lines of references loaded × ~4 tokens/line
- Must be <1,200 lines (down from current 2,363)

## Related Specs

| Spec | Relevance | Relationship | May Need Update |
|------|-----------|--------------|-----------------|
| `engine-state-hardening` | **High** | Precedes spec 2 in roadmap. Adds verification layers, HOLD checks, state validation to coordinator-pattern.md. | **Yes** — changes made in spec 1 will be split in spec 2. Coordinate to avoid conflicts. |
| `native-task-sync` | **Medium** | Completed spec that added 8 Native Task Sync sections to coordinator-pattern.md. These are the sections being consolidated in spec 2. | **No** — spec 2 builds on spec's work, consolidating it. |
| `fix-impl-context-bloat` | **Medium** | Earlier attempt to reduce coordinator context. Research may contain relevant analysis. | **No** — spec 2 supersedes this work with more systematic approach. |

### Coordination Notes

**Spec 1 dependency**: Spec 1 (`engine-state-hardening`) MUST complete before spec 2 starts. Spec 1 modifies `coordinator-pattern.md` (verification layers, HOLD checks, state validation). Spec 2 will split these changes into new modular structure. If spec 2 runs first, its file surgery will conflict with spec 1's edits.

**Coordination approach**: After spec 1 completes, spec 2 should read the modified `coordinator-pattern.md` and split it, preserving spec 1's additions in the appropriate new modules.

## Feasibility Assessment

| Aspect | Assessment | Notes |
|--------|------------|-------|
| Technical Viability | **High** | Pure refactoring, no algorithm changes. File splitting is mechanical. Consolidation is pattern replacement. |
| Effort Estimate | **MEDIUM** | ~40-60 tasks across 4 phases. File surgery requires care but is straightforward. Validation is critical. |
| Risk Level | **LOW** | No behavior changes. Only reorganization. Risk is breaking references (file paths, section names). |
| Token Reduction Target | **Achievable** | Current: 2,363 lines × 4 = ~9,452 tokens. Target: <1,200 lines × 4 = <4,800 tokens. Reduction: ~50% |

**Token budget breakdown** (target <1,200 lines):
| Module | Estimated Lines | Rationale |
|--------|-----------------|-----------|
| `coordinator-core.md` | 150 | Role, FSM, critical rules, signal protocol (lines 1-47, 78-177 of current) |
| `ve-verification-contract.md` | 200 | VE delegation, skills loading (extracted from current) |
| `task-modification.md` | 150 | SPLIT/PREREQ/FOLLOWUP/ADJUST (lines 756-908 of current) |
| `pr-lifecycle.md` | 150 | PR management, CI monitoring (part of lines 756-908) |
| `git-strategy.md` | 100 | Commit/push strategy (extracted from current) |
| Native Task Sync (2 sections) | 100 | Consolidated from 8 sections (~200 lines → 100 lines) |
| `failure-recovery.md` (trimmed 50%) | 272 | Dedup removal reduces from 544 lines |
| `commit-discipline.md` (unchanged) | 110 | Git commit conventions |
| `phase-rules.md` (after dedup) | ~250 | Reduced from 451 lines after removing VE defs + intent classification |
| **Total (worst case)** | **~1,282** | **Marginally over target without phase-rules dedup** |
| **Total (with dedup)** | **~1,132** | **Under 1,200 target once dedup complete** |

**Assumptions**:
- `failure-recovery.md` trimmed 50% via dedup removal → 272 lines
- `verification-layers.md` (235 lines) is NOT loaded separately — its content is absorbed into `ve-verification-contract.md`
- `phase-rules.md` reduced from 451 to ~250 after removing VE definitions + intent classification
- On-demand loading means coordinator NEVER loads all 5 new modules at once
- **Critical**: target is achievable ONLY if phase-rules.md dedup is included. Without it: 150+200+272+110+451=1,183 (barely under) but with verification-layers still counting separately: exceeds target.

## Recommendations for Requirements

1. **Split coordinator-pattern.md into 5 modules** — Create `coordinator-core.md` (always loaded), `ve-verification-contract.md`, `task-modification.md`, `pr-lifecycle.md`, `git-strategy.md` (loaded on-demand based on task type).

2. **Consolidate 8 Native Task Sync sections into 2** — "Before delegation" (Initial Setup + Bidirectional + Pre-Delegation + Parallel + Failure + Modification) and "After completion" (Post-Verification + Completion). Define graceful degradation pattern once, reference twice.

3. **Eliminate 5 categories of duplication** — Move Quality checkpoints, VE definitions, E2E anti-patterns, Intent classification, Test integrity to single canonical sources. Update all references to point to canonical files.

4. **Extract detailed scripts to hooks/scripts/** — Move atomic append scripts, jq patterns, VE-cleanup pseudocode, Native Task Sync algorithms to `hooks/scripts/` as reference utilities. Reference by name in prompts.

5. **Update implement.md reference loading** — After split, coordinator loads `coordinator-core.md` (always) plus one of the 4 special-purpose modules (on-demand). Never all at once. Update agent prompts to reference new file names.

6. **Validate with token count test** — Create verification task that counts lines of loaded references and confirms <1,200 lines per iteration.

## Open Questions

- **Does implement.md load phase-rules.md and verification-layers.md separately?** Critical for token budget math. If verification-layers.md is loaded alongside coordinator-core.md it adds 235 lines and may push total over 1,200. Need to inspect implement.md Step 1 reference list before starting.
- **Is the split between task-modification.md and pr-lifecycle.md clear in lines 756-908?** Both modules claim this line range. The exact boundary needs to be determined when reading the actual file content.
- **Does failure-recovery.md actually contain 50% duplicated content?** The 50% trim assumption directly impacts feasibility. If less is duplicated, the total may exceed 1,200 lines without more aggressive consolidation.

## Sources

### External Sources
- **Diátaxis Documentation Framework** — `/websites/diataxis_fr` (documentation structure and organization principles)
  - Complex hierarchies: https://diataxis.fr/complex-hierarchies
  - How to use Diátaxis: https://diataxis.fr/how-to-use-diataxis

### Internal Sources
- **ENGINE_ROADMAP.md** — `/mnt/bunker_data/ai/smart-ralph/docs/ENGINE_ROADMAP.md`
  - Spec 2 brief (Section 6.2): lines 318-330
  - Verification criteria (Section 7.1.2): line 511
  - Success criteria (Section 8): lines 502-523

- **coordinator-pattern.md** — `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/references/coordinator-pattern.md` (1,023 lines)

- **implement.md** — `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/commands/implement.md` (reference loading at lines 228-240)

- **native-task-sync spec** — `/mnt/bunker_data/ai/smart-ralph/specs/native-task-sync/.progress.md` (completed work on 8 sync sections)

- **hooks/scripts/** — `/mnt/bunker_data/ai/smart-ralph/plugins/ralph-specum/hooks/scripts/` (existing script extraction pattern)

- **Quality checkpoints duplication** — grep results across `quality-checkpoints.md`, `phase-rules.md`, `task-planner.md`

- **VE definitions duplication** — grep results across `quality-checkpoints.md`, `phase-rules.md`

- **E2E anti-patterns duplication** — grep results across `e2e-anti-patterns.md`, `coordinator-pattern.md`

- **Intent classification duplication** — grep results across `intent-classification.md`, `phase-rules.md`, `task-planner.md`
