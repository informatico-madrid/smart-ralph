ralph-quality-improvements

Goal: Improve Smart Ralph's spec quality and add external reviewer protocol.
Two independent improvement tracks combined in one spec:

Track A — Spec Quality (from postmortem analysis): prevent the 5 categories of 
spec errors that required human correction in the ha-ev-trip-planner refactor.

Track B — External Reviewer Protocol: allow an external async agent (different 
process, potentially different model) to review completed tasks and communicate 
results back to Ralph via filesystem files.

---

## Track A: Spec Quality Improvements

### Background

A postmortem of the ha-ev-trip-planner refactor identified 5 recurring error 
categories in Ralph-generated specs that all required human correction before 
implementation:

1. Type annotation inconsistency — Callable return type declared as None but 
   used with await (requires Awaitable[None])
2. Duplicate document sections — same H3 heading appearing twice with identical 
   content (copy-paste not cleaned)
3. Stale text after partial updates — requirements header contradicting an FR 
   that was updated in a later iteration  
4. Unverified technical claims — assertions about external framework behavior 
   (concurrency, async ordering) stated as fact without citation
5. Missing ordering/concurrency documentation — critical operation sequences 
   not documented with their rationale, only shown in code examples

Root cause analysis identified 3 structural gaps:
- Agents produce but do not self-review (no document re-read before delivery)
- Templates have no "risk zones" for concurrency/ordering constraints
- Partial document updates have no reconciliation step

### A1 — architect-reviewer.md: add Document Self-Review Checklist

Append a new `<mandatory>` section to 
`plugins/ralph-specum/agents/architect-reviewer.md` AFTER the existing 
"Quality Checklist" section and BEFORE "Final Step: Set Awaiting Approval".

Section title: `## Document Self-Review Checklist`

The checklist must run AFTER design.md is fully written, BEFORE setting 
awaitingApproval. It must contain exactly these 4 steps:

**Step 1 — Type consistency**
For every `Callable[..., X]` type annotation in design.md:
- Find its corresponding usage example in the same document
- If usage uses `await` → type MUST be `Callable[..., Awaitable[SomeType]]`
- If usage does NOT use `await` → type MUST NOT use Awaitable
- Fix any mismatch before delivering. Do not leave mismatched types.

