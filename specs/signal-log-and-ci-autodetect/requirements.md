# Requirements: Signal Event Log + CI Auto-Detection

## Goal

Replace the fragile grep-based HOLD signal detection in chat.md with a structured `signals.jsonl` event log (Gap C2), and auto-detect CI commands from project markers instead of manual discovery from Verification Contract (Gap C4).

## User Stories

### US-1: Structured Control Signal Logging

**As a** coordinator
**I want to** read control signals from a `signals.jsonl` file instead of grep-ing chat.md
**So that** HOLD/PENDING/DEADLOCK detection is 100% mechanical with no false positives

**Acceptance Criteria:**
- AC-1.1: `signals.jsonl` exists in spec path, one JSON object per line with fields: `type`, `signal`, `from`, `to`, `task`, `status`, `timestamp`, `reason`
- AC-1.2: Active control signals (HOLD, PENDING, URGENT, DEADLOCK) are queryable via `jq` filter `select(.status=="active")`
- AC-1.3: Signal resolution appends a new event with `status: resolved` -- original event is never modified
- AC-1.4: Atomic append uses `flock fd 202` -- distinct from chat.md (fd 200) and tasks.md (fd 201)
- AC-1.5: `signals.lastProcessedLine` cursor tracks last read line in spec state

### US-2: CI Command Auto-Detection

**As a** coordinator
**I want to** auto-detect CI commands from project markers at spec start
**So that** I no longer need to manually discover commands from Verification Contract

**Acceptance Criteria:**
- AC-2.1: `detect-ci-commands.sh` script scans project markers and outputs commands as JSON array to `.ralph-state.json` `ciCommands`
- AC-2.2: Detects Python tools via `pyproject.toml`: ruff check, ruff format, mypy, pytest
- AC-2.3: Detects Node tools via `package.json`: pnpm/npm lint, check-types, test
- AC-2.4: Detects Makefile targets: make lint, make test, make check
- AC-2.5: Detects Rust tools via `Cargo.toml`: cargo clippy, test, fmt --check
- AC-2.6: Detects Go tools via `go.mod`: go vet, go test ./...
- AC-2.7: Integrates with existing `discover-ci.sh` (workflows + bats) -- extends, not replaces
- AC-2.8: Falls back to Verification Contract commands if no markers detected

### US-3: Backward Compatibility with chat.md

**As a** external-reviewer
**I want to** emit signals via signals.jsonl while chat.md remains for rich collaboration
**So that** the protocol is backward compatible during transition

**Acceptance Criteria:**
- AC-3.1: Control signals (HOLD, PENDING, DEADLOCK, URGENT, INTENT-FAIL, SPEC-ADJUSTMENT, SPEC-DEFICIENCY) write to signals.jsonl only
- AC-3.2: Collaboration signals (ACK, CONTINUE, OVER, CLOSE, ALIVE, STILL) write to chat.md (existing behavior)
- AC-3.3: Stop-watcher.sh reads signals.jsonl via jq before delegating -- consistent HOLD detection engine-wide
- AC-3.4: chat.md signal legend updated: control signals point to signals.jsonl, collaboration signals remain in chat.md

## Functional Requirements

| ID | Requirement | Priority | Acceptance Criteria |
|----|-------------|----------|---------------------|
| FR-1 | signals.jsonl template with header comment and example events | High | File created in templates/ with documented fields |
| FR-2 | implement.md: replace grep HOLD check with jq on signals.jsonl | High | `jq -r 'select(.signal=="HOLD"...|select(.status=="active")'` used instead of grep |
| FR-3 | detect-ci-commands.sh script in hooks/scripts/ | High | Script detects markers, writes ciCommands to .ralph-state.json |
| FR-4 | Channel map updated: signals.jsonl (fd 202), writers: coordinator/external-reviewer/spec-executor | High | channel-map.md reflects new channel |
| FR-5 | Schema update: add `signals.lastProcessedLine: integer` to spec.schema.json | High | Field exists with type integer, minimum 0, default 0 |
| FR-6 | stop-watcher.sh reads signals.jsonl for HOLD detection | Medium | Consistent detection across all engine components |
| FR-7 | Signals archive when signals.jsonl exceeds 500 lines | Low | Resolved signals archived to `.signals-archive/` |

