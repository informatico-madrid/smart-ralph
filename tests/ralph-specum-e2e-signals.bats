#!/usr/bin/env bats
# Tests for ralph-specum v4.9.3 changes:
#   - VERIFICATION_DEGRADED signal in qa-engineer
#   - EXECUTOR_START signal in spec-executor
#   - Module system detection in playwright-env / spec-executor
#   - E2E anti-patterns canonical reference (new file)
#   - Context auditor skill (new file)
#   - Delegation Contract in coordinator-pattern and executor-prompt
#   - Navigation anti-patterns in playwright-session
#   - Domain-specific skill loading across multiple agents
#   - Subagent timeout recovery in phase-transitions
#   - Version bumps and subagent_type naming fixes

# ---------------------------------------------------------------------------
# Paths (relative to repo root, matching BATS convention)
# ---------------------------------------------------------------------------
PLUGIN_ROOT="plugins/ralph-specum"

QA_ENGINEER="$PLUGIN_ROOT/agents/qa-engineer.md"
SPEC_EXECUTOR="$PLUGIN_ROOT/agents/spec-executor.md"
TASK_PLANNER="$PLUGIN_ROOT/agents/task-planner.md"

START_CMD="$PLUGIN_ROOT/commands/start.md"

COORDINATOR_PATTERN="$PLUGIN_ROOT/references/coordinator-pattern.md"
E2E_ANTI_PATTERNS="$PLUGIN_ROOT/references/e2e-anti-patterns.md"
PHASE_RULES="$PLUGIN_ROOT/references/phase-rules.md"

CONTEXT_AUDITOR="$PLUGIN_ROOT/skills/context-auditor/SKILL.md"
MCP_PLAYWRIGHT="$PLUGIN_ROOT/skills/e2e/mcp-playwright.skill.md"
PLAYWRIGHT_ENV="$PLUGIN_ROOT/skills/e2e/playwright-env.skill.md"
PLAYWRIGHT_SESSION="$PLUGIN_ROOT/skills/e2e/playwright-session.skill.md"
SMART_RALPH="$PLUGIN_ROOT/skills/smart-ralph/SKILL.md"
SPEC_WORKFLOW="$PLUGIN_ROOT/skills/spec-workflow/SKILL.md"
PHASE_TRANSITIONS="$PLUGIN_ROOT/skills/spec-workflow/references/phase-transitions.md"

EXECUTOR_PROMPT="$PLUGIN_ROOT/templates/prompts/executor-prompt.md"
RESEARCH_PROMPT="$PLUGIN_ROOT/templates/prompts/research-prompt.md"

MARKETPLACE_JSON=".claude-plugin/marketplace.json"
PLUGIN_JSON="$PLUGIN_ROOT/.claude-plugin/plugin.json"

# ---------------------------------------------------------------------------
# Version consistency
# ---------------------------------------------------------------------------

@test "marketplace.json ralph-specum version is 4.9.3" {
    version=$(jq -r '.plugins[] | select(.name == "ralph-specum") | .version' "$MARKETPLACE_JSON")
    [ "$version" = "4.9.3" ]
}

@test "plugin.json version is 4.9.3" {
    grep -q '"version": "4.9.3"' "$PLUGIN_JSON"
}

@test "marketplace.json and plugin.json versions are identical" {
    marketplace_ver=$(jq -r '.plugins[] | select(.name == "ralph-specum") | .version' "$MARKETPLACE_JSON")
    plugin_ver=$(jq -r '.version' "$PLUGIN_JSON")
    [ "$marketplace_ver" = "$plugin_ver" ]
}

# ---------------------------------------------------------------------------
# e2e-anti-patterns.md — new file: existence and structure
# ---------------------------------------------------------------------------

@test "e2e-anti-patterns.md exists" {
    [ -f "$E2E_ANTI_PATTERNS" ]
}

@test "e2e-anti-patterns.md declares itself single source of truth" {
    grep -q "single source of truth" "$E2E_ANTI_PATTERNS"
}

@test "e2e-anti-patterns.md has TypeScript Module System Anti-Patterns section" {
    grep -q "## TypeScript Module System Anti-Patterns" "$E2E_ANTI_PATTERNS"
}

