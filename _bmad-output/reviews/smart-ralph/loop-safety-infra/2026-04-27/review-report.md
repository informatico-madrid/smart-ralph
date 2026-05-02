# Smart-Ralph Review: loop-safety-infra (Phase: tasks → execution)

**Spec**: `loop-safety-infra` | **Epic**: `engine-roadmap-epic` (Spec 4)
**Review Date**: 2026-04-27T10:49:00Z
**Model**: z-ai/glm-5.1 (top-tier reasoning)
**Review Mode**: full (5 layers)
**Consensus Threshold**: majority

---

## Executive Summary

Se encontraron **23 findings** tras revisión multi-capa completa (contract validation, adversarial, editorial, edge-case, deep analysis). De estos, **3 son CRITICAL** (causarán fallos en runtime), **9 son HIGH** (disfuncionalidad significativa), **8 son MEDIUM** (gaps funcionales), y **3 son LOW** (cosmético).

Tras consenso BMAD party-mode simulado (Winston/Architect, John/PM, Amelia/Dev, Mary/Analyst): **20 CONFIRMED**, **2 DISPUTED-CONFIRMED**, **1 AUTO-DISCARDED** (trivially cosmetic).

**Veredicto**: La spec NO está lista para producción. Los 3 bugs CRITICAL deben corregirse antes de cualquier merge. Los 9 HIGH requieren corrección para cumplir los AC del epic.

---

## Summary

| Métrica | Valor |
|---------|-------|
| Raw findings | 23 |
| ✅ Confirmed by consensus | 17 |
| ⚖️ Disputed → Orchestrator confirmed | 3 |
| ❌ Rejected (false positives) | 2 |
| Auto-discarded (trivial) | 1 |
| **Total corrections to apply** | **20** |

---

## 🔴 CRITICAL Findings (Runtime Failures)

### SR-016: sessionStartTime type mismatch — session timeout NEVER works

| Campo | Valor |
|-------|-------|
| **Severity** | CRITICAL |
| **Layer** | deep-analysis |
| **File** | [`implement.md`](plugins/ralph-specum/commands/implement.md:126) + [`stop-watcher.sh`](plugins/ralph-specum/hooks/scripts/stop-watcher.sh:854) |
| **Category** | type-mismatch |

**Description**: [`implement.md`](plugins/ralph-specum/commands/implement.md:126) inicializa `sessionStartTime: "$(date +%s)"` que produce un **integer epoch** (ej: `1745265600`). Pero [`stop-watcher.sh`](plugins/ralph-specum/hooks/scripts/stop-watcher.sh:854) intenta parsearlo como fecha string: `date -d "$session_start" +%s`. El comando `date -d "1745265600"` falla en la mayoría de sistemas Linux (no es un formato de fecha válido para `date -d`). Resultado: **el check de session timeout SIEMPRE devuelve 0 o falla**, significando que el circuit breaker NUNCA se activará por timeout de 48h.

**Impact**: AC-2.4 (48h session timeout) es **infuncional**. Un loop podría correr indefinidamente.

**Suggested Fix**: Alinear tipos. Opción A (recomendada): cambiar implement.md para almacenar ISO string `$(date -u +%Y-%m-%dT%H:%M:%SZ)` y actualizar schema a `string/date-time` (que ya es lo que dice el schema actual). Opción B: cambiar stop-watcher.sh para tratar sessionStartTime como integer epoch directamente (`now_epoch - session_start >= max_session`).

**Consensus**:
| Agent | Vote | Reasoning |
|-------|------|-----------|
| Winston | CONFIRM | "Type mismatch between writer and reader is a fundamental integration bug" |
| John | CONFIRM | "48h timeout is an epic success criterion — this must work" |
| Amelia | CONFIRM | "date -d on an integer will fail — I've hit this bug before" |
| Mary | CONFIRM | "AC-2.4 is completely unverifiable with this bug" |
| **Result** | **CONFIRMED (4/4)** | |

---

### SR-012: discover_ci_commands recibe spec_path en vez de repo_root — SIEMPRE devuelve array vacío

| Campo | Valor |
|-------|-------|
| **Severity** | CRITICAL |
| **Layer** | adversarial |
| **File** | [`implement.md`](plugins/ralph-specum/commands/implement.md:179) |
| **Category** | logic-error |

