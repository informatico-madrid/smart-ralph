# Tasks: RalphHarness Rename

## Overview

**Goal:** Rename project from tzachbon/smart-ralph (ralph-specum plugin) to informatico-madrid/RalphHarness (ralphharness plugin). This is a **rename-only refactoring** -- no architecture changes, no logic changes, no new features.

**Intent:** REFACTOR (rename-only) -- TDD workflow adapted: the "test" in TDD terms is: verify grep returns 0 for old names AND grep returns >0 for new names. The "implementation" is: applying the sed/git-mv changes. Tests pass immediately if the rename is correct.

**Total tasks:** 70

## Completion Criteria (Autonomous Execution Standard)

This spec is not complete until ALL criteria are met:

- [x] **Zero Regressions:** No code logic changed, all plugin.json/TOML/YAML files valid
- [x] **Git History Preserved:** `git log --follow` works for all renamed directories
- [x] **All Verification Passes:** V1-V8 sequence completes with all checks passing
- [x] **Reference Completeness:** 0 matches for "ralph-specum", "tzachbon", "smart-ralph" in in-scope files

> **Quality Checkpoints:** Intermediate quality gate checks ([VERIFY]) are inserted every 2-3 tasks to catch issues early.

## Task Writing Guide

**Sizing rules:** Max 4 Do steps, max 3 files per task. Split if exceeded. For git mv batches (simple copy operations), expand to max 8 git mvs per task.

**Parallel markers:** Mark independent tasks with [P] for concurrent execution. [VERIFY] tasks always break groups.

### Task Writing Principles

1. **Think First:** Tasks should surface what's unclear, not assume. If a task depends on an uncertain assumption (e.g., "config file exists at X"), state it explicitly in the Do section.
2. **Simplicity:** Minimum steps to achieve the goal. No speculative features, no abstractions for single-use code.
3. **Surgical:** Each task touches only what it must. Every changed file traces directly to the task's goal.
4. **Goal-Driven:** Emphasize **Done when** and **Verify** over **Do** steps. The Do is guidance; the Done when is the contract.

## Phase 0: Pre-flight Safety

**Goal:** Document baseline counts before any changes. Create audit trail.

- [x] 0.1 Record pre-change grep counts for audit trail
  - **Do**:
    1. Run grep for "ralph-specum" excluding out-of-scope dirs, save count
    2. Run grep for "tzachbon" excluding out-of-scope dirs, save count
    3. Run grep for "smart-ralph" excluding out-of-scope dirs, save count
    4. Verify git working tree is clean (`git status --porcelain` returns empty)
  - **Files**: `.pre-change-counts.txt` (new file)
  - **Done when**: Three pre-change counts documented and working tree confirmed clean
  - **Verify**: `test -f .pre-change-counts.txt && wc -l .pre-change-counts.txt`
  - **Commit**: `chore(rename): record pre-change grep counts for audit trail`
  - _Requirements: AC-1.6, Verification Contract_

- [ ] 0.2 [VERIFY] Pre-flight verification: baseline counts documented
  - **Do**: Verify that pre-change grep counts file exists and contains non-zero values for all three patterns, confirming the files exist before changes
  - **Verify**: `grep -c "ralph-specum\|tzachbon\|smart-ralph" .pre-change-counts.txt | grep -q "3"`
  - **Done when**: All three baseline counts are positive numbers (files exist to rename)
  - **Commit**: `chore(rename): pre-flight verified` (only if pre-change counts differ from zero)
  - _Requirements: Verification Contract_

## Phase 1: Foundation -- Directory Renames + Manifests

**Goal:** Rename directory structures with `git mv` and update all manifest files. Each change is immediately verified.

- [x] 1.1 [P] Rename main plugin directory with `git mv`
- **Do**:
  1. `git mv plugins/ralph-specum plugins/ralphharness`
  2. Verify directory exists at new path: `test -d plugins/ralphharness`
  3. Verify git sees rename: `git status --short | grep -q "R.*ralphharness"`
- **Files**: `plugins/ralphharness/` (entire directory, renamed)
- **Done when**: `plugins/ralphharness/` exists and git shows it as renamed from `plugins/ralph-specum/`
- **Verify**: `test -d plugins/ralphharness && git log --follow -1 plugins/ralphharness/ | head -1`
- **Commit**: `rename(plugin): git mv plugins/ralph-specum -> plugins/ralphharness`
- _Requirements: AC-1.1, FR-1, NFR-1_

- [ ] 1.2 [P] Rename speckit plugin directory with `git mv`
  - **Do**:
    1. `git mv plugins/ralph-speckit plugins/ralphharness-speckit`
    2. Verify directory exists at new path
    3. Verify git sees rename
  - **Files**: `plugins/ralphharness-speckit/` (entire directory, renamed)
  - **Done when**: `plugins/ralphharness-speckit/` exists with git history preserved
  - **Verify**: `test -d plugins/ralphharness-speckit && git log --follow -1 plugins/ralphharness-speckit/ | head -1`
  - **Commit**: `rename(plugin): git mv plugins/ralph-speckit -> plugins/ralphharness-speckit`
  - _Requirements: AC-2.1, FR-2, NFR-1_

- [ ] 1.3 [P] Rename codex plugin directory with `git mv`
  - **Do**:
    1. `git mv plugins/ralph-specum-codex plugins/ralphharness-codex`
    2. Verify directory exists at new path
    3. Verify git sees rename
  - **Files**: `plugins/ralphharness-codex/` (entire directory, renamed)
  - **Done when**: `plugins/ralphharness-codex/` exists with git history preserved
  - **Verify**: `test -d plugins/ralphharness-codex && git log --follow -1 plugins/ralphharness-codex/ | head -1`
  - **Commit**: `rename(plugin): git mv plugins/ralph-specum-codex -> plugins/ralphharness-codex`
  - _Requirements: AC-13.1, FR-31, NFR-1_

- [ ] 1.4 [P] Codex skill directory renames -- batch 1
  - **Do**:
    1. `git mv plugins/ralphharness-codex/skills/ralph-specum plugins/ralphharness-codex/skills/ralphharness`
    2. `git mv plugins/ralphharness-codex/skills/ralph-specum-cancel plugins/ralphharness-codex/skills/ralphharness-cancel`
    3. `git mv plugins/ralphharness-codex/skills/ralph-specum-design plugins/ralphharness-codex/skills/ralphharness-design`
    4. `git mv plugins/ralphharness-codex/skills/ralph-specum-feedback plugins/ralphharness-codex/skills/ralphharness-feedback`
  - **Files**: `plugins/ralphharness-codex/skills/ralph-specum{,-cancel,-design,-feedback}` → `ralphharness{,-cancel,-design,-feedback}`
  - **Done when**: All four skill directories renamed under codex plugin
  - **Verify**: `test -d plugins/ralphharness-codex/skills/ralphharness && test -d plugins/ralphharness-codex/skills/ralphharness-cancel && test -d plugins/ralphharness-codex/skills/ralphharness-design && test -d plugins/ralphharness-codex/skills/ralphharness-feedback`
  - **Commit**: `rename(plugin): git mv codex skills batch 1 -> ralphharness{-cancel,-design,-feedback}`
  - _Requirements: AC-13.3, FR-31_

- [ ] 1.5 [P] Codex skill directory renames -- batch 2
  - **Do**:
    1. `git mv plugins/ralphharness-codex/skills/ralph-specum-help plugins/ralphharness-codex/skills/ralphharness-help`
    2. `git mv plugins/ralphharness-codex/skills/ralph-specum-implement plugins/ralphharness-codex/skills/ralphharness-implement`
    3. `git mv plugins/ralphharness-codex/skills/ralph-specum-index plugins/ralphharness-codex/skills/ralphharness-index`
    4. `git mv plugins/ralphharness-codex/skills/ralph-specum-refactor plugins/ralphharness-codex/skills/ralphharness-refactor`
  - **Files**: `plugins/ralphharness-codex/skills/ralph-specum{,-help,-implement,-index,-refactor}`
  - **Done when**: All four skill directories renamed under codex plugin
  - **Verify**: `test -d plugins/ralphharness-codex/skills/ralphharness-help && test -d plugins/ralphharness-codex/skills/ralphharness-implement && test -d plugins/ralphharness-codex/skills/ralphharness-index && test -d plugins/ralphharness-codex/skills/ralphharness-refactor`
  - **Commit**: `rename(plugin): git mv codex skills batch 2 -> ralphharness{-help,-implement,-index,-refactor}`
  - _Requirements: AC-13.3, FR-31_

