<h2><a href="https://github.com/Nayjest/Gito"><img src="https://raw.githubusercontent.com/Nayjest/Gito/main/press-kit/logo/gito-bot-1_64top.png" align="left" width=64 height=50 title="Gito v4.0.3"/></a>I've Reviewed the Code</h2>



This comprehensive rename to `RalphHarness` successfully standardizes the project's branding and slash-command structure across the spec-driven agent workflow, but requires cleanup of several trailing naming inconsistencies, typos, and minor script logic flaws to ensure full documentation accuracy and prevent runtime parsing confusion.

**⚠️ 32 issues found** across 282 files
## `#1`  Inconsistent project naming in documentation
[CONTRIBUTING.md L1](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/CONTRIBUTING.md#L1)

    
The document header refers to the project as "Smart Ralph", but all setup commands, directory structures, and slash commands now use "RalphHarness". This inconsistency will confuse contributors following the guide. Update the title to match the new project name.
**Tags: readability, naming**
**Affected code:**
```markdown
1: # Contributing to Smart Ralph
```
**Proposed change:**
```markdown
# Contributing to RalphHarness
```

## `#2`  Naming inconsistency/typo in Goal statement
[docs/plans/2026-02-20-brainstorming-style-interviews-plan.md L5](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/docs/plans/2026-02-20-brainstorming-style-interviews-plan.md#L5)

    
The diff replaces 'Ralph Specum' with 'RalphHarness' in the Goal line, but the rest of the document (file paths like `plugins/ralph-specum/...`, commit messages, etc.) consistently uses 'ralph-specum'. This appears to be a typo that introduces a confusing inconsistency. It should be corrected to 'Ralph Specum' to match the rest of the codebase context.
**Tags: naming, readability**
**Affected code:**
```markdown
5: **Goal:** Replace fixed question pool interviews with adaptive brainstorming-style dialogue across all 4 RalphHarness phases.
```
**Proposed change:**
```markdown
**Goal:** Replace fixed question pool interviews with adaptive brainstorming-style dialogue across all 4 Ralph Specum phases.
```

## `#3`  Typo in file paths and variable references (`ralh` -> `ralph`)
[platforms/codex/skills/ralphharness-research/agents/openai.yaml L1-L6](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/platforms/codex/skills/ralphharness-research/agents/openai.yaml#L1-L6)

    
The provided diff contains `ralh-specum-research` and `ralharness-research` in both the file rename paths and the `default_prompt` variable reference. The missing 'p' in 'Ralph' will cause file resolution failures or incorrect variable interpolation within the plugin system. Additionally, 'Specum' appears to be a typo for 'Spec', which is inconsistent with the project's spec-driven development focus.
**Tags: naming, typo**
**Affected code:**
```yaml
1: interface:
2:   display_name: "RalphHarness Research"
3:   short_description: "Generate research for an active spec"
4:   default_prompt: "Use $ralphharness-research to write research.md, then ask me to `approve current artifact`, `request changes`, or `continue to requirements`."
5: policy:
6:   allow_implicit_invocation: false
```
**Proposed change:**
```yaml
interface:
  display_name: "RalphHarness Research"
  short_description: "Generate research for an active spec"
  default_prompt: "Use $ralphharness-research to write research.md, then ask me to `approve current artifact`, `request changes`, or `continue to requirements`."
policy:
  allow_implicit_invocation: false
```

## `#4`  Typographical error in response handoff instructions
[platforms/codex/skills/ralphharness-tasks/SKILL.md L43](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/platforms/codex/skills/ralphharness-tasks/SKILL.md#L43)

    
Line 43 contains a duplicated term: '- After writing `tasks.md`, name `tasks.md` and summarize the task plan briefly.' This is redundant and likely a copy-paste typo. It should probably read 'name **the output** `tasks.md`' or 'name **the artifact** `tasks.md`' to clearly instruct the agent.
**Tags: readability, language**
**Affected code:**
```markdown
43: - After writing `tasks.md`, name `tasks.md` and summarize the task plan briefly.
```
**Proposed change:**
```markdown
  - After writing `tasks.md`, name **the output** `tasks.md` and summarize the task plan briefly.
```

## `#5`  Documentation inconsistency: states 5 phases but lists 4
[platforms/codex/skills/ralphharness/assets/templates/tasks.md L6](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/platforms/codex/skills/ralphharness/assets/templates/tasks.md#L6)

    
Line 6 incorrectly states 'POC-first workflow with 5 phases:' after Phase 4 and Phase 5 were merged into a single combined phase. The subsequent numbered list only enumerates 4 phases. This should be updated to '4 phases' to maintain consistency with the actual workflow structure.
**Tags: readability, maintainability**
**Affected code:**
```markdown
6: POC-first workflow with 5 phases:
```
**Proposed change:**
```markdown
POC-first workflow with 4 phases:
```

## `#6`  Inconsistent naming for configuration fields in documentation
[platforms/codex/skills/ralphharness/references/state-contract.md L59](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/platforms/codex/skills/ralphharness/references/state-contract.md#L59)

    
Line 59 references `default_max_iterations` and `auto_commit_spec` using snake_case, which conflicts with the camelCase JSON state fields defined in the same file (`maxGlobalIterations`/`maxTaskIterations` and `commitSpec`). This mismatch creates ambiguity and will likely cause runtime errors or misconfiguration if the parser expects exact key names from the schema or if users copy-paste the documented names.
**Tags: naming, bug, language**
**Affected code:**
```markdown
59: Read `default_max_iterations` and `auto_commit_spec` from `.claude/ralphharness.local.md` when present.
```
**Proposed change:**
```markdown
Read `maxGlobalIterations` and `commitSpec` from `.claude/ralphharness.local.md` when present.
```

## `#7`  Incorrect NFR line counting due to overly broad grep pattern
[plugins/ralphharness-bmad-bridge/scripts/import.sh L738](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness-bmad-bridge/scripts/import.sh#L738)

    
The original regex `'| '` matches any line containing a pipe and space, which can incorrectly count table headers, separators, or unrelated lines. The updated pattern `'^| NFR-'` strictly matches the generated NFR table rows (e.g., `| NFR-1 | ...`), ensuring accurate counting for the final summary report.
**Tags: bug**
**Affected code:**
```bash
738:                 nfr_lines=$(grep -c '^| NFR-' "$NFR_TMP" 2>/dev/null || true)
```
**Proposed change:**
```bash
                nfr_lines=$(grep -c '^| NFR-' "$NFR_TMP" 2>/dev/null || true)
```

## `#8`  Incorrect variable quoting in `bash -c` blocks prevents sourcing the import script
[plugins/ralphharness-bmad-bridge/tests/test-import.sh L365-L369,L438-L442,L481-L484](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness-bmad-bridge/tests/test-import.sh#L365-L369)

    
In test scripts `t311.sh`, `t313.sh`, and `t314.sh`, the `bash -c` command wraps sourcing the import script and calling test functions. However, variables like `$import_sh` and `$td` are enclosed in single quotes inside the double-quoted `bash -c` string (e.g., `source '$import_sh'`). In Bash, single quotes inside double quotes prevent variable expansion, meaning the script attempts to source a file literally named `$import_sh` instead of the intended path. This will cause the tests to fail during sourcing. Additionally, using `bash -c` here is unnecessary and introduces complex quoting requirements. It should be replaced with direct execution since the variables are already defined in the outer script scope.
**Tags: bug, code-style**
**Affected code:**
```bash
365: EPICEOF
366: bash -c "
367: source '$import_sh'
368: parse_epics '$td/epics.md' '$td/tasks.md' 2>/dev/null
369: " || rc=$?
```
**Proposed change:**
```bash
    source "$import_sh"
    parse_epics "$td/epics.md" "$td/tasks.md" 2>/dev/null
    rc=$?
```
**Affected code:**
```bash
438: bash -c "
439: source '$import_sh'
440: parse_prd_frs '$td/prd.md' '$td/reqs.md' 2>/dev/null
441: exit 0
442: "
```
**Proposed change:**
```bash
    source "$import_sh"
    parse_prd_frs "$td/prd.md" "$td/reqs.md" 2>/dev/null
    exit 0
```
**Affected code:**
```bash
481: bash -c "
482: source '$import_sh'
483: parse_epics '$td/epics.md' '$td/tasks.md' 2>/dev/null
484: " || rc=$?
```
**Proposed change:**
```bash
    source "$import_sh"
    parse_epics "$td/epics.md" "$td/tasks.md" 2>/dev/null
    rc=$?
```

## `#9`  Inconsistent property naming conventions across schema definitions
[plugins/ralphharness-codex/schemas/spec.schema.json L271-L273,L283-L287,L434-L438,L438-L442](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness-codex/schemas/spec.schema.json#L271-L273)

    
The JSON schema mixes multiple naming conventions for object properties: snake_case (`done_when`, `requirements_refs`, `design_refs`), kebab-case (`source-type`, `source-id`), and short/camelCase forms (`do`, `files`, `verify`, `basePath`, `taskIndex`). This inconsistency reduces readability and maintainability. Additionally, kebab-case keys require quoted access in most programming languages, increasing the risk of developer friction and bugs when mapping schema data to runtime objects. Standardizing on a single convention (e.g., camelCase for programmatic fields and explicitly documenting if snake/kebab-case is inherited from external YAML/Markdown frontmatter formats) is recommended.
**Tags: naming, maintainability, code-style**
**Affected code:**
```json
271:         "done_when": {
272:           "type": "string",
273:           "description": "Explicit success criteria"
```
**Affected code:**
```json
283:         "requirements_refs": {
284:           "type": "array",
285:           "items": { "type": "string" },
286:           "description": "Referenced requirement IDs"
287:         },
```
**Affected code:**
```json
434:         "source-type": {
435:           "type": "string",
436:           "enum": ["url", "mcp", "skill"],
437:           "description": "Type of external resource"
438:         },
```
**Affected code:**
```json
438:         },
439:         "source-id": {
440:           "type": "string",
441:           "description": "URL, MCP server name, or skill identifier"
442:         },
```

## `#10`  `mkdir` fails when `state_file` lacks a directory component
[plugins/ralphharness-codex/scripts/merge_state.py L72](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness-codex/scripts/merge_state.py#L72)

    
When `state_file` is provided without a directory path (e.g., `state.json`), `state_path.parent` resolves to `.`. Calling `Path(".").mkdir(parents=True, exist_ok=True)` raises `FileExistsError` because the current directory already exists, causing the script to terminate unexpectedly.
**Tags: bug**
**Affected code:**
```python
72:     state_path.parent.mkdir(parents=True, exist_ok=True)
```
**Proposed change:**
```python
    try:
        state_path.parent.mkdir(parents=True, exist_ok=True)
    except FileExistsError:
        pass
```

## `#11`  Inconsistent state file naming in skill instructions
[plugins/ralphharness-codex/skills/ralphharness-cancel/SKILL.md L15,L25](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness-codex/skills/ralphharness-cancel/SKILL.md#L15)

    
The instructions reference the current spec state file with two different naming conventions: `.current-spec` (hyphenated) on line 15 and `.current_spec` (underscored) on line 25. This inconsistency can cause the AI agent to fail to locate or clear the state file. Please unify the naming convention to match the actual project file.
**Tags: naming, bug**
**Affected code:**
```markdown
15: - Resolve the target by explicit path, exact name, or `.current-spec`
```
**Affected code:**
```markdown
25: 4. If the user wants full removal, confirm first, then delete the spec directory and clear `.current-spec` when it points to that spec.
```

## `#12`  Typographical error in source directory name
[plugins/ralphharness-codex/templates/epic.md ](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness-codex/templates/epic.md)

    
The source directory name in the rename operation contains a typo: 'ralph-specum-codex' should be 'ralph-spec-codex'. This inconsistency affects naming conventions and may cause confusion or path resolution issues.
**Tags: naming, maintainability**

## `#13`  Contradictory instructions on file creation vs appending
[plugins/ralphharness-speckit/.claude/commands/speckit.checklist.md L95,L213](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness-speckit/.claude/commands/speckit.checklist.md#L95)

    
Line 95 instructs the command to append items to an existing domain checklist or create a new one if it doesn't exist. Line 213 directly contradicts this by stating that each command invocation creates a NEW checklist file with a unique domain-based name. This inconsistency will likely cause the AI model to ignore the append logic, potentially overwriting existing checklists or failing to accumulate items correctly across runs.
**Tags: bug, readability, maintainability**
**Affected code:**
```markdown
95:    - Each `/speckit.checklist` run appends items to the existing checklist file for the same domain, OR creates a NEW file if no existing checklist for that domain exists.
```
**Proposed change:**
```markdown
   - Each `/speckit.checklist` run appends items to the existing checklist file for the same domain, OR creates a NEW file if no existing checklist for that domain exists.
```
**Affected code:**
```markdown
213: **Important**: Each `/speckit.checklist` command invocation creates a NEW checklist file with a unique domain-based name.
```
**Proposed change:**
```markdown
**Important**: Each `/speckit.checklist` command invocation checks for an existing domain checklist, appending to it if found, or creating a NEW file if it does not exist.
```

## `#14`  Unescaped paths and filenames injected into JSON output
[plugins/ralphharness-speckit/.specify/scripts/bash/check-prerequisites.sh L89-L91,L147-L149,L151](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness-speckit/.specify/scripts/bash/check-prerequisites.sh#L89-L91)

    
The script uses printf with %s to directly embed file paths and document names into JSON strings (lines 89-91, 151) and constructs a JSON array manually (lines 147-149). This approach fails to escape special JSON characters (quotes, backslashes, control characters, or newlines) that may legitimately appear in file paths or document names. This results in malformed JSON, breaking any downstream tool or script that parses this output reliably. A proper JSON escaping mechanism should be used, or external tools like jq should be preferred for safe serialization.
**Tags: bug**
**Affected code:**
```bash
89:         printf '{"REPO_ROOT":"%s","BRANCH":"%s","FEATURE_DIR":"%s","FEATURE_SPEC":"%s","IMPL_PLAN":"%s","TASKS":"%s"}\n' \
90:             "$REPO_ROOT" "$CURRENT_BRANCH" "$FEATURE_DIR" "$FEATURE_SPEC" "$IMPL_PLAN" "$TASKS"
91:     else
```
**Affected code:**
```bash
147:         json_docs=$(printf '"%s",' "${docs[@]}")
148:         json_docs="[${json_docs%,}]"
149:     fi
```
**Affected code:**
```bash
151:     printf '{"FEATURE_DIR":"%s","AVAILABLE_DOCS":%s}\n' "$FEATURE_DIR" "$json_docs"
```

## `#15`  Inconsistent directory navigation in local development example
[plugins/ralphharness-speckit/CONTRIBUTING.md L18](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness-speckit/CONTRIBUTING.md#L18)

    
The contributing guide instructs developers to run `cd ralphharness-speckit` after cloning the repository, but the subsequent command accesses `./plugins/ralphharness-speckit`. Since the plugin resides within the `plugins/` directory of the repository, the `cd` command should navigate to `plugins/ralphharness-speckit` to align with the relative path used later. This inconsistency will cause confusion and path errors when contributors attempt to test the plugin locally.
**Tags: bug, readability**
**Affected code:**
```markdown
18: cd ralphharness-speckit
```
**Proposed change:**
```markdown
cd plugins/ralphharness-speckit
```

## `#16`  Typographical error in renamed directory path
[plugins/ralphharness-speckit/agents/spec-analyst.md ](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness-speckit/agents/spec-analyst.md)

    
The diff changes the directory from 'ralph-speckit' to 'ralphharness-speckit'. The concatenated 'ralphharness' appears to be a typo and breaks naming consistency with the 'Smart Ralph' project and the original 'ralph-speckit' path. It should be corrected to 'ralph-harness' or simply 'ralph'.
**Tags: naming, language**

## `#17`  Logical inconsistency between validation instructions and bash implementation
[plugins/ralphharness-speckit/commands/switch.md L43-L47](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness-speckit/commands/switch.md#L43-L47)

    
The markdown instructions under '## Validate' step 1 specify: 'If no name provided, list available features and ask user to choose'. However, the added bash script unconditionally checks for an empty '$name' and exits with code 1. This contradicts the intended UX flow defined in the same file and will cause the AI agent to halt prematurely instead of presenting the feature list fallback.
**Tags: bug, maintainability**
**Affected code:**
```markdown
43:    # Check for empty name
44:    if [ -z "$name" ]; then
45:      echo "ERROR: No feature name provided" >&2
46:      exit 1
47:    fi
```
**Proposed change:**
```markdown
   # Check for empty name
   # If no name provided, fall through to the 'List Available' section below instead of exiting
   # if [ -z "$name" ]; then
   #   echo "ERROR: No feature name provided" >&2
   #   exit 1
   # fi
```

## `#18`  Missing HTTP scheme in curl verification command
[plugins/ralphharness-speckit/examples/tasks.md L76](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness-speckit/examples/tasks.md#L76)

    
The `curl` command in task T008's Verify step omits the `http://` protocol scheme. Without it, `curl` will fail to interpret the target as a network URL (typically returning 'Protocol not supported' or misinterpreting `localhost` as a file path). The provided diff correctly patches this by adding `http://`.
**Tags: bug, language**
**Affected code:**
```markdown
76:   - **Verify**: `curl -X POST http://localhost:3000/api/auth/register -d '{"email":"test@example.com","password":"Test123!"}' -H 'Content-Type: application/json'`
```
**Proposed change:**
```markdown
  - **Verify**: `curl -X POST http://localhost:3000/api/auth/register -d '{"email":"test@example.com","password":"Test123!"}' -H 'Content-Type: application/json'`
```

## `#19`  Incorrect task ID matching logic in tasks.md unmark script
[plugins/ralphharness/agents/external-reviewer.md L497-L500](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness/agents/external-reviewer.md#L497-L500)

    
The script defines `marker_prefix` on line 497 but never uses it. Instead, line 500 uses `task_id in stripped`, which performs a substring match. If task IDs share prefixes (e.g., `1.1` and `1.1.1`), the condition will incorrectly match multiple tasks, potentially unmarking the wrong one. The check should use `stripped.startswith(marker_prefix)` to ensure exact prefix matching.
**Tags: bug**
**Affected code:**
```markdown
497: marker_prefix = f'- [x] {task_id} '
498: for i, line in enumerate(lines):
499:     stripped = line.lstrip()
500:     if stripped.startswith('- [x] ') and task_id in stripped:
```
**Proposed change:**
```markdown
    marker_prefix = f'- [x] {task_id} '
    for i, line in enumerate(lines):
        stripped = line.lstrip()
        if stripped.startswith(marker_prefix):
```

## `#20`  Broken markdown inline code backticks
[plugins/ralphharness/agents/product-manager.md L163-L164](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness/agents/product-manager.md#L163-L164)

    
Lines 163-164 contain a split markdown backtick around `research.md → Verification Tooling`. The backtick opens on line 163 and closes on line 164, breaking the inline code formatting. This causes improper rendering and may confuse the AI agent when parsing the template instructions.
**Tags: language, code-style**
**Affected code:**
```markdown
163:    in `spec-executor` (note: `task-planner` derives project type from `research.md → Verification
164:    Tooling` instead). Use the **e2e routing type**, not the spec-intent type:
```
**Proposed change:**
```markdown
    in `spec-executor` (note: `task-planner` derives project type from `research.md → Verification Tooling` instead). Use the **e2e routing type**, not the spec-intent type:
```

## `#21`  Undefined variable $SPEC_NAME in epic state cleanup logic
[plugins/ralphharness/commands/cancel.md L76-L88](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness/commands/cancel.md#L76-L88)

    
The variable $SPEC_NAME is used on line 80 to filter the epic's specs array, but it is never defined in the preceding resolution steps (which rely on $spec_path and $ARGUMENTS). This will cause the jq command to fail or match unexpectedly. Additionally, the else block attempts to clean up $TMP, which is only initialized inside the if-then block, leading to a rm command on an empty/unset variable. The epic cleanup logic should explicitly derive the spec name from the resolved path and correct the variable scoping.
**Tags: bug**
**Affected code:**
```markdown
76:    EPIC_NAME=$(cat "$CWD/specs/.current-epic" 2>/dev/null || true)
77:    if [ -n "$EPIC_NAME" ] && [ -f "$CWD/specs/_epics/$EPIC_NAME/.epic-state.json" ]; then
78:        EPIC_STATE="$CWD/specs/_epics/$EPIC_NAME/.epic-state.json"
79:        # Check if this spec exists in the epic's specs array
80:        if jq -e --arg name "$SPEC_NAME" '.specs[] | select(.name == $name)' "$EPIC_STATE" >/dev/null 2>&1; then
81:            # Remove the spec entry from the epic's specs array (atomic via same-dir mktemp + mv)
82:            TMP=$(mktemp "$(dirname "$EPIC_STATE")/.epic-state.XXXXXX")
83:            jq --arg name "$SPEC_NAME" 'del(.specs[] | select(.name == $name))' "$EPIC_STATE" > "$TMP"
84:            mv "$TMP" "$EPIC_STATE"
85:        else
86:            rm -f "$TMP"
87:        fi
88:    fi
```
**Proposed change:**
```markdown
    EPIC_NAME=$(cat "$CWD/specs/.current-epic" 2>/dev/null || true)
    if [ -n "$EPIC_NAME" ] && [ -f "$CWD/specs/_epics/$EPIC_NAME/.epic-state.json" ]; then
        EPIC_STATE="$CWD/specs/_epics/$EPIC_NAME/.epic-state.json"
        # Derive spec name from the resolved path
        SPEC_NAME="${spec_path##*/}"
        # Check if this spec exists in the epic's specs array
        if jq -e --arg name "$SPEC_NAME" '.specs[] | select(.name == $name)' "$EPIC_STATE" >/dev/null 2>&1; then
            # Remove the spec entry from the epic's specs array (atomic via same-dir mktemp + mv)
            TMP=$(mktemp "$(dirname "$EPIC_STATE")/.epic-state.XXXXXX")
            jq --arg name "$SPEC_NAME" 'del(.specs[] | select(.name == $name))' "$EPIC_STATE" > "$TMP"
            mv "$TMP" "$EPIC_STATE"
        fi
    fi
```

## `#22`  Redundant mandatory delegation constraints
[plugins/ralphharness/commands/triage.md L123-L136](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness/commands/triage.md#L123-L136)

    
The prompt contains two nearly identical <mandatory> blocks instructing the AI to act as a coordinator and delegate work to subagents. The first appears in Step 4 (lines 79-91) and the second immediately precedes Step 5 (lines 123-136). Repeating critical constraints in this manner bloats the prompt, wastes tokens, and can dilute the LLM's attention. The second block should be removed or merged into the first to improve prompt efficiency and maintainability.
**Tags: maintainability, readability**
**Affected code:**
```markdown
123: <mandatory>
124: ## CRITICAL: Delegation Requirement
125: 
126: **YOU ARE A COORDINATOR, NOT AN IMPLEMENTER.**
127: 
128: You MUST delegate ALL substantive work to subagents. This is NON-NEGOTIABLE.
129: 
130: **NEVER do any of these yourself:**
131: - Write epic.md or research.md content
132: - Perform research or analysis
133: - Make decomposition decisions
134: 
135: **ALWAYS delegate to the appropriate subagent.**
136: </mandatory>
```

## `#23`  tr -d '[:space:]' mangles file paths containing spaces
[plugins/ralphharness/hooks/scripts/path-resolver.sh L136](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness/hooks/scripts/path-resolver.sh#L136)

    
Line 136 uses `tr -d '[:space:]'` to strip whitespace from the `.current-spec` file content. However, the `[:space:]` character class includes space characters, meaning any path containing spaces will have them removed. This causes the script to search for non-existent directories when spaces are present in the spec name or path. The command should only strip leading/trailing whitespace and line terminators, not internal spaces.
**Tags: bug**
**Affected code:**
```bash
136:         content=$(cat "$current_spec_file" 2>/dev/null | tr -d '[:space:]')
```
**Proposed change:**
```bash
        content=$(<"$current_spec_file" 2>/dev/null | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
```

## `#24`  Incorrect timezone handling in `jq` timestamp generation
[plugins/ralphharness/references/loop-safety.md L35](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness/references/loop-safety.md#L35)

    
The `jq` filter uses `now | strftime("%Y-%m-%dT%H:%M:%SZ")` to generate the session start time. In `jq`, `now` and `strftime` operate on the local system time by default, but the format string appends a `Z` suffix implying UTC. This produces timestamps that incorrectly claim to be UTC while containing local time values, violating the ISO-8601 UTC format specified in the state file schema. Fix by piping `now` through `gmtime` before formatting to ensure correct UTC output.
**Tags: bug, compatibility**
**Affected code:**
```markdown
35: 4. Manually reset: `jq '.circuitBreaker.state = "closed" | .circuitBreaker.consecutiveFailures = 0 | .circuitBreaker.openedAt = null | .circuitBreaker.sessionStartTime = now | strftime("%Y-%m-%dT%H:%M:%SZ")' .ralph-state.json > tmp && mv tmp .ralph-state.json`
```
**Proposed change:**
```markdown
4. Manually reset: `jq '.circuitBreaker.state = "closed" | .circuitBreaker.consecutiveFailures = 0 | .circuitBreaker.openedAt = null | .circuitBreaker.sessionStartTime = now | gmtime | strftime("%Y-%m-%dT%H:%M:%SZ")' .ralph-state.json > tmp && mv tmp .ralph-state.json`
```

## `#25`  Typo in 'Diagnostic-first principle'
[plugins/ralphharness/references/phase-rules.md L227](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness/references/phase-rules.md#L227)

    
Line 227 contains a spelling error: 'Diagnostic-first principle' should be 'Diagnostic-first principle'.
**Tags: language**
**Affected code:**
```markdown
227: - **Diagnostic-first principle**: Only make code changes when you are certain you can solve the problem. Otherwise: (1) address the root cause, not the symptoms; (2) add descriptive logging statements and error messages to track variable and code state; (3) add test functions and statements to isolate the problem
```
**Proposed change:**
```markdown
- **Diagnostic-first principle**: Only make code changes when you are certain you can solve the problem. Otherwise: (1) address the root cause, not the symptoms; (2) add descriptive logging statements and error messages to track variable and code state; (3) add test functions and statements to isolate the problem
```

## `#26`  Misplaced and duplicated POC sections at end of document
[plugins/ralphharness/references/phase-rules.md L435-L451](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness/references/phase-rules.md#L435-L451)

    
The sections 'POC Target Task Count' and 'POC Behaviors Per Phase' (lines 435-451) are duplicated and placed at the very end of the file, far from the main POC-First Workflow definition (line 29). This disrupts logical document flow, violates DRY principles, and creates redundancy. These sections should be removed from the end and their content integrated into the POC-First Workflow section earlier in the document.
**Tags: maintainability, readability**
**Affected code:**
```markdown
435: ## POC Target Task Count
436: 
437: - Standard spec: 40-60+ tasks
438: - Phase distribution: Phase 1 = 50-60%, Phase 2 = 15-20%, Phase 3 = 15-20%, Phase 4-5 = 10-15%
439: 
440: ## POC Behaviors Per Phase
441: 
442: | Behavior | Phase 1 | Phase 2 | Phase 3 | Phase 4 | Phase 5 |
443: |----------|---------|---------|---------|---------|---------|
444: | Tests required | No | No | Yes | Yes | Yes |
445: | Type check must pass | Yes | Yes | Yes | Yes | Yes |
446: | Lint must pass | No | No | No | Yes | Yes |
447: | Hardcoded values OK | Yes | No | No | No | No |
448: | Error handling required | No | Yes | Yes | Yes | Yes |
449: | CI must be green | No | No | No | Yes | Yes |
450: | PR required | No | No | No | Yes | Yes |
451: | Review comments resolved | No | No | No | No | Yes |
```

## `#27`  Invalid Playwright locator syntax in Shadow DOM example
[plugins/ralphharness/skills/e2e/examples/homeassistant-selector-map.skill.md L50](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness/skills/e2e/examples/homeassistant-selector-map.skill.md#L50)

    
The selector `:scope >> text=Ruta activa` on line 50 is not valid Playwright syntax. Playwright does not recognize `:scope` in its locator chain combinator, and `>>` requires valid locator strings on both sides. Text matching inside a scoped element should use `text=` or `getByText()` directly.
**Tags: bug, code-style**
**Affected code:**
```markdown
50: const shadowContent = haCard.locator(':scope >> text=Ruta activa')
```
**Proposed change:**
```markdown
const shadowContent = haCard.locator('text=Ruta activa')
```

## `#28`  Typo in lock file name in documentation comment
[plugins/ralphharness/skills/e2e/mcp-playwright.skill.md L96](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness/skills/e2e/mcp-playwright.skill.md#L96)

    
The comment on line 96 incorrectly states "acquire a flock on `.ralph-state.json`", which refers to the state file itself. It should correctly reference `.ralph-state.json.lock` to match the actual bash code below it and prevent confusion for future developers.
**Tags: readability, language**
**Affected code:**
```markdown
96: Write result to `.ralph-state.json` — acquire a flock on `.ralph-state.json` before the
```
**Proposed change:**
```markdown
Write result to `.ralph-state.json` — acquire a flock on `.ralph-state.json.lock` before the
```

## `#29`  Playwright `getByTestId()` is deprecated in v1.40+
[plugins/ralphharness/skills/e2e/selector-map.skill.md L25,L36,L103,L131](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness/skills/e2e/selector-map.skill.md#L25)

    
Playwright officially deprecated `getByTestId()` in favor of `locator('[data-testid="..."]')` starting from v1.40. The skill still recommends `getByTestId()` as the 3rd preferred selector and uses it in code examples. Updating to the modern `locator` syntax will keep the skill aligned with current Playwright best practices and prevent future deprecation warnings.
**Tags: deprecation, maintainability**
**Affected code:**
```markdown
25: 3. getByTestId()        — data-testid explícito, sin semántica UI
```
**Proposed change:**
```markdown
3. locator('[data-testid=...]') — data-testid explícito, sin semántica UI
```
**Affected code:**
```markdown
36: | `getByTestId` | Componentes sin semántica ARIA / shadow DOM | `getByTestId('user-card')` |
```
**Proposed change:**
```markdown
| `locator('[data-testid=...]')` | Componentes sin semántica ARIA / shadow DOM | `locator('[data-testid="user-card"]')` |
```
**Affected code:**
```markdown
103: const card = page.getByTestId('user-card')
```
**Proposed change:**
```markdown
const card = page.locator('[data-testid="user-card"]')
```
**Affected code:**
```markdown
131: await expect(page.getByTestId('list-item')).toHaveCount(3)
```
**Proposed change:**
```markdown
await expect(page.locator('[data-testid="list-item"]')).toHaveCount(3)
```

## `#30`  Critical removal of core exploration steps in Step 1A-explore
[plugins/ralphharness/skills/e2e/ui-map-init.skill.md L134-L143](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness/skills/e2e/ui-map-init.skill.md#L134-L143)

    
The diff proposes removing steps 'a' through 'f' under '### Step 1A-explore — Explore Entry Points'. These steps contain the skill's essential browser automation logic: classifying routes, navigating to them, verifying auth state, extracting interactive elements, generating stable locators, and capturing screenshots. Removing them entirely breaks the skill's primary responsibility, leaving it unable to produce a valid `ui-map.local.md`. Furthermore, the filtering paragraph explicitly references 'steps (b)–(f)', which becomes syntactically orphaned and misleading without the corresponding steps.
**Tags: bug, architecture**
**Affected code:**
```markdown
134:    a. Classify the route as **public** (accessible without auth) or **protected** (requires auth)
135:    b. `browser_navigate` to the route
136:    c. `browser_snapshot` + stable state check — if the page is the login form
137:       (detected by the presence of username/password fields in the snapshot),
138:       treat as auth-expired: emit `VERIFICATION_FAIL` and stop.
139:    d. `browser_snapshot` → extract interactive elements (buttons, inputs, links, forms)
140:    e. `browser_generate_locator` for each key element → record selector
141:    f. `browser_take_screenshot` → save using the canonical prefixed filename:
142:       - Public routes: `<basePath>/screenshots/ve0-public-<route-slug>.png`
143:       - Protected routes: `<basePath>/screenshots/ve0-auth-<route-slug>.png`
```

## `#31`  Typo in source file path: 'ralph-specum'
[plugins/ralphharness/skills/interview-framework/references/algorithm.md ](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/plugins/ralphharness/skills/interview-framework/references/algorithm.md)

    
The source path in the rename operation contains a typo 'ralph-specum' which should likely be 'ralph-harness' to align with the target path and project naming conventions. This typo should be corrected to ensure consistent plugin structure and avoid resolution or indexing confusion.
**Tags: naming**

## `#32`  Incorrect variable in error message
[tests/helpers/version-sync.sh L7](https://github.com/informatico-madrid/smart-ralph/blob/feature%2Frenaming/tests/helpers/version-sync.sh#L7)

    
Line 7 prints `$CLAUDE_VER` twice in the FAIL message (`Codex=$CLAUDE_VER`). It should reference `$CODEX_VER` to correctly display the mismatched Codex version.
**Tags: bug**
**Affected code:**
```bash
7:   echo "FAIL: Claude=$CLAUDE_VER Codex=$CODEX_VER"
```
**Proposed change:**
```bash
  echo "FAIL: Claude=$CLAUDE_VER Codex=$CODEX_VER"
```
<!-- GITO_COMMENT:CODE_REVIEW_REPORT -->