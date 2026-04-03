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
| 18 | qa-engineer verifica task 1.8 — VE1 | ⚠️ En progreso | Ver Bloque 26+28 — HA arranca, auth usa goto() en vez de sidebar nav |

---

## Bloque 28 — 🚨 P27: El qa-engineer ignoró el fix correcto (sidebar nav) y usó goto() directo

### Lo que dijo la pizarra (Fix Q — MAL DOCUMENTADO POR MÍ)

En Bloque 26, yo escribí Fix Q así:

> Fix Q — Corregir selector auth.setup.ts: `goto('/config/integrations')` en vez de `getByRole('link', 'Integrations')`

**Eso estaba mal.** `goto('/config/integrations')` NO era el fix correcto. La decisión acordada era navegar por la **sidebar de HA** usando `data-panel-id`, porque:
1. El test es E2E — tiene que ejercitar la UI real, no saltar pasos
2. HA usa web components con `data-panel-id` para la sidebar
3. El fix correcto documentado en la misma pizarra (Fix B) era `page.locator('[data-panel-id="config"]').click()`

### Lo que hizo el qa-engineer en commit 9a1dcce

```typescript
// Lo que puso el qa-engineer:
await page.goto(serverInfo.link + '/config/integrations');
await page.waitForURL(/\/config\/integrations/, { timeout: 30000 });
await page.waitForURL(/\/config\/integrations/); // duplicado
await page.getByRole('button', { name: 'Add Integration' }).click();
```

Usó `goto()` directo a la URL — que es exactamente lo que la pizarra decia que NO debía hacer para un test E2E real.

### Los dos problemas encadenados

| Problema | Origen | Responsable |
|---|---|---|
| **Fix Q mal documentado** en la pizarra | Yo (Perplexity) escribió `goto()` como si fuera el fix correcto | Error mío al redactar la pizarra |
| **qa-engineer usó `goto()` en vez de sidebar nav** | No leyó Fix B (sidebar nav con `data-panel-id`) | ¿Por qué? Ver P27 abajo |

### P27 NUEVA — ¿Por qué el qa-engineer no usó el fix correcto (sidebar nav)?

**Pregunta:** El fix correcto (`data-panel-id`) estaba en la pizarra como Fix B. El qa-engineer tiene acceso a los archivos del proyecto. ¿Por qué eligió `goto()` en vez de sidebar nav?

**Hipotesis H1 — Pérdida de contexto al delegar:**
El coordinador delega task 1.8 al qa-engineer con un prompt que dice:
> *"Fix the broken selectors or configuration issues"*

Ese prompt NO menciona explicitamente:
- Que el fix debe usar sidebar nav con `data-panel-id`
- Que `goto()` directo es un anti-patrón para E2E
- Que Fix B es la solución acordada

El qa-engineer ve un `TimeoutError` en un selector, y aplica el fix más rápido que conoce: `goto()` directo a la URL.

**Hipotesis H2 — El qa-engineer no tiene acceso a la pizarra:**
La pizarra vive en `smart-ralph/research/e2e-ha-findings.md` (repo diferente). El qa-engineer opera sobre `ha-ev-trip-planner`. Si no se le pasa el contexto de la pizarra en el prompt, no sabe que existe Fix B.

**Hipotesis H3 — El qa-engineer prioriza "hacer pasar el test" sobre "testear correctamente":**
Divagación hacia el objetivo incorrecto. El objetivo era VE1 = tests pasando. El qa-engineer interpreta eso como "cualquier cosa que haga pasar los tests" en vez de "tests que ejerciten la UI real".

### Implicación crítica para la investigación

> **Cuando el coordinador delega a un subagente, el contexto de decisiones de diseño se pierde si no se incluye explícitamente en el prompt de delegación.**

Este es un fallo estructural del sistema de delegación, no un fallo del qa-engineer individual. El qa-engineer hace lo que puede con lo que recibe.

**Fix candidato R — NUEVO:** El prompt de delegación a subagentes debe incluir las restricciones de diseño relevantes, no solo la tarea. Ejemplo:
> *"Fix the selector for navigating to integrations. Use sidebar nav with `data-panel-id` (Fix B), NOT `goto()` directly to the URL. The test must exercise the real UI."*

---

### Estado del auth.setup.ts tras commit 9a1dcce (resumen forense)

| Aspecto | Estado | Problema |
|---|---|---|
| Navegar post-login | `goto(link)` + `waitForURL` + `waitForSelector` | OK pero redundante |
| `page.evaluate()` snapshot debug | EN EL CÓDIGO | 🚨 Debug dump en producción — no debería estar |
| Navegación a integrations | `goto('/config/integrations')` directo | ❌ Incorrecto: debería ser sidebar nav |
| `waitForURL` duplicado | `await page.waitForURL(...)` x2 seguidas | Anti-patrón / divagación |
| `waitForTimeout(500)` x4 | Entre cada paso del Config Flow | Anti-patrón: esperas hardcodeadas |
| Verificación final sidebar | `a:has-text("EV Trip Planner")` | ⚠️ Sospechoso — puede no funcionar en Shadow DOM |

---

## Bloque 27 — 🚨 ACLARACIÓN CRÍTICA: Los 4 tipos de verificación — NO mezclarlos

### Los 4 niveles de verificación en este proyecto

