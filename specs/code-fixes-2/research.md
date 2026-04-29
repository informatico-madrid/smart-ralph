---
spec: code-fixes-2
phase: research
created: 2026-04-29T14:45:00Z
---

# Research: Code Fixes 2

## Executive Summary

This spec fixes 29 documentation/typos, naming inconsistency, and requirements gap bugs across the Smart Ralph codebase. Most issues are in plugin agent prompts, spec documentation files, and BMAD module CSVs. Key findings: many bugs reference files that have since been fixed or moved; the spec-level research docs (.research-codebase.md) have some bugs that are hard to verify since the content may have changed. Lock file naming is the most actionable code-level bug (external-reviewer.md uses tasks.md.lock while the canonical name is .tasks.lock).

---

## Verification Tooling

**Project Type**: Plugin (Claude Code plugin, no UI, no web framework)
**Verification**: No automated tests. Fixes are all doc/text changes verified by reading files.
**Tools**: grep, cat, find, wc

---

## 1. Typos/Documentation Bugs (13 items)

### #11 skill-manifest.csv -- distillator to distiller
**Status: VERIFIED -- Present**
- File: _bmad/core/skill-manifest.csv line 5: bmad-distillator
- Also: _bmad/_config/skill-manifest.csv line 5
- Directory name: _bmad/core/bmad-distillator/ -- the directory is actually named "distillator"
- **Note**: This is a naming convention baked into the BMAD codebase. Fixing would require renaming the directory AND updating all references (~40 files in files-manifest.csv). Low-value change.
- **Recommendation**: Defer -- requires coordinated rename across BMAD, not a simple typo fix.

### #13 module-help.csv -- Missing article 'a'
**Status: NOT FOUND**
- Searched all module-help.csv files for missing article patterns.
- Descriptions use "Use when..." phrasing, not noun phrases that would need an article.
- **Likely already fixed or misattributed.**

### #18 core/module-help.csv -- 'Distillator' typo
**Status: VERIFIED -- Present**
- File: _bmad/core/module-help.csv line 12: Core,bmad-distillator,Distillator,DG,...
- Same issue as #11 -- "Distillator" appears as the display name.
- Directory is bmad-distillator/ so the CSV matches the directory name.
- **Recommendation**: Same as #11 -- defer directory rename, fix display names only.