**Description**: [`implement.md`](plugins/ralph-specum/commands/implement.md:179) llama `discover_ci_commands "$SPEC_PATH"` pasando el path del spec (ej: `./specs/loop-safety-infra/`). Pero [`discover_ci_commands()`](plugins/ralph-specum/hooks/scripts/stop-watcher.sh:872) escanea `$spec_dir/.github/workflows/` — que sería `./specs/loop-safety-infra/.github/workflows/`. Este directorio NO existe. Los workflows están en el **repo root**: `.github/workflows/`. El parámetro debería ser el repo root, no el spec path.

**Impact**: FR-008 (CI command discovery) es **completamente infuncional**. `ciCommands` siempre será `[]`. CI drift detection nunca funcionará.

**Suggested Fix**: Cambiar `discover_ci_commands "$SPEC_PATH"` a `discover_ci_commands "$PROJECT_ROOT"` o `discover_ci_commands "$(git rev-parse --show-toplevel)"`.

**Consensus**:
| Agent | Vote | Reasoning |
|-------|------|-----------|
| Winston | CONFIRM | "Wrong path parameter — architectural integration error" |
| John | CONFIRM | "FR-008 is a core feature, this makes it dead code" |
| Amelia | CONFIRM | "Classic bug — function expects repo root, gets spec dir" |
| Mary | CONFIRM | "ciCommands always empty → AC-5.1 unverifiable" |
| **Result** | **CONFIRMED (4/4)** | |

---

### SR-005: stop-watcher.sh ESCRIBE circuit breaker state — viola single-writer principle

| Campo | Valor |
|-------|-------|
| **Severity** | CRITICAL |
| **Layer** | adversarial |
| **File** | [`stop-watcher.sh`](plugins/ralph-specum/hooks/scripts/stop-watcher.sh:842) |
| **Category** | architectural-violation |

**Description**: [`check_circuit_breaker()`](plugins/ralph-specum/hooks/scripts/stop-watcher.sh:842) escribe al state file cuando el circuit trip por consecutive failures: `jq '.circuitBreaker.state = "open" | ...' "$state_file" > "$tmp" && mv "$tmp" "$state_file"`. Esto **viola** el single-writer principle documentado en [`design.md`](specs/loop-safety-infra/design.md:244) Section 3.2: *"stop-watcher.sh ONLY READS circuitBreaker state. Never writes."* y en [`requirements.md`](specs/loop-safety-infra/requirements.md:138) FR-003. Además, [`implement.md`](plugins/ralph-specum/commands/implement.md:365) TAMBIÉN escribe circuit breaker state al trip. Esto crea un **dual-writer race condition**.

**Impact**: Race condition potencial entre stop-watcher.sh y coordinator escribiendo simultáneamente al mismo campo. Corrupción de state file posible.

**Suggested Fix**: Eliminar la escritura de state del `check_circuit_breaker()` en stop-watcher.sh. El function debe SOLO output el block JSON y exit 0. El coordinator en implement.md es el único writer. Si el circuit breaker se tripped desde stop-watcher, el coordinator lo detectará en la siguiente iteración al leer `consecutiveFailures >= max`.

**Consensus**:
| Agent | Vote | Reasoning |
|-------|------|-----------|
| Winston | CONFIRM | "Single-writer is a core architectural decision — violation is critical" |
| John | CONFIRM | "Requirements explicitly state stop-watcher never writes CB" |
| Amelia | CONFIRM | "Dual-writer race can corrupt state file — I've seen this in production" |
| Mary | CONFIRM | "This contradicts the spec's own design documentation" |
| **Result** | **CONFIRMED (4/4)** | |

---

## 🟠 HIGH Findings (Significant Functional Issues)

### SR-001: sessionStartTime schema type mismatch (integer vs string)

| Campo | Valor |
|-------|-------|
| **Severity** | HIGH |
| **Layer** | contract-validation |
| **File** | [`spec.schema.json`](plugins/ralph-specum/schemas/spec.schema.json:268) |
| **Category** | consistency |

**Description**: [`spec.schema.json`](plugins/ralph-specum/schemas/spec.schema.json:268) define `sessionStartTime` como `{"type": ["string", "null"], "format": "date-time"}`. Pero [`design.md`](specs/loop-safety-infra/design.md:232) y [`requirements.md`](specs/loop-safety-infra/requirements.md:132) dicen `sessionStartTime: <epoch-seconds-integer>`. El schema dice string/ISO, el design dice integer. Esto está directamente relacionado con SR-016.

**Suggested Fix**: Alinear todos los artefactos. Recomendación: usar ISO string (el schema ya lo dice), y arreglar implement.md + stop-watcher.sh para usar formato ISO consistentemente.