@test "e2e-anti-patterns.md has Navigation Anti-Patterns section" {
    grep -q "## Navigation Anti-Patterns" "$E2E_ANTI_PATTERNS"
}

@test "e2e-anti-patterns.md has Selector Anti-Patterns section" {
    grep -q "## Selector Anti-Patterns" "$E2E_ANTI_PATTERNS"
}

@test "e2e-anti-patterns.md has Timing Anti-Patterns section" {
    grep -q "## Timing Anti-Patterns" "$E2E_ANTI_PATTERNS"
}

@test "e2e-anti-patterns.md has Auth Anti-Patterns section" {
    grep -q "## Auth Anti-Patterns" "$E2E_ANTI_PATTERNS"
}

@test "e2e-anti-patterns.md has Test Quality Anti-Patterns section" {
    grep -q "## Test Quality Anti-Patterns" "$E2E_ANTI_PATTERNS"
}

@test "e2e-anti-patterns.md documents fileURLToPath as canonical ESM pattern" {
    grep -q "fileURLToPath" "$E2E_ANTI_PATTERNS"
    grep -q "import\.meta\.url" "$E2E_ANTI_PATTERNS"
}

@test "e2e-anti-patterns.md warns against page.goto for internal routes" {
    grep -q "page.goto" "$E2E_ANTI_PATTERNS"
}

@test "e2e-anti-patterns.md warns against consumed OAuth / auth_callback tokens" {
    grep -q "auth_callback" "$E2E_ANTI_PATTERNS"
}

@test "e2e-anti-patterns.md warns against waitForTimeout" {
    grep -q "waitForTimeout" "$E2E_ANTI_PATTERNS"
}

@test "e2e-anti-patterns.md documents __dirname as ESM anti-pattern" {
    grep -q "__dirname" "$E2E_ANTI_PATTERNS"
}

@test "e2e-anti-patterns.md lists files that use it (used-by header)" {
    grep -q "coordinator-pattern.md" "$E2E_ANTI_PATTERNS"
    grep -q "task-planner.md" "$E2E_ANTI_PATTERNS"
    grep -q "spec-executor.md" "$E2E_ANTI_PATTERNS"
    grep -q "qa-engineer.md" "$E2E_ANTI_PATTERNS"
}

@test "e2e-anti-patterns.md provides reference path for delegation prompts" {
    grep -q 'CLAUDE_PLUGIN_ROOT.*references/e2e-anti-patterns.md' "$E2E_ANTI_PATTERNS"
}

# ---------------------------------------------------------------------------
# context-auditor/SKILL.md — new file: existence and structure
# ---------------------------------------------------------------------------

@test "context-auditor SKILL.md exists" {
    [ -f "$CONTEXT_AUDITOR" ]
}

@test "context-auditor SKILL.md has correct name in frontmatter" {
    grep -q "^name: context-auditor" "$CONTEXT_AUDITOR"
}

@test "context-auditor SKILL.md has version 1.0.0" {
    grep -q "^version: 1.0.0" "$CONTEXT_AUDITOR"
}

@test "context-auditor SKILL.md is marked non-user-invocable" {
    grep -q "^user-invocable: false" "$CONTEXT_AUDITOR"
}

@test "context-auditor SKILL.md documents unconditional activation rule" {
    grep -q "ALWAYS invoke" "$CONTEXT_AUDITOR"
    grep -q "No keyword matching" "$CONTEXT_AUDITOR"
}

@test "context-auditor SKILL.md has algorithm with all 5 steps" {
    grep -q "### Step 1" "$CONTEXT_AUDITOR"
    grep -q "### Step 2" "$CONTEXT_AUDITOR"
    grep -q "### Step 3" "$CONTEXT_AUDITOR"
    grep -q "### Step 4" "$CONTEXT_AUDITOR"
    grep -q "### Step 5" "$CONTEXT_AUDITOR"
}

@test "context-auditor SKILL.md documents AUDIT_CLEAN signal" {
    grep -q "AUDIT_CLEAN" "$CONTEXT_AUDITOR"
}