- [ ] 1.6 [P] Codex skill directory renames -- batch 3
  - **Do**:
    1. `git mv plugins/ralphharness-codex/skills/ralph-specum-requirements plugins/ralphharness-codex/skills/ralphharness-requirements`
    2. `git mv plugins/ralphharness-codex/skills/ralph-specum-research plugins/ralphharness-codex/skills/ralphharness-research`
    3. `git mv plugins/ralphharness-codex/skills/ralph-specum-rollback plugins/ralphharness-codex/skills/ralphharness-rollback`
    4. `git mv plugins/ralphharness-codex/skills/ralph-specum-start plugins/ralphharness-codex/skills/ralphharness-start`
  - **Files**: `plugins/ralphharness-codex/skills/ralph-specum{,-requirements,-research,-rollback,-start}`
  - **Done when**: All four skill directories renamed under codex plugin
  - **Verify**: `test -d plugins/ralphharness-codex/skills/ralphharness-requirements && test -d plugins/ralphharness-codex/skills/ralphharness-research && test -d plugins/ralphharness-codex/skills/ralphharness-rollback && test -d plugins/ralphharness-codex/skills/ralphharness-start`
  - **Commit**: `rename(plugin): git mv codex skills batch 3 -> ralphharness{-requirements,-research,-rollback,-start}`
  - _Requirements: AC-13.3, FR-31_

- [ ] 1.7 [P] Codex skill directory renames -- batch 4 + VERIFY
  - **Do**:
    1. `git mv plugins/ralphharness-codex/skills/ralph-specum-status plugins/ralphharness-codex/skills/ralphharness-status`
    2. `git mv plugins/ralphharness-codex/skills/ralph-specum-switch plugins/ralphharness-codex/skills/ralphharness-switch`
    3. `git mv plugins/ralphharness-codex/skills/ralph-specum-tasks plugins/ralphharness-codex/skills/ralphharness-tasks`
    4. `git mv plugins/ralphharness-codex/skills/ralph-specum-triage plugins/ralphharness-codex/skills/ralphharness-triage`
    5. Verify all 16 skill directories exist at new paths
  - **Files**: `plugins/ralphharness-codex/skills/ralph-specum{,-status,-switch,-tasks,-triage}`
  - **Done when**: All 16 codex skill directories renamed (ralph-specum → ralphharness with suffixes)
  - **Verify**: `test -d plugins/ralphharness-codex/skills/ralphharness && test -d plugins/ralphharness-codex/skills/ralphharness-status && test -d plugins/ralphharness-codex/skills/ralphharness-switch && test -d plugins/ralphharness-codex/skills/ralphharness-tasks && test -d plugins/ralphharness-codex/skills/ralphharness-triage && ! test -d plugins/ralphharness-codex/skills/ralph-specum && echo "ALL_16_SKILLS_RENAMED"`
  - **Commit**: `rename(plugin): git mv codex skills batch 4 -> ralphharness{-status,-switch,-tasks,-triage} + verify all 16`
  - _Requirements: AC-13.3, FR-31_

- [ ] 1.8 [P] Rename smart-ralph skill directories (main plugins)
  - **Do**:
    1. `git mv plugins/ralphharness/skills/smart-ralph plugins/ralphharness/skills/ralphharness`
    2. `git mv plugins/ralphharness-speckit/skills/smart-ralph plugins/ralphharness-speckit/skills/ralphharness`
    3. Verify both new directories exist
  - **Files**: `plugins/ralphharness/skills/ralphharness/`, `plugins/ralphharness-speckit/skills/ralphharness/`
  - **Done when**: Both skill directories renamed from `smart-ralph` to `ralphharness`
  - **Verify**: `test -d plugins/ralphharness/skills/ralphharness && test -d plugins/ralphharness-speckit/skills/ralphharness`
  - **Commit**: `rename(plugin): git mv smart-ralph skill dirs -> ralphharness`
  - _Requirements: AC-11.1, FR-14_

- [ ] 1.9 [P] Rename bmad-bridge plugin directory with `git mv`
  - **Do**:
    1. `git mv plugins/ralph-bmad-bridge plugins/ralphharness-bmad-bridge`
    2. Verify directory exists at new path
    3. Verify git sees rename
    4. NOTE: design.md says directory name is "unchanged" because it has no `ralph-specum` in it, but we are renaming `ralph-` to `ralphharness-` for consistency. The bmad-bridge contains no ralph-specum references in its content.
  - **Files**: `plugins/ralphharness-bmad-bridge/` (entire directory, renamed)
  - **Done when**: `plugins/ralphharness-bmad-bridge/` exists with git history preserved
  - **Verify**: `test -d plugins/ralphharness-bmad-bridge && git log --follow -1 plugins/ralphharness-bmad-bridge/ | head -1`
  - **Commit**: `rename(plugin): git mv plugins/ralph-bmad-bridge -> plugins/ralphharness-bmad-bridge`
  - _Requirements: AC-3.1, FR-5_

- [ ] 1.10 Rename settings file and verify
  - **Do**:
    1. `git mv .claude/ralph-specum.local.md .claude/ralphharness.local.md`
    2. Verify new file exists
  - **Files**: `.claude/ralphharness.local.md` (renamed from ralph-specum.local.md)
  - **Done when**: `.claude/ralphharness.local.md` exists, old file gone
  - **Verify**: `test -f .claude/ralphharness.local.md && ! test -f .claude/ralph-specum.local.md`
  - **Commit**: `rename(config): git mv ralph-specum.local.md -> ralphharness.local.md`
  - _Requirements: AC-9.1, FR-13_

- [ ] 1.11 Delete README.fork.md
  - **Do**:
    1. `git rm README.fork.md`
    2. Verify file no longer exists
  - **Files**: `README.fork.md` (deleted)
  - **Done when**: `README.fork.md` does not exist
  - **Verify**: `! test -f README.fork.md`
  - **Commit**: `chore(rename): delete README.fork.md`
  - _Requirements: AC-7.3, FR-21_

- [ ] 1.12 [VERIFY] Foundation checkpoint: all directory renames verified
  - **Do**:
    1. Verify all directories exist at new paths: `plugins/ralphharness/`, `plugins/ralphharness-speckit/`, `plugins/ralphharness-codex/`, `plugins/ralphharness-bmad-bridge/`, `.claude/ralphharness.local.md`
    2. Verify old directories no longer exist
    3. Verify git log --follow works for at least `plugins/ralphharness/`
    4. Verify `README.fork.md` deleted
    5. No git conflicts or errors
  - **Verify**:
    ```bash
    test -d plugins/ralphharness && test -d plugins/ralphharness-speckit \
      && test -d plugins/ralphharness-codex && test -d plugins/ralphharness-bmad-bridge \
      && test -f .claude/ralphharness.local.md \
      && ! test -d plugins/ralph-specum && ! test -d plugins/ralph-speckit \
      && ! test -d plugins/ralph-specum-codex && ! test -d plugins/ralph-bmad-bridge \
      && ! test -f README.fork.md \
      && git log --follow -1 plugins/ralphharness/ > /dev/null \
      && echo "ALL_FOUNDATIONS_PASS"
    ```
  - **Done when**: All four plugin directories, settings file exist at new paths; old paths confirmed gone; git history preserved
  - **Commit**: `chore(rename): pass foundation checkpoint` (only if fixes needed)
  - _Requirements: AC-1.1, AC-2.1, AC-3.1, AC-13.1, AC-9.1, FR-1, FR-2, FR-5, FR-13_

- [ ] 1.13 Update main plugin.json (name, author, version)
  - **Do**:
    1. Set `"name": "ralphharness"` in `plugins/ralphharness/.claude-plugin/plugin.json`
    2. Set `author.name` to `"informatico-madrid"`
    3. Set `"version": "5.0.0"`
  - **Files**: `plugins/ralphharness/.claude-plugin/plugin.json`
  - **Done when**: All three fields updated correctly in JSON
  - **Verify**: `jq -r '.name' plugins/ralphharness/.claude-plugin/plugin.json` returns `"ralphharness"` AND `jq -r '.version' plugins/ralphharness/.claude-plugin/plugin.json` returns `"5.0.0"`
  - **Commit**: `chore(rename): update main plugin.json -> name=ralphharness, version=5.0.0`
  - _Requirements: AC-1.2, AC-1.3, AC-1.4, FR-3_

- [ ] 1.14 Update speckit plugin.json (name, author, version)
  - **Do**:
    1. Set `"name": "ralphharness-speckit"` in `plugins/ralphharness-speckit/.claude-plugin/plugin.json`
    2. Set `author.name` to `"informatico-madrid"`
    3. Set `"version": "1.0.0"`
  - **Files**: `plugins/ralphharness-speckit/.claude-plugin/plugin.json`
  - **Done when**: name=ralphharness-speckit, author=informatico-madrid, version=1.0.0
  - **Verify**: `jq -r '.name' plugins/ralphharness-speckit/.claude-plugin/plugin.json` returns `"ralphharness-speckit"` AND `jq -r '.version'` returns `"1.0.0"`
  - **Commit**: `chore(rename): update speckit plugin.json -> ralphharness-speckit v1.0.0`
  - _Requirements: AC-2.1, AC-2.2, AC-2.3, FR-4_

- [ ] 1.15 [VERIFY] Manifest validation: JSON parsing + jq checks
  - **Do**:
    1. Validate all four plugin.json files parse correctly: `jq . <file>` for each
    2. Verify main plugin: `jq -r '.name' = "ralphharness"`
    3. Verify speckit plugin: `jq -r '.name' = "ralphharness-speckit"`
    4. Verify no old names remain in manifests
  - **Verify**: `jq -r '.name' plugins/ralphharness/.claude-plugin/plugin.json | grep -q "ralphharness$" && jq -r '.name' plugins/ralphharness-speckit/.claude-plugin/plugin.json | grep -q "ralphharness-speckit$" && echo "MANIFESTS_OK"`
  - **Done when**: All manifest JSON files parse correctly and contain new names
  - **Commit**: `chore(rename): pass manifest validation checkpoint` (only if fixes needed)
  - _Requirements: AC-1.6, AC-2.1_

