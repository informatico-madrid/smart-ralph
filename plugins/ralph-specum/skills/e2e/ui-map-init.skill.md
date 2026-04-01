---
name: ui-map-init
version: 3
description: Load this skill to build the ui-map.local.md selector map before running Playwright tests. Explores the running app, catalogs stable selectors, and writes the map file. Includes invalidation logic and protected-route auth handling.
agents: [spec-executor, qa-engineer]
---

# UI Map Init Skill

This skill builds `ui-map.local.md` — a catalog of stable, verified selectors for the running app. Every Playwright VE task references this map instead of guessing selectors.

---

## When to Run

Run once per spec, as task `VE0`, immediately before the first Playwright VE task.

Before deciding to skip, run the **freshness check** below. A stale or incomplete map is worse than no map — it causes VE tasks to reference locators that no longer exist.

### Freshness Check (replaces simple EXISTS_SKIP)

```bash
MAP_FILE="<basePath>/ui-map.local.md"

if [ ! -f "$MAP_FILE" ]; then
  echo NEEDS_INIT
else
  # Check age: if the map is older than 4 hours, re-generate
  MAP_AGE_HOURS=$(( ( $(date +%s) - $(date -r "$MAP_FILE" +%s) ) / 3600 ))
  if [ "$MAP_AGE_HOURS" -ge 4 ]; then
    echo STALE_REINIT
  else
    echo EXISTS_FRESH
  fi
fi
```

```
NEEDS_INIT    → run ui-map-init now
STALE_REINIT  → delete old map and re-run ui-map-init
EXISTS_FRESH  → skip, proceed to VE tasks
```

**Additional invalidation triggers** — re-run even if the map is fresh:
- `requirements.md` was modified after the map's last-modified timestamp
- The agent observes a `VERIFICATION_FAIL` caused by a stale locator (element not found or wrong element matched)
- The human explicitly requests a map refresh

```bash
# Check if requirements.md is newer than the map
REQ_FILE="<basePath>/requirements.md"
if [ -f "$REQ_FILE" ] && [ "$REQ_FILE" -nt "$MAP_FILE" ]; then
  echo REQUIREMENTS_CHANGED_REINIT
fi
```

---

## Step -1: Resolve Environment Context (MANDATORY FIRST)

Before anything else, load `playwright-env.skill.md` to resolve the browser
execution context.

```
Load: playwright-env.skill.md
```

`playwright-env` will resolve `appUrl`, validate connectivity, run seedCommand
if configured, and write `playwrightEnv` to `.ralph-state.json`.

**Do not proceed to Step 0 if `playwright-env` emits `ESCALATE`.**

This step is identical to Step -1 in `mcp-playwright.skill.md`. If both skills
are loaded in the same VE session, `playwright-env` only needs to run once —
check `.ralph-state.json → playwrightEnv` before re-running.

```bash
jq -r '.playwrightEnv.appUrl // empty' <basePath>/.ralph-state.json
# If non-empty: playwrightEnv already resolved, skip Step -1
# If empty: run playwright-env now
```

---

## Step 0: Dependency Check

After environment context is resolved, verify MCP Playwright is available (read from `.ralph-state.json`):

```bash
jq -r '.mcpPlaywright' <basePath>/.ralph-state.json
```

- `available` → proceed with MCP exploration (Step 1A)
- `missing` → proceed with static exploration (Step 1B)
- key absent → run dependency check from `mcp-playwright.skill.md` Step 0, then re-read

---

## Step 1A: MCP Exploration (Preferred)

### Auth before exploration

Read `authMode` from `.ralph-state.json → playwrightEnv`.

- If `authMode = none`: navigate directly to `appUrl` and begin exploration.
- If `authMode ≠ none`: **complete the auth flow from `playwright-session.skill.md → Auth Flow` before navigating to any route.** Do not attempt to explore protected routes without an authenticated session — the app will redirect to login and the map will be incomplete or consist entirely of login-page selectors.

After auth, confirm the authenticated state with `browser_snapshot` + stable state check before proceeding.

### Exploration steps

1. Navigate to `appUrl` (from `.ralph-state.json → playwrightEnv.appUrl`)
2. `browser_snapshot` → read full accessibility tree
3. For each significant UI region (nav, main, forms, modals, CTAs):
   - `browser_generate_locator` for key interactive elements
   - Record: element type, generated locator, visible text/label, region
4. Navigate to each main route (if discoverable from nav)
5. **Redirect detection**: after each navigation, snapshot and check whether the current URL differs from the target route:
   ```
   Target route: /dashboard
   Actual URL after navigation: /login
     → redirect to login detected
     → do NOT record login-page selectors as belonging to /dashboard
     → document the gap in the map under Notes: "Route /dashboard requires auth — redirected to login during exploration"
     → if authMode=none: emit ESCALATE:
         reason: protected routes discovered during map exploration
         routes: [list of redirected routes]
         resolution: set authMode to the appropriate value in playwright-env.local.md
   ```
6. Repeat snapshot + locator generation per successfully loaded route
7. Write `ui-map.local.md` (see Output Format)

---

## Step 1B: Static Exploration (Degraded)

When MCP is not available:

1. Search source for `data-testid`, `aria-label`, `role`, `id` attributes in templates/JSX/HTML
2. Search for route definitions
3. Build best-effort selector map from source
4. Mark all entries as `source: static` in the map
5. Write `ui-map.local.md` with degradation note

---

## Output Format: ui-map.local.md

```markdown
# UI Map — <spec name>

Generated: <ISO 8601 timestamp>
Source: mcp | static
App URL: <base URL>
Auth used: <authMode value or "none">

## Routes

| Route | Description | Auth required |
|---|---|---|
| / | Home / landing | no |
| /login | Auth entry point | no |
| /dashboard | Main dashboard | yes |

## Selectors

| Region | Element | Locator | Label / Text | Source |
|---|---|---|---|---|
| nav | Logo link | <generated locator> | Home | mcp |
| nav | Login button | <generated locator> | Log in | mcp |
| main | CTA button | <generated locator> | Get started | mcp |
| login form | Email input | <generated locator> | Email | mcp |
| login form | Submit | <generated locator> | Sign in | mcp |

## Notes

- <any anomalies found during exploration>
- <elements with unstable or missing locators>
- <routes that redirected to login — not explored>
```

---

## Rules

- **Never hardcode selectors in VE tasks.** Reference `ui-map.local.md` entries by label.
- **Check freshness before using the map.** A map older than 4 hours or outdated relative to `requirements.md` must be regenerated.
- If a locator in the map becomes stale (element moved/renamed), re-run `ui-map-init` for that route.
- Static-source entries are lower confidence — flag them in verification reports.
- **Never explore protected routes without auth.** Complete auth flow before navigation if `authMode ≠ none`.
- **Document redirect gaps in the map.** If a route redirected during exploration, record it in Notes — do not silently omit it.
- `ui-map.local.md` is a local artifact (`.gitignore` it) — it describes the running instance, not the source of truth.