@test "context-auditor SKILL.md documents AUDIT_WARNINGS signal" {
    grep -q "AUDIT_WARNINGS" "$CONTEXT_AUDITOR"
}

@test "context-auditor SKILL.md does NOT block spec execution on warnings" {
    grep -q "Do NOT block spec execution" "$CONTEXT_AUDITOR"
}

@test "context-auditor SKILL.md enforced by start.md reference" {
    grep -q "start.md" "$CONTEXT_AUDITOR"
}

@test "context-auditor SKILL.md classifies assertion types: FILESYSTEM URL COMMAND ENV SCRIPT" {
    grep -q "FILESYSTEM" "$CONTEXT_AUDITOR"
    grep -q "COMMAND" "$CONTEXT_AUDITOR"
    grep -q "ENV" "$CONTEXT_AUDITOR"
    grep -q "SCRIPT" "$CONTEXT_AUDITOR"
}

# ---------------------------------------------------------------------------
# qa-engineer.md — VERIFICATION_DEGRADED signal
# ---------------------------------------------------------------------------

@test "qa-engineer description includes VERIFICATION_DEGRADED" {
    # The frontmatter description must list all three signals
    grep -q "VERIFICATION_DEGRADED" "$QA_ENGINEER"
}

@test "qa-engineer body text lists VERIFICATION_DEGRADED as output option" {
    grep -q "output VERIFICATION_PASS, VERIFICATION_FAIL, or VERIFICATION_DEGRADED" "$QA_ENGINEER"
}

@test "qa-engineer documents tool prerequisite missing condition for DEGRADED" {
    grep -q "Tool prerequisite missing" "$QA_ENGINEER"
}

@test "qa-engineer VERIFICATION_DEGRADED conditions block exists" {
    grep -q "VERIFICATION_DEGRADED conditions" "$QA_ENGINEER"
}

@test "qa-engineer documents DEGRADED is not FAIL semantics" {
    grep -q "DEGRADED.*FAIL\|DEGRADED ≠ FAIL" "$QA_ENGINEER"
}

@test "qa-engineer documents mcp-playwright-missing as DEGRADED reason" {
    grep -q "mcp-playwright-missing" "$QA_ENGINEER"
}

@test "qa-engineer decision table maps MCP tool not installed to VERIFICATION_DEGRADED" {
    grep -q "MCP tool not installed" "$QA_ENGINEER"
    grep -q "VERIFICATION_DEGRADED" "$QA_ENGINEER"
}

@test "qa-engineer documents DEGRADED bypasses repair loop" {
    grep -q "bypass.*repair\|repair loop" "$QA_ENGINEER"
}

@test "qa-engineer E2E Source-of-Truth Protocol section exists" {
    grep -q "Source-of-Truth Protocol" "$QA_ENGINEER"
}

@test "qa-engineer regex pattern uses escaped quotes" {
    # The fix changes ['"] (old) to ['\"] (new) — adds backslash before double-quote
    # Use fixed-string (-F) to match the literal backslash in the character class
    grep -qF "['\\\"]" "$QA_ENGINEER"
}

# ---------------------------------------------------------------------------
# spec-executor.md — EXECUTOR_START signal and module system detection
# ---------------------------------------------------------------------------

@test "spec-executor.md version is 0.4.7" {
    grep -q "^version: 0.4.7" "$SPEC_EXECUTOR"
}

@test "spec-executor.md documents EXECUTOR_START signal" {
    grep -q "EXECUTOR_START" "$SPEC_EXECUTOR"
}

@test "spec-executor.md EXECUTOR_START is mandatory first output" {
    grep -q "MANDATORY FIRST OUTPUT\|VERY FIRST output" "$SPEC_EXECUTOR"
}

@test "spec-executor.md escalates with executor-not-invoked reason when EXECUTOR_START absent" {
    grep -q "executor-not-invoked" "$SPEC_EXECUTOR"
}

@test "spec-executor.md documents Module System Detection section" {
    grep -q "Module System Detection" "$SPEC_EXECUTOR"
}

@test "spec-executor.md documents fileURLToPath as correct ESM pattern" {
    grep -q "fileURLToPath" "$SPEC_EXECUTOR"
}

