---
name: playwright-session
version: 2
description: Load this skill before any Playwright browser interaction in a VE task. Covers session lifecycle, context isolation, and cleanup. Requires playwright-env to be loaded first.
agents: [spec-executor, qa-engineer]
---

# Playwright Session Skill

This skill governs the **session lifecycle** for MCP Playwright interactions. Load it before any VE task that uses browser tools.

**Prerequisite**: `playwright-env.skill.md` must be loaded and resolved before
this skill runs. Session start reads `appUrl`, `authMode`, and related values
from `.ralph-state.json → playwrightEnv` — never from hardcoded values.

---

## Session Lifecycle

### Start

1. Check `mcpPlaywright` in `.ralph-state.json` — if `missing`, switch to degraded mode (see `mcp-playwright.skill.md`)
2. Read `playwrightEnv` from `.ralph-state.json` — use `appUrl`, `browser`, `headless`, `viewport`, `locale`, `timezone`
3. Launch MCP server with correct capability flags (baseline: `--caps=testing`)
4. Open a new browser context — never reuse a context from a previous session
5. If `authMode` is not `none`, complete auth flow (see Auth Flow below) before navigating to the target URL
6. Navigate to the target URL
7. Wait for page to be in a stable state (no pending network requests)

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

## Auth Flow

Read `authMode` from `.ralph-state.json → playwrightEnv`. Then follow the
matching pattern. Credentials come exclusively from environment variables —
never from state files or hardcoded strings.

### `none`
No auth step needed. Navigate directly to `appUrl`.

### `form`
1. Navigate to `loginUrl` (or `appUrl` if not set)
2. `browser_snapshot` → locate username and password fields using `browser_generate_locator`
3. Fill credentials from env vars (`RALPH_LOGIN_USER`, `RALPH_LOGIN_PASS`)
4. Submit the form
5. `browser_snapshot` → confirm authenticated state (absence of login form, presence of authenticated UI)
6. If auth fails → emit `VERIFICATION_FAIL` with diagnosis, do not proceed

### `token`
1. Navigate to `appUrl`
2. Inject token from env var (`RALPH_AUTH_TOKEN`) per the bootstrap rule documented in `playwright-env.local.md`
3. `browser_snapshot` → confirm authenticated state

### `cookie`
1. Before navigating, inject cookie from env vars (`RALPH_SESSION_COOKIE_NAME`, `RALPH_SESSION_COOKIE_VALUE`) into the browser context
2. Navigate to `appUrl`
3. `browser_snapshot` → confirm authenticated state

### `basic`
1. Navigate to `appUrl` with Basic Auth credentials from env vars embedded in the request
2. `browser_snapshot` → confirm page loaded without 401

### `storage-state`
1. Load browser state from `RALPH_STORAGE_STATE_PATH` when creating the context
2. Navigate to `appUrl`
3. `browser_snapshot` → confirm authenticated state (session may have expired — treat expired session as `VERIFICATION_FAIL`)

### `oauth` / `sso`
Agent cannot complete external IdP flows or MFA autonomously.
Emit `ESCALATE` unless a valid `storage-state` has been prepared:

```
ESCALATE
  reason: oauth/sso auth requires pre-authenticated session
  resolution: set authMode=storage-state and provide RALPH_STORAGE_STATE_PATH
```

---

## Context Isolation Rules

| Scenario | Rule |
|---|---|
| Multiple VE tasks in same spec | Same context OK if flows are sequential and related |
| Independent user flows (e.g., logged-in vs logged-out) | Separate contexts — clear state between |
| Parallel VE tasks | Never share context — one context per task |

---

## State Persistence

Reuse the authenticated session within a spec rather than re-authenticating per sub-step:
1. Complete auth flow once at session start
2. `browser_snapshot` to confirm auth state before proceeding to first VE task
3. If auth expires mid-flow, treat as `VERIFICATION_FAIL` (unexpected state) and run diagnostic
4. Do NOT re-authenticate silently — surface the expiry in the failure report

---

## Cleanup Checklist

Before marking any VE task complete:

- [ ] Browser context closed
- [ ] No pending `browser_navigate` or action calls in flight
- [ ] Session status written to `.ralph-state.json`
- [ ] Screenshots saved to `<basePath>/screenshots/` (create dir if absent)
- [ ] Signal emitted (`VERIFICATION_PASS`, `VERIFICATION_FAIL`, or `VERIFICATION_DEGRADED`)