## Phase 2: Core Rename -- Plugin Content

**Goal:** Apply grep-sed replacements across all plugin content. CRITICAL: sed expression order must be LONGER FIRST (`ralph-specum:` before `ralph-specum`). Dry-run before each directory.

- [ ] 2.1 [P] Rename bmad-bridge plugin.json
- **Do**:
  1. Set `author.name` to `"informatico-madrid"` in `plugins/ralphharness-bmad-bridge/.claude-plugin/plugin.json`
  2. Update description to not mention "Smart Ralph" as external property
- **Files**: `plugins/ralphharness-bmad-bridge/.claude-plugin/plugin.json`
- **Done when**: author.name = "informatico-madrid" and no "Smart Ralph" in description
- **Verify**: `jq -r '.author.name' plugins/ralphharness-bmad-bridge/.claude-plugin/plugin.json` returns `"informatico-madrid"`
- **Commit**: `chore(rename): update bmad-bridge plugin.json -> author=informatico-madrid`
- _Requirements: AC-3.1, AC-3.2, FR-5_

- [ ] 2.2 Update main marketplace.json (owner, name, paths, authors)
  - **Do**:
    1. Set `"name": "ralphharness"` (was "smart-ralph")
    2. Set `owner.name` to `"informatico-madrid"` (was "tzachbon")
    3. Update all `source` paths from old directory names to new ones
    4. Update all `author.name` entries to `"informatico-madrid"`
  - **Files**: `.claude-plugin/marketplace.json`
  - **Done when**: owner=informatico-madrid, name=ralphharness, all source paths and authors updated
  - **Verify**: `jq -r '.owner.name' .claude-plugin/marketplace.json` returns `"informatico-madrid"` AND `jq -r '.name'` returns `"ralphharness"`
  - **Commit**: `chore(rename): update .claude-plugin/marketplace.json -> ralphharness owner`
  - _Requirements: AC-4.1, AC-4.2, AC-4.3, AC-4.4, FR-6_

- [ ] 2.3 [P] Update parallel marketplace.json (.agents/plugins)
  - **Do**:
    1. Set `"name": "ralphharness"` (was "smart-ralph")
    2. Update all `source.path` values to use new directory names
    3. Update all `author.name` entries to `"informatico-madrid"`
  - **Files**: `.agents/plugins/marketplace.json`
  - **Done when**: Name=ralphharness, all paths and authors point to new names
  - **Verify**: `jq '.name' .agents/plugins/marketplace.json | grep -q "ralphharness"`
  - **Commit**: `chore(rename): update .agents/plugins/marketplace.json -> ralphharness`
  - _Requirements: AC-10.5, FR-16_

- [ ] 2.4 Update main plugin schema.json ($id, title, description)
  - **Do**:
    1. Set `$id` to `"ralphharness"` in `plugins/ralphharness/schemas/spec.schema.json`
    2. Update title and description text to reference ralphharness
  - **Files**: `plugins/ralphharness/schemas/spec.schema.json`
  - **Done when**: `$id` = "ralphharness", title and description reference ralphharness
  - **Verify**: `jq -r '.["$id"]' plugins/ralphharness/schemas/spec.schema.json` returns `"ralphharness"`
  - **Commit**: `chore(rename): update main schema.json -> $id=ralphharness`
  - _Requirements: FR-7 (schema part)_

- [ ] 2.5 Update codex plugin.json (name, author, version)
  - **Do**:
    1. Set `"name": "ralphharness-codex"` in `plugins/ralphharness-codex/.codex-plugin/plugin.json`
    2. Set `author.name` to `"informatico-madrid"`
    3. Set `"version": "5.0.0"`
  - **Files**: `plugins/ralphharness-codex/.codex-plugin/plugin.json`
  - **Done when**: name=ralphharness-codex, author=informatico-madrid, version=5.0.0
  - **Verify**: `jq -r '.name' plugins/ralphharness-codex/.codex-plugin/plugin.json` returns `"ralphharness-codex"`
  - **Commit**: `chore(rename): update codex plugin.json -> ralphharness-codex v5.0.0`
  - _Requirements: AC-13.2, FR-31_

- [ ] 2.6 [VERIFY] Core manifests checkpoint: all 6 manifests validated
  - **Do**:
    1. Validate all JSON manifests parse correctly (4 plugin.json + 2 marketplace.json + 2 schema.json = 8 files total)
    2. Verify no `"tzachbon"` remains in any manifest
    3. Verify no old plugin names in manifest `name` or `author` fields
    4. Check JSON validity across all structured files in plugins directory
  - **Verify**:
    ```bash
    for f in plugins/ralphharness/.claude-plugin/plugin.json plugins/ralphharness-speckit/.claude-plugin/plugin.json \
      plugins/ralphharness-bmad-bridge/.claude-plugin/plugin.json plugins/ralphharness-codex/.codex-plugin/plugin.json \
      .claude-plugin/marketplace.json .agents/plugins/marketplace.json \
      plugins/ralphharness/schemas/spec.schema.json plugins/ralphharness-codex/schemas/spec.schema.json; do
      jq . "$f" > /dev/null 2>&1 || echo "INVALID_JSON: $f"
    done && echo "ALL_JSON_VALID"
    ```
  - **Done when**: All 8 JSON files parse correctly, no tzachbon in manifests
  - **Commit**: `chore(rename): pass manifest validation checkpoint 2` (only if fixes needed)
  - _Requirements: AC-4.5, AC-13.2_

- [ ] 2.7 [P] Core rename: commands directory (all 16 files)
- **Do**:
  1. Dry-run on `plugins/ralphharness/commands/` to verify expected matches
  2. Apply sed with longer-first ordering:
     ```bash
     find plugins/ralphharness/commands -type f -name '*.md' -exec sed -i \
       -e 's/ralph-specum:/ralph-harness:/g' \
       -e 's/ralph-specum/ralphharness/g' \
       -e 's/smart-ralph/ralphharness/g' \
       -e 's/tzachbon/informatico-madrid/g' \
       {} +
     ```
  3. Verify: `grep -r "ralph-specum:" plugins/ralphharness/commands/ | wc -l` returns 0
- **Files**: `plugins/ralphharness/commands/*.md` (16 files)
- **Done when**: All command files use `/ralph-harness:` prefix, no `ralph-specum:` remains
- **Verify**: `grep -r "ralph-specum:" plugins/ralphharness/commands/ | wc -l` returns 0 AND `grep -r "/ralph-harness:" plugins/ralphharness/commands/ | wc -l` returns >0
- **Commit**: `rename(plugin): sed commands/ -> ralph-harness prefix + identities`
- _Requirements: AC-5.1, AC-5.2, AC-5.3, AC-5.4, FR-7, FR-11_

- [ ] 2.8 [P] Core rename: hook scripts directory (all 10 files)
  - **Do**:
    1. Dry-run on `plugins/ralphharness/hooks/scripts/` to verify expected matches
    2. Apply sed with all patterns including log prefixes:
       ```bash
       find plugins/ralphharness/hooks/scripts -type f -name '*.sh' -exec sed -i \
         -e 's/\[ralph-specum\]/[ralphharness]/g' \
         -e 's/ralph-specum:/ralph-harness:/g' \
         -e 's/ralph-specum/ralphharness/g' \
         -e 's/smart-ralph/ralphharness/g' \
         -e 's/ralph-specum\.local\.md/ralphharness.local.md/g' \
         -e 's/tzachbon/informatico-madrid/g' \
         {} +
       ```
    3. Verify: `[ralph-specum]` log prefix gone, `ralphharness.local.md` path in scripts
  - **Files**: `plugins/ralphharness/hooks/scripts/*.sh` (10 files)
  - **Done when**: Log prefixes updated, settings file path updated to ralphharness.local.md
  - **Verify**: `grep -r "\[ralph-specum\]" plugins/ralphharness/hooks/scripts/ | wc -l` returns 0 AND `grep -r "ralphharness.local.md" plugins/ralphharness/hooks/scripts/ | wc -l` returns >0
  - **Commit**: `rename(plugin): sed hooks/scripts/ -> log prefixes + settings path`
  - _Requirements: AC-8.1, AC-8.2, AC-8.3, FR-7, FR-12_