## Non-Functional Requirements

| ID | Requirement | Metric | Target |
|----|-------------|--------|--------|
| NFR-1 | Performance | signals.jsonl scan time | <50ms for 1000 lines via jq |
| NFR-2 | Reliability | False positive rate for HOLD detection | 0% (jq field filter vs grep text match) |
| NFR-3 | Availability | jq fallback | grep fallback if jq unavailable, with warning log |

## Glossary

- **signals.jsonl**: Append-only JSON Lines file storing control signal events with explicit status field
- **Control signals**: HOLD, PENDING, URGENT, DEADLOCK, INTENT-FAIL, SPEC-ADJUSTMENT, SPEC-DEFICIENCY -- stored in signals.jsonl
- **Collaboration signals**: ACK, CONTINUE, OVER, CLOSE, ALIVE, STILL -- stored in chat.md (existing)
- **detect-ci-commands.sh**: Script that scans project markers to auto-detect CI toolchain commands
- **discover-ci.sh**: Existing script that extracts commands from GitHub workflows and bats test files

## Out of Scope

- chat.md removal or migration (future Spec 7 collaboration-resolution)
- CI command execution (only detection, not running)
- Signal condensation or archival implementation in v1 (FR-7 deferred)
- Schema change from `ciCommands: string[]` to `ciCommands: [{command, category}]`

## Dependencies

- Spec 1 (engine-state-hardening): grep-based HOLD check exists -- replaced by jq approach
- Spec 3 (role-boundaries): Role contracts define who can write signals.jsonl
- Spec 4 (loop-safety-infra): `ciCommands` already exists in schema

## Success Criteria

- `grep '^\[HOLD\]$' chat.md` returns 0 active holds (signals in signals.jsonl only)
- `jq` check for active control signals returns correct count matching signals.jsonl contents
- `detect-ci-commands.sh` populates ciCommands from pyproject.toml, package.json, Makefile, Cargo.toml, or go.mod
- Channel map documents signals.jsonl with fd 202 and correct writers/readers
- Schema includes signals.lastProcessedLine field

## Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| jq unavailable on system | High | Fallback to grep with warning log |
| signals.jsonl grows large (1000+ lines) | Low | Archive resolved signals to .signals-archive/ after 500 lines |
| Agents write malformed JSON to signals.jsonl | Medium | Template with example, validation in append script |
| Race condition writing signals.jsonl | Medium | flock fd 202 (same pattern as chat.md fd 200) |
| detect-ci-commands.sh detects non-existent commands | Low | Verify with `command -v` before adding to ciCommands |

## Verification Contract

> Coordination protocol for signal event log and CI auto-detection

**Project type**: CLI tool / Coordination engine

**Entry points**: `implement.md` (Step 3 pre-loop), `stop-watcher.sh`, `signals.jsonl`

**Observable signals**:
- PASS looks like: `signals.jsonl` contains active signals; `jq` check returns correct count; `ciCommands` populated in `.ralph-state.json`
- FAIL looks like: `grep` on chat.md still finds HOLD markers; `ciCommands` empty after running script

**Hard invariants**:
- signals.jsonl is append-only -- never modify resolved events
- fd 202 lock is distinct from chat.md (200) and tasks.md (201)
- Control signals go to signals.jsonl, collaboration signals go to chat.md

**Seed data**: Empty `signals.jsonl` template with header comment

**Dependency map**: `chat.md` (collaboration signals), `.ralph-state.json` (ciCommands, signals.lastProcessedLine), `signals.jsonl`

**Escalate if**: Malformed JSON detected in signals.jsonl -- requires human to fix corrupted line