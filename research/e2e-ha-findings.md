# E2E HA Findings — Pizarra de Investigación Forense

> Rama de trabajo: `research/e2e-ha-findings`  
> **Objetivo:** Reducir el gap entre agentes escribiendo tests malos y tests correctos para HA custom components.

---

## Leyenda de estado

| Icono | Significado |
|---|---|
| ✅ | Confirmado, fuente verificada |
| ⚠️ | Plausible pero sin fuente directa |
| ❌ | Rebatido o descartado |
| 🔍 | Pendiente de investigar más |
| 💬 | En debate, no resuelto |

---

## Hipótesis central (A + B + C)

- **A) Le falta información** — HA routing, 404, sidebar nav
- **B) Le falta metodología** — no experimenta, no verifica que la infra existe
- **C) La fuente de verdad está rota** — `copilot-instructions.md` describe infra inexistente

---

## PLAN DE PRUEBA — Estado completo

| Paso | Acción | Estado | Observaciones |
|---|---|---|---|
| 1-10 | Interview (9 preguntas) | ✅ Completado | Ver Bloque 12 |
| 11 | Phase 1 — Explore codebase | ✅ Completado | Ver Bloque 14 — resultados excelentes |
| 12 | Phase 1 — research-analyst (1er intento) | ❌ Bloqueado/timeout | Agente no retornó. Ver Bloque 15 |
| 13 | Phase 1 — research-analyst (2º intento) | ✅ Completado | Web search rota → pivotó a codebase local. Ver Bloque 16 |
| 14 | Phase 2 — requirements | ✅ Completado | 9 preguntas → 6 US, 9 FR, 3 NFR. Ver Bloque 17 |
| 15 | Phase 2 — design | ✅ Completado + Aprobado | 590 líneas. Sólido. Ver Bloque 18 |
| 16 | Phase 3 — tasks | ✅ Completado | 18 tareas coarse. P15 resuelta. Ver Bloque 19 |
| 16b | Phase 3 — spec-reviewer (8/8 PASS) | ✅ Completado | Pasó sin detectar P16 ni P20. Ver Bloque 19 |
| 17 | Phase 3 — implement tasks 1.1–1.6 | ✅ Completado | 6 commits locales. Ver Bloque 20 |
| 17b | Phase 3 — artifact reviewer | ✅ Completado | REVIEW_FAIL: 3 críticos, 3 importantes. Ver Bloque 21 |
| 17c | Phase 3 — fix tasks 1.1.1, 1.3.1, 1.5.1, 1.6.1 | ✅ Completado (parcialmente) | spec-executor → coordinador ejecutó fixes directamente. Ver Bloque 22 y 23 |
| 17d | Fix adicional coordinador — scope `page` en trip.spec.ts | ✅ Completado | Bug P22 detectado y corregido por coordinador. Ver Bloque 23 |
| 18 | qa-engineer verifica task 1.8 — VE1 | 🔍 Delegado | Ver Bloque 25 |

---

## Bloque 25 — 🔍 VE1: qa-engineer recibe task 1.8 — PENDIENTE RESULTADO

### Contexto
Tras marcar `taskIndex = 8` y completar todos los fix tasks, el coordinador delegó la tarea 1.8 (POC verification — Run tests against ephemeral HA) a `qa-engineer`.

### La tarea delegada
```
Execute verification task 1.8 for spec e2e-ev-trip-planner.

Task: POC verification - Run tests against ephemeral HA

Do:
1. Run npx playwright test tests/e2e/vehicle.spec.ts --timeout=180000
   - global.setup.ts starts ephemeral HA
   - Config Flow runs via global.setup.ts's auth integration
   - vehicle.spec.ts creates a vehicle via Config Flow and verifies panel opens
   - afterEach cleanup removes the integration

2. If vehicle.spec.ts passes, also run trip.spec.ts

Verify:
- Exit code 0 from playwright test
- No TypeScript errors
- Config Flow completes successfully in logs
- Panel opens and is accessible
```

### Preguntas forenses P23 (nuevas)

**P23a — ¿Qué ocurre cuando VE1 corre contra `hass-taste-test`?**
La pregunta central: ¿`global.setup.ts` arrancará correctamente `hass-taste-test` via docker-compose? ¿El auth flow de Config Flow funcionará en el HA ephemeral?

Hipótesis:
- **H1:** `hass-taste-test` arranca pero el Config Flow selector `hass-integration-card` falla porque el selector en el código tiene espacio inicial (bug I2, marcado como importante no crítico en REVIEW_FAIL — ¿fue corregido en los fix tasks?)
- **H2:** El auth flow falla porque la URL de HA ephemeral no coincide con `baseURL` en `playwright.config.ts`
- **H3:** El flow completo funciona y VE1 pasa — en ese caso tenemos un artefacto de infra de test funcional por primera vez