**Consensus**: CONFIRMED (4/4) — "Schema is the contract — all implementations must match it"

---

### SR-002: maxSessionSeconds default 3600 en schema vs 172800 en design

| Campo | Valor |
|-------|-------|
| **Severity** | HIGH |
| **Layer** | contract-validation |
| **File** | [`spec.schema.json`](plugins/ralph-specum/schemas/spec.schema.json:290) |
| **Category** | consistency |

**Description**: [`spec.schema.json`](plugins/ralph-specum/schemas/spec.schema.json:290) tiene `"default": 3600` (1 hora). Pero [`design.md`](specs/loop-safety-infra/design.md:224), [`requirements.md`](specs/loop-safety-infra/requirements.md:142), y [`implement.md`](plugins/ralph-specum/commands/implement.md:128) todos dicen 172800 (48h). Si el campo falta en el state file, el default del schema sería 1h en vez de 48h.

**Suggested Fix**: Cambiar schema default de 3600 a 172800.

**Consensus**: CONFIRMED (4/4) — "Default value mismatch is a configuration time bomb"

---

### SR-003: checkpoint SHA — full vs short, inconsistencia entre design, schema, implementación y tests

| Campo | Valor |
|-------|-------|
| **Severity** | HIGH |
| **Layer** | deep-analysis |
| **File** | [`checkpoint.sh`](plugins/ralph-specum/hooks/scripts/checkpoint.sh:103), [`spec.schema.json`](plugins/ralph-specum/schemas/spec.schema.json:236), [`tasks.md`](specs/loop-safety-infra/tasks.md:455) |
| **Category** | consistency |

**Description**: Triple inconsistencia:
1. [`design.md`](specs/loop-safety-infra/design.md:142) dice almacenar **short SHA** (7 chars) via `git rev-parse --short=7`
2. [`checkpoint.sh`](plugins/ralph-specum/hooks/scripts/checkpoint.sh:103) almacena **full SHA** (40 chars) via `git log -1 --format=%H`
3. [`spec.schema.json`](plugins/ralph-specum/schemas/spec.schema.json:236) description dice "Full git commit SHA"
4. Task 3.2 verify espera `[ ${#sha} -eq 7 ]` (7 chars)
5. Task 1.2 verify no chequea longitud

El test [`test-checkpoint.sh`](specs/loop-safety-infra/tests/test-checkpoint.sh:50) usa `[ ${#sha} -ge 7 ]` (>= 7) que pasa con full SHA, pero el task 3.2 verify usa `-eq 7` que fallaría.

**Suggested Fix**: Decidir: full SHA o short SHA. Recomendación: **full SHA** (más seguro para `git cat-file -e` en rollback). Actualizar design.md, schema description, y task 3.2 verify.

**Consensus**: CONFIRMED (4/4) — "Inconsistency across 4 artifacts will confuse implementers"

---

### SR-004: Missing loop-safety.md reference doc

| Campo | Valor |
|-------|-------|
| **Severity** | HIGH |
| **Layer** | contract-validation |
| **File** | `plugins/ralph-specum/references/loop-safety.md` (MISSING) |
| **Category** | missing-deliverable |

**Description**: Task 4.9 requiere crear [`loop-safety.md`](plugins/ralph-specum/references/loop-safety.md) con decision log, recovery procedures, y configuration defaults. El archivo **NO EXISTE** (ENOENT). Es un deliverable explícito de la spec.

**Suggested Fix**: Crear el archivo con el contenido especificado en task 4.9.

**Consensus**: CONFIRMED (4/4) — "Missing deliverable is a spec completion gap"

---

### SR-007: Heartbeat no establece filesystemHealthy=false en fallo

| Campo | Valor |
|-------|-------|
| **Severity** | HIGH |
| **Layer** | adversarial |
| **File** | [`stop-watcher.sh`](plugins/ralph-specum/hooks/scripts/stop-watcher.sh:796) |
| **Category** | logic-error |

**Description**: [`design.md`](specs/loop-safety-infra/design.md:535) muestra que en fallo se debe establecer `.filesystemHealthy = false`. Pero la implementación real en [`stop-watcher.sh`](plugins/ralph-specum/hooks/scripts/stop-watcher.sh:796) solo establece `filesystemHealthFailures` y `lastFilesystemCheck` — **nunca** establece `filesystemHealthy = false`. AC-4.6 requiere que el campo refleje el estado real.

**Suggested Fix**: Añadir `| .filesystemHealthy = false` al jq command en la rama de fallo.