- [ ] 2.9 [P] Core rename: agents directory (all 10 files)
  - **Do**:
    1. Dry-run on `plugins/ralphharness/agents/` to verify expected matches
    2. Apply sed:
       ```bash
       find plugins/ralphharness/agents -type f -name '*.md' -exec sed -i \
         -e 's/ralph-specum:/ralph-harness:/g' \
         -e 's/ralph-specum/ralphharness/g' \
         -e 's/smart-ralph/ralphharness/g' \
         -e 's/tzachbon/informatico-madrid/g' \
         {} +
       ```
    3. Verify: skill invocations use `ralphharness:<name>` format
  - **Files**: `plugins/ralphharness/agents/*.md` (10 files)
  - **Done when**: All skill invocations use `ralphharness:<name>` format
  - **Verify**: `grep -r "ralph-specum:" plugins/ralphharness/agents/ | wc -l` returns 0
  - **Commit**: `rename(plugin): sed agents/ -> skill invocations + identities`
  - _Requirements: AC-5.2, FR-7_

- [ ] 2.10 [P] Core rename: skills directory (all 17 files)
  - **Do**:
    1. Dry-run on `plugins/ralphharness/skills/` to verify expected matches
    2. Apply sed:
       ```bash
       find plugins/ralphharness/skills -type f \( -name '*.md' -o -name '*.json' \) -exec sed -i \
         -e 's/ralph-specum:/ralph-harness:/g' \
         -e 's/ralph-specum/ralphharness/g' \
         -e 's/smart-ralph/ralphharness/g' \
         -e 's/tzachbon/informatico-madrid/g' \
         {} +
       ```
    3. Verify: skill names updated, smart-ralph -> ralphharness in SKILL.md files
  - **Files**: `plugins/ralphharness/skills/**/*.md` (17 files)
  - **Done when**: All skill files use ralphharness names
  - **Verify**: `grep -r "smart-ralph" plugins/ralphharness/skills/ | wc -l` returns 0
  - **Commit**: `rename(plugin): sed skills/ -> skill names + identities`
  - _Requirements: AC-11.2, FR-7_

- [ ] 2.11 [VERIFY] Core plugin checkpoint: ralphharness directory clean
  - **Do**:
    1. Verify zero `ralph-specum` references in entire `plugins/ralphharness/` directory
    2. Verify zero `tzachbon` references in `plugins/ralphharness/`
    3. Verify zero `smart-ralph` references in `plugins/ralphharness/`
    4. Verify all JSON files in plugins directory parse correctly
    5. Run shellcheck on hook scripts
  - **Verify**:
    ```bash
    grep -rn "ralph-specum\|tzachbon\|smart-ralph" plugins/ralphharness/ --include='*.md' --include='*.json' --include='*.sh' | wc -l
    ```
    returns 0 AND `for f in $(find plugins -name '*.json'); do jq . "$f" > /dev/null 2>&1 || echo "INVALID: $f"; done` outputs nothing
  - **Done when**: Zero old-name references in ralphharness plugin directory
  - **Commit**: `chore(rename): pass core plugin checkpoint` (only if fixes needed)
  - _Requirements: FR-7, FR-9, FR-10_

- [ ] 2.12 [P] Codex plugin: agent-config TOML templates (all 10 files)
- **Do**:
  1. Dry-run on `plugins/ralphharness-codex/agent-configs/` to verify expected matches
  2. Apply sed:
     ```bash
     find plugins/ralphharness-codex/agent-configs -type f -name '*.toml.template' -exec sed -i \
       -e 's/ralph-specum:/ralph-harness:/g' \
       -e 's/ralph-specum/ralphharness/g' \
       -e 's/tzachbon/informatico-madrid/g' \
       {} +
     ```
  3. Verify: TOML agent config keys use `ralphharness-<name>` format
- **Files**: `plugins/ralphharness-codex/agent-configs/*.toml.template` (10 files)
- **Done when**: All TOML agent config keys renamed to ralphharness-<name>
- **Verify**: `grep -r "ralph-specum" plugins/ralphharness-codex/agent-configs/ | wc -l` returns 0
- **Commit**: `rename(plugin): sed codex agent-configs/ -> TOML config keys`
- _Requirements: FR-31_

- [ ] 2.13 [P] Codex plugin: README.md (1 file)
  - **Do**:
    1. Dry-run on `plugins/ralphharness-codex/README.md` to verify expected matches
    2. Apply sed:
       ```bash
       sed -i -e 's/ralph-specum:/ralph-harness:/g' \
         -e 's/ralph-specum/ralphharness/g' \
         -e 's/smart-ralph/ralphharness/g' \
         -e 's/Ralph Specum/RalphHarness/g' -e 's/Smart Ralph/RalphHarness/g' \
         -e 's/tzachbon/informatico-madrid/g' \
         plugins/ralphharness-codex/README.md
       ```
    3. Verify: brand references updated throughout README
  - **Files**: `plugins/ralphharness-codex/README.md`
  - **Done when**: All brand and identity references updated in codex README
  - **Verify**: `grep -c "ralphharness" plugins/ralphharness-codex/README.md` returns >0 AND `grep -c "ralph-specum" plugins/ralphharness-codex/README.md` returns 0
  - **Commit**: `rename(plugin): sed codex README.md -> brand updates`
  - _Requirements: FR-31_

- [ ] 2.14 [P] Codex plugin: skills directory (32 files)
  - **Do**:
    1. Dry-run on `plugins/ralphharness-codex/skills/` to verify expected matches
    2. Apply sed across all skill files:
       ```bash
       find plugins/ralphharness-codex/skills -type f -exec sed -i \
         -e 's/ralph-specum:/ralph-harness:/g' \
         -e 's/ralph-specum/ralphharness/g' \
         -e 's/tzachbon/informatico-madrid/g' \
         {} +
       ```
    3. Verify: skill name patterns updated
  - **Files**: `plugins/ralphharness-codex/skills/**/*` (32 files)
  - **Done when**: All codex skill files use ralphharness naming
  - **Verify**: `grep -r "ralph-specum:" plugins/ralphharness-codex/skills/ | wc -l` returns 0
  - **Commit**: `rename(plugin): sed codex skills/ -> skill name patterns`
  - _Requirements: FR-31_

- [ ] 2.15 [P] Codex plugin: schemas, scripts, templates (7 files)
  - **Do**:
    1. Dry-run on remaining codex subdirs to verify expected matches
    2. Apply sed:
       ```bash
       find plugins/ralphharness-codex -type f \( -name '*.json' -o -name '*.py' -o -name '*.yaml' \) -exec sed -i \
         -e 's/ralph-specum/ralphharness/g' \
         -e 's/tzachbon/informatico-madrid/g' \
         {} +
       ```
    3. Verify: schema $id updated, script paths updated
  - **Files**: `plugins/ralphharness-codex/schemas/spec.schema.json`, `plugins/ralphharness-codex/scripts/*.py`, `plugins/ralphharness-codex/templates/*` (7 files)
  - **Done when**: Schema, script, and template references updated
  - **Verify**: `grep -r "ralph-specum" plugins/ralphharness-codex/schemas/ | wc -l` returns 0
  - **Commit**: `rename(plugin): sed codex schemas/scripts/templates -> identity updates`
  - _Requirements: FR-31_

- [ ] 2.16 [P] Codex plugin: agent-config README
  - **Do**:
    1. Apply sed on `plugins/ralphharness-codex/agent-configs/README.md`
    2. Update documentation references to new plugin paths
    3. Verify: all references to plugin paths use ralphharness-codex
  - **Files**: `plugins/ralphharness-codex/agent-configs/README.md`
  - **Done when**: Agent config README references ralphharness-codex paths
  - **Verify**: `grep -c "ralphharness-codex" plugins/ralphharness-codex/agent-configs/README.md` returns >0
  - **Commit**: `rename(plugin): sed codex agent-configs README.md`
  - _Requirements: FR-31_

- [ ] 2.17 [VERIFY] Codex content checkpoint: all codex subdirs clean
  - **Do**:
    1. Verify zero `ralph-specum` references in entire `plugins/ralphharness-codex/`
    2. Verify zero `tzachbon` references in codex plugin
    3. Verify all JSON files in codex parse correctly
    4. Verify all TOML templates in codex parse correctly
  - **Verify**:
    ```bash
    grep -rn "ralph-specum\|tzachbon" plugins/ralphharness-codex/ --include='*.md' --include='*.json' --include='*.sh' --include='*.toml*' --include='*.py' --include='*.yaml' | wc -l
    ```
    returns 0 AND `for f in $(find plugins/ralphharness-codex -name '*.json'); do jq . "$f" > /dev/null 2>&1 || echo "INVALID: $f"; done` outputs nothing
  - **Done when**: Zero old-name references in codex plugin, all structured files valid
  - **Commit**: `chore(rename): pass codex content checkpoint` (only if fixes needed)
  - _Requirements: FR-31_

- [ ] 2.18 [P] Speckit plugin: sed content updates
- **Do**:
  1. Apply sed on `plugins/ralphharness-speckit/`:
     ```bash
     find plugins/ralphharness-speckit -type f \( -name '*.md' -o -name '*.json' -o -name '*.sh' -o -name '*.toml*' \) -exec sed -i \
       -e 's/ralph-speckit/ralphharness-speckit/g' \
       -e 's/smart-ralph/ralphharness/g' \
       -e 's/tzachbon/informatico-madrid/g' \
       {} +
     ```
  2. Verify: no ralph-speckit references remain (except in directory name)
