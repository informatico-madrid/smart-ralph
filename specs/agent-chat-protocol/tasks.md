# Tasks: agent-chat-protocol

## Overview

Total tasks: 46

**Intent Classification**: GREENFIELD — POC-first workflow

**POC-first workflow**:
1. Phase 1: Make It Work (POC) - Validate idea end-to-end
2. Phase 2: Refactoring - Clean up code structure
3. Phase 3: Testing - Add unit/integration/e2e tests
4. Phase 4: Quality Gates - Local quality checks and PR creation

## Phase 1: Make It Work (POC)

Focus: Validate the idea works end-to-end. Skip tests, accept hardcoded values.

- [ ] 1.1 Create chat.md template file
  - **Do**:
    1. Create `plugins/ralph-specum/templates/chat.md` with format header containing signals legend table
    2. Include the message format: `### [<writer> → <addressee>] <HH:MM:SS> | <task-ID> | <SIGNAL>`
    3. Include signals legend table with all 10 signals (OVER, ACK, CONTINUE, HOLD, STILL, ALIVE, CLOSE, URGENT, DEADLOCK, INTENT-FAIL)
    4. Include example messages section showing OVER/ACK/CONTINUE/CLOSE patterns
    5. Add comment: `<!-- Messages accumulate here. Append only. Do not edit or delete. -->`
  - **Files**: `plugins/ralph-specum/templates/chat.md`
  - **Done when**: Template file exists with correct format and all 10 signals documented
  - **Verify**: `grep -c "OVER\|ACK\|CONTINUE\|HOLD\|STILL\|ALIVE\|CLOSE\|URGENT\|DEADLOCK\|INTENT-FAIL" plugins/ralph-specum/templates/chat.md`
  - **Commit**: `feat(chat-template): create chat.md template with FLOC signals legend`
  - _Requirements: FR-1, FR-2_
  - _Design: Chat Template section_

- [ ] 1.2 Add chat field to .ralph-state.json schema
  - **Do**:
    1. Read current `.ralph-state.json` schema to understand state structure
    2. Add `chat` field to `.ralph-state.json` inside `specs/agent-chat-protocol/` with structure:
       ```json
       "chat": {
         "executor": { "lastReadIndex": 0, "lastSignal": null, "lastSignalTask": null, "stillTtl": 0 },
         "reviewer": { "lastReadIndex": 0, "lastSignal": null, "lastSignalTask": null, "pendingIntentFail": null }
       }
       ```
    3. Initialize this in the spec's `.ralph-state.json` if it exists, or create a new one
  - **Files**: `specs/agent-chat-protocol/.ralph-state.json`
  - **Done when**: `.ralph-state.json` contains `chat` field with per-agent subfields
  - **Verify**: `jq '.chat' specs/agent-chat-protocol/.ralph-state.json`
  - **Commit**: `feat(chat-state): add chat field to .ralph-state.json schema`
  - _Requirements: FR-14_
  - _Design: Per-Agent State section_

- [ ] 1.3 Create chat-helpers.sh library (shared utilities)
  - **Do**:
    1. Create `plugins/ralph-specum/hooks/scripts/chat-helpers.sh` with shared utilities:
       - `chat_get_timestamp()` — returns HH:MM:SS format
       - `chat_get_task_id()` — formats task ID from state
       - `chat_validate_signal(signal)` — validates signal is one of 10 known
       - `chat_format_message(agent, addressee, task_id, signal, body)` — formats message header
       - `chat_update_state(agent, field, value)` — atomic state update using jq
       - `chat_get_state_value(agent, field)` — read state value from .ralph-state.json
       - `chat_init_state(agent)` — initialize chat state for agent if missing
    2. Both chat-writer.sh and chat-reader.sh will source this file
    3. Require `SPEC_DIR` environment variable set by caller
  - **Files**: `plugins/ralph-specum/hooks/scripts/chat-helpers.sh`
  - **Done when**: Shared library exists with all helper functions
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/chat-helpers.sh && echo "HELPERS_OK"`
  - **Commit**: `feat(chat-helpers): create shared chat helper library`
  - _Requirements: NFR-1_
  - _Design: Component: Chat Channel section_

- [ ] 1.4 Create ChatWriter utility - core message writing
  - **Do**:
    1. Create `plugins/ralph-specum/hooks/scripts/chat-writer.sh` with core functions:
       - `chat_write_message(agent, addressee, task_id, signal, body)` — writes message using temp-file+rename pattern
       - `chat_write_over(agent, task_id, question)` — sends OVER signal
       - `chat_write_ack(agent, task_id, message)` — sends ACK signal
       - `chat_write_continue(agent, task_id)` — sends CONTINUE signal
    2. Implement atomic write: `cat > chat.tmp.{agent}.{timestamp} <<EOF ... EOF && mv chat.tmp.{agent}.{timestamp} chat.md`
    3. Source chat-helpers.sh for shared functions
    4. Require `SPEC_DIR` environment variable set by caller
  - **Files**: `plugins/ralph-specum/hooks/scripts/chat-writer.sh`
  - **Done when**: Script exists with OVER/ACK/CONTINUE write functions, atomic write pattern implemented
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/chat-writer.sh && echo "SYNTAX_OK"`
  - **Commit**: `feat(chat-writer): create ChatWriter with core signal writers`
  - _Requirements: FR-2, FR-13_
  - _Design: Atomic Write Implementation section_