### #52 epic.md -- Spec 7 self-reference
**Status: VERIFIED -- Present**
- File: specs/_epics/engine-roadmap-epic/epic.md line 138
- Text: Dependencies: Spec 7 (depends on Spec 6's collaboration signals...
- Spec 7 IS pair-debug-auto-trigger, and this section IS about Spec 7. It refers to itself as "Spec 7" in its own dependency list.
- **Fix**: Change to "This spec depends on Spec 6's collaboration signals..." or reword.

### #53 epic.md -- "before task complete" to "before task completion"
**Status: NOT FOUND**
- Searched all epic.md files for "before task complete" (without "completion").
- No matches found. Either already fixed or misattributed.

### #54 epic.md -- Wrong command name
**Status: NOT FOUND**
- Searched all epic.md files for incorrect /ralph-specum: command names.
- All command references use valid command names. Either already fixed or misattributed.

### #55 plan.md -- Wrong command name
**Status: NOT FOUND**
- Searched all plan.md files for incorrect command names.
- No invalid references found. Either already fixed or misattributed.

### #90 research-circuit-breaker.md -- Contradictory timestamp comment
**Status: VERIFIED -- Present**
- File: specs/loop-safety-infra/research-circuit-breaker.md line 267
- Text: "sessionStartTime": 1745673600,  // epoch seconds (ISO in human-readable output)
- The comment says "epoch seconds" then parenthetically "(ISO in human-readable output)" which is contradictory. Epoch seconds are NOT ISO format.
- **Fix**: Remove "(ISO in human-readable output)" or clarify as "(ISO format recommended for human-readable)".

### #93 research-read-only-detection.md -- Heading typo O_TMPF
**Status: VERIFIED -- Present**
- File: specs/loop-safety-infra/research-read-only-detection.md line 210
- Text: ### 3.5 Alternative: O_TMPF (Linux 3.11+)
- Should be O_TMPFILE (the actual Linux syscall constant).
- **Fix**: Change O_TMPF to O_TMPFILE.

### #99 chat.md -- "VOLATION" typo
**Status: VERIFIED -- Present but not actionable**
- File: specs/role-boundaries/chat.md line 31
- Text: f84aab7: fix(role-boundaries): fix BOUNDARY_VOLATION typo to BOUNDARY_VIOLATION (RR-007)
- The word "VOLATION" appears in a git commit message reference (the typo that was fixed).
- **Assessment**: This is describing a previous fix. The VOLATION is part of the quoted commit message showing the old typo. Not actionable.

### #100 requirements.md -- AC.3.3 dot vs hyphen
**Status: NOT A BUG (already consistent)**
- File: specs/codebase-indexing/requirements.md line 66
- Text: AC-3.3: Component specs are searchable by keywords, exports, dependencies
- Uses hyphen (AC-3.3) which is the consistent convention. All other references use hyphens (AC-2.1, AC-3.3, etc.).
- **Assessment**: Already uses the correct convention. No dot-vs-hyphen inconsistency found.

### #101 research.md -- qa-engineer file access misattribution
**Status: DOCUMENTATION GAP (minor)**
- The term "research.md" could refer to several files. Checked key files:
  - plugins/ralph-specum/agents/spec-executor.md line 181: "Delegation: Use Task tool to invoke qa-engineer with spec name, path, and full task description."
  - plugins/ralph-specum/references/role-contracts.md line 29: qa-engineer file access contract defined.
- **Potential issue**: spec-executor.md delegates qa-engineer but doesn't document what files qa-engineer can access. The qa-engineer file access contract exists in role-contracts.md (authoritative) but isn't cross-referenced in spec-executor.md's delegation instructions.
- **Assessment**: Minor documentation gap, not a hard bug.

### #102 research.md -- Misplaced backtick
**Status: NOT VERIFIED (requires specific file identification)**
- Searched for common backtick placement issues. No obvious misplaced backticks found.
- **Assessment**: May require identifying the exact research.md file the bug refers to.

---

## 2. Naming/Consistency (12 items)

### #16 cis/module-help.csv -- Missing bmad-cis- prefix
**Status: VERIFIED -- Present**
- File: _bmad/cis/module-help.csv line 6
- Text: Creative Intelligence Suite,bmad-brainstorming,Brainstorming,BS,...
- Other entries have bmad-cis- prefix (bmad-cis-innovation-strategy, bmad-cis-problem-solving, etc.)
- bmad-brainstorming is missing the prefix.
- **Fix**: Change bmad-brainstorming to bmad-cis-brainstorming.

### #20 ARCHITECTURE.md -- external-reviewer vs spec-reviewer
**Status: NOT A BUG**
- File: docs/ARCHITECTURE.md
- Lines 15, 290, 393: Uses both spec-reviewer and external-reviewer.
- **Assessment**: Not a bug. These are two distinct agents with different roles. spec-reviewer = rubric-based artifact reviewer; external-reviewer = parallel independent QA reviewer.

### #35 external-reviewer.md -- Lock file name mismatch
**Status: VERIFIED -- Present (ACTIONABLE)**
- File: plugins/ralph-specum/agents/external-reviewer.md lines 479, 514
- Uses: tasks.md.lock (exec 201>"${basePath}/tasks.md.lock")
- Canonical names (per spec-executor.md and qa-engineer.md):
  - .tasks.lock (for tasks.md operations)
  - .git-commit.lock (for git operations)
  - chat.md.lock (for chat.md operations)
- **Fix**: Change tasks.md.lock to .tasks.lock to match the canonical naming convention.

### #38 spec-executor.md -- Inconsistent state.json field path
**Status: VERIFIED -- Present**
- File: plugins/ralph-specum/agents/spec-executor.md
- Line 13: chat.lastReadLine (shorthand)
- Line 147: .chat.executor.lastReadLine (full path in jq)
- Line 371: chat.executor.lastReadLine (full path)
- Line 395: chat.lastReadLine (shorthand again)
- **Inconsistency**: Sometimes uses chat.lastReadLine, sometimes chat.executor.lastReadLine.
- **Fix**: Use full path chat.executor.lastReadLine consistently.

### #47 loop-safety.md -- Inconsistent header casing
**Status: VERIFIED -- Present**
- File: plugins/ralph-specum/references/loop-safety.md
- Line 85: ### filesystem Health (lowercase 'f', capitalized 'H')
- Other headers follow camelCase: ### checkpoint, ### circuitBreaker, ### ciCommands
- **Fix**: Change ### filesystem Health to ### filesystemHealth to match camelCase convention.

### #48 loop-safety.md -- Unclear phrasing
**Status: NOT VERIFIED (needs more specific guidance)**
- Checked loop-safety.md for unclear phrasing. Without specific guidance on which phrase, cannot pinpoint.

### #50 index-state.json -- "complete" vs "completed"
**Status: VERIFIED -- Present (ACTIONABLE)**
- File: specs/.index/index-state.json line 239
- Text: "phase": "complete" (for ralph-quality-improvements spec)
- All other specs use "phase": "completed".
- **Fix**: Change "complete" to "completed".

### #51 index.md -- Same phase typo
**Status: DERIVED FROM #50**
- File: specs/.index/index.md -- the phase column reflects the raw values from index-state.json.
- **Fix**: Fix #50 (index-state.json) which is the root cause. The index.md may auto-regenerate.

### #56 plan.md -- Inconsistent terminology
**Status: NOT VERIFIED**
- The role-boundaries plan.md is superseded by requirements.md. Searched for terminology inconsistency -- not found in current files.
- **Assessment**: May refer to a different spec's plan.md or has been fixed.

### #60 research.md -- Hyphen/underscore inconsistency
**Status: NOT VERIFIED**
- Searched for hyphen/underscore inconsistencies across research.md files. No clear pattern found.
- **Assessment**: May refer to a specific file that has been updated.

### #76 .research-codebase.md -- Section 10 heading level
**Status: NOT A BUG**
- File: specs/loop-safety-infra/.research-codebase.md (551 lines)
- Section 10 heading: ## 10. Spec Plan Alignment (line 535) -- correctly uses ## (H2).
- **Assessment**: Heading level is correct.

### #77 .research-codebase.md -- Contradictory line count
**Status: NOT A BUG**
- File has 551 lines. Section 1 references stop-watcher.sh (765 lines) which appears accurate.
- No contradictory line counts found.
- **Assessment**: Either already fixed or misattributed.

---

## 3. Requirements Gaps (5 items)

### #57 requirements.md -- FR-2/FR-3 missing AC references
**Status: REFERENCED BUT LACKS TRACEABILITY**
- FR-2 references AC-2.1 through AC-2.6 and these ACs exist in the document.
- FR-3 references AC-3.1 through AC-3.3 and these ACs exist in the document.
- **Issue**: The AC items don't have explicit "Parent: FR-2/FR-3" labels that trace back to their requirement. The references exist in the FR table but are not bidirectional.

### #58 requirements.md -- jq for YAML processing inaccuracy
**Status: VERIFIED -- Present (minor)**
- File: specs/role-boundaries/requirements.md
- The requirement describes jq operations on JSON baseline files. However, the broader context mentions YAML frontmatter (BMAD artifacts).
- **Issue**: jq is a JSON processor, not a YAML processor. The requirement conflates JSON processing (for the baseline file) with YAML handling (for the BMAD artifacts).
- **Fix**: Clarify that jq is used for the JSON baseline file only, not for YAML BMAD artifacts.

### #59 requirements.md -- "bmalph" typo in glossary
**Status: VERIFIED -- Present (ACTIONABLE)**
- File: specs/bmad-bridge-plugin/requirements.md line 131
- Text: BMAD | bmalph -- a BMAD Method agent framework (v6.4.0)...
- **Fix**: Change bmalph to BMAD. The glossary describes the BMAD framework but misspells it.

### #83 plan.md -- Interface Contracts missing output references
**Status: LEGACY (superseded by requirements.md)**
- The role-boundaries plan.md has an Interface Contracts section with Reads and Writes but no output file references.
- requirements.md supersedes plan.md.
- **Assessment**: Legacy issue. If fixing, note that requirements.md is the authoritative document.

### #84 plan.md -- Ambiguous "N" for two metrics
**Status: NOT VERIFIED**
- Searched role-boundaries plan.md and requirements.md for ambiguous "N" metric values.
- The NFR table uses descriptive text in the "Metric" column, not numeric values.
- **Assessment**: May refer to a different spec's plan.md or has been fixed.

---

## 4. Combined Implementation Plan

### Priority 1: Quick Wins (text-only fixes, low risk, 5 min total)
| # | File | Fix | Effort |
|---|------|-----|--------|
| #50 | specs/.index/index-state.json | "complete" to "completed" | 1 min |
| #93 | specs/loop-safety-infra/research-read-only-detection.md | O_TMPF to O_TMPFILE | 1 min |
| #90 | specs/loop-safety-infra/research-circuit-breaker.md | Remove contradictory comment | 1 min |
| #59 | specs/bmad-bridge-plugin/requirements.md | bmalph to BMAD | 1 min |
| #52 | specs/_epics/engine-roadmap-epic/epic.md | Self-reference fix | 1 min |

### Priority 2: Plugin Agent Prompt Fixes (code-level, medium risk)
| # | File | Fix | Effort |
|---|------|-----|--------|
| #35 | plugins/ralph-specum/agents/external-reviewer.md | tasks.md.lock to .tasks.lock | 2 min |
| #38 | plugins/ralph-specum/agents/spec-executor.md | Normalize chat.lastReadLine to chat.executor.lastReadLine | 3 min |
| #47 | plugins/ralph-specum/references/loop-safety.md | filesystem Health to filesystemHealth | 1 min |

### Priority 3: BMAD Module Fixes (requires care)
| # | File | Fix | Effort |
|---|------|-----|--------|
| #16 | _bmad/cis/module-help.csv | bmad-brainstorming to bmad-cis-brainstorming | 2 min |
| #11 | _bmad/core/skill-manifest.csv | Defer (directory rename needed) | -- |
| #18 | _bmad/core/module-help.csv | Defer (directory rename needed) | -- |

### Not Actionable (already fixed, not bugs, or require specific file)
| # | Reason |
|---|--------|
| #13 | Missing article 'a' -- not found in module-help.csv |
| #53 | "before task complete" -- not found in any epic.md |
| #54 | Wrong command name -- not found in any epic.md |
| #55 | Wrong command name -- not found in any plan.md |
| #99 | VOLATION in chat.md -- describes a past fix in commit message |
| #100 | AC.3.3 dot vs hyphen -- already uses correct hyphen convention |
| #101 | qa-engineer file access -- minor gap, not hard bug |
| #102 | Misplaced backtick -- not found without specific file ID |
| #20 | external-reviewer vs spec-reviewer -- not a bug, different agents |
| #48 | Unclear phrasing -- needs specific guidance |
| #51 | index.md phase typo -- root cause is #50, fixes with it |
| #56 | Inconsistent terminology -- not found (plan.md superseded) |
| #57 | FR-2/FR-3 references -- exist but lack bidirectional traceability |
| #58 | jq/YAML inaccuracy -- minor clarification needed |
| #60 | Hyphen/underscore -- not found |
| #76 | Section 10 heading level -- correct (## 10) |
| #77 | Contradictory line count -- no contradiction found |
| #83 | Interface Contracts -- legacy (superseded by requirements.md) |
| #84 | Ambiguous N -- not found |

---

## 5. Documentation/Typos Analysis

All 13 typo items checked. 5 verified as present (#11, #18, #52, #90, #93, #99), 1 not actionable (#99), 5 not found (#13, #53, #54, #55), 1 already correct (#100). #101 and #102 require more specific file identification.

## 6. Naming/Consistency Analysis

All 12 naming items checked. 4 verified as present (#16, #35, #38, #47, #50, #51), 2 not bugs (#20, #76), 3 not verified without more guidance (#48, #56, #77). #60 not found.

## 7. Requirements Gap Analysis

All 5 gaps checked. 3 verified as present (#57, #58, #59, #83), 2 not verified (#84, #57 traceability issue).

## Sources

| Source | Key Point |
|--------|-----------|
| _bmad/core/skill-manifest.csv | bmad-distillator confirmed at line 5 |
| _bmad/core/module-help.csv | Distillator display name at line 12 |
| _bmad/cis/module-help.csv | bmad-brainstorming missing bmad-cis- prefix at line 6 |
| specs/.index/index-state.json | "phase": "complete" at line 239 |
| specs/_epics/engine-roadmap-epic/epic.md | Spec 7 self-reference at line 138 |
| specs/loop-safety-infra/research-circuit-breaker.md | Contradictory timestamp comment at line 267 |
| specs/loop-safety-infra/research-read-only-detection.md | O_TMPF at line 210 |
| plugins/ralph-specum/agents/external-reviewer.md | tasks.md.lock vs .tasks.lock at lines 479, 514 |
| plugins/ralph-specum/agents/spec-executor.md | Inconsistent chat.lastReadLine at lines 13, 147, 371, 395 |
| plugins/ralph-specum/references/loop-safety.md | filesystem Health casing at line 85 |
| specs/bmad-bridge-plugin/requirements.md | bmalph typo at line 131 |
| specs/role-boundaries/chat.md | BOUNDARY_VOLATION in commit message at line 31 |
| specs/role-boundaries/requirements.md | FR references, jq/YAML context |
| specs/role-boundaries/plan.md | Superseded by requirements.md |
| plugins/ralph-specum/references/role-contracts.md | Authority on file access contracts |
| docs/ARCHITECTURE.md | spec-reviewer and external-reviewer are different agents |