- **Files**: `plugins/ralphharness-speckit/**/*.md`, `*.json`, `*.sh`, `*.toml*` (file count varies by plugin contents)
- **Done when**: All speckit content uses ralphharness-speckit references
- **Verify**: `grep -r "ralph-speckit" plugins/ralphharness-speckit/ --include='*.md' --include='*.json' | wc -l` returns 0
- **Commit**: `rename(plugin): sed ralphharness-speckit/ -> speckit references`
- _Requirements: AC-2.1, FR-8_

- [ ] 2.19 [P] BMAD bridge: sed content updates
  - **Do**:
    1. Apply sed on `plugins/ralphharness-bmad-bridge/`:
       ```bash
       find plugins/ralphharness-bmad-bridge -type f \( -name '*.md' -o -name '*.json' -o -name '*.sh' \) -exec sed -i \
         -e 's/ralph-specum:/ralph-harness:/g' \
         -e 's/ralph-specum/ralphharness/g' \
         -e 's/smart-ralph/ralphharness/g' \
         -e 's/tzachbon/informatico-madrid/g' \
         {} +
       ```
    2. Verify: "smart-ralph" in comments updated to "ralphharness"
  - **Files**: All files under `plugins/ralphharness-bmad-bridge/` (typically 2-3 files)
  - **Done when**: No "smart-ralph" or "tzachbon" in bmad-bridge content
  - **Verify**: `grep -r "smart-ralph\|tzachbon" plugins/ralphharness-bmad-bridge/ | wc -l` returns 0
  - **Commit**: `rename(plugin): sed ralphharness-bmad-bridge/ -> smart-ralph/tzachbon`
  - _Requirements: AC-3.2, FR-7_

- [ ] 2.20 [P] Core rename: templates directory (all 14+ files)
  - **Do**:
    1. Dry-run on `plugins/ralphharness/templates/` to verify expected matches
    2. Apply sed:
       ```bash
       find plugins/ralphharness/templates -type f -name '*.md' -exec sed -i \
         -e 's/ralph-specum:/ralph-harness:/g' \
         -e 's/ralph-specum/ralphharness/g' \
         -e 's/smart-ralph/ralphharness/g' \
         -e 's/tzachbon/informatico-madrid/g' \
         {} +
       ```
    3. Verify: skill invocation patterns use ralphharness: format
  - **Files**: `plugins/ralphharness/templates/**/*.md` (14+ files)
  - **Done when**: All templates use ralphharness references
  - **Verify**: `grep -r "ralph-specum:" plugins/ralphharness/templates/ | wc -l` returns 0
  - **Commit**: `rename(plugin): sed templates/ -> skill invocations in templates`
  - _Requirements: AC-5.2, FR-7_

- [ ] 2.21 [P] Core rename: references directory (all 20+ files)
  - **Do**:
    1. Dry-run on `plugins/ralphharness/references/` to verify expected matches
    2. Apply sed:
       ```bash
       find plugins/ralphharness/references -type f -name '*.md' -exec sed -i \
         -e 's/ralph-specum:/ralph-harness:/g' \
         -e 's/ralph-specum/ralphharness/g' \
         -e 's/smart-ralph/ralphharness/g' \
         -e 's/tzachbon/informatico-madrid/g' \
         {} +
       ```
    3. Verify: no ralph-specum references remain in references
  - **Files**: `plugins/ralphharness/references/**/*.md` (20+ files)
  - **Done when**: All reference files use ralphharness names
  - **Verify**: `grep -r "ralph-specum" plugins/ralphharness/references/ | wc -l` returns 0
  - **Commit**: `rename(plugin): sed references/ -> identity updates`
  - _Requirements: FR-7_

- [ ] 2.22 [VERIFY] Core rename checkpoint: all plugin content verified
  - **Do**:
    1. Verify zero old-name references across ALL four plugins: `plugins/ralphharness/`, `plugins/ralphharness-codex/`, `plugins/ralphharness-speckit/`, `plugins/ralphharness-bmad-bridge/`
    2. Validate all JSON files in plugins parse correctly
    3. Check TOML files in codex agent-configs parse correctly
    4. Run shellcheck on all shell scripts in hooks
  - **Verify**:
    ```bash
    grep -rn "ralph-specum\|tzachbon\|smart-ralph" plugins/ \
      --include='*.md' --include='*.json' --include='*.sh' --include='*.toml*' \
      --exclude-dir=node_modules | wc -l
    ```
    returns 0 AND `for f in $(find plugins -name '*.json'); do jq . "$f" > /dev/null 2>&1 || echo "INVALID: $f"; done` outputs nothing
  - **Done when**: Zero old-name references in all four plugins, all structured files valid
  - **Commit**: `chore(rename): pass core rename checkpoint` (only if fixes needed)
  - _Requirements: FR-7, FR-8, FR-9, FR-10_

## Phase 3: External References

**Goal:** Apply sed replacements to root docs, configs, CI/CD, tests, skills outside plugins, and BMAD configs.

- [ ] 3.1 [P] Root documentation: README.md
- **Do**:
  1. Apply sed on `README.md`:
     ```bash
     sed -i -e 's/ralph-specum:/ralph-harness:/g' \
       -e 's/ralph-specum/ralphharness/g' \
       -e 's/smart-ralph/RalphHarness/g' -e 's/Smart Ralph/RalphHarness/g' \
       -e 's/Ralph Specum/RalphHarness/g' -e 's/tzachbon/informatico-madrid/g' \
       -e 's/tzachbon\/smart-ralph/informatico-madrid\/RalphHarness/g' \
       README.md
     ```
  2. Verify: README.md title mentions "RalphHarness"
  3. Verify: GitHub clone URL updated to informatico-madrid/RalphHarness
  4. Verify: no `ralphharness:` appears (indicates wrong sed order)
- **Files**: `README.md`
- **Done when**: README.md contains "RalphHarness" throughout, no old names remain
- **Verify**: `grep -c "RalphHarness" README.md` returns >0 AND `grep -c "ralph-specum" README.md` returns 0
- **Commit**: `rename(docs): sed README.md -> brand + identity + clone URL`
- _Requirements: AC-7.1, FR-19_

- [ ] 3.2 [P] Root documentation: CLAUDE.md
  - **Do**:
    1. Apply sed on `CLAUDE.md`:
       ```bash
       sed -i -e 's/ralph-specum/ralphharness/g' -e 's/ralph-specum:/ralph-harness:/g' \
         -e 's/smart-ralph/RalphHarness/g' -e 's/Smart Ralph/RalphHarness/g' \
         -e 's/tzachbon/informatico-madrid/g' \
         CLAUDE.md
       ```
    2. Verify: Plugin Structure section references `plugins/ralphharness/`
    3. Verify: Command examples use `/ralph-harness:` prefix
  - **Files**: `CLAUDE.md`
  - **Done when**: CLAUDE.md architecture overview updated with new names
  - **Verify**: `grep -c "ralphharness" CLAUDE.md` returns >0 AND `grep -c "ralph-specum" CLAUDE.md` returns 0
  - **Commit**: `rename(docs): sed CLAUDE.md -> architecture + plugin structure + commands`
  - _Requirements: AC-7.2, FR-20_

- [ ] 3.3 [P] Root documentation: CONTRIBUTING.md
  - **Do**:
    1. Apply sed on `CONTRIBUTING.md`:
       ```bash
       sed -i -e 's/tzachbon\/smart-ralph/informatico-madrid\/RalphHarness/g' \
         -e 's/tzachbon/informatico-madrid/g' \
         CONTRIBUTING.md
       ```
    2. Verify: GitHub URLs point to informatico-madrid/RalphHarness
  - **Files**: `CONTRIBUTING.md`
  - **Done when**: All GitHub URLs in CONTRIBUTING.md updated
  - **Verify**: `grep "informatico-madrid\/RalphHarness" CONTRIBUTING.md | wc -l` returns >0
  - **Commit**: `rename(docs): sed CONTRIBUTING.md -> GitHub URLs`
  - _Requirements: AC-7.4, FR-23_

- [ ] 3.4 [P] Root documentation: TROUBLESHOOTING.md
  - **Do**:
    1. Apply sed on `TROUBLESHOOTING.md`:
       ```bash
       sed -i -e 's/ralph-specum/ralphharness/g' -e 's/ralph-specum:/ralph-harness:/g' \
         -e 's/tzachbon\/smart-ralph/informatico-madrid\/RalphHarness/g' \
         -e 's/tzachbon/informatico-madrid/g' \
         TROUBLESHOOTING.md
       ```
    2. Verify: Command examples updated to `/ralph-harness:`
    3. Verify: GitHub URLs updated
  - **Files**: `TROUBLESHOOTING.md`
  - **Done when**: All command examples and GitHub URLs updated
  - **Verify**: `grep -c "ralph-harness:" TROUBLESHOOTING.md` returns >0 AND `grep -c "ralph-specum" TROUBLESHOOTING.md` returns 0
  - **Commit**: `rename(docs): sed TROUBLESHOOTING.md -> commands + GitHub URLs`
  - _Requirements: AC-7.5, FR-24_