- [ ] 1.5 Add HOLD, STILL, ALIVE write functions to ChatWriter
  - **Do**:
    1. Add to `chat-writer.sh`:
       - `chat_write_hold(agent, task_id, reason)` — sends HOLD signal
       - `chat_write_still(agent, task_id, message)` — sends STILL signal
       - `chat_write_alive(agent, task_id)` — sends ALIVE signal
    2. Source chat-helpers.sh for shared functions
  - **Files**: `plugins/ralph-specum/hooks/scripts/chat-writer.sh`
  - **Done when**: HOLD/STILL/ALIVE write functions exist
  - **Verify**: `grep "chat_write_hold\|chat_write_still\|chat_write_alive" plugins/ralph-specum/hooks/scripts/chat-writer.sh | wc -l`
  - **Commit**: `feat(chat-writer): add HOLD, STILL, ALIVE signal writers`
  - _Requirements: FR-6, FR-7, FR-8_
  - _Design: FLOC Signal State Machine section_

- [ ] 1.6 Add CLOSE, URGENT, DEADLOCK, INTENT-FAIL write functions to ChatWriter
  - **Do**:
    1. Add to `chat-writer.sh`:
       - `chat_write_close(agent, task_id, reason)` — sends CLOSE signal
       - `chat_write_urgent(agent, task_id, reason)` — sends URGENT signal
       - `chat_write_deadlock(agent, task_id, reason)` — sends DEADLOCK signal
       - `chat_write_intent_fail(agent, task_id, fix_hint)` — sends INTENT-FAIL signal
    2. Verify all 10 signals now have write functions
  - **Files**: `plugins/ralph-specum/hooks/scripts/chat-writer.sh`
  - **Done when**: All 10 FLOC signals have write functions
  - **Verify**: `grep -c "chat_write_" plugins/ralph-specum/hooks/scripts/chat-writer.sh`
  - **Commit**: `feat(chat-writer): add CLOSE, URGENT, DEADLOCK, INTENT-FAIL signal writers`
  - _Requirements: FR-9, FR-10, FR-11, FR-12_
  - _Design: FLOC Signal State Machine section_

- [ ] 1.7 Create ChatReader utility - read new messages
  - **Do**:
    1. Create `plugins/ralph-specum/hooks/scripts/chat-reader.sh` with functions:
       - `chat_read_new(agent)` — reads messages after lastReadIndex, updates state
       - `chat_has_signal(agent, signal)` — checks if signal exists since last read
    2. Read SPEC_DIR from environment, use `.ralph-state.json` for lastReadIndex
    3. Update lastReadIndex after each read using atomic jq pattern
  - **Files**: `plugins/ralph-specum/hooks/scripts/chat-reader.sh`
  - **Done when**: Script exists with read functions, lastReadIndex tracking works
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/chat-reader.sh && echo "SYNTAX_OK"`
  - **Commit**: `feat(chat-reader): create ChatReader with read functions`
  - _Requirements: FR-14, FR-6_
  - _Design: Per-Agent State section_

- [ ] 1.8 Add HOLD detection and state query functions to ChatReader
  - **Do**:
    1. Add to `chat-reader.sh`:
       - `chat_has_hold()` — checks if HOLD signal present in unread messages
       - `chat_get_last_signal(agent)` — returns lastSignal from state
       - `chat_get_still_ttl(agent)` — returns stillTtl value
       - `chat_get_pending_intent_fail(agent)` — returns pendingIntentFail value
    2. Source chat-helpers.sh for shared functions
  - **Files**: `plugins/ralph-specum/hooks/scripts/chat-reader.sh`
  - **Done when**: HOLD detection and state query functions exist
  - **Verify**: `grep "chat_has_hold\|chat_get_last_signal\|chat_get_still_ttl" plugins/ralph-specum/hooks/scripts/chat-reader.sh | wc -l`
  - **Commit**: `feat(chat-reader): add HOLD detection and state query functions`
  - _Requirements: FR-6, FR-14_
  - _Design: Per-Agent State section_

- [ ] 1.9 Add Chat Protocol section to spec-executor.md - chat reading at task START
  - **Do**:
    1. Read `plugins/ralph-specum/agents/spec-executor.md`
    2. Add new section "## Chat Protocol" after the "## External Review Protocol" section
    3. Add chat reading at task START:
       - Check if `chat.md` exists in basePath
       - If exists and has >= 1 message, read new messages using chat-reader.sh
       - Check for HOLD signal — if present, block until ACK/CONTINUE
       - Update lastReadIndex after reading
    4. Implement OVER timeout logic: 1 task cycle then auto-CONTINUE
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: spec-executor.md contains Chat Protocol section with HOLD checking at task START
  - **Verify**: `grep -c "Chat Protocol\|chat_read_new\|chat_has_hold" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `feat(spec-executor): add Chat Protocol section with chat reading at task START`
  - _Requirements: FR-3, FR-6_
  - _Design: FLOC Signal State Machine section_