**P23b — ¿El qa-engineer leerá `global.setup.ts` antes de ejecutar?**
El qa-engineer debería verificar que `global.setup.ts` referencia `hass-taste-test` y no `test-ha/docker-compose.yml`. Si no lo hace, podría ejecutar ciegamente y obtener un error opaco.

**P23c — ¿Hay un race condition entre `global.setup.ts` y el test runner?**
El `global.setup.ts` arranca HA de forma async. Si playwright lanza los tests antes de que HA esté ready, fallará con errores de conexión, no con errores de test. ¿Tiene health-check el setup?

### Estado
🔍 Pendiente de resultado del qa-engineer.

---

## Bloque 24 — ✅ taskIndex advancement: coordinador gestiona estado directamente

### Observación forense
Tras el bloqueo de P21 (`spec-executor` unknown), el **coordinador no se quedó bloqueado indefinidamente**. En la sesión actual:

1. **Ejecutó los fix tasks directamente** (sin delegar a spec-executor)
2. **Avanzó manualmente el `taskIndex`** de 6 a 8 con jq
3. **Marcó task 1.7 (TypeScript check) como completa** al verificar que `npx tsc --noEmit` pasaba
4. **Delegó correctamente task 1.8** al qa-engineer

### Implicación forense
El coordinador tiene capacidad de auto-recuperación ante el fallo de skill delegation. Cuando `spec-executor` falló (P21), el coordinador adoptó el rol de executor directamente. Esto es:
- ✅ **Positivo**: El proyecto no quedó bloqueado, los fixes se aplicaron
- ⚠️ **Riesgo**: El coordinador actuó como executor sin respetar la separación de responsabilidades del sistema ralph-specum. ¿Es esto un comportamiento documentado o es drift?

### Fix candidato O
Documentar en `phase-rules.md` qué ocurre cuando `spec-executor` no está disponible: ¿el coordinador debe actuar como fallback o debe escalar al usuario?

---

## Bloque 23 — ✅ P22 NUEVA: Bug `page` out-of-scope en test functions de trip.spec.ts

### El bug
Tras los fix tasks del subagente (1.1.1, 1.3.1, 1.5.1, 1.6.1), el coordinador leyó `trip.spec.ts` y encontró un nuevo bug crítico **que no estaba en los fix tasks originales**:

```typescript
// ANTES (incorrecto):
test('US-3 + US-4: create recurring trip...', async () => {
  await panel.openFromSidebar();
  await expect(page.locator('ev-trip-planner-panel >> .trip-card')).toContainText('25.5');
  // ^^^ page no existe en scope — es solo parámetro de beforeEach
});

// DESPUÉS (correcto):
test('US-3 + US-4: create recurring trip...', async ({ page }) => {
  // page destructured desde fixture de Playwright
  await panel.openFromSidebar();
  await expect(page.locator('ev-trip-planner-panel >> .trip-card')).toContainText('25.5');
});
```

### Commit aplicado
```
ce67f27 fix(e2e): add page fixture to trip test functions
```

Diff concreto: 2 líneas cambiadas (las 2 definiciones de `test()` que faltaban `{ page }`).

### Análisis forense

**¿Por qué el artifact reviewer (Bloque 21) no lo detectó?**
El reviewer encontró C2 (`browserPage` fixture incorrecta) y C3 (`tripId` undefined), pero NO detectó que las firmas de las funciones `test()` no recibían `page`. Posibles causas:
1. **El reviewer no ejecutó TypeScript** — solo leyó el código. El TypeScript check hubiera capturado esto.
2. **El reviewer asumió que `page` venía del outer scope** — error de lectura, `beforeEach({ page })` hace que `page` sea local a ese callback.
3. **El bug fue introducido por el fix task 1.3.1** (replace `browserPage` with `page`) — al cambiar `browserPage` a `page`, el executor no añadió `{ page }` a la firma del test. El reviewer vio el cambio terminado pero no verificó que la firma fuera correcta.

**¿Por qué el TypeScript check no lo capturó antes?**
`page` en el outer scope de `test.describe` no existe, por lo que TypeScript debería haber dado error `Cannot find name 'page'`. Sin embargo el coordinador corrió `npx tsc --noEmit` y pasó. Hipótesis: `@playwright/test` declara `page` como global en sus tipos. Esto sería un caso donde **TypeScript no detecta un bug de runtime** porque los tipos de Playwright permiten `page` globalmente.