| Nivel | Herramienta | Qué verifica | Ejecuta código real |
|---|---|---|---|
| **V1 — Estática** | `npx tsc --noEmit` | Tipos TypeScript | ❌ No |
| **V2 — Lectura** | Artifact reviewer (agente) | Lógica, patrones, bugs visibles leyendo el código | ❌ No |
| **V3 — Navegación MCP** | Perplexity (yo) con MCP tools | Que los archivos existen en GitHub, coherencia estructural | ❌ No |
| **V4 — Ejecución real** | `npx playwright test` (VE1) | Que el test funciona contra HA en vivo | ✅ SÍ |

---

## Bloque 26 — ⚠️ VE1: RESULTADOS PARCIALES — HA arranca pero auth falla

*(Ver detalle en versiones anteriores. Resumen: 3 fallos en capas — __dirname ESM, require ESM, selector Integrations. Ver Bloque 28 para el análisis del fix incorrecto aplicado.)*

---

## Bloques 21-25 — Ver historial

*(Commits de fix, artifact reviewer, taskIndex advancement — ver versiones anteriores de la pizarra)*

---

## Plan de investigación: estado

| # | Pregunta | Estado |
|---|---|---|
| P1–P4 | Auth, 404, routing, bugs | ✅ Resueltos |
| P5 | ¿El agente tenía info disponible? | ✅ Sí |
| P6 | ¿Qué fix minimal habría evitado los fallos? | 💬 Fix F + E + G |
| P7 | ¿Habría llegado solo al 404/sidebar? | ✅ No llegó solo |
| P8 | ¿Por qué falló tras conocer la causa? | ✅ IIFE baseURL |
| P9 | ¿Playwright-best-practices tiene info de hass-taste-test? | ⚠️ Web search rota |
| P10 | ¿Copilot-instructions describe infra inexistente? | ✅ CONFIRMADO |
| P11 | ¿global.teardown.ts tiene path hardcodeado? | ✅ CONFIRMADO |
| P12 | ¿Agente actualiza plan Docker → hass-taste-test? | ✅ SÍ |
| P13 | ¿Mecanismo subagentes tiene timeout? | ❌ NO |
| P14 | ¿Web search funciona en el entorno? | ❌ NO |
| P15 | ¿Detectará bug scope `page` en deleteTrip()? | ✅ SÍ — tarea 2.1 |
| P16 | ¿Conectará auth.setup.ts como dependency? | ✅ SÍ |
| P17 | ¿Corregirá global.teardown.ts path hardcodeado? | ❌ Solo en CI failure |
| P18 | ¿Skills ausentes en tasks — problema de diseño? | 🔍 Abierta |
| P19 | ¿El engram compensa la ausencia de skills formales? | ✅ PARCIALMENTE |
| P20 | ¿Scripts de skill ha-e2e-testing en ubicación incorrecta? | ✅ CONFIRMADO |
| P21 | ¿Fix task flow falla porque `spec-executor` no existe? | ✅ CONFIRMADO |
| P22 | ¿TypeScript types de Playwright enmascaran bug de scope `page`? | ✅ CONFIRMADO |
| P23a | ¿VE1 pasará contra hass-taste-test ephemeral? | ⚠️ PARCIAL — HA arranca OK, fix de auth incorrecto |
| P23b | ¿El qa-engineer leerá global.setup.ts antes de ejecutar? | ✅ SÍ |
| P23c | ¿Race condition entre global.setup.ts y test runner? | ✅ NO — health-check funciona |
| P24 | ¿Selector `getByRole('link', 'Integrations')` es incorrecto para HA sidebar? | ✅ CONFIRMADO |
| P25 | ¿Dos bugs ESM en mismo sprint = patrón sistemático? | ✅ CONFIRMADO |
| P26 | ¿Los 4 tipos de verificación estaban mezclados en la pizarra? | ✅ CORREGIDO |
| P27 | ¿El qa-engineer pierde contexto de decisiones de diseño al recibir delegación? | 🔍 ABIERTA — ver Bloque 28, hipotesis H1/H2/H3 |

---

## Fix candidatos acumulados

| ID | Descripción | Estado |
|---|---|---|
| Fix A | Añadir `waitUntil: 'networkidle'` en `goto()` | 🔍 |
| Fix B | Documentar sidebar nav con `data-panel-id` (el fix correcto para navegar en HA) | 🔍 — NO implementado aún |
| Fix C | Documentar 404 → reload pattern en copilot-instructions | 🔍 |
| Fix D | Configurar `baseURL` correctamente (evitar IIFE) | 🔍 |
| Fix E | Proporcionar `hass-taste-test` como docker-compose funcional | ✅ YA EXISTE |
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
| Fix P | Añadir nota ESM en copilot-instructions: `import.meta.url` no `__dirname` | 🔍 URGENTE |
| Fix Q | ~~`goto('/config/integrations')`~~ ❌ MAL DOCUMENTADO — el fix correcto es Fix B (sidebar nav) | ❌ DESCARTADO |
| Fix R | El prompt de delegación a subagentes debe incluir restricciones de diseño, no solo la tarea | 🔍 NUEVO |

---

*Última actualización: Bloque 28 — Fix Q descartado (era erróneo), P27 abierta (pérdida de contexto en delegación), Fix R nuevo (prompts de delegación con restricciones de diseño)*