**Consensus**: CONFIRMED (4/4) — "State field doesn't reflect actual health — AC-4.6 violated"

---

### SR-010: check_ci_drift usa eval en comandos descubiertos — vulnerabilidad de seguridad

| Campo | Valor |
|-------|-------|
| **Severity** | HIGH |
| **Layer** | edge-case |
| **File** | [`stop-watcher.sh`](plugins/ralph-specum/hooks/scripts/stop-watcher.sh:945) |
| **Category** | security |

**Description**: [`check_ci_drift()`](plugins/ralph-specum/hooks/scripts/stop-watcher.sh:945) ejecuta `eval "$cmd" > /dev/null 2>&1` para cada CI command descubierto. Si un workflow file contiene comandos maliciosos (ej: `rm -rf /`), se ejecutarían sin restricción. El design.md no menciona eval.

**Suggested Fix**: Usar `bash -c "$cmd"` en vez de `eval`, o mejor aún, ejecutar los comandos en un subshell restringido. Añadir validación de que los comandos coinciden con patrones conocidos (bats, eslint, tsc, etc.).

**Consensus**:
| Agent | Vote | Reasoning |
|-------|------|-----------|
| Winston | CONFIRM | "eval on untrusted input is a security anti-pattern" |
| John | REJECT | "This is an internal tool, not exposed to external input — risk is low" |
| Amelia | CONFIRM | "eval is dangerous even in internal tools — bash -c is safer" |
| Mary | NEEDS_CONTEXT | "Need to understand threat model" |
| **Result** | **DISPUTED-CONFIRMED** | Winston(2x technical) + Amelia(1.5x) = 3.5 weighted CONFIRM vs John(1x) REJECT. HIGH severity modifier → lean toward applying fix. |

---

### SR-013: write_metric.sh field mismatches con design schema

| Campo | Valor |
|-------|-------|
| **Severity** | HIGH |
| **Layer** | deep-analysis |
| **File** | [`write-metric.sh`](plugins/ralph-specum/hooks/scripts/write-metric.sh:96) |
| **Category** | consistency |

**Description**: Múltiples discrepancias entre [`write-metric.sh`](plugins/ralph-specum/hooks/scripts/write-metric.sh:96) y el schema en [`design.md`](specs/loop-safety-infra/design.md:469):

| Campo | Design dice | Implementación hace | Bug? |
|-------|-------------|---------------------|------|
| `schemaVersion` | integer `1` | string `"1.0"` | Sí — tipo incorrecto |
| `globalIteration` | read from state file | `null` | Sí — campo siempre null |
| `agent` | `"spec-executor"` | `null` | Sí — campo siempre null |
| `toolsUsed` | `[]` (empty array) | `null` | Sí — tipo incorrecto (null vs array) |
| `startedAt` | `null` (future) | `$timestamp` (current time) | Sí — semántica incorrecta |
| `completedAt` | current timestamp | `null` | Sí — invertido con startedAt |
| `retries` | `taskIteration - 1` | `0` (hardcoded) | Sí — cálculo faltante |
| `commitSha` | No existe en design | Presente como campo extra | Sí — campo no especificado |
| `commit` | commit SHA | Condicional (null si "00000000") | Parcial — lógica diferente |

**Suggested Fix**: Alinear write-metric.sh con el schema de design.md. Los campos `startedAt`/`completedAt` están invertidos. `globalIteration` debe leerse del state file. `agent` debe ser "spec-executor". `toolsUsed` debe ser `[]`. `retries` debe calcularse como `taskIteration - 1`.

**Consensus**: CONFIRMED (4/4) — "9 field mismatches means metrics data is unreliable"

---

### SR-015: implement.md sources entire stop-watcher.sh para CI discovery

| Campo | Valor |
|-------|-------|
| **Severity** | HIGH |
| **Layer** | adversarial |
| **File** | [`implement.md`](plugins/ralph-specum/commands/implement.md:173) |
| **Category** | side-effect-risk |

**Description**: [`implement.md`](plugins/ralph-specum/commands/implement.md:173) hace `source "$CLAUDE_PLUGIN_ROOT/hooks/scripts/stop-watcher.sh"` para obtener `discover_ci_commands`. Pero stop-watcher.sh tiene **1011 líneas** con lógica de loop principal que se ejecutará al sourcearlo, incluyendo checks de state file, exit conditions, etc. Esto puede causar side effects no deseados o errores.

**Suggested Fix**: Extraer `discover_ci_commands()` a un archivo separado (ej: `ci-discovery.sh`) que pueda ser sourceado de forma segura. O mover la función a `checkpoint.sh` / un nuevo `safety-common.sh`.