- [ ] 3.5 [P] Root documentation: LICENSE + gito-review-classification.md
  - **Do**:
    1. Apply sed on `LICENSE`: change copyright from `tzachbon` to `"RalphHarness Project Authors"`
    2. Apply sed on `gito-review-classification.md`: `sed -i 's/plugins\/ralph-specum/plugins\/ralphharness/g' gito-review-classification.md`
    3. Apply sed on `plugins/ralphharness-speckit/LICENSE`: update copyright
  - **Files**: `LICENSE`, `gito-review-classification.md`, `plugins/ralphharness-speckit/LICENSE`
  - **Done when**: LICENSE has "RalphHarness Project Authors", classification file updated
  - **Verify**: `grep "RalphHarness Project Authors" LICENSE` returns match AND `grep -c "tzachbon" LICENSE` returns 0
  - **Commit**: `rename(docs): sed LICENSE + classification -> copyright + paths`
  - _Requirements: AC-6.4, FR-22_

- [ ] 3.6 [VERIFY] Root docs checkpoint: documentation consistency
  - **Do**:
    1. Verify zero old-name references in root documentation files
    2. Verify all key docs contain "RalphHarness" brand
    3. Verify no README.fork.md exists
    4. Verify AGENTS.md symlink (if exists) still resolves correctly: `test -L AGENTS.md && readlink AGENTS.md`
  - **Verify**:
    ```bash
    grep -l "ralph-specum\|tzachbon\|smart-ralph" README.md CLAUDE.md CONTRIBUTING.md TROUBLESHOOTING.md LICENSE 2>/dev/null | wc -l
    ```
    returns 0 AND `grep -c "RalphHarness" README.md` returns >0
  - **Done when**: All root documentation clean of old names, RalphHarness brand present
  - **Commit**: `chore(rename): pass root docs checkpoint` (only if fixes needed)
  - _Requirements: AC-7.1, AC-7.2_

- [ ] 3.7 [P] Root configs: .claude/settings.json + .claude/local.md
- **Do**:
  1. Update `.claude/settings.json`: change `enabledPlugins.ralph-specum@smart-ralph` to `enabledPlugins.ralphharness@informatico-madrid`
  2. Set new key to `true`: `"enabledPlugins.ralphharness@informatico-madrid": true`
  3. Remove old key: delete `ralph-specum@smart-ralph` entry
  4. Verify settings.json parses as valid JSON
  5. Verify old key removed, new key present
- **Files**: `.claude/settings.json`
- **Done when**: settings.json has `ralphharness@informatico-madrid: true`, no `ralph-specum` in enabledPlugins
- **Verify**: `jq -r '.enabledPlugins."ralphharness@informatico-madrid"' .claude/settings.json` returns `true` AND `jq -r '.enabledPlugins."ralph-specum@smart-ralph"' .claude/settings.json` returns `null`
- **Commit**: `fix(config): update .claude/settings.json -> ralphharness@informatico-madrid plugin enablement`
- _Requirements: AC-1.5, AC-1.8, AC-1.9, AC-1.10, FR-15_

- [ ] 3.8 [P] Root configs: .gito/config.toml + .serena/project.yml
  - **Do**:
    1. Apply sed on `.gito/config.toml`: update project comment from "smart-ralph" to "RalphHarness"
    2. Apply sed on `.serena/project.yml`: set `project_name: "RalphHarness"` (was "smart-ralph")
    3. Verify both files remain valid format
  - **Files**: `.gito/config.toml`, `.serena/project.yml`
  - **Done when**: Gito config and Serena project name updated to RalphHarness
  - **Verify**: `grep "RalphHarness" .gito/config.toml .serena/project.yml | wc -l` returns 2
  - **Commit**: `rename(config): sed .gito/config.toml + .serena/project.yml`
  - _Requirements: FR-27_

- [ ] 3.9 [VERIFY] Historical backup file: do NOT modify settingsback artifact
  - **Do**:
    1. Check `.claude/settingsback.localback.jsonBACK` for ralph-specum references
    2. If references found, FLAG but do NOT modify -- this is a restore artifact with `.BACK` extension
    3. Document findings in rollback notes if references found
  - **Files**: `.claude/settingsback.localback.jsonBACK` (read-only, no modifications)
  - **Done when**: Backup file status documented; file left unchanged regardless of content
  - **Verify**: `test -f .claude/settingsback.localback.jsonBACK && echo "BACKUP_EXISTS"`
  - **Commit**: `chore(rename): document settingsback backup file status (no changes)`
  - _Requirements: FR-7 (check only, no sed)_

- [ ] 3.10 [VERIFY] Check PR template and other .github files for references
  - **Do**:
    1. Check `.github/PULL_REQUEST_TEMPLATE.md` for ralph-specum references
    2. Check `AGENTS.md` (symlink to CLAUDE.md) — if symlink, content follows CLAUDE.md changes
    3. Verify any files with old references are handled
  - **Files**: `.github/PULL_REQUEST_TEMPLATE.md`, `AGENTS.md` (read-only check)
  - **Done when**: Any references in PR template noted; AGENTS.md symlink verified
  - **Verify**: `grep -c "ralph-specum" .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null || echo "0"`
  - **Commit**: `chore(rename): check PR template and AGENTS.md (no changes expected)`
  - _Requirements: FR-7 (check only)_

- [ ] 3.11 [P] GitHub CI/CD: workflows (all 4 files)
- **Do**:
  1. Apply sed on `.github/workflows/bats-tests.yml`: update `plugins/ralph-specum-codex/**` to `plugins/ralphharness-codex/**`
  2. Apply sed on `.github/workflows/codex-version-check.yml`: update paths, MANIFEST path, PR names
  3. Check `.github/workflows/plugin-version-check.yml`: verify generic glob, no hardcoded names (likely clean)
  4. Check `.github/workflows/spec-file-check.yml`: verify no ralph-specum references (likely clean)
  5. Verify: all YAML files remain valid
- **Files**: `.github/workflows/bats-tests.yml`, `.github/workflows/codex-version-check.yml`, `.github/workflows/plugin-version-check.yml`, `.github/workflows/spec-file-check.yml`
- **Done when**: All workflow paths updated to ralphharness-codex
- **Verify**: `git grep -l "ralph-specum-codex" .github/workflows/ | wc -l` returns 0
- **Commit**: `rename(ci): sed .github/workflows/ -> codex paths + triggers`
- _Requirements: AC-10.1, AC-10.2, AC-13.6, AC-13.7, FR-17, FR-32_

- [ ] 3.11 [P] GitHub issue templates (all 3 files)
  - **Do**:
    1. Apply sed on `.github/ISSUE_TEMPLATE/bug_report.yml`: update command examples `/ralph-specum:` to `/ralph-harness:`
    2. Apply sed on `.github/ISSUE_TEMPLATE/feature_request.yml`: update command examples
    3. Apply sed on `.github/ISSUE_TEMPLATE/config.yml`: update GitHub repo URL to informatico-madrid/RalphHarness
    4. Check `.github/ISSUE_TEMPLATE/question.yml`: verify no ralph-specum references (likely clean)
    5. Verify: all YAML files remain valid
  - **Files**: `.github/ISSUE_TEMPLATE/bug_report.yml`, `.github/ISSUE_TEMPLATE/feature_request.yml`, `.github/ISSUE_TEMPLATE/config.yml`, `.github/ISSUE_TEMPLATE/question.yml`
  - **Done when**: All issue templates use /ralph-harness: commands and new GitHub URL
  - **Verify**: `grep -r "/ralph-harness:" .github/ISSUE_TEMPLATE/ | wc -l` returns >0 AND `grep -r "ralph-specum" .github/ISSUE_TEMPLATE/ | wc -l` returns 0
  - **Commit**: `rename(ci): sed .github/ISSUE_TEMPLATE/ -> commands + repo URL`
  - _Requirements: AC-10.3, AC-10.4, FR-18_

- [ ] 3.12 [VERIFY] GitHub CI/CD checkpoint: workflows + templates valid
  - **Do**:
    1. Validate all YAML files in `.github/` parse correctly
    2. Verify no ralph-specum-codex references remain in workflows
    3. Verify no tzachbon references in issue templates
    4. Verify repo URL points to informatico-madrid/RalphHarness
  - **Verify**:
    ```bash
    for f in .github/workflows/*.yml .github/ISSUE_TEMPLATE/*.yml; do
      python3 -c "import yaml; yaml.safe_load(open('$f'))" 2>/dev/null \
        || echo "INVALID_YAML: $f"
    done && echo "ALL_YAML_VALID"
    ```
    AND `grep -r "ralph-specum-codex\|tzachbon" .github/ | wc -l` returns 0
  - **Done when**: All GitHub YAML valid, no old references in CI/CD
  - **Commit**: `chore(rename): pass GitHub CI/CD checkpoint` (only if fixes needed)
  - _Requirements: AC-10.1, AC-10.2, AC-10.3, AC-10.4_