@test "spec-executor.md documents __dirname as wrong for ESM" {
    grep -q "__dirname" "$SPEC_EXECUTOR"
}

@test "spec-executor.md documents VE Task Consult Before Write Protocol" {
    grep -q "Consult Before Write" "$SPEC_EXECUTOR"
}

@test "spec-executor.md VE protocol requires reading design.md Test Strategy first" {
    grep -q "design.md" "$SPEC_EXECUTOR"
    grep -q "Test Strategy" "$SPEC_EXECUTOR"
}

@test "spec-executor.md VE protocol requires reading Delegation Contract" {
    grep -q "Delegation Contract" "$SPEC_EXECUTOR"
}

@test "spec-executor.md documents domain-specific selector map for Home Assistant" {
    grep -q "homeassistant-selector-map" "$SPEC_EXECUTOR"
}

@test "spec-executor.md VE0 signal handling documents VERIFICATION_FAIL as ESCALATE trigger" {
    grep -q "VERIFICATION_FAIL.*ESCALATE\|ESCALATE.*cannot run VE1" "$SPEC_EXECUTOR"
}

@test "spec-executor.md module detection uses jq to read package.json type" {
    grep -q "jq.*\.type.*commonjs\|jq.*package\.json" "$SPEC_EXECUTOR"
}

@test "spec-executor.md propagates module type to .progress.md" {
    grep -q "\.progress\.md" "$SPEC_EXECUTOR"
    grep -q "Module System" "$SPEC_EXECUTOR"
}

# ---------------------------------------------------------------------------
# task-planner.md — full E2E skill chain
# ---------------------------------------------------------------------------

@test "task-planner.md VE tasks reference playwright-env skill" {
    grep -q "playwright-env.skill.md" "$TASK_PLANNER"
}

@test "task-planner.md VE tasks reference mcp-playwright skill" {
    grep -q "mcp-playwright.skill.md" "$TASK_PLANNER"
}

@test "task-planner.md VE tasks reference playwright-session skill" {
    grep -q "playwright-session.skill.md" "$TASK_PLANNER"
}

@test "task-planner.md VE tasks require Anti-Patterns field" {
    grep -q "Anti-Patterns" "$TASK_PLANNER"
    grep -q "e2e-anti-patterns.md" "$TASK_PLANNER"
}

@test "task-planner.md skill chain described as full E2E skill chain" {
    grep -q "full E2E skill chain" "$TASK_PLANNER"
}

@test "task-planner.md subagents execute in isolation rationale documented" {
    grep -q "Subagents receive tasks in isolation\|subagent.*isolation\|fresh context" "$TASK_PLANNER"
}

# ---------------------------------------------------------------------------
# start.md — mandatory context-auditor invocation
# ---------------------------------------------------------------------------

@test "start.md has mandatory pre-scan Context Audit step" {
    grep -q "Mandatory pre-scan.*Context Audit\|mandatory.*context-auditor" "$START_CMD"
}

@test "start.md invokes context-auditor skill unconditionally" {
    grep -q "ralph-specum:context-auditor" "$START_CMD"
}

@test "start.md documents context-auditor as always-invoked" {
    grep -q "always-invoked" "$START_CMD"
}

@test "start.md context-auditor step is numbered 0 (before semantic matching)" {
    # Step 0 must appear before step 1 in the skill discovery pass
    line_zero=$(grep -n "Mandatory pre-scan" "$START_CMD" | head -1 | cut -d: -f1)
    line_one=$(grep -n "Scan SKILL.md files from all skill paths" "$START_CMD" | head -1 | cut -d: -f1)
    [ -n "$line_zero" ] && [ -n "$line_one" ]
    [ "$line_zero" -lt "$line_one" ]
}

# ---------------------------------------------------------------------------
# coordinator-pattern.md — EXECUTOR_START verification and Delegation Contract
# ---------------------------------------------------------------------------

@test "coordinator-pattern.md has EXECUTOR_START Verification section" {
    grep -q "EXECUTOR_START Verification" "$COORDINATOR_PATTERN"
}

@test "coordinator-pattern.md escalates on missing EXECUTOR_START" {
    grep -q "EXECUTOR_START.*absent\|absent.*EXECUTOR_START" "$COORDINATOR_PATTERN"
}