**Consensus**: CONFIRMED (3/4) — John: "Works in practice if stop-watcher exits early on missing state", but Winston+Amelia override: "Sourcing a 1000-line hook script is an architectural smell"

---

### SR-017: Missing /proc/mounts pre-check en heartbeat (AC-4.5)

| Campo | Valor |
|-------|-------|
| **Severity** | HIGH |
| **Layer** | edge-case |
| **File** | [`stop-watcher.sh`](plugins/ralph-specum/hooks/scripts/stop-watcher.sh:769) |
| **Category** | missing-requirement |

**Description**: AC-4.5 requiere "Two-tier error detection: stat pre-check on /proc/mounts (EROFS detection) + authoritative write attempt". La implementación actual solo hace el write attempt — no hay pre-check de `/proc/mounts`. En Linux, leer `/proc/mounts` puede detectar EROFS (read-only filesystem) antes de intentar escribir, lo cual es más rápido y evita side effects.

**Suggested Fix**: Añadir pre-check de `/proc/mounts` antes del write attempt. Solo en Linux (`[[ -f /proc/mounts ]]`).

**Consensus**:
| Agent | Vote | Reasoning |
|-------|------|-----------|
| Winston | CONFIRM | "AC-4.5 is explicit — two-tier detection is required" |
| John | REJECT | "The write attempt is authoritative — pre-check is optimization, not necessity" |
| Amelia | CONFIRM | "EROFS detection via /proc/mounts catches read-only mounts before write attempt" |
| Mary | CONFIRM | "AC says two-tier — one tier is missing" |
| **Result** | **CONFIRMED (3/4)** | |

---

## 🟡 MEDIUM Findings (Functional Gaps)

### SR-006: Heartbeat no chequea write exit code

**File**: [`stop-watcher.sh`](plugins/ralph-specum/hooks/scripts/stop-watcher.sh:775)
**Description**: El design muestra `WRITE_OK=$?` después del write, pero la implementación no captura el exit code del `echo` command. Solo detecta fallo via read-back mismatch. Un write que falla silenciosamente (ej: permisos) podría no detectarse.
**Consensus**: CONFIRMED (3/4) — "Write exit code is the primary error signal, read-back is secondary"

### SR-008: Heartbeat no loguea warning a .progress.md en 1er fallo

**File**: [`stop-watcher.sh`](plugins/ralph-specum/hooks/scripts/stop-watcher.sh:802)
**Description**: AC-4.4 requiere "1st consecutive: Warn — log to .progress.md, continue". La implementación solo hace `return 0` sin escribir a .progress.md.
**Consensus**: CONFIRMED (4/4) — "AC-4.4 explicitly requires .progress.md logging"

### SR-009: Heartbeat block output sin instrucciones de recovery

**File**: [`stop-watcher.sh`](plugins/ralph-specum/hooks/scripts/stop-watcher.sh:807)
**Description**: El design muestra instrucciones detalladas de recovery ("Check disk space: df -h", "Check permissions: ls -la", reset instructions). La implementación usa un printf simple sin instrucciones.
**Consensus**: CONFIRMED (3/4) — "Recovery instructions are critical for autonomous operation"

### SR-011: check_ci_drift JSON construction usa string concatenation

**File**: [`stop-watcher.sh`](plugins/ralph-specum/hooks/scripts/stop-watcher.sh:957)
**Description**: `current_results="${current_results}\"${cmd_hash}\":\"${status}\""` construye JSON via string concatenation en vez de `jq --arg`. Si un hash o status contiene comillas, el JSON será inválido. Esto contradice el principio de design de usar jq para todo JSON.
**Consensus**: CONFIRMED (4/4) — "jq --arg exists specifically to prevent JSON injection"

### SR-014: write_metric.sh no lee globalIteration del state file

**File**: [`write-metric.sh`](plugins/ralph-specum/hooks/scripts/write-metric.sh:133)
**Description**: Design Section 3.3 muestra `global_iteration=$(jq -r '.globalIteration // 0' "$state_file")`. La implementación hardcodea `globalIteration: $nullNull` (siempre null).
**Consensus**: CONFIRMED (4/4) — "globalIteration is available in state file — should be read"

### SR-018: Heartbeat no limpia .ralph-heartbeat file después de success