**Step 2 — Duplicate section detection**
Run mentally (or via grep): check for any H3 heading (###) appearing more 
than once in the document. If found: remove the duplicate, keep the 
last/most complete version.

**Step 3 — Ordering and concurrency notes**
For every `await` expression in code blocks that makes a resource visible 
to concurrent callers (e.g., storing a callback, setting a flag, writing 
to shared state):
- Ask: "If a concurrent caller accessed this resource before this await 
  completes, what breaks?"
- If something breaks: add inline comment `# CRITICAL: assign after await` 
  in the code block AND add a row to the `## Concurrency & Ordering Risks` 
  section (see A2)
  
**Step 4 — Internal contradiction scan**
For every sentence containing "CANNOT", "MUST NOT", "not possible", 
"cannot be stored":
- Verify it does not contradict any FR, code block, or other section in 
  the same document
- If contradiction found: remove the outdated statement, add comment 
  `<!-- superseded by FR-X -->`

Add this checklist to the existing Quality Checklist at the bottom as 
additional items:
- [ ] Document Self-Review Checklist passed (all 4 steps)

### A2 — templates/design.md: add Concurrency & Ordering Risks section

Add a new section to `plugins/ralph-specum/templates/design.md` between 
`## Edge Cases` and `## Test Strategy`.

```markdown
## Concurrency & Ordering Risks

<!-- Document any sequence-critical operations, async ordering constraints,
     or race conditions an implementer MUST know.
     If none identified: write "None identified." — do NOT leave this blank. -->

| Operation | Required Order | Risk if Inverted |
|-----------|---------------|-----------------|
| (example) capture async callback | AFTER `await async_add_entities()` | Service handler race condition during setup |
```

The architect-reviewer's Document Self-Review Checklist (Step 3) feeds 
directly into this section.

### A3 — product-manager.md: add On Requirements Update section

Add a new `<mandatory>` section to 
`plugins/ralph-specum/agents/product-manager.md` AFTER the existing 
"Append Learnings" section.

Section title: `## On Requirements Update`

Content: when product-manager is modifying an EXISTING requirements.md 
(not creating a new one), it must execute these steps before completing:

1. Note the concept/value being replaced or superseded
2. Search the ENTIRE requirements.md for any other occurrence of the old 
   concept: mentally scan all User Adjustments, Goal section, Non-Functional 
   Requirements, and the document header
3. For every occurrence outside the updated section: decide if it should 
   be updated to match the new concept, or removed as outdated
4. Verify the document header and any "User Adjustment" comments match the 
   current FR content — if any header text contradicts an FR, the FR wins, 
   remove or update the header text
5. Append a one-line changelog at the bottom of requirements.md:
   `<!-- Changed: <brief description> — supersedes User Adjustment #N if applicable -->`

Add to product-manager's existing Quality Checklist:
- [ ] If updating existing requirements: On Requirements Update steps completed

### A4 — spec-executor.md: add Type Consistency Pre-Check

Add a new subsection to `plugins/ralph-specum/agents/spec-executor.md` 
inside the "Implementation Tasks" section (no tag), after the existing 
`data-testid` update block.

Subsection title: `### Type Consistency Pre-Check (typed Python or TypeScript tasks)`

Content: Before implementing any task that involves `Callable`, `Awaitable`, 
`Coroutine`, `Promise`, or similar async type annotations:

1. Find the type declaration in design.md or requirements.md
2. Find the usage example in the same document for that type
3. Verify they are consistent:
   - `Callable[..., None]` → usage must NOT use `await`
   - `Callable[..., Awaitable[T]]` → usage MUST use `await`
   - TypeScript `() => void` → usage must NOT use `await`
   - TypeScript `() => Promise<T>` → usage MUST use `await`
4. If inconsistent: use the usage example as ground truth (it represents 
   intent), fix the type in your implementation to match usage, and append 
   to .progress.md:
   `Type corrected: spec declared X but usage example shows Y — implemented as Y`
5. If both the type AND the usage are ambiguous (neither clearly implies 
   sync or async): ESCALATE before implementing, do not guess.

---

## Track B: External Reviewer Protocol

### Background

An external async reviewer agent runs as an independent process (different 
model, different runtime) and communicates with Ralph exclusively via 
filesystem files in the spec directory. Ralph does not know or care what 
model the reviewer uses. The reviewer:

- Polls tasks.md every ~3 minutes looking for newly-completed tasks [x]
- Reviews completed tasks against their acceptance criteria
- Writes results to task_review.md (new file, defined below)
- For critical failures: unmarks the task in tasks.md and increments 
  external_unmarks in .ralph-state.json
- For minor issues: writes a WARNING entry without unmarking

Ralph's role: read task_review.md at the START of each task and respect 
external_unmarks in stuck-detection.

### B1 — New template: task_review.md

Create `plugins/ralph-specum/templates/task_review.md` with this exact 
structure:

```markdown
# Task Review Log

<!-- 
  Written by: external reviewer agent (independent process)
  Read by: spec-executor at the start of each task
  
  Workflow:
  - FAIL (critical): reviewer unmarks task in tasks.md + increments 
    external_unmarks in .ralph-state.json + writes entry here
  - WARNING (minor): reviewer writes entry here, task stays marked done
  - PASS: reviewer writes entry here for audit trail
  - PENDING: reviewer is working on it, spec-executor should not re-mark
    this task until status changes

  spec-executor: read this file before starting each task. See protocol below.
-->

## Reviews

<!-- Template for each review entry — copy and fill:

### [task-X.Y] <task title>
- **status**: PASS | FAIL | WARNING | PENDING
- **severity**: critical | minor | note
- **reviewed_at**: <ISO 8601 timestamp>
- **criterion_failed**: <exact acceptance criterion text from tasks.md, or "none">
- **evidence**: <exact error message, diff, or test output — not a summary>
- **fix_hint**: <optional: specific suggestion for the fix>
- **resolved_at**: <!-- spec-executor fills this when fix is confirmed -->

-->
```

### B2 — spec-executor.md: read task_review.md before each task

Add a new `<mandatory>` section to spec-executor.md titled 
`## External Review Protocol` positioned AFTER the "Startup Signal" section 
and BEFORE the "Task Loop" section.

Content:

**On every task start** (before reading tasks.md to find the next task):

1. Check if `<basePath>/task_review.md` exists
2. If it does NOT exist: proceed normally
3. If it DOES exist:
   a. Read it fully
   b. Find any entry where task id matches the current task being started
   c. Apply the following rules based on status:
      - **FAIL**: treat as VERIFICATION_FAIL. The fix_hint is the starting 
        point. Apply fix, then mark the entry's `resolved_at` with timestamp 
        before marking the task complete in tasks.md
      - **PENDING**: do NOT start the task. Append to .progress.md: 
        "External review PENDING for task X — waiting one cycle". Skip this 
        task and move to the next unchecked one. On the next invocation, 
        check again.
      - **WARNING**: read the warning, append it to .progress.md, proceed 
        with the task but apply the suggested fix if one is provided
      - **PASS**: proceed normally, no action needed

4. Append to .progress.md when a FAIL or WARNING is found:
   `External review [FAIL|WARNING] for task X.Y: <criterion_failed>`

### B3 — .ralph-state.json: external_unmarks field

This is a schema documentation change only (no code to write — it's a JSON file).

Update the spec-executor's stuck-detection logic (in the "Task Loop" section 
and the "Stuck State Protocol" section) to reference a new optional field 
`external_unmarks` in .ralph-state.json.

The field is an object mapping task IDs to integer counts:
```json
{
  "taskIndex": 4,
  "taskIteration": 1,
  "external_unmarks": {
    "task-2.4": 2
  }
}
```

Spec-executor must:
1. On task start: read `external_unmarks[currentTaskId]` (default 0 if absent)
2. For stuck-detection: use `effectiveIterations = taskIteration + external_unmarks[taskId]`
3. If `effectiveIterations >= maxTaskIterations`: ESCALATE with reason 
   `external-reviewer-repeated-fail` — do NOT retry, the reviewer has 
   already seen this fail multiple times
4. `external_unmarks` values are NEVER reset to 0 by spec-executor. They 
   are cumulative across sessions. Only the external reviewer increments them.
5. On ESCALATE due to external_unmarks: include in the escalation message:
   `External reviewer has unmarked this task N times. Human investigation required.`

### B4 — .ralph-state.json schema documentation

Add `external_unmarks` to any existing schema documentation for 
.ralph-state.json in the codebase (README.md, CLAUDE.md, or wherever 
the state file fields are documented). Mark it as:
- Type: `object` (map of taskId string → integer)
- Optional: yes, defaults to `{}`
- Written by: external reviewer only
- Read by: spec-executor for stuck detection

---

## Out of Scope

- The external reviewer implementation itself (runs in a different repo/process)
- Any polling mechanism inside Ralph — Ralph is event-driven, not polling
- Any specific model or provider for the reviewer
- Any network protocol — filesystem only
- Changes to the research-analyst, task-planner, or triage-analyst agents
- Changes to any command files
- Changes to the anti-stuck pattern logic beyond the external_unmarks addition

---

## Acceptance Criteria

### Track A
- AC-A1: architect-reviewer.md has Document Self-Review Checklist with 4 steps, inside a `<mandatory>` block, positioned after Quality Checklist
- AC-A2: templates/design.md has `## Concurrency & Ordering Risks` section with the table structure, positioned between Edge Cases and Test Strategy
- AC-A3: product-manager.md has `## On Requirements Update` section inside `<mandatory>`, positioned after Append Learnings
- AC-A4: spec-executor.md has Type Consistency Pre-Check subsection inside Implementation Tasks section
- AC-A5: All additions are surgical (surrounding content unchanged)

### Track B
- AC-B1: `templates/task_review.md` exists with the schema and instructions defined above
- AC-B2: spec-executor.md has `## External Review Protocol` section as `<mandatory>`, positioned after Startup Signal, before Task Loop
- AC-B3: spec-executor.md stuck-detection references `effectiveIterations = taskIteration + external_unmarks[taskId]`
- AC-B4: `external_unmarks` field documented in state file schema wherever .ralph-state.json fields are documented
- AC-B5: No existing spec-executor behavior is changed beyond the two additions

### All tracks
- AC-G1: All existing tests in the repo pass (no regression)
- AC-G2: Each modified file has its version bumped per CLAUDE.md versioning rules

---

## Notes for task-planner

Tasks-size: fine — these are changes to core agent prompts, surgical precision required.

Each Track A change (A1–A4) is one task. Each Track B change (B1–B4) is one task.
Add a [VERIFY] task after Track A and after Track B to verify no surrounding 
content was accidentally modified.

Priority: Track A tasks first (A1→A2→A3→A4→VERIFY-A), then Track B (B1→B2→B3→B4→VERIFY-B).

Do NOT generate implementation code for the changes — these are markdown prompt 
files. The executor reads the target file, appends or inserts the new section 
at the exact position specified, and verifies the surrounding content is untouched.