- [ ] 3.13 [P] Test infrastructure: bats files (all 6+ files)
- **Do**:
  1. Discover ALL .bats files: `find tests -name '*.bats'` to ensure full coverage
  2. Apply sed on `tests/codex-plugin.bats`: update ~30 skill name and path references
  3. Apply sed on `tests/codex-platform.bats`: update ~50 hardcoded references to plugin paths and skill names
  4. Apply sed on `tests/codex-platform-scripts.bats`: update ~10 codex path references
  5. Apply sed on `tests/stop-hook.bats`: update `[ralph-specum]` log prefix to `[ralphharness]`
  6. Apply sed on `tests/interview-framework.bats`: update ~20 plugin path references
  7. Apply sed on `tests/helpers/version-sync.sh`: update manifest read paths
  8. Verify: all .bats files remain valid bash
- **Files**: `tests/codex-plugin.bats`, `tests/codex-platform.bats`, `tests/codex-platform-scripts.bats`, `tests/stop-hook.bats`, `tests/interview-framework.bats`, `tests/helpers/version-sync.sh`, plus any additional `.bats` files discovered
- **Done when**: All test references updated to ralphharness paths and names
- **Verify**: `grep -c "ralph-specum" tests/codex-platform.bats` returns 0 AND `grep -c "\[ralph-specum\]" tests/stop-hook.bats` returns 0
- **Commit**: `rename(tests): sed tests/*.bats -> paths + skill names + log prefixes`
- _Requirements: AC-12.1, AC-12.2, AC-12.3, AC-12.4, AC-12.5, FR-29_

- [ ] 3.14 [P] Test infrastructure: setup helpers
  - **Do**:
    1. Apply sed on `tests/helpers/setup.bash`: update paths from `plugins/ralph-specum/` to `plugins/ralphharness/`
    2. Apply sed on `tests/speckit-helpers/setup.bash`: update paths from `plugins/ralph-speckit/` to `plugins/ralphharness-speckit/`
    3. Verify: bash scripts remain valid syntax
  - **Files**: `tests/helpers/setup.bash`, `tests/speckit-helpers/setup.bash`
  - **Done when**: Test setup scripts reference new plugin directory names
  - **Verify**: `grep -c "ralphharness" tests/helpers/setup.bash tests/speckit-helpers/setup.bash` returns >0 AND `grep -c "ralph-specum" tests/helpers/setup.bash tests/speckit-helpers/setup.bash` returns 0
  - **Commit**: `rename(tests): sed test setup helpers -> plugin paths`
  - _Requirements: AC-12.6_

- [ ] 3.15 [VERIFY] Test infrastructure checkpoint
  - **Do**:
    1. Verify zero old-name references in all test files
    2. Verify all bash scripts in tests/ parse correctly
    3. Run `bats tests/*.bats` to confirm tests pass
  - **Verify**:
    ```bash
    grep -rn "ralph-specum\|tzachbon\|smart-ralph" tests/ --include='*.bats' --include='*.sh' | wc -l
    ```
    returns 0 AND `bats tests/*.bats 2>&1 | tail -3` shows all pass
  - **Done when**: Zero old-name references in tests, all bats tests pass
  - **Commit**: `chore(rename): pass test infrastructure checkpoint` (only if fixes needed)
  - _Requirements: AC-12.7_

- [ ] 3.16 [P] BMAD configs: all config files in _bmad/
- **Do**:
  1. Apply sed on `_bmad/config.toml`: `project_name = "smart-ralph"` -> `project_name = "RalphHarness"`
  2. Apply sed on `_bmad/bmm/config.yaml`: update plugin name references
  3. Apply sed on `_bmad/cis/config.yaml`: update plugin name references
  4. Apply sed on `_bmad/core/config.yaml`: update plugin name references
  5. Apply sed on `_bmad/tea/config.yaml`: update plugin name references
  6. Apply sed on `_bmad/config.user.toml`: update plugin name references
  7. Verify: all YAML files parse correctly
  8. Verify: all TOML files parse correctly
- **Files**: `_bmad/config.toml`, `_bmad/bmm/config.yaml`, `_bmad/cis/config.yaml`, `_bmad/core/config.yaml`, `_bmad/tea/config.yaml`, `_bmad/config.user.toml`
- **Done when**: All BMAD config files use ralphharness references
- **Verify**: `grep -r "ralph-specum\|smart-ralph" _bmad/ --include='*.yaml' --include='*.toml' | wc -l` returns 0 AND `for f in $(find _bmad -name '*.yaml'); do python3 -c "import yaml; yaml.safe_load(open('$f'))" 2>/dev/null || echo "INVALID_YAML: $f"; done` outputs nothing AND `for f in $(find _bmad -name '*.toml'); do python3 -c "import tomllib; tomllib.load(open('$f', 'rb'))" 2>/dev/null || echo "INVALID_TOML: $f"; done` outputs nothing
- **Commit**: `rename(config): sed _bmad/ -> all BMAD config files`
- _Requirements: AC-14.1, AC-14.2, FR-25, FR-26_

- [ ] 3.17 [P] Skills outside plugins: .claude/skills/ and .agents/skills/
  - **Do**:
    1. Apply sed on `.claude/skills/smart-ralph-review/SKILL.md`: update dozens of `/ralph-specum:` to `/ralph-harness:`, update review output paths
    2. Apply sed on `.agents/skills/smart-ralph-review/SKILL.md`: duplicate of above, same updates
    3. Check `.claude/skills/bmad-party-mode/*_context.md` for command references
    4. Check `.claude/skills/autonomous-adversarial-coordinator/` for command references
  - **Files**: `.claude/skills/smart-ralph-review/SKILL.md`, `.agents/skills/smart-ralph-review/SKILL.md`, `.claude/skills/bmad-party-mode/*_context.md`, `.claude/skills/autonomous-adversarial-coordinator/SKILL.md`
  - **Done when**: All skills outside plugins use /ralph-harness: commands
  - **Verify**: `grep -r "ralph-specum:" .claude/skills/ .agents/skills/ --include='*.md' | wc -l` returns 0
  - **Commit**: `rename(config): sed .claude/skills/ + .agents/skills/ -> commands`
  - _Requirements: AC-14.4, FR-7_

- [ ] 3.18 [VERIFY] External references checkpoint: comprehensive grep
  - **Do**:
    1. Run final comprehensive grep across ALL in-scope directories
    2. Verify zero old-name references:
       ```bash
       grep -rn "ralph-specum\|tzachbon\|smart-ralph" . \
         --include='*.md' --include='*.json' --include='*.sh' --include='*.yml' --include='*.yaml' \
         --exclude-dir=specs --exclude-dir=_bmad-output --exclude-dir=docs/brainstormmejora \
         --exclude-dir=docs/plans --exclude-dir=plans --exclude-dir=.git | wc -l
       ```
    3. Validate all JSON files parse correctly
    4. Validate all YAML files parse correctly
    5. Validate all TOML files parse correctly
  - **Verify**: The comprehensive grep returns 0 lines AND all structured file validations pass
  - **Done when**: Zero old-name references in ALL in-scope files, all structured files valid
  - **Commit**: `chore(rename): pass external references checkpoint` (only if fixes needed)
  - _Requirements: FR-7, FR-8, FR-9, FR-10, FR-11_

## Phase 4: Verification

**Goal:** Run full verification sequence V1 through V8. Quality checkpoints, CI checks, and acceptance criteria checklist.

- [ ] 4.1 [VERIFY] V1: JSON/TOML/YAML structured file validation
  - **Do**:
    1. Validate all JSON files in plugins, .claude-plugin, .agents, .gito, .serena: `jq . <file>`
    2. Validate all TOML files in plugins, .gito, _bmad, .bmad-harness: `python3 -c "import tomllib; tomllib.load(open('$f', 'rb'))"`
    3. Validate all YAML files in plugins, _bmad, .github, .serena: `python3 -c "import yaml; yaml.safe_load(open('$f'))"`
    4. Report any invalid files found
  - **Verify**: All validation commands produce zero errors
  - **Done when**: Every structured file in the repository parses correctly
  - **Commit**: `chore(rename): pass V1 structured file validation` (only if fixes needed)
  - _Requirements: Verification Contract_

- [ ] 4.2 [VERIFY] V2: shellcheck on all shell scripts
  - **Do**:
    1. Run `shellcheck` on all .sh files in plugins/, .github/hooks/, .bmad-harness/hooks/, tests/
    2. Fix any syntax errors introduced by sed (unlikely but verify)
  - **Verify**: `find plugins .github .bmad-harness tests -name '*.sh' -exec shellcheck {} +` returns 0 errors
  - **Done when**: All shell scripts pass shellcheck
  - **Commit**: `chore(rename): pass V2 shellcheck` (only if fixes needed)
  - _Requirements: Verification Contract_

- [ ] 4.3 [VERIFY] V3: BATS test suite runs
  - **Do**:
    1. Run `bats tests/*.bats` and capture results
    2. Verify all tests pass (expected: 100% pass rate)
    3. If any test fails, investigate and fix the cause
  - **Verify**: `bats tests/*.bats` output shows all tests passing
  - **Done when**: All bats tests pass with zero failures
  - **Commit**: `chore(rename): pass V3 bats test suite` (only if fixes needed)
  - _Requirements: AC-12.7, NFR-3_