**Implicación crítica:**
> El TypeScript check pasó, el artifact reviewer no lo detectó, y el bug solo se hubiera manifestado en runtime cuando los tests corrieran. **El único detector real hubiera sido VE1 (ejecutar los tests).**

### P22 abierta
¿Por qué `@playwright/test` types declaran `page` como global, enmascarando el error de scope? ¿Es esto un problema conocido del ecosistema Playwright?

---

## Bloque 22 — ⚠️ Fix Tasks: spec-executor bloqueado → coordinador ejecutó directamente

### Contexto
El artifact reviewer (Bloque 21) encontró REVIEW_FAIL con 3 críticos. El coordinador intentó delegar 4 fix tasks a subagentes `spec-executor` en paralelo.

### El fallo original (P21)
El modelo coordinador (MiniMax-M2.7) intentó:
```
Skill("spec-executor", team_name="fix-e2e", name="fix-1", task_index=6)
...
```
**Resultado para los 4:** `Unknown skill: spec-executor`

### Lo que ocurrió después (nuevo)
El coordinador **no se bloqueó** — asumió el rol de executor directamente en la siguiente sesión:

#### Fix 1.1.1 — auth.setup.ts + global.setup.ts + playwright.config.ts
El coordinador reestructuró el auth flow completo:
- `auth.setup.ts` → convertido de test-as-setup a función `runAuthSetup()` callable
- `global.setup.ts` → actualizado para importar y llamar `runAuthSetup()`  
- `playwright.config.ts` → usa `storageState: 'playwright/.auth/user.json'` en lugar de `setupProject` (que no existe en Playwright 1.58)
- Commit: `5851fc6`

#### Fix 1.3.1 — browserPage → page en trip.spec.ts
- Subagente previo había hecho este cambio (commit `eb8f921`)
- Pero dejó el bug de scope (P22) que el coordinador encontró después

#### Fix 1.5.1 y 1.6.1 — locator space + dialog handler
- Commits `b876fe6` y `3d28971` aplicados por el subagente

### Commits de fix (en orden)
```
09ee089 fix(e2e): invoke auth.setup.ts via setupProject (WRONG — no existe en PW 1.58)
3d28971 fix(e2e): move dialog handler from POM deleteTrip to test beforeEach
b876fe6 fix(e2e): remove leading space from hass-integration-card locator
eb8f921 fix(e2e): replace browserPage fixture with page in trip.spec.ts
5851fc6 fix(e2e): update playwright configuration and integrate auth setup (FIX CORRECTO del auth)
ce67f27 fix(e2e): add page fixture to trip test functions (P22 fix)
```

### Observación clave
El commit `09ee089` (setupProject) fue incorrecto y el coordinador lo sobreescribió en `5851fc6`. El sistema de fix tasks generó **un commit incorrecto seguido de un commit de corrección**. Esto es un patrón de "fix sobre fix" que indica que el primer subagent executor no verificó que `setupProject` existiera en Playwright 1.58.

---

## Bloque 21 — ✅ Artifact Reviewer: REVIEW_FAIL (3 críticos, 3 importantes)

### Resultado: REVIEW_FAIL

El reviewer leyó los 6 archivos producidos por tasks 1.1–1.6 y encontró:

#### Fallos críticos (bloquean ejecución)

| # | Archivo | Problema |
|---|---|---|
| C1 | `playwright.config.ts` | `auth.setup.ts` nunca invocado — falta `setupProject` |
| C2 | `trip.spec.ts` | Usa fixture `browserPage` (no existe en Playwright) en vez de `page` |
| C3 | `trip.spec.ts` | `afterEach` referencia `tripId` indefinido; dialog handler dentro del loop |

#### Fallos importantes

| # | Archivo | Problema |
|---|---|---|
| I1 | `EVTripPlannerPage.ts` | `this.page.on('dialog', ...)` dentro de `deleteTrip()` — listener persistente acumulativo |
| I2 | `vehicle.spec.ts` | Locator con espacio inicial: `' hass-integration-card'` |
| I3 | `trip.spec.ts` | `beforeEach` no sigue el patrón de diseño |

### Observaciones forenses

**P16 RESUELTA ✅ — El reviewer SÍ detectó la falta de `setupProject`**
Con el código real delante, detectó C1 correctamente. La hipótesis anterior era: "sin el código, no puede ver el problema" — confirmada.

**El reviewer encontró bugs que el task-planner NO puso como tareas**
- C2 (`browserPage` fixture) y C3 (`tripId` undefined) son bugs introducidos por los executors durante implement, no presentes en el design. El reviewer los encontró leyendo el código real.
- Esto confirma la necesidad del artifact reviewer como capa de seguridad post-implement.

**Fix task flow activado correctamente**
El coordinador siguió el protocolo correcto:
1. Actualizó `.ralph-state.json` con `fixTaskMap`
2. Insertó 4 nuevas tareas en `tasks.md`
3. Intentó delegar en paralelo (falló por P21)

---

## Bloque 20 — ✅ Phase 3 Implement tasks 1.1–1.6: Análisis forense

### Los 6 commits producidos (en repo local, pendientes de push)

```
1b3ef20 feat(e2e): add trip.spec.ts for US-3, US-4, and US-5
ee18b61 docs(e2e): mark Task 1.3 complete in progress and tasks
ddbc107 feat(e2e): add EVTripPlannerPage POM with Shadow DOM pierce selectors
f3f19d9 feat(e2e): add auth.setup.ts for Config Flow authentication
b4d8b2c feat(e2e): add vehicle.spec.ts for US-1 and US-2
bf5985e feat(e2e): add ConfigFlowPage POM
ed596d7 feat(e2e): add playwright.config.ts with globalSetup and Chromium project
```

### Observación crítica: ejecución paralela (executors 2, 3, 5)
El coordinador lanzó 6 subagentes en paralelo. Cada executor recibió su prompt de tarea individualmente. Esto confirma que el sistema ralph-specum tiene capacidad de paralelización real en fase implement.

### P19 NUEVA — El engram como sustituto implícito de skills
**Observación:** Los executors 2, 3 y 5 disponían de 1535 memorias (202 sobre Playwright, 292 sobre HA). El executor-3 (`auth.setup.ts`) encontró en el engram la corrección previa de `getByPlaceholder` y la aplicó sin que nadie se la indicara explícitamente.

**Implicación:** El engram actúa como un sistema de skills informal y acumulativo. Cuando las skills formales no están disponibles o están mal ubicadas (ver P20), el engram puede compensar parcialmente.

**Riesgo:** El engram es específico del proyecto/usuario. Un agente en otro entorno sin ese historial no tendría esa compensación. Las skills formales siguen siendo necesarias para garantizar el comportamiento correcto en cualquier entorno.

**Fix candidato M:** Documentar en `phase-rules.md` que las skills formales deben referenciarse explícitamente en tasks, no asumir que el engram las compensa.

### Engram cross-project (hallazgo adicional)
**Observación:** El Session Briefing muestra actividad reciente de proyectos completamente distintos (`mnt/informatico-madrid` — VPS, nginx, UniFi). El vault es **global por usuario**, no aislado por proyecto.

**Implicación para ralph-specum:** Si el agente tiene memoria de un proyecto de infraestructura de red junto a memorias de tests Playwright, podría haber contaminación de contexto o simplemente ruido. En este caso no parece haber causado problemas, pero es un riesgo latente.

---

## Plan de investigación: estado

| # | Pregunta | Estado |
|---|---|---|
| P1–P4 | Auth, 404, routing, bugs | ✅ Resueltos |
| P5 | ¿El agente tenía info disponible? | ✅ Sí, en copilot-instructions y global.setup.ts |
| P6 | ¿Qué fix minimal habría evitado los fallos? | 💬 Fix F + E + G |
| P7 | ¿Habría llegado solo al 404/sidebar? | ✅ Observado — no llegó solo en Phase 3 implement |
| P8 | ¿Por qué falló tras conocer la causa? | ✅ IIFE baseURL |
| P9 | ¿Playwright-best-practices tiene info de hass-taste-test? | ⚠️ Web search rota |
| P10 | ¿Copilot-instructions describe infra inexistente? | ✅ CONFIRMADO |
| P11 | ¿global.teardown.ts tiene path hardcodeado? | ✅ CONFIRMADO |
| P12 | ¿Agente actualiza plan Docker → hass-taste-test? | ✅ SÍ — design phase |
| P13 | ¿Mecanismo subagentes tiene timeout? | ❌ NO |
| P14 | ¿Web search funciona en el entorno? | ❌ NO — API Error 400 |
| P15 | ¿Detectará bug scope `page` en deleteTrip()? | ✅ SÍ — tarea 2.1 en tasks |
| P16 | ¿Conectará auth.setup.ts como dependency? | ✅ SÍ — artifact reviewer lo detectó en código real |
| P17 | ¿Corregirá global.teardown.ts path hardcodeado? | ❌ NO en tasks — solo en CI failure |
| P18 | ¿Skills ausentes en tasks — problema de diseño? | 🔍 NUEVA — ver Bloque 19 |
| P19 | ¿El engram compensa la ausencia de skills formales? | ✅ PARCIALMENTE — executor-3 aplicó fix previo de engram |
| P20 | ¿Scripts de skill ha-e2e-testing en ubicación incorrecta? | ✅ CONFIRMADO — engram lo registra como corrección crítica |
| P21 | ¿Fix task flow falla porque `spec-executor` no existe? | ✅ CONFIRMADO — Unknown skill: spec-executor |
| P22 | ¿TypeScript types de Playwright enmascaran bug de scope `page`? | 🔍 NUEVA — ver Bloque 23 |
| P23a | ¿VE1 pasará contra hass-taste-test ephemeral? | 🔍 NUEVA — pendiente resultado |
| P23b | ¿El qa-engineer leerá global.setup.ts antes de ejecutar? | 🔍 NUEVA — pendiente |
| P23c | ¿Race condition entre global.setup.ts y test runner? | 🔍 NUEVA — pendiente |

---

## Bloque 19 — ✅ Phase 3 Tasks: Análisis forense

### Resultado: 18 tareas coarse, 5 fases

| Fase | Tareas | Contenido |
|---|---|---|
| Phase 1 POC | 1.1–1.8 | 6 archivos crear + TypeScript check + smoke test |
| Phase 2 Refactor | 2.1–2.3 | Fix dialog handler, API cleanup, quality gate |
| Phase 3 Testing | 3.1–3.2 | Selector fixes, full suite |
| Phase 4 Quality | 4.1–4.3 + VE1–VE3 | Local CI + CI pipeline + AC checklist + infra VE |
| Phase 5 PR | 5.1–5.2 | PR creation + CI monitor |

### P15 RESUELTA ✅ — El agente detectó solo el bug de scope

Tarea 2.1 incluye explícitamente:
> *"Fix deleteTrip method — the design had `page.on('dialog', ...)` inside an instance method which is wrong"*

El task-planner releyó el design con ojo crítico y detectó el bug sin que nadie se lo dijera.

### P17 — global.teardown.ts NO incluido en tasks

El path hardcodeado `/mnt/bunker_data/...` no aparece como tarea de fix. **Confirmado: el bug solo se descubrirá en VE3/CI.** Esto es el hallazgo esperado.

### P18 — 🔍 Skills ausentes en tasks.md

**Observación:** Ninguna tarea referencia skills del sistema (`playwright-best-practices`, `ha-e2e-testing`, etc.). Las tareas describen qué hacer pero no indican qué skill consultar durante la implementación.

**Pregunta forense:** ¿Es esto un problema de diseño de ralph-specum (las skills deberían referenciarse en tasks) o es intencionado (el agente implementador las consulta por su cuenta)?

**Sub-preguntas:**
- ¿El agente de implement consultará skills proactivamente?
- ¿Si no las consulta, escribirá código peor que si las tuviera?
- ¿Deberían las tasks incluir `skills: [playwright-best-practices, ha-e2e-testing]` por tarea?

---

## Fix candidatos acumulados

| ID | Descripción | Estado |
|---|---|---|
| Fix A | Añadir `waitUntil: 'networkidle'` en `goto()` | 🔍 |
| Fix B | Documentar sidebar nav con `data-panel-id` | 🔍 |
| Fix C | Documentar 404 → reload pattern en copilot-instructions | 🔍 |
| Fix D | Configurar `baseURL` correctamente (evitar IIFE) | 🔍 |
| Fix E | Proporcionar `hass-taste-test` como docker-compose funcional | 🔍 |
| Fix F | Actualizar `copilot-instructions.md` para eliminar referencias a infra inexistente | 🔍 |
| Fix G | Añadir `test-ha/docker-compose.yml` real al repo | 🔍 |
| Fix H | Configurar timeout de subagentes en ralph-specum | 🔍 |
| Fix I | Aislar el vault/engram por proyecto | 🔍 |
| Fix J | Reparar web search en el entorno de test | 🔍 |
| Fix K | Añadir script de verificación de infra pre-test | 🔍 |
| Fix L | Corregir path hardcodeado en `global.teardown.ts` | 🔍 |
| Fix M | Documentar skills en phase-rules.md para que tasks las referencien | 🔍 |
| Fix N | Verificar nombre real de skill de ejecución en ralph-specum | ✅ URGENTE |
| Fix O | Documentar comportamiento fallback coordinador cuando spec-executor falla | 🔍 |

---

*Última actualización: Bloque 25 — VE1 delegado a qa-engineer, P22/P23 abiertas, Bloque 24 fix-sobre-fix pattern*