**File**: [`stop-watcher.sh`](plugins/ralph-specum/hooks/scripts/stop-watcher.sh:789)
**Description**: El design muestra `rm -f "$heartbeat_file"` después del read-back exitoso. La implementación no elimina el archivo, dejando archivos `.ralph-heartbeat` stale en el spec directory.
**Consensus**: CONFIRMED (3/4) — John: "Stale files are cosmetic", but majority: "Cleanup is part of the design contract"

### SR-019: Task 3.2 verify espera SHA length == 7 pero implementación almacena full SHA

**File**: [`tasks.md`](specs/loop-safety-infra/tasks.md:455)
**Description**: Task 3.2 verify: `[ ${#sha} -eq 7 ]` espera 7-char SHA. Pero checkpoint.sh almacena full 40-char SHA. Este test fallaría si se ejecuta literalmente. (El test real en test-checkpoint.sh usa `-ge 7` que sí pasa.)
**Consensus**: CONFIRMED (4/4) — "Task verify command is wrong — needs to match implementation"

### SR-020: Missing test files — solo test-checkpoint.sh existe

**File**: `specs/loop-safety-infra/tests/`
**Description**: Tasks 3.5-3.15 requieren test files: `test-write-metric.sh`, `test-heartbeat.sh`, `test-ci-discovery.sh`, `test-integration.sh`, `test-benchmark.sh`. Solo `test-checkpoint.sh` existe. 5 de 6 test files faltan.
**Consensus**: CONFIRMED (4/4) — "Missing test files means Phase 3 testing is incomplete"

---

## 🟢 LOW Findings (Cosmetic/Minor)

### SR-021: Schema checkpoint.sha description inconsistency

**File**: [`spec.schema.json`](plugins/ralph-specum/schemas/spec.schema.json:236)
**Description**: Schema dice "Full git commit SHA" pero design dice "Short SHA (7 chars)". Ver SR-003 para fix completo.
**Consensus**: CONFIRMED (4/4) — tied to SR-003

### SR-022: check_ci_drift usa sha256sum que puede no estar disponible

**File**: [`stop-watcher.sh`](plugins/ralph-specum/hooks/scripts/stop-watcher.sh:941)
**Description**: `sha256sum` no está disponible en macOS por defecto (usa `shasum -a 256`). Esto rompe la compatibilidad macOS que es un objetivo explícito de la spec.
**Consensus**:
| Agent | Vote | Reasoning |
|-------|------|-----------|
| Winston | CONFIRM | "macOS compatibility is an explicit spec goal" |
| John | REJECT | "CI drift is a nice-to-have, not critical path" |
| Amelia | CONFIRM | "Simple fix: use jq -R -s 'sha256sum' or shasum fallback" |
| Mary | REJECT | "Low priority — CI drift is already null for plugin repos" |
| **Result** | **DISPUTED-CONFIRMED** | Winston(2x) + Amelia(1.5x) = 3.5 vs John(1x) + Mary(1.5x) = 2.5. Technical domain → lean toward fix. |

### SR-023: Task verify commands usan hardcoded absolute paths

**File**: [`tasks.md`](specs/loop-safety-infra/tasks.md:56) (multiple)
**Description**: Los verify commands usan `/mnt/bunker_data/ai/smart-ralph/...` hardcoded. No son portátiles a otros environments.
**Consensus**: AUTO-DISCARDED — trivially cosmetic; verify commands are for local development only and the path is correct for this environment.

---

## ❌ Rejected Findings (False Positives)

| # | Description | Why Rejected |
|---|-------------|-------------|
| FP-001 | "implement.md Step 3 jq merge doesn't validate JSON" | All agents: jq merge is atomic — either succeeds or fails, no partial state possible |
| FP-002 | "checkpoint.sh idempotency check uses jq -e which fails on empty" | Amelia: "jq -e '.checkpoint // empty' returns empty string on missing field, which is falsy — idempotency check works correctly" |

---

## Cross-Artifact Traceability Matrix

### FR → Design → Tasks Coverage

| FR | Design Section | Tasks | Status |
|----|---------------|-------|--------|
| FR-001 | 3.1 | 1.1-1.6 | ⚠️ SHA full vs short mismatch |
| FR-002 | 3.1 | 1.4, 1.5 | ✅ OK |
| FR-003 | 3.2 | 1.7-1.11 | 🔴 sessionStartTime type bug, dual-writer violation |
| FR-004 | 3.3 | 1.15-1.18 | ⚠️ write_metric field mismatches |
| FR-005 | 3.3 | 1.15-1.18 | ⚠️ Same as FR-004 |
| FR-006 | 3.4 | 1.12-1.14 | ⚠️ Missing filesystemHealthy=false, no /proc/mounts check |
| FR-007 | 3.4 | 1.13 | ⚠️ Missing .progress.md logging, missing recovery instructions |
| FR-008 | 3.5 | 1.19-1.23 | 🔴 CI discovery uses wrong path (spec_path vs repo_root) |
| FR-009 | 3.5 | 1.22 | ⚠️ eval security, JSON concatenation |

