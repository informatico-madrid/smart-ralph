---
name: playwright-session
version: 1
description: Load this skill before any Playwright browser interaction in a VE task. Covers session lifecycle, context isolation, and cleanup.
agents: [spec-executor, qa-engineer]
---

# Playwright Session Skill

This skill governs the **session lifecycle** for MCP Playwright interactions. Load it before any VE task that uses browser tools.

---

## Session Lifecycle

### Start

1. Check `mcpPlaywright` in `.ralph-state.json` — if `missing`, switch to degraded mode (see `mcp-playwright.skill.md`)
2. Launch MCP server with correct capability flags (baseline: `--caps=testing`)
3. Open a new browser context — never reuse a context from a previous session
4. Navigate to the target URL
5. Wait for page to be in a stable state (no pending network requests)

### During

- One context per spec — do not share contexts across different specs
- Reset context state between unrelated flows (clear cookies/storage if flows must be independent)
- Always re-snapshot after any navigation or significant DOM mutation before continuing

### End (MANDATORY)

Always close the session, even if verification failed:

```
1. browser_close (or equivalent context close)
2. Verify no orphaned browser processes
3. Write session status to .ralph-state.json:
   jq '.lastPlaywrightSession = "closed"' <basePath>/.ralph-state.json > /tmp/state.json && mv /tmp/state.json <basePath>/.ralph-state.json
```

A leaked browser process will consume memory and interfere with subsequent VE tasks.

---

## Context Isolation Rules

| Scenario | Rule |
|---|---|---|
| Multiple VE tasks in same spec | Same context OK if flows are sequential and related |
| Independent user flows (e.g., logged-in vs logged-out) | Separate contexts — clear state between |
| Parallel VE tasks | Never share context — one context per task |

---

## State Persistence

If a flow requires authentication:
1. Complete the auth flow once in the session
2. Use `browser_snapshot` to confirm auth state before proceeding
3. Do NOT re-authenticate for each sub-step — reuse the session
4. If auth expires mid-flow, treat as `VERIFICATION_FAIL` (unexpected state) and run diagnostic

---

## Cleanup Checklist

Before marking any VE task complete:

- [ ] Browser context closed
- [ ] No pending `browser_navigate` or action calls in flight
- [ ] Session status written to `.ralph-state.json`
- [ ] Screenshots saved to `<basePath>/screenshots/` (create dir if absent)
- [ ] Signal emitted (`VERIFICATION_PASS`, `VERIFICATION_FAIL`, or `VERIFICATION_DEGRADED`)