- [ ] 1.10 Add STILL TTL tracking to spec-executor.md
  - **Do**:
    1. Add STILL TTL tracking to spec-executor.md:
       - Track stillTtl counter per task cycle
       - Decrement on each task with no signal from reviewer
       - Raise alarm when TTL reaches 0 (3 consecutive tasks)
       - Implement ALIVE-triggered TTL reset
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`
  - **Done when**: STILL TTL tracking implemented in executor
  - **Verify**: `grep -c "stillTtl\|STILL" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `feat(spec-executor): add STILL TTL tracking for deadlock prevention`
  - _Requirements: FR-7, FR-8_
  - _Design: STILL Signal section_

- [ ] 1.11 Add FLOC signals to external-reviewer.md - reading at review cycle
  - **Do**:
    1. Read `plugins/ralph-specum/agents/external-reviewer.md`
    2. Add chat reading at review cycle (similar to executor)
    3. Respond to OVER with ACK/CONTINUE/CLOSE within 1 task cycle
    4. Implement HOLD pre-task gate for reviewer
  - **Files**: `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: external-reviewer.md reads chat at review cycle
  - **Verify**: `grep -c "chat_read_new\|chat_has_hold" plugins/ralph-specum/agents/external-reviewer.md`
  - **Commit**: `feat(external-reviewer): add chat reading at review cycle`
  - _Requirements: FR-4, FR-5, FR-6_
  - _Design: FLOC Signal State Machine section_

- [ ] 1.12 Add ALIVE and STILL signals to external-reviewer.md
  - **Do**:
    1. Add to external-reviewer.md:
       - ALIVE every 3 tasks of silence (when STILL TTL would expire)
       - STILL signal for intentional silence during active work
    2. Implement TTL tracking: stillTtl field that resets on any signal
  - **Files**: `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: ALIVE and STILL signals implemented
  - **Verify**: `grep -c "ALIVE\|STILL" plugins/ralph-specum/agents/external-reviewer.md`
  - **Commit**: `feat(external-reviewer): add ALIVE and STILL signal implementation`
  - _Requirements: FR-7, FR-8_
  - _Design: STILL Signal section_