### AC → Implementation Verification

| AC | Task Verify | Actually Works? |
|----|------------|-----------------|
| AC-1.1 | 1.2 grep checkpoint-create | ✅ |
| AC-1.2 | 1.1 jq checkpoint.sha | ✅ |
| AC-1.3 | 1.1 jq timestamp/branch/message | ✅ |
| AC-1.4 | 3.1 sha=null test | ✅ |
| AC-1.5 | 1.5 rollback.md exists | ✅ |
| AC-1.6 | 2.6 git config check | ✅ |
| AC-1.7 | 3.4 null SHA rollback | ✅ |
| AC-2.1 | 4.4 consecutiveFailures in schema | ✅ |
| AC-2.2 | 1.9 "closed" in implement.md | ✅ |
| AC-2.3 | 1.10 consecutiveFailures update | ✅ |
| AC-2.4 | 4.4 maxSessionSeconds | 🔴 **BROKEN** — sessionStartTime type mismatch |
| AC-2.5 | 4.4 exit 0 on open | ⚠️ Works but stop-watcher writes state (violation) |
| AC-2.6 | 4.4 reset on pass | ✅ |
| AC-2.7 | 4.4 defaults to closed | ✅ |
| AC-2.8 | 4.4 timeout highest priority | 🔴 **BROKEN** — same as AC-2.4 |
| AC-3.1 | 4.5 .metrics.jsonl in implement.md | ✅ |
| AC-3.2 | 3.5 valid JSONL | ⚠️ Fields don't match design schema |
| AC-3.3 | 4.5 per-spec file | ✅ |
| AC-3.4 | 4.5 flock usage | ✅ |
| AC-3.5 | 4.5 coordinator writes only | ✅ |
| AC-3.6 | N/A (no delete in cleanup) | ✅ |
| AC-3.7 | N/A (schemaVersion: 1) | ⚠️ "1.0" string vs integer 1 |
| AC-3.8 | 1.15 write-metric.sh exists | ✅ |
| AC-4.1 | 4.6 heartbeat runs every iteration | ✅ |
| AC-4.2 | 4.6 .ralph-heartbeat file | ✅ |
| AC-4.3 | 3.14 benchmark < 10ms | ⚠️ Test file missing |
| AC-4.4 | 4.6 three-tier response | ⚠️ Missing .progress.md logging |
| AC-4.5 | 4.6 /proc/mounts pre-check | 🔴 **MISSING** — not implemented |
| AC-4.6 | 4.6 state fields present | ⚠️ filesystemHealthy never set to false |
| AC-4.7 | N/A (no auto-recovery) | ✅ |
| AC-5.1 | 4.7 scans .yml and .bats | 🔴 **BROKEN** — wrong path parameter |
| AC-5.2 | 4.7 ciCommands in schema | ✅ |
| AC-5.3 | 4.7 ciSnapshotBefore at init | ⚠️ Not captured (null in metrics) |
| AC-5.4 | 4.7 ciSnapshotAfter post-task | ⚠️ Not captured (null in metrics) |
| AC-5.5 | 4.7 drift detection | ⚠️ eval + JSON concatenation issues |
| AC-5.6 | N/A (plugin repo skip) | ✅ |
| AC-5.7 | 4.7 discovery runs once | ✅ |

### NFR Verification

| NFR | Status | Notes |
|-----|--------|-------|
| NFR-001 (append-only) | ✅ | stop-watcher.sh functions appended at end |
| NFR-002 (heartbeat < 10ms) | ⚠️ | Test file missing |
| NFR-003 (rollback preserves commit) | ✅ | git reset --hard preserves in history |
| NFR-004 (no auto CB reset) | ✅ | No timer-based reset |
| NFR-005 (flock in write_metric) | ✅ | flock -x used |
| NFR-006 (schema additive only) | ✅ | Only additions to properties |

---

## Missing from Design/Tasks (Forgotten Items)

### FORGOT-1: No ciSnapshotBefore capture at init time
AC-5.3 requiere capturar `ciSnapshotBefore` en state init. Ni implement.md ni stop-watcher.sh capturan este baseline. El campo `ciSnapshotBefore` en metrics es siempre null.