@test "coordinator-pattern.md escalates with executor-not-invoked reason" {
    grep -q "executor-not-invoked" "$COORDINATOR_PATTERN"
}

@test "coordinator-pattern.md documents coordinator self-implementation as anti-pattern" {
    grep -q "coordinator self-implementation\|coordinator.*self.*implement" "$COORDINATOR_PATTERN"
}

@test "coordinator-pattern.md Delegation Contract exists in VERIFY task template" {
    grep -q "Delegation Contract" "$COORDINATOR_PATTERN"
}

@test "coordinator-pattern.md Delegation Contract has Design Decisions section" {
    grep -q "Design Decisions" "$COORDINATOR_PATTERN"
}

@test "coordinator-pattern.md Delegation Contract has Anti-Patterns section" {
    grep -q "Anti-Patterns (DO NOT)" "$COORDINATOR_PATTERN"
}

@test "coordinator-pattern.md Delegation Contract has Required Skills section" {
    grep -q "Required Skills" "$COORDINATOR_PATTERN"
}

@test "coordinator-pattern.md Delegation Contract has Success Criteria section" {
    grep -q "Success Criteria" "$COORDINATOR_PATTERN"
}

@test "coordinator-pattern.md Delegation Contract is mandatory for VE tasks" {
    grep -q "MANDATORY for VE tasks\|contract is MANDATORY" "$COORDINATOR_PATTERN"
}

# ---------------------------------------------------------------------------
# playwright-session.skill.md — navigation anti-patterns
# ---------------------------------------------------------------------------

@test "playwright-session.skill.md version is 9" {
    grep -q "^version: 9$" "$PLAYWRIGHT_SESSION"
}

@test "playwright-session.skill.md has Navigation Anti-Patterns section" {
    grep -q "## Navigation Anti-Patterns" "$PLAYWRIGHT_SESSION"
}

@test "playwright-session.skill.md warns against page.goto for internal routes" {
    grep -q "NEVER use.*page\.goto.*internal\|goto.*internal.*routes" "$PLAYWRIGHT_SESSION"
}

@test "playwright-session.skill.md documents TimeoutError as consequence of goto anti-pattern" {
    grep -q "TimeoutError" "$PLAYWRIGHT_SESSION"
}

@test "playwright-session.skill.md warns against consumed OAuth auth_callback tokens" {
    grep -q "auth_callback" "$PLAYWRIGHT_SESSION"
    grep -q "consumed" "$PLAYWRIGHT_SESSION"
}

@test "playwright-session.skill.md documents new URL origin as correct OAuth fix" {
    grep -q "new URL.*\.origin" "$PLAYWRIGHT_SESSION"
}

@test "playwright-session.skill.md warns against duplicate waitForURL calls" {
    grep -q "duplicate.*waitForURL\|waitForURL.*duplicate\|NEVER duplicate" "$PLAYWRIGHT_SESSION"
}

@test "playwright-session.skill.md references homeassistant-selector-map for HA navigation" {
    grep -q "homeassistant-selector-map" "$PLAYWRIGHT_SESSION"
}

@test "playwright-session.skill.md documents base URL goto exception" {
    grep -q "base URL.*correct\|Exception.*base URL\|goto.*base.*correct" "$PLAYWRIGHT_SESSION"
}

# ---------------------------------------------------------------------------
# playwright-env.skill.md — module system detection
# ---------------------------------------------------------------------------

@test "playwright-env.skill.md version is 10" {
    grep -q "^version: 10$" "$PLAYWRIGHT_ENV"
}

@test "playwright-env.skill.md has Module System Detection section" {
    grep -q "## Module System Detection" "$PLAYWRIGHT_ENV"
}

@test "playwright-env.skill.md stores moduleType in playwrightEnv state" {
    grep -q '"moduleType"' "$PLAYWRIGHT_ENV"
}

@test "playwright-env.skill.md documents ESM vs CJS detection via package.json" {
    grep -q "package\.json" "$PLAYWRIGHT_ENV"
    grep -q '"type".*"module"\|"module".*commonjs' "$PLAYWRIGHT_ENV"
}