- [ ] 1.13 Add INTENT-FAIL, CLOSE, URGENT, DEADLOCK to external-reviewer.md
  - **Do**:
    1. Add to external-reviewer.md:
       - INTENT-FAIL pre-warning before writing FAIL to task_review.md (1-task window)
       - CLOSE response to resolved OVER threads
       - URGENT for critical issues (respecting qa-engineer delegation boundary)
       - DEADLOCK for human escalation
  - **Files**: `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: INTENT-FAIL, CLOSE, URGENT, DEADLOCK signals implemented
  - **Verify**: `grep -c "INTENT-FAIL\|CLOSE\|URGENT\|DEADLOCK" plugins/ralph-specum/agents/external-reviewer.md`
  - **Commit**: `feat(external-reviewer): add INTENT-FAIL, CLOSE, URGENT, DEADLOCK signals`
  - _Requirements: FR-9, FR-10, FR-11, FR-12_
  - _Design: FLOC Signal State Machine section_

- [ ] 1.14 [VERIFY] Quality Checkpoint: syntax and structure
  - **Do**: Verify all created files have correct syntax and structure
  - **Verify**:
    - `bash -n plugins/ralph-specum/hooks/scripts/chat-writer.sh && echo "WRITER_OK"`
    - `bash -n plugins/ralph-specum/hooks/scripts/chat-reader.sh && echo "READER_OK"`
    - `bash -n plugins/ralph-specum/hooks/scripts/chat-helpers.sh && echo "HELPERS_OK"`
    - `jq '.' specs/agent-chat-protocol/.ralph-state.json && echo "STATE_OK"`
    - `grep -q "Chat Protocol" plugins/ralph-specum/agents/spec-executor.md && echo "EXEC_PROTOCOL_OK"`
    - `grep -q "ALIVE" plugins/ralph-specum/agents/external-reviewer.md && echo "REVIEWER_SIGNALS_OK"`
  - **Done when**: All checks pass with no errors
  - **Commit**: `chore: pass Phase 1 quality checkpoint`
  - _Requirements: NFR-1, NFR-2_

- [ ] 1.15 Initialize chat.md in spec directory
  - **Do**:
    1. Copy `plugins/ralph-specum/templates/chat.md` to `specs/agent-chat-protocol/chat.md`
    2. Verify file exists and has correct format
  - **Files**: `specs/agent-chat-protocol/chat.md`
  - **Done when**: chat.md exists in spec directory with template content
  - **Verify**: `[ -f specs/agent-chat-protocol/chat.md ] && grep -q "Signals Legend" specs/agent-chat-protocol/chat.md`
  - **Commit**: `feat(chat-init): initialize chat.md in spec directory`
  - _Requirements: FR-1_
  - _Design: Chat Template section_

- [ ] 1.16 POC test: executor writes OVER, reviewer responds ACK
  - **Do**:
    1. Set up test environment: create temp spec directory with chat.md and .ralph-state.json
    2. Simulate executor writes OVER to chat.md using chat-writer.sh
    3. Simulate reviewer reads chat.md, responds with ACK using chat-writer.sh
    4. Verify both messages appear in chat.md with correct format
    5. Verify state file updated correctly (lastReadIndex for both agents)
  - **Files**: `plugins/ralph-specum/hooks/scripts/chat-writer.sh`, `plugins/ralph-specum/hooks/scripts/chat-reader.sh`
  - **Done when**: OVER and ACK messages appear in chat.md with correct format
  - **Verify**: `grep "OVER\|ACK" specs/agent-chat-protocol/chat.md | wc -l`
  - **Commit**: `test(chat-poc): verify OVER/ACK bidirectional message flow`
  - _Requirements: FR-3, FR-4_
  - _Design: Signal Sequencing Rules section_

- [ ] 1.17 POC test: HOLD pre-task gate blocks executor
  - **Do**:
    1. Create test scenario: executor starts task, reviewer sends HOLD
    2. Verify executor reads HOLD at task START only (not mid-task)
    3. Verify executor blocks until ACK or CONTINUE received
    4. Verify executor proceeds with current task when HOLD received mid-execution
  - **Files**: `plugins/ralph-specum/hooks/scripts/chat-reader.sh`
  - **Done when**: Executor correctly respects HOLD as pre-task gate
  - **Verify**: `grep -c "HOLD" plugins/ralph-specum/agents/spec-executor.md`
  - **Commit**: `test(chat-poc): verify HOLD pre-task gate semantics`
  - _Requirements: FR-6_
  - _Design: HOLD Signal section_

- [ ] 1.18 POC test: STILL/ALIVE heartbeat cycle
  - **Do**:
    1. Simulate 3 tasks of reviewer silence
    2. Verify STILL TTL decrements on each task
    3. Verify ALIVE is sent when TTL would expire
    4. Verify ALIVE resets TTL to 3
  - **Files**: `plugins/ralph-specum/hooks/scripts/chat-helpers.sh`
  - **Done when**: ALIVE appears after 3 tasks of silence
  - **Verify**: `grep "ALIVE" specs/agent-chat-protocol/chat.md`
  - **Commit**: `test(chat-poc): verify STILL/ALIVE heartbeat cycle`
  - _Requirements: FR-7, FR-8_
  - _Design: STILL Signal section_

- [ ] 1.19 POC test: INTENT-FAIL 1-task window
  - **Do**:
    1. Simulate reviewer writes INTENT-FAIL to chat.md
    2. Verify executor has 1 task cycle to respond
    3. Verify FAIL written to task_review.md only after 1 task if not corrected
  - **Files**: `plugins/ralph-specum/hooks/scripts/chat-writer.sh`
  - **Done when**: INTENT-FAIL appears in chat before FAIL in task_review.md
  - **Verify**: `grep "INTENT-FAIL" specs/agent-chat-protocol/chat.md`
  - **Commit**: `test(chat-poc): verify INTENT-FAIL 1-task window`
  - _Requirements: FR-11_
  - _Design: INTENT-FAIL Signal section_

- [ ] 1.20 POC test: CLOSE thread resolution
  - **Do**:
    1. Simulate OVER exchange between executor and reviewer
    2. Simulate reviewer sends CLOSE to resolve thread
    3. Verify CLOSE appears in chat.md with correct format
    4. Verify new OVER on different topic still works
  - **Files**: `plugins/ralph-specum/hooks/scripts/chat-writer.sh`
  - **Done when**: CLOSE appears in chat.md
  - **Verify**: `grep "CLOSE" specs/agent-chat-protocol/chat.md`
  - **Commit**: `test(chat-poc): verify CLOSE thread resolution`
  - _Requirements: FR-9_
  - _Design: CLOSE Signal section_

- [ ] 1.21 POC Checkpoint: end-to-end signal flow
  - **Do**: Run a full POC demonstrating all major signals work:
    1. Executor sends OVER
    2. Reviewer sends ACK
    3. Reviewer sends CONTINUE
    4. Executor proceeds
    5. Reviewer sends HOLD
    6. Executor respects HOLD at next task
    7. Reviewer sends ACK
    8. Executor proceeds
  - **Done when**: All signals appear in correct order in chat.md
  - **Verify**: `grep -E "OVER|ACK|CONTINUE|HOLD" specs/agent-chat-protocol/chat.md`
  - **Commit**: `chore: complete POC validation`
  - _Requirements: FR-3, FR-4, FR-5, FR-6_

## Phase 2: Refactoring

After POC validated, clean up code.

- [ ] 2.1 Refactor ChatWriter: extract format validation
  - **Do**:
    1. Add message format validation function to chat-helpers.sh
    2. Validate format: `### [<writer> → <addressee>] <HH:MM:SS> | <task-ID> | <SIGNAL>`
    3. Validate SIGNAL is one of 10 known signals
    4. Refactor chat-writer.sh to use validation
  - **Files**: `plugins/ralph-specum/hooks/scripts/chat-helpers.sh`, `plugins/ralph-specum/hooks/scripts/chat-writer.sh`
  - **Done when**: Message format validated before writing
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/chat-writer.sh && echo "OK"`
  - **Commit**: `refactor(chat-writer): add message format validation`
  - _Design: Error Handling section_

- [ ] 2.2 Refactor ChatReader: add error recovery for missing files
  - **Do**:
    1. Add error recovery for missing chat.md (graceful skip)
    2. Add error recovery for corrupted state file (reset to defaults)
    3. Add error recovery for lastReadIndex > actual lines (reset to line count)
  - **Files**: `plugins/ralph-specum/hooks/scripts/chat-reader.sh`
  - **Done when**: Chat reader handles all error cases in Error Handling table
  - **Verify**: `bash -n plugins/ralph-specum/hooks/scripts/chat-reader.sh && echo "OK"`
  - **Commit**: `refactor(chat-reader): add error recovery for missing files`
  - _Design: Error Handling section_

- [ ] 2.3 Refactor: add atomic write verification
  - **Do**:
    1. Add verification that temp file is removed after rename
    2. Add check that message appears in chat.md after write
    3. Add cleanup of orphaned temp files on error
  - **Files**: `plugins/ralph-specum/hooks/scripts/chat-writer.sh`
  - **Done when**: No orphaned temp files remain after write
  - **Verify**: `ls chat.tmp.* 2>/dev/null || echo "NO_ORPHANS"`
  - **Commit**: `refactor(chat-writer): add atomic write verification`
  - _Requirements: NFR-1_
  - _Design: Error Handling section_

- [ ] 2.4 Refactor: extract signal-specific helpers to chat-helpers.sh
  - **Do**:
    1. Extract signal validation to `chat_validate_signal()`
    2. Extract signal-specific message formatting to individual functions
    3. Ensure all chat scripts source chat-helpers.sh consistently
  - **Files**: `plugins/ralph-specum/hooks/scripts/chat-helpers.sh`, `plugins/ralph-specum/hooks/scripts/chat-writer.sh`
  - **Done when**: Signal logic centralized in helpers
  - **Verify**: `grep "source.*chat-helpers" plugins/ralph-specum/hooks/scripts/chat-*.sh | wc -l`
  - **Commit**: `refactor(chat): extract signal helpers to chat-helpers.sh`
  - _Design: Component: Chat Channel section_

- [ ] 2.5 [VERIFY] Quality Checkpoint: refactoring complete
  - **Do**: Run all scripts to verify refactoring doesn't break functionality
  - **Verify**:
    - `bash -n plugins/ralph-specum/hooks/scripts/chat-helpers.sh && echo "HELPERS_OK"`
    - `bash -n plugins/ralph-specum/hooks/scripts/chat-writer.sh && echo "WRITER_OK"`
    - `bash -n plugins/ralph-specum/hooks/scripts/chat-reader.sh && echo "READER_OK"`
  - **Done when**: All syntax checks pass
  - **Commit**: `chore: pass Phase 2 quality checkpoint`

## Phase 3: Testing

- [ ] 3.1 Unit tests: ChatWriter.write() with clean state
  - **Do**:
    1. Create `tests/chat-writer.bats` with test cases:
       - Message appears in file with correct format
       - Format validation rejects invalid signals
       - Atomic write leaves no temp files
    2. Use temp directory for test workspace
    3. Clean up temp files in teardown
  - **Files**: `tests/chat-writer.bats`
  - **Done when**: All unit tests pass
  - **Verify**: `bats tests/chat-writer.bats`
  - **Commit**: `test(chat-writer): add unit tests for ChatWriter`
  - _Design: Test Coverage Table - ChatWriter.write()_

- [ ] 3.2 Unit tests: ChatWriter.atomicRename()
  - **Do**:
    1. Add test cases to `tests/chat-writer.bats`:
       - Temp file gone after rename
       - Content correctly in target file
       - Concurrent rename safety
    2. Use real temp files in temp directory
  - **Files**: `tests/chat-writer.bats`
  - **Done when**: All atomic rename tests pass
  - **Verify**: `bats tests/chat-writer.bats`
  - **Commit**: `test(chat-writer): add atomic rename tests`
  - _Design: Test Coverage Table - ChatWriter.atomicRename()_

- [ ] 3.3 Unit tests: ChatReader.readNewMessages()
  - **Do**:
    1. Create `tests/chat-reader.bats` with test cases:
       - Returns only messages after lastReadIndex
       - State file updated with correct index
       - Handles empty chat (first read)
       - Handles missing state file
    2. Create fixture files in `tests/fixtures/chat/`
  - **Files**: `tests/chat-reader.bats`, `tests/fixtures/chat/`
  - **Done when**: All unit tests pass
  - **Verify**: `bats tests/chat-reader.bats`
  - **Commit**: `test(chat-reader): add unit tests for ChatReader`
  - _Design: Test Coverage Table - ChatReader.readNewMessages()_

- [ ] 3.4 Unit tests: ChatReader.updateLastReadIndex()
  - **Do**:
    1. Add test cases to `tests/chat-reader.bats`:
       - lastReadIndex updated correctly after read
       - Atomic state update pattern works
       - State file remains valid JSON after update
    2. Use real jq on temp state file
  - **Files**: `tests/chat-reader.bats`
  - **Done when**: All update tests pass
  - **Verify**: `bats tests/chat-reader.bats`
  - **Commit**: `test(chat-reader): add lastReadIndex update tests`
  - _Design: Test Coverage Table - ChatReader.updateLastReadIndex()_

- [ ] 3.5 Unit tests: PerAgentState JSON serialization
  - **Do**:
    1. Create `tests/chat-state.bats` with test cases:
       - Valid JSON output from jq pattern
       - Parsed state matches expected schema
       - Atomic update pattern works
    2. Test with real jq on valid and invalid JSON
  - **Files**: `tests/chat-state.bats`
  - **Done when**: All unit tests pass
  - **Verify**: `bats tests/chat-state.bats`
  - **Commit**: `test(chat-state): add unit tests for per-agent state`
  - _Design: Test Coverage Table - PerAgentState JSON serialization_

- [ ] 3.6 Unit tests: FLOC state - ACTIVE to BLOCKED on OVER
  - **Do**:
    1. Create `tests/floc-state-machine.bats` with test case:
       - UNKNOWN/ACTIVE state transitions to BLOCKED when OVER signal sent
       - State recorded correctly in chat state
    2. Test pure state transitions without filesystem
  - **Files**: `tests/floc-state-machine.bats`
  - **Done when**: All unit tests pass
  - **Verify**: `bats tests/floc-state-machine.bats`
  - **Commit**: `test(floc): add ACTIVE to BLOCKED on OVER test`
  - _Design: Test Coverage Table - FLOC state: ACTIVE → BLOCKED on OVER_

- [ ] 3.7 Unit tests: FLOC state - BLOCKED to ACTIVE on ACK
  - **Do**:
    1. Add test case to `tests/floc-state-machine.bats`:
       - BLOCKED state transitions to ACTIVE when ACK received
       - BLOCKED state transitions to ACTIVE when CONTINUE received
    2. Test pure state transitions without filesystem
  - **Files**: `tests/floc-state-machine.bats`
  - **Done when**: All unit tests pass
  - **Verify**: `bats tests/floc-state-machine.bats`
  - **Commit**: `test(floc): add BLOCKED to ACTIVE on ACK test`
  - _Design: Test Coverage Table - FLOC state: BLOCKED → ACTIVE on ACK_

- [ ] 3.8 Unit tests: FLOC state - auto-CONTINUE on timeout
  - **Do**:
    1. Add test case to `tests/floc-state-machine.bats`:
       - BLOCKED state transitions to ACTIVE when 1 task passes without response
       - auto-CONTINUE behavior verified
    2. Test pure state transitions without filesystem
  - **Files**: `tests/floc-state-machine.bats`
  - **Done when**: All unit tests pass
  - **Verify**: `bats tests/floc-state-machine.bats`
  - **Commit**: `test(floc): add auto-CONTINUE on timeout test`
  - _Design: Test Coverage Table - FLOC state: auto-CONTINUE on timeout_

- [ ] 3.9 Integration tests: concurrent writes (100 messages)
  - **Do**:
    1. Create `tests/chat-concurrent.bats` with test cases:
       - Both agents append 100 messages simultaneously
       - Verify zero corruption (valid format per message)
       - Verify zero lost messages (count matches)
    2. Use background processes in bash
  - **Files**: `tests/chat-concurrent.bats`
  - **Done when**: All integration tests pass with no corruption
  - **Verify**: `bats tests/chat-concurrent.bats`
  - **Commit**: `test(chat-concurrent): add concurrent writes integration test`
  - _Requirements: NFR-1_
  - _Design: Test Coverage Table - Concurrent writes_

- [ ] 3.10 Integration tests: HOLD pre-task gate behavior
  - **Do**:
    1. Create `tests/chat-hold-gate.bats` with test cases:
       - Executor respects HOLD at task START
       - Executor does NOT block mid-task (pre-task gate only)
       - Executor unblocks after ACK/CONTINUE
       - HOLD invisible until task boundary
  - **Files**: `tests/chat-hold-gate.bats`
  - **Done when**: All integration tests pass
  - **Verify**: `bats tests/chat-hold-gate.bats`
  - **Commit**: `test(chat-hold): add HOLD pre-task gate integration test`
  - _Design: Test Coverage Table - HOLD pre-task gate_

- [ ] 3.11 Integration tests: INTENT-FAIL 1-task window
  - **Do**:
    1. Create `tests/chat-intent-fail.bats` with test cases:
       - INTENT-FAIL appears before FAIL
       - Executor has 1 task window to respond
       - FAIL written only after window expires
       - Corrected issue prevents FAIL
  - **Files**: `tests/chat-intent-fail.bats`
  - **Done when**: All integration tests pass
  - **Verify**: `bats tests/chat-intent-fail.bats`
  - **Commit**: `test(chat-intent-fail): add INTENT-FAIL window integration test`
  - _Design: Test Coverage Table - INTENT-FAIL 1-task window_

- [ ] 3.12 Integration tests: Executor respects HOLD (not mid-task)
  - **Do**:
    1. Create `tests/chat-hold-behavior.bats` with test cases:
       - Executor proceeds with current task when HOLD received mid-execution
       - Executor blocks at next task if HOLD not resolved
       - Executor unblocks when ACK or CONTINUE received
  - **Files**: `tests/chat-hold-behavior.bats`
  - **Done when**: All integration tests pass
  - **Verify**: `bats tests/chat-hold-behavior.bats`
  - **Commit**: `test(chat-hold): add executor respects HOLD not mid-task test`
  - _Design: Test Coverage Table - Executor respects HOLD (not mid-task)_

- [ ] 3.13 Integration tests: STILL/ALIVE heartbeat cycle
  - **Do**:
    1. Create `tests/chat-heartbeat.bats` with test cases:
       - STILL TTL decrements each task
       - ALIVE resets TTL to 3
       - ALIVE sent when TTL would expire
       - ANY signal resets STILL counter
  - **Files**: `tests/chat-heartbeat.bats`
  - **Done when**: All integration tests pass
  - **Verify**: `bats tests/chat-heartbeat.bats`
  - **Commit**: `test(chat-heartbeat): add STILL/ALIVE heartbeat integration test`
  - _Design: Test Coverage Table - ALIVE resets STILL TTL_

- [ ] 3.14 Integration tests: chat format human-readable
  - **Do**:
    1. Create `tests/chat-format.bats` with test cases:
       - `cat chat.md` shows readable markdown
       - Each message has correct format header
       - Signals are human-readable (not encoded)
       - Human can read with standard tools
  - **Files**: `tests/chat-format.bats`
  - **Done when**: All integration tests pass
  - **Verify**: `bats tests/chat-format.bats`
  - **Commit**: `test(chat-format): add human-readable format integration test`
  - _Requirements: NFR-5_
  - _Design: Test Coverage Table - Chat format human-readable_

- [ ] 3.15 [VERIFY] Quality Checkpoint: all tests pass
  - **Do**: Run full test suite to verify all tests pass
  - **Verify**: `bats tests/chat-writer.bats tests/chat-reader.bats tests/chat-state.bats tests/floc-state-machine.bats tests/chat-concurrent.bats tests/chat-hold-gate.bats tests/chat-hold-behavior.bats tests/chat-intent-fail.bats tests/chat-heartbeat.bats tests/chat-format.bats`
  - **Done when**: All bats tests pass
  - **Commit**: `chore: pass Phase 3 quality checkpoint`

## Phase 4: Quality Gates

- [ ] 4.1 Lint modified files
  - **Do**:
    1. Run shellcheck on all chat-*.sh scripts
    2. Run bats on all test files
    3. Verify markdownlint on chat.md template
  - **Files**: `plugins/ralph-specum/hooks/scripts/chat-*.sh`, `plugins/ralph-specum/templates/chat.md`
  - **Done when**: All linting passes with no errors
  - **Verify**: `shellcheck plugins/ralph-specum/hooks/scripts/chat-*.sh && echo "SHELLCHECK_OK"`
  - **Commit**: `chore: pass linting on chat scripts`
  - _Requirements: NFR-1, NFR-2_

- [ ] 4.2 Update spec-executor.md version
  - **Do**:
    1. Read `plugins/ralph-specum/agents/spec-executor.md`
    2. Bump version in frontmatter (patch +0.0.1)
    3. Update version in marketplace.json entry for ralph-specum
  - **Files**: `plugins/ralph-specum/agents/spec-executor.md`, `.claude-plugin/marketplace.json`
  - **Done when**: Version bumped correctly
  - **Verify**: `grep "version:" plugins/ralph-specum/agents/spec-executor.md | head -1`
  - **Commit**: `chore: bump spec-executor version for chat protocol`
  - _Requirements: Plugin versioning requirement from CLAUDE.md_

- [ ] 4.3 Update external-reviewer.md version
  - **Do**:
    1. Read `plugins/ralph-specum/agents/external-reviewer.md`
    2. Bump version in frontmatter (patch +0.0.1)
  - **Files**: `plugins/ralph-specum/agents/external-reviewer.md`
  - **Done when**: Version bumped correctly
  - **Verify**: `grep "version:" plugins/ralph-specum/agents/external-reviewer.md | head -1`
  - **Commit**: `chore: bump external-reviewer version for chat protocol`
  - _Requirements: Plugin versioning requirement from CLAUDE.md_

- [ ] 4.4 [VERIFY] Final verification: all tasks complete
  - **Do**:
    1. Verify chat.md template exists and has correct format
    2. Verify chat state in .ralph-state.json works
    3. Verify ChatWriter, ChatReader, ChatHelpers all exist and are syntactically correct
    4. Verify spec-executor.md has Chat Protocol section
    5. Verify external-reviewer.md has FLOC signals
    6. Run all bats tests
  - **Verify**:
    ```bash
    [ -f plugins/ralph-specum/templates/chat.md ] && \
    [ -f plugins/ralph-specum/hooks/scripts/chat-writer.sh ] && \
    [ -f plugins/ralph-specum/hooks/scripts/chat-reader.sh ] && \
    [ -f plugins/ralph-specum/hooks/scripts/chat-helpers.sh ] && \
    grep -q "Chat Protocol" plugins/ralph-specum/agents/spec-executor.md && \
    grep -q "ALIVE" plugins/ralph-specum/agents/external-reviewer.md && \
    bats tests/chat-*.bats && \
    echo "ALL_CHECKS_PASSED"
    ```
  - **Done when**: All verification checks pass
  - **Commit**: `chore: final verification complete`

- [ ] 4.5 Create PR for agent-chat-protocol
  - **Do**:
    1. Verify current branch is a feature branch: `git branch --show-current`
    2. If on default branch, STOP and alert user
    3. Stage all changes: chat-writer.sh, chat-reader.sh, chat-helpers.sh, chat template, spec-executor.md, external-reviewer.md, tests/
    4. Commit with descriptive message
    5. Push branch: `git push -u origin $(git branch --show-current)`
    6. Create PR using gh CLI
  - **Files**: All modified and created files
  - **Done when**: PR created with all changes
  - **Verify**: `gh pr view --json state | jq -r '.state'`
  - **Commit**: `feat(chat-protocol): implement FLOC-based bidirectional chat channel`
  - _Requirements: All functional requirements_

## Notes

- **POC shortcuts taken**: Direct temp-file+rename without fallback to O_APPEND; state stored in .ralph-state.json (not separate .chat-state files as initially designed — changed per design decision to use existing atomic write pattern)
- **Production TODOs**: Chat archival rotation threshold not implemented; DEADLOCK human notification mechanism not specified

## Dependencies

```
Phase 1 (POC) → Phase 2 (Refactor) → Phase 3 (Testing) → Phase 4 (Quality)
```