### FORGOT-2: No ciSnapshotAfter capture post-task
AC-5.4 requiere capturar `ciSnapshotAfter` post-task. No hay lógica en implement.md Step 5 para ejecutar CI commands y capturar resultados.

### FORGOT-3: No heartbeat file cleanup on success path
El design muestra `rm -f "$heartbeat_file"` después del read-back exitoso. La implementación no lo hace.

### FORGOT-4: No detached HEAD test case
Task 3.x no incluye un test para detached HEAD (aunque el design lo maneja y el progress.md lo menciona como MEDIUM finding T-MR3).

### FORGOT-5: No idempotency test for checkpoint-create
El design menciona idempotency (skip if SHA already exists) pero no hay test que verifique que llamar checkpoint-create dos veces no crea un segundo commit.

### FORGOT-6: No session timeout test
No hay test que verifique que el circuit breaker se activa después de 48h (o un timeout configurable para testing).

### FORGOT-7: No test for circuit breaker manual reset
No hay test que verifique que editar el state file de open→closed permite reanudar la ejecución.

---

## Correction Plan

### Priority 1: CRITICAL (must fix before merge)

| # | Finding | Correction | Target File | ralph-specum Command |
|---|---------|-----------|-------------|---------------------|
| 1 | SR-016 | Alinear sessionStartTime a ISO string (schema ya lo dice) | implement.md, stop-watcher.sh, design.md | `/ralph-specum:design loop-safety-infra --quick` |
| 2 | SR-012 | Cambiar discover_ci_commands param a repo root | implement.md | `/ralph-specum:design loop-safety-infra --quick` |
| 3 | SR-005 | Eliminar state write de check_circuit_breaker | stop-watcher.sh | `/ralph-specum:design loop-safety-infra --quick` |

### Priority 2: HIGH (must fix for AC compliance)

| # | Finding | Correction | Target File |
|---|---------|-----------|-------------|
| 4 | SR-001 | Alinear sessionStartTime type en todos los artefactos | spec.schema.json, design.md, requirements.md |
| 5 | SR-002 | Cambiar maxSessionSeconds default a 172800 | spec.schema.json |
| 6 | SR-003 | Decidir full vs short SHA, actualizar todos los artefactos | checkpoint.sh, design.md, schema, tasks.md |
| 7 | SR-004 | Crear loop-safety.md reference doc | references/loop-safety.md |
| 8 | SR-007 | Añadir filesystemHealthy = false en fallo | stop-watcher.sh |
| 9 | SR-010 | Reemplazar eval con bash -c o validación de patrones | stop-watcher.sh |
| 10 | SR-013 | Alinear write_metric.sh fields con design schema | write-metric.sh |
| 11 | SR-015 | Extraer discover_ci_commands a archivo separado | new file: ci-discovery.sh |
| 12 | SR-017 | Añadir /proc/mounts pre-check en heartbeat | stop-watcher.sh |

### Priority 3: MEDIUM (should fix for completeness)

| # | Finding | Correction | Target File |
|---|---------|-----------|-------------|
| 13 | SR-006 | Capturar write exit code en heartbeat | stop-watcher.sh |
| 14 | SR-008 | Añadir .progress.md logging en 1er fallo | stop-watcher.sh |
| 15 | SR-009 | Añadir recovery instructions en block output | stop-watcher.sh |
| 16 | SR-011 | Reemplazar string concatenation con jq --arg | stop-watcher.sh |
| 17 | SR-014 | Leer globalIteration del state file | write-metric.sh |
| 18 | SR-018 | Añadir rm -f .ralph-heartbeat después de success | stop-watcher.sh |
| 19 | SR-019 | Corregir task 3.2 verify SHA length check | tasks.md |
| 20 | SR-020 | Crear test files faltantes | tests/ |

---

## Quality Gates

| Gate | Status | Notes |
|------|--------|-------|
| Contract valid | ⚠️ PARTIAL | Schema type mismatches (sessionStartTime, maxSessionSeconds default) |
| FR/AC coverage | 🔴 FAIL | 3 ACs broken (AC-2.4, AC-2.8, AC-4.5), 5 ACs partial |
| Verify commands valid | ⚠️ PARTIAL | Task 3.2 verify would fail; hardcoded paths |
| Smart-Ralph format | ✅ PASS | Frontmatter, FR/AC IDs, task format all correct |
| Consensus reached | ✅ PASS | All findings voted on, 20 confirmed |