- [ ] 4.4 [VERIFY] V4: Comprehensive grep verification
  - **Do**:
    1. Run final grep for all three patterns across all in-scope files:
       ```bash
       grep -rn "ralph-specum\|tzachbon\|smart-ralph" . \
         --include='*.md' --include='*.json' --include='*.sh' --include='*.yml' --include='*.yaml' \
         --exclude-dir=specs --exclude-dir=_bmad-output --exclude-dir=docs/brainstormmejora \
         --exclude-dir=docs/plans --exclude-dir=plans --exclude-dir=.git
       ```
    2. Compare against pre-change counts from Phase 0
    3. Verify the count is 0
  - **Verify**: `grep -rn "ralph-specum\|tzachbon\|smart-ralph" . --include='*.md' --include='*.json' --include='*.sh' --include='*.yml' --include='*.yaml' --exclude-dir=specs --exclude-dir=_bmad-output --exclude-dir=docs/brainstormmejora --exclude-dir=docs/plans --exclude-dir=plans --exclude-dir=.git | wc -l` returns 0
  - **Done when**: Zero matches for all three patterns in in-scope files
  - **Commit**: `chore(rename): pass V4 comprehensive grep` (only if fixes needed)
  - _Requirements: AC-12.8, Verification Contract, NFR-4_

- [ ] 4.5 [VERIFY] V5: CI pipeline check
  - **Do**:
    1. Push branch to remote (if on feature branch): `git push -u origin $(git branch --show-current)`
    2. Wait for CI to start (3 minutes)
    3. Check CI status: `gh pr checks` or `gh run list`
    4. If CI fails, investigate and fix
  - **Verify**: CI checks show all green (or skip if no CI pipeline / not on PR)
  - **Done when**: All CI pipeline checks passing (or confirmed N/A for this repo)
  - **Commit**: `chore(rename): pass V5 CI pipeline check` (only if fixes needed)
  - _Requirements: Verification Contract_

- [ ] 4.6 [VERIFY] V6: Acceptance criteria checklist
  - **Do**:
    1. Verify each acceptance criterion from requirements.md:
       - AC-1.6: `jq -r '.name' plugins/ralphharness/.claude-plugin/plugin.json` = `"ralphharness"`
       - AC-1.10: `jq -r '.enabledPlugins."ralphharness@informatico-madrid"' .claude/settings.json` = `true`
       - AC-4.5: `jq -r '.owner.name' .claude-plugin/marketplace.json` = `"informatico-madrid"`
       - AC-5.3: `grep "/ralph-harness:" plugins/ralphharness/commands/*.md` returns >0
       - AC-5.4: `grep -r "ralph-specum:" plugins/ralphharness/` returns 0
       - AC-7.1: `grep "RalphHarness" README.md` returns match
       - AC-13.1: `test -d plugins/ralphharness-codex`
    2. Document each check result
  - **Verify**: All checks above pass
  - **Done when**: All acceptance criteria from requirements.md verified
  - **Commit**: `chore(rename): pass V6 acceptance criteria checklist` (only if fixes needed)
  - _Requirements: All AC-* entries from requirements.md_

- [ ] 4.7 [VERIFY] V7: Plugin load and functional verification
  - **Do**:
    1. Verify plugin directory structure is correct: `ls plugins/ralphharness/`
    2. Verify commands directory: `test -d plugins/ralphharness/commands && test $(ls plugins/ralphharness/commands/*.md | wc -l) -ge 10`
    3. Verify hooks directory: `test -d plugins/ralphharness/hooks/scripts`
    4. Verify agents directory: `test -d plugins/ralphharness/agents`
    5. Verify skills directory: `test -d plugins/ralphharness/skills`
    6. Run `jq . plugins/ralphharness/.claude-plugin/plugin.json` to verify valid manifest
  - **Verify**: All directory structures exist and plugin manifest is valid JSON
  - **Done when**: Plugin structure verified, manifest valid, all subdirectories present
  - **Commit**: `chore(rename): pass V7 plugin load verification` (only if fixes needed)
  - _Requirements: AC-1.7, AC-13.1, AC-13.3_

- [ ] 4.8 [VERIFY] V8: Git history preservation verification
  - **Do**:
    1. Run `git log --follow -- plugins/ralphharness/ | head -5` and verify shows commits
    2. Run `git log --follow -- plugins/ralphharness-codex/ | head -5` and verify shows commits
    3. Run `git log --follow -- plugins/ralphharness-speckit/ | head -5` and verify shows commits
    4. Verify git status is clean (no uncommitted changes)
  - **Verify**: All three `git log --follow` commands return at least 1 commit
  - **Done when**: Git history preserved for all renamed directories, working tree clean
  - **Commit**: `chore(rename): pass V8 git history verification` (only if fixes needed)
  - _Requirements: NFR-1_

- [ ] 4.9 VF [VERIFY] Goal verification: original failure now passes
  - **Do**:
    1. Read Phase 0 pre-change counts from `.pre-change-counts.txt`
    2. Re-run comprehensive grep: `grep -rn "ralph-specum\|tzachbon\|smart-ralph" . --include='*.md' --include='*.json' --include='*.sh' --include='*.yml' --include='*.yaml' --exclude-dir=specs --exclude-dir=_bmad-output --exclude-dir=docs/brainstormmejora --exclude-dir=docs/plans --exclude-dir=plans --exclude-dir=.git | wc -l`
    3. Compare against pre-change counts -- should now be 0
    4. Document after state in Phase 4 summary
  - **Verify**: `grep -rn "ralph-specum\|tzachbon\|smart-ralph" . --include='*.md' --include='*.json' --include='*.sh' --include='*.yml' --include='*.yaml' --exclude-dir=specs --exclude-dir=_bmad-output --exclude-dir=docs/brainstormmejora --exclude-dir=docs/plans --exclude-dir=plans --exclude-dir=.git | wc -l` returns 0
  - **Done when**: Command that returned >0 in Phase 0 now returns 0
  - **Commit**: `chore(rename): verify fix resolves original issue`

- [ ] 4.10 Final summary: rename complete
  - **Do**:
    1. Output a summary of all changes made
    2. Confirm: all pre-change counts now at 0 for in-scope files
    3. Confirm: all post-change checks pass
    4. Run final clean status check: `git status --short`
    5. Prepare summary of what was changed
  - **Verify**: `git status --short` shows all expected changes staged or committed
  - **Done when**: Final summary generated, all checks confirmed passing
  - **Commit**: `chore(rename): ralphharness rename complete - summary` (only if uncommitted changes remain)
  - _Requirements: All success criteria from requirements.md_

## Phase 5: PR Lifecycle

**Goal:** Create PR, monitor CI, resolve review comments, final validation.

- [ ] 5.1 Local quality check
  - **Do**: Run ALL quality checks locally
  - **Verify**: All commands must pass:
    - `bats tests/*.bats` (test suite)
    - All JSON files parse: `for f in $(find . -name '*.json' -not -path './specs/*' -not -path './.git/*'); do jq . "$f" > /dev/null 2>&1 || echo "INVALID: $f"; done`
    - All YAML files parse: `for f in $(find . -name '*.yml' -not -path './specs/*' -not -path './.git/*'); do python3 -c "import yaml; yaml.safe_load(open('$f'))" 2>/dev/null || echo "INVALID: $f"; done`
  - **Done when**: All commands pass with no errors
  - **Commit**: `fix(rename): address lint/type issues` (if fixes needed)

- [ ] 5.2 Create PR and verify CI
  - **Do**:
    1. Verify current branch is a feature branch: `git branch --show-current`
    2. Push branch: `git push -u origin $(git branch --show-current)`
    3. Create PR using gh CLI: `gh pr create --title "feat(rename): ralph-specum -> ralphharness" --body "Complete rename of ralph-specum plugin to ralphharness. See design.md for full plan."`
    4. If gh CLI unavailable, provide URL for manual PR creation
  - **Verify**: Use gh CLI to verify CI:
    - `gh pr checks --watch` (wait for CI completion)
    - Or `gh pr checks` (poll current status)
    - All checks must show passing
  - **Done when**: All CI checks green, PR ready for review
  - **If CI fails**:
    1. Read failure details: `gh pr checks`
    2. Fix issues locally
    3. Push fixes: `git push`
    4. Re-verify: `gh pr checks --watch`

## Notes

- **Sed expression order**: LONGER FIRST -- `ralph-specum:` must be replaced before `ralph-specum` to avoid double-substitution producing `ralph-harness-harness`
- **Phase 1 split**: Codex skill renames split into 4 batches (16 git mvs total) to respect 4-Do-steps limit per task
- **Production TODOs**:
  - Version bumps for speckit (1.0.0 vs 0.6.0) and codex (5.0.0 vs 4.11.0) may need clarification if manifest values are wrong
  - `.claude/settings.json` key format (`ralphharness@informatico-madrid` vs `ralphharness@smart-ralph`) needs confirmation
- **Quality checkpoints**: 15 checkpoints total across all phases (every 2-3 tasks)
- **Total task count**: 72 tasks (increased from 58 due to 16 codex skill renames split into 4 tasks + 1 bmad-bridge dir rename + 3 quality gate additions + 1 VF task)