@test "playwright-env.skill.md has Domain-Specific Resources section" {
    grep -q "## Domain-Specific Resources" "$PLAYWRIGHT_ENV"
}

@test "playwright-env.skill.md references homeassistant-selector-map for HA projects" {
    grep -q "homeassistant-selector-map" "$PLAYWRIGHT_ENV"
}

@test "playwright-env.skill.md Done When checklist includes moduleType detection" {
    grep -q "moduleType.*detected\|moduleType.*written" "$PLAYWRIGHT_ENV"
}

@test "playwright-env.skill.md references e2e-anti-patterns.md for module system mistakes" {
    grep -q "e2e-anti-patterns.md" "$PLAYWRIGHT_ENV"
}

# ---------------------------------------------------------------------------
# mcp-playwright.skill.md — version and anti-pattern additions
# ---------------------------------------------------------------------------

@test "mcp-playwright.skill.md version is 8" {
    grep -q "^version: 8$" "$MCP_PLAYWRIGHT"
}

@test "mcp-playwright.skill.md warns against page.goto for internal app routes" {
    grep -q "Never use.*page\.goto.*internal\|goto.*internal.*routes" "$MCP_PLAYWRIGHT"
}

@test "mcp-playwright.skill.md warns against waitForTimeout" {
    grep -q "Never use.*waitForTimeout\(\)" "$MCP_PLAYWRIGHT"
}

@test "mcp-playwright.skill.md warns against auth_callback navigation" {
    grep -q "auth_callback" "$MCP_PLAYWRIGHT"
}

@test "mcp-playwright.skill.md warns against inventing selectors from memory" {
    grep -q "Never invent selectors" "$MCP_PLAYWRIGHT"
}

@test "mcp-playwright.skill.md warns against duplicate waitForURL calls" {
    grep -q "Never write duplicate.*waitForURL" "$MCP_PLAYWRIGHT"
}

@test "mcp-playwright.skill.md has Domain-Specific Resources section" {
    grep -q "## Domain-Specific Resources" "$MCP_PLAYWRIGHT"
}

@test "mcp-playwright.skill.md references homeassistant-selector-map in domain table" {
    grep -q "homeassistant-selector-map.skill.md" "$MCP_PLAYWRIGHT"
}

# ---------------------------------------------------------------------------
# smart-ralph/SKILL.md — delegation contract and version
# ---------------------------------------------------------------------------

@test "smart-ralph SKILL.md version is 0.3.0" {
    grep -q "^version: 0.3.0" "$SMART_RALPH"
}

@test "smart-ralph SKILL.md has Delegation Contract section" {
    grep -q "### Delegation Contract" "$SMART_RALPH"
}

@test "smart-ralph SKILL.md Delegation Contract is mandatory for VE/Test tasks" {
    grep -q "MANDATORY for VE" "$SMART_RALPH"
}

@test "smart-ralph SKILL.md documents four contract components" {
    grep -q "Design Decisions" "$SMART_RALPH"
    grep -q "Anti-Patterns" "$SMART_RALPH"
    grep -q "Required Skills" "$SMART_RALPH"
    grep -q "Success Criteria" "$SMART_RALPH"
}

@test "smart-ralph SKILL.md explains why contract is needed (fresh context)" {
    grep -q "fresh context\|no memory" "$SMART_RALPH"
}

@test "smart-ralph SKILL.md references coordinator-pattern.md for contract template" {
    grep -q "coordinator-pattern.md" "$SMART_RALPH"
}

# ---------------------------------------------------------------------------
# spec-workflow/SKILL.md — domain-specific skill loading and version
# ---------------------------------------------------------------------------

@test "spec-workflow SKILL.md version is 0.3.2" {
    grep -q "^version: 0.3.2" "$SPEC_WORKFLOW"
}

@test "spec-workflow SKILL.md has Domain-Specific Skill Loading section" {
    grep -q "### Domain-Specific Skill Loading" "$SPEC_WORKFLOW"
}

@test "spec-workflow SKILL.md maps Home Assistant to homeassistant-selector-map skill" {
    grep -q "homeassistant-selector-map.skill.md" "$SPEC_WORKFLOW"
}

