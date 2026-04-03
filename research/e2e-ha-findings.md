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
| 18 | qa-engineer verifica task 1.8 — VE1 | ⚠️ En progreso | Ver Bloque 26 — HA arranca, auth selector falla |

---

## Bloque 26 — ⚠️ VE1: RESULTADOS PARCIALES — HA arranca pero auth falla

### Secuencia de fallos observada en VE1

El qa-engineer corrió `npx playwright test tests/e2e/vehicle.spec.ts --timeout=180000` tres veces. Cada iteración encontró un fallo diferente. Esto es un patrón en capas ("fallo A → fix → fallo B → fix → fallo C").

---

#### ❌ Fallo 1 (intento 1): `__dirname is not defined in ES module scope`

```
ReferenceError: __dirname is not defined in ES module scope
    at file:///mnt/.../playwright.config.ts:21:26
```

**Causa raíz:** El proyecto usa `"type": "module"` en `package.json` (ESM). El agente usó `__dirname` en `playwright.config.ts`, que es una variable CommonJS no disponible en ESM.

**Fix aplicado:** Reemplazar `__dirname` por `fileURLToPath(new URL('.', import.meta.url))`.

**Análisis forense:** Este es el **bug ESM clásico** de Node.js. El agente que escribió `playwright.config.ts` no verificó si el proyecto era CJS o ESM. TypeScript NO detectó este error (funciona en compilación, falla en runtime ESM).

---

#### ❌ Fallo 2 (intento 2): `require is not defined in ES module scope` en auth.setup.ts

```
ReferenceError: require is not defined in ES module scope
   at auth.setup.ts:94
94 | if (require.main === module) {
```

**Causa raíz:** El mismo problema ESM. El coordinador añadió `if (require.main === module)` para permitir ejecutar `auth.setup.ts` como script standalone, pero `require` no existe en ESM.

**Fix aplicado:** Reemplazar por el equivalente ESM:
```typescript
// ESM equivalent of require.main === module
const isMain = import.meta.url === `file://${process.argv[1]}`;
if (isMain) { runAuthSetup()... }
```

**Análisis forense:** El coordinador introdujo este bug al restructurar `auth.setup.ts` en Bloque 22. Es un segundo bug ESM en el mismo archivo, mismo origen.

---

#### ❌ Fallo 3 (intento 3 — ACTUAL): `TimeoutError` en auth.setup.ts línea 41

```
TimeoutError: locator.click: Timeout 30000ms exceeded.
Call log:
  - waiting for getByRole('link', { name: 'Integrations' })

   at auth.setup.ts:41
41 |     await page.getByRole('link', { name: 'Integrations' }).click();
```

**Contexto relevante del log:**
```
[GlobalSetup] Server URL: http://127.0.0.1:8531/?auth_callback=1&code=...&state=...
[GlobalSetup] Running Config Flow authentication...
[AuthSetup] Starting Config Flow authentication...
[AuthSetup] Step 1: Navigate to integrations...
```
→ HA arrancó correctamente y generó una URL de auth_callback. El auth con token funcionó. El problema es el **selector del paso siguiente**.

**Análisis:**
- La URL que HA generó es un `auth_callback` con código de autorización: `http://127.0.0.1:8531/?auth_callback=1&code=...`
- `auth.setup.ts` navega a esa URL con el token de auth ya configurado en `storageState`
- Después intenta hacer `page.getByRole('link', { name: 'Integrations' })` — espera un link de texto "Integrations"
- **Ese link no existe en esa URL**. La UI de HA en `/` muestra el dashboard, no la sidebar con texto "Integrations"

**Hipótesis del fallo:**
- **H1:** Después del auth_callback, el navegador está en la home `/` o en el dashboard, no en `/config/integrations`. El link "Integrations" es la entrada de la sidebar, que en HA puede estar colapsada o no tener ese exact text.
- **H2:** El auth_callback URL redirige a la home pero el auth state no persiste correctamente, por lo que la página que carga no muestra la sidebar de usuario logueado.
- **H3:** En hass-taste-test, la sidebar tiene un item diferente — quizás `data-panel-id="config"` en lugar de texto "Integrations"

**Dato clave del log:**
```
[GlobalSetup] Copied panel.js to: /tmp/hasstest-6nbakS/www/panel.js
[GlobalSetup] Waiting for HA to be ready...
[GlobalSetup] Server URL: http://127.0.0.1:8531/?auth_callback=1&...
```
→ `global.setup.ts` copia el panel.js Y genera el auth_callback URL. Esto confirma que `hass-taste-test` está funcionando correctamente — el custom component está montado y el servidor está up.

---

### P23 RESUELTA PARCIALMENTE

| Sub-pregunta | Estado | Resultado |
|---|---|---|
| P23a — ¿VE1 pasará? | ⚠️ Parcial | HA arranca ✅, auth selector falla ❌ |
| P23b — ¿qa-engineer lee global.setup.ts? | ✅ SÍ | Leyó global.setup.ts y auth.setup.ts antes de cada fix |
| P23c — ¿Race condition? | ✅ NO hay | global.setup.ts tiene health-check, HA espera a estar ready |

---

### P24 NUEVA — El selector `getByRole('link', { name: 'Integrations' })` es incorrecto para HA

**Observación:** Este es el bug más importante del VE1. `auth.setup.ts` asume que tras el login hay un link con texto "Integrations" visible. En HA, la sidebar usa web components propios con `data-panel-id` attributes, no links de texto plano.

**El patrón correcto para navegar a Settings > Integrations en HA:**
```typescript
// INCORRECTO (lo que tiene auth.setup.ts):
await page.getByRole('link', { name: 'Integrations' }).click();

// CORRECTO (navegar directamente a la URL):
await page.goto('/config/integrations');
// O via sidebar:
await page.locator('[data-panel-id="config"]').click();
await page.locator('ha-config-navigation a[href*="integrations"]').click();
```

**Implicación forense crítica:**
> Este bug estaba en el **design original** (que fue aprobado por el spec-reviewer). Nadie lo detectó porque el design usaba pseudocódigo de alto nivel (`"navigate to integrations page"`) que el executor tradujo a un selector incorrecto. El **único detector posible era VE1** — ejecutar los tests reales.

**Esto confirma definitivamente** que la verificación estática (TypeScript, linting, artifact reviewer) no puede sustituir la ejecución real. Los tests E2E **son** la única verificación real.

---

### P25 NUEVA — Dos bugs ESM en el mismo sprint = patrón de fallo sistemático

**Observación:** Dos archivos distintos (`playwright.config.ts` y `auth.setup.ts`) tenían bugs ESM (`__dirname` y `require.main`). Ambos escritos por agentes diferentes, ambos en el mismo sprint.

**Hipótesis:** Los agentes no verifican si el proyecto es CJS o ESM antes de escribir código. Asumen CJS por defecto porque es el patrón más común en sus datos de entrenamiento.

**Dato de contexto:** El proyecto usa `"type": "module"` en `package.json`. Esto está visible en el archivo, pero los executors no lo consultaron antes de escribir `__dirname` o `require.main`.

**Fix candidato P:** Añadir en `copilot-instructions.md` una nota explícita: `"Este proyecto usa ESM. Usa import.meta.url en lugar de __dirname, e import() en lugar de require()."`

---

### Concepto aclarado: "verificación real" vs "tests E2E"

**¿Los tests E2E no son la verificación real?**

Sí, los tests E2E **son** la verificación real — son exactamente eso. Lo que en la pizarra llamamos "VE1" (verificación real) ES el test E2E ejecutándose contra HA.

Lo que quería decir en Bloque 23 con "el único detector real era VE1" es:
- TypeScript check = verificación **estática** (sin ejecutar)
- Artifact reviewer = verificación **de lectura** (sin ejecutar)
- `npx playwright test` = verificación **de ejecución** = "verificación real" = los tests E2E corriendo de verdad

El bug de `page` out-of-scope (P22) no era detectable por TypeScript porque los tipos de Playwright declaran `page` como global. Solo se hubiera manifestado cuando el test intentara acceder a `page` en runtime — es decir, al ejecutar los tests E2E. Los tests E2E son siempre la fuente de verdad final.

---

## Bloque 25 — ⚠️ VE1: qa-engineer recibe task 1.8 — Ver Bloque 26

*(Actualizado — ver Bloque 26 para resultados)*

---

## Bloque 24 — ✅ taskIndex advancement: coordinador gestiona estado directamente

### Observación forense
Tras el bloqueo de P21 (`spec-executor` unknown), el **coordinador no se quedó bloqueado indefinidamente**. En la sesión actual:

1. **Ejecutó los fix tasks directamente** (sin delegar a spec-executor)
2. **Avanzó manualmente el `taskIndex`** de 6 a 8 con jq
3. **Marcó task 1.7 (TypeScript check) como completa** al verificar que `npx tsc --noEmit` pasaba
4. **Delegó correctamente task 1.8** al qa-engineer

### Fix candidato O
Documentar en `phase-rules.md` qué ocurre cuando `spec-executor` no está disponible.

---

## Bloque 23 — ✅ P22: Bug `page` out-of-scope en test functions de trip.spec.ts

### El bug
```typescript
// ANTES (incorrecto — page no está en scope):
test('US-3 + US-4: create recurring trip...', async () => {
  await expect(page.locator('ev-trip-planner-panel >> .trip-card')).toContainText('25.5');
});
// DESPUÉS (correcto):
test('US-3 + US-4: create recurring trip...', async ({ page }) => { ... });
```

### Análisis forense
**¿Por qué TypeScript no lo detectó?** `@playwright/test` declara `page` como tipo global en sus definiciones, enmascarando el error de scope. **El único detector real era VE1 (ejecutar los tests).**

---

## Bloque 22 — ⚠️ Fix Tasks: spec-executor bloqueado → coordinador ejecutó directamente

*(Ver descripción completa en versiones anteriores de la pizarra)*

### Commits de fix (en orden)
```
09ee089 fix(e2e): invoke auth.setup.ts via setupProject (WRONG — no existe en PW 1.58)
3d28971 fix(e2e): move dialog handler from POM deleteTrip to test beforeEach
b876fe6 fix(e2e): remove leading space from hass-integration-card locator
eb8f921 fix(e2e): replace browserPage fixture with page in trip.spec.ts
5851fc6 fix(e2e): update playwright configuration and integrate auth setup (FIX CORRECTO del auth)
ce67f27 fix(e2e): add page fixture to trip test functions (P22 fix)
```

---

## Bloque 21 — ✅ Artifact Reviewer: REVIEW_FAIL (3 críticos, 3 importantes)

| # | Archivo | Problema |
|---|---|---|
| C1 | `playwright.config.ts` | `auth.setup.ts` nunca invocado — falta `setupProject` |
| C2 | `trip.spec.ts` | Usa fixture `browserPage` (no existe en Playwright) en vez de `page` |
| C3 | `trip.spec.ts` | `afterEach` referencia `tripId` indefinido |
| I1 | `EVTripPlannerPage.ts` | `this.page.on('dialog', ...)` dentro de `deleteTrip()` |
| I2 | `vehicle.spec.ts` | Locator con espacio inicial: `' hass-integration-card'` |
| I3 | `trip.spec.ts` | `beforeEach` no sigue el patrón de diseño |

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
| P22 | ¿TypeScript types de Playwright enmascaran bug de scope `page`? | ✅ CONFIRMADO — ver Bloque 23 |
| P23a | ¿VE1 pasará contra hass-taste-test ephemeral? | ⚠️ PARCIAL — HA arranca OK, auth selector falla |
| P23b | ¿El qa-engineer leerá global.setup.ts antes de ejecutar? | ✅ SÍ |
| P23c | ¿Race condition entre global.setup.ts y test runner? | ✅ NO — health-check funciona |
| P24 | ¿Selector `getByRole('link', Integrations')` es incorrecto para HA sidebar? | ✅ CONFIRMADO — ver Bloque 26 |
| P25 | ¿Dos bugs ESM en mismo sprint = patrón sistemático? | ✅ CONFIRMADO — agentes asumen CJS por defecto |

---

## Fix candidatos acumulados

| ID | Descripción | Estado |
|---|---|---|
| Fix A | Añadir `waitUntil: 'networkidle'` en `goto()` | 🔍 |
| Fix B | Documentar sidebar nav con `data-panel-id` | 🔍 |
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
| Fix Q | Corregir selector auth.setup.ts: `goto('/config/integrations')` en vez de `getByRole('link', 'Integrations')` | 🔍 URGENTE |

---

*Última actualización: Bloque 26 — VE1 running: HA arranca OK, 2 bugs ESM corregidos por qa-engineer, fallo 3 en auth selector HA sidebar, P24+P25 confirmadas*