@test "spec-workflow SKILL.md documents HA detection signals" {
    grep -q "hass\|home-assistant\|lovelace" "$SPEC_WORKFLOW"
}

# ---------------------------------------------------------------------------
# phase-transitions.md — subagent timeout recovery protocol
# ---------------------------------------------------------------------------

@test "phase-transitions.md has Subagent Timeout and Recovery Protocol section" {
    grep -q "## Subagent Timeout and Recovery Protocol" "$PHASE_TRANSITIONS"
}

@test "phase-transitions.md documents timeout detection threshold" {
    grep -q "5.*minutes\|5+.*minutes" "$PHASE_TRANSITIONS"
}

@test "phase-transitions.md documents first retry step" {
    grep -q "First retry\|Re-delegate" "$PHASE_TRANSITIONS"
}

@test "phase-transitions.md documents blocked task status format" {
    grep -q "TIMEOUT" "$PHASE_TRANSITIONS"
}

@test "phase-transitions.md prohibits fabricating output for timed-out subagent" {
    grep -q "Never fabricate\|fabricate.*timed" "$PHASE_TRANSITIONS"
}

@test "phase-transitions.md documents post-sprint retry for timed-out tasks" {
    grep -q "Post-sprint retry\|after completing remaining" "$PHASE_TRANSITIONS"
}

# ---------------------------------------------------------------------------
# executor-prompt.md — Delegation Contract template and subagent_type fix
# ---------------------------------------------------------------------------

@test "executor-prompt.md subagent_type is bare spec-executor (not plugin-qualified)" {
    grep -q "subagent_type.*\`spec-executor\`" "$EXECUTOR_PROMPT"
    # Must NOT use the plugin-qualified form for subagent_type value
    ! grep -E "^\s*-\s+\*\*subagent_type:\*\*\s+\`ralph-specum:spec-executor\`" "$EXECUTOR_PROMPT"
}

@test "executor-prompt.md includes note explaining bare name convention" {
    grep -q "ralph-specum:spec-executor.*routing\|bare agent name\|plugin-qualified.*routing failure" "$EXECUTOR_PROMPT"
}

@test "executor-prompt.md has Delegation Contract section" {
    grep -q "## Delegation Contract" "$EXECUTOR_PROMPT"
}

@test "executor-prompt.md Delegation Contract includes all four placeholder fields" {
    grep -q "{DESIGN_DECISIONS}" "$EXECUTOR_PROMPT"
    grep -q "{ANTI_PATTERNS}" "$EXECUTOR_PROMPT"
    grep -q "{REQUIRED_SKILLS}" "$EXECUTOR_PROMPT"
    grep -q "{SUCCESS_CRITERIA}" "$EXECUTOR_PROMPT"
}

@test "executor-prompt.md placeholder list in header includes new contract fields" {
    grep -q "{DESIGN_DECISIONS}.*{ANTI_PATTERNS}.*{REQUIRED_SKILLS}.*{SUCCESS_CRITERIA}" "$EXECUTOR_PROMPT"
}

@test "executor-prompt.md instructions require reading design.md Test Strategy before tests" {
    grep -q "design.md.*Test Strategy\|Test Strategy.*design.md" "$EXECUTOR_PROMPT"
}

@test "executor-prompt.md instructions require loading skill files before writing E2E code" {
    grep -q "load all skills\|load.*skills.*Required Skills\|Skills.*before writing" "$EXECUTOR_PROMPT"
}

@test "executor-prompt.md instructions require consulting skill files and ui-map.local.md for selectors" {
    grep -q "ui-map.local.md" "$EXECUTOR_PROMPT"
}

# ---------------------------------------------------------------------------
# research-prompt.md — subagent_type naming fix
# ---------------------------------------------------------------------------

@test "research-prompt.md subagent_type is bare research-analyst (not plugin-qualified)" {
    grep -q "subagent_type.*\`research-analyst\`" "$RESEARCH_PROMPT"
    ! grep -E "^\s*-\s+\*\*subagent_type:\*\*\s+\`ralph-specum:research-analyst\`" "$RESEARCH_PROMPT"
}

# ---------------------------------------------------------------------------
# phase-rules.md — URL verification note
# ---------------------------------------------------------------------------

@test "phase-rules.md Phase 3 includes URL verification note" {
    grep -q "verify how that URL is constructed\|Do not assume URLs from requirements" "$PHASE_RULES"
}

# ---------------------------------------------------------------------------
# Cross-reference integrity: referenced files must exist
# ---------------------------------------------------------------------------

@test "e2e-anti-patterns.md file referenced in coordinator-pattern.md actually exists" {
    grep -q "e2e-anti-patterns.md" "$COORDINATOR_PATTERN"
    [ -f "$E2E_ANTI_PATTERNS" ]
}

@test "context-auditor SKILL.md referenced in start.md actually exists" {
    grep -q "context-auditor" "$START_CMD"
    [ -f "$CONTEXT_AUDITOR" ]
}

@test "homeassistant-selector-map.skill.md referenced in playwright-env actually exists" {
    grep -q "homeassistant-selector-map.skill.md" "$PLAYWRIGHT_ENV"
    [ -f "$PLUGIN_ROOT/skills/e2e/examples/homeassistant-selector-map.skill.md" ]
}

@test "homeassistant-selector-map.skill.md referenced in mcp-playwright actually exists" {
    grep -q "homeassistant-selector-map.skill.md" "$MCP_PLAYWRIGHT"
    [ -f "$PLUGIN_ROOT/skills/e2e/examples/homeassistant-selector-map.skill.md" ]
}

@test "homeassistant-selector-map.skill.md referenced in playwright-session actually exists" {
    grep -q "homeassistant-selector-map" "$PLAYWRIGHT_SESSION"
    [ -f "$PLUGIN_ROOT/skills/e2e/examples/homeassistant-selector-map.skill.md" ]
}

@test "homeassistant-selector-map.skill.md referenced in task-planner actually exists" {
    grep -q "homeassistant-selector-map" "$TASK_PLANNER"
    [ -f "$PLUGIN_ROOT/skills/e2e/examples/homeassistant-selector-map.skill.md" ]
}

@test "phase-transitions.md referenced from spec-workflow SKILL.md actually exists" {
    grep -q "phase-transitions" "$SPEC_WORKFLOW"
    [ -f "$PHASE_TRANSITIONS" ]
}

# ---------------------------------------------------------------------------
# Regression: old plugin-qualified subagent_type must not appear in prompts
# ---------------------------------------------------------------------------

@test "executor-prompt.md does not use ralph-specum:spec-executor as subagent_type value" {
    ! grep -E "\*\*subagent_type:\*\*\s+\`ralph-specum:spec-executor\`" "$EXECUTOR_PROMPT"
}

@test "research-prompt.md does not use ralph-specum:research-analyst as subagent_type value" {
    ! grep -E "\*\*subagent_type:\*\*\s+\`ralph-specum:research-analyst\`" "$RESEARCH_PROMPT"
}

# ---------------------------------------------------------------------------
# Boundary / negative cases
# ---------------------------------------------------------------------------

@test "qa-engineer does NOT emit VERIFICATION_DEGRADED for command failures" {
    grep -q "Do NOT emit VERIFICATION_DEGRADED for command failures" "$QA_ENGINEER"
}

@test "qa-engineer DEGRADED is exclusive to e2e skills (not general verification)" {
    grep -q "Emitted exclusively from e2e skills" "$QA_ENGINEER"
}

@test "spec-executor does NOT allow coordinator to implement tasks directly" {
    grep -q "Do NOT implement tasks directly\|coordinator.*ESCALATE\|implement.*directly.*forbidden" "$SPEC_EXECUTOR"
}

@test "context-auditor does NOT read env file content (only checks existence)" {
    grep -q "Do NOT read the content\|check existence only" "$CONTEXT_AUDITOR"
}

@test "context-auditor does NOT make network requests to verify URLs" {
    grep -q "Do NOT make network requests\|NOT attempt network" "$CONTEXT_AUDITOR"
}

@test "playwright-session.skill.md exception allows page.goto to base URL" {
    grep -q "Exception.*base URL\|base URL.*app root.*correct" "$PLAYWRIGHT_SESSION"
}