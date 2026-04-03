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
| 12 | Phase 1 — research-analyst | ⚠️ Bloqueado/timeout | Agente no retornó. Flujo detenido. |
| 13 | Phase 2 — scaffold | 🔍 Pendiente | Desbloqueado manualmente |
| 14 | Phase 3 — implement | 🔍 Pendiente | |
| 15 | qa-engineer verifica | 🔍 Pendiente | |

---

## Bloque 14 — ✅ Phase 1 Explore: Hallazgos críticos

### Hallazgo 14.1 — ⚠️ CONTRADICCIÓN DOCKER CONFIRMADA (Fix F validado)

Existen **dos docker-compose distintos** en el repo:

| Archivo | Propósito real | Estado |
|---|---|---|
| `docker-compose.yml` (raíz) | Manual testing. Puerto **8124**. Volumenes locales hardcodeados. | Existe, pero NO es para CI |
| `test-ha/docker-compose.yml` | Lo que describe `copilot-instructions.md` para tests | **NO EXISTE** |

`copilot-instructions.md` apunta a `test-ha/docker-compose.yml` que no existe. El agente en la interview dijo "Docker compose" asumiendo que existe. **Fix F es urgente e independiente del experimento.**

### Hallazgo 14.2 — ✅ hass-taste-test ya lo gestiona todo (invalida el Docker approach)

**Esto es el hallazgo más importante de Phase 1:**

`global.setup.ts` ya existe y usa `hass-taste-test` para levantar HA efímero:
```typescript
import { HomeAssistant, PlaywrightBrowser } from 'hass-taste-test';
const hassInstance = await HomeAssistant.create(`...yaml config...`, {
  python: process.env.PYTHON_PATH || 'python3',
  browser: new PlaywrightBrowser('chromium'),
  customComponents: [evTripPlannerPath],
});
// Guarda server-info.json con el puerto dinámico
```

**Implicación crítica:** El agente propuso crear `test-ha/docker-compose.yml` (approach A de la interview), pero **el codebase ya tiene una solución mejor**: `hass-taste-test` levanta HA efímero sin Docker. El GitHub Actions workflow ya lo usa correctamente:
```yaml
- name: Get Python path for hass-taste-test
  run: echo "PYTHON_PATH=$(which python3)" >> $GITHUB_ENV
```

**Pregunta forense activa:** ¿El agente, al leer este `global.setup.ts`, actualizará su plan y abandonará el approach Docker en favor de `hass-taste-test`? O ¿creará `test-ha/docker-compose.yml` de todas formas porque la interview lo decidió?

### Hallazgo 14.3 — ⚠️ Shadow DOM: Explore NO encontró `navigateViaSidebar`

El Explore agent documentó correctamente las opciones de Shadow DOM:
- `locator('ev-trip-planner-panel').locator('pierce/.trip-card')`
- `page.evaluate()` para acceder al Shadow DOM

Pero **no encontró** ningún patrón de navegación al panel. Solo documentó la URL: `/ev-trip-planner-{vehicle_id}`.

❌ **NO hay `navigateViaSidebar` en el codebase** — no existe como función implementada. El agente tendrá que inventarla o usar `page.goto()` directo.

**Pregunta forense:** ¿Sabe el agente que `page.goto('/ev-trip-planner-chispitas')` dará 404 sin auth correcta? ¿O asumirá que basta el storageState?

### Hallazgo 14.4 — ✅ CSS selectors del panel (disponibles)

El Explore agent identificó los selectores reales del panel:
- Botón añadir viaje: `.add-trip-btn`
- Modal formulario: `.trip-form-overlay`, `.trip-form-container`
- Lista viajes: `.trips-list`, `.trip-card[data-trip-id]`
- Estado vacío: `.no-trips`

**Nota:** Estos selectores están dentro del Shadow DOM de `ev-trip-planner-panel`.

### Hallazgo 14.5 — Tensión Jest vs Playwright

`package.json` tiene dos frameworks mezclados:
- `jest` ^30.3.0 (tests existentes con `.test.js`)
- `@playwright/test` ^1.58.2 (para e2e con `.spec.ts`)

Los scripts `test:e2e` y `test:ui` usan `jest`, no `playwright`. El workflow de GitHub Actions usa `npx playwright test tests/e2e/`. **El agente tendrá que decidir cuál usa** — si copia el patrón de `package.json` usará jest, si sigue el workflow usará playwright.

### Hallazgo 14.6 — Incidente: research-analyst bloqueado

El agente principal se quedó esperando al research-analyst que no retornó. El flujo se detuvo.

**Implicación para el sistema:** El mecanismo de coordinación de subagentes no tiene timeout. Si un subagente falla o tarda, el agente principal se bloquea indefinidamente. ⇒ **Fix H candidato:** `phase-rules.md` debería especificar un timeout máximo de espera y cómo proceder cuando un subagente no retorna.

---

## Bloque 12 — Interview: Análisis forense

| Capturado | NO capturado |
|---|---|
| Happy-path, POM, Docker, CI, Chromium | Shadow DOM (`pierce/` selector) |
| Docker test HA ≠ localhost:8123 | `page.goto` vs sidebar nav |
| Separate tests per action | `baseURL` dinámico / puerto efímero |
| | `hass-taste-test` reemplaza Docker |

**Progreso.md sí mencionó Shadow DOM** (de copilot-instructions). Pero no como constraint de arquitectura.

---

## Plan de investigación: estado

| # | Pregunta | Estado |
|---|---|---|
| P1-P4 | Auth, 404, routing, bugs | ✅ Resueltos |
| P5 | ¿El agente tenía info disponible? | ✅ Confirmado: sí, en copilot-instructions y global.setup.ts |
| P6 | ¿Qué fix minimal habría evitado los fallos? | 💬 Fix F (copilot-instructions) + E (hass-taste-test skill) + G (verificar infra) |
| P7 | ¿Habría llegado solo al 404/sidebar? | 🔍 A observar en Phase 3 |
| P8 | ¿Por qué falló tras conocer la causa? | ✅ IIFE baseURL |
| P9 | ¿Playwright-best-practices tiene info de hass-taste-test? | ⚠️ Probable sí (agente lo nombró en research) |
| P10 | ¿Copilot-instructions describe infra inexistente? | ✅ CONFIRMADO |
| P11 | ¿Explore agent verifica que docker-compose no existe? | ⚠️ Parcial — detectó que `test-ha/` no existe, propuso hass-taste-test como alternativa |
| P12 | ¿Agente actualiza plan Docker → hass-taste-test al ver global.setup.ts? | 🔍 A observar en Phase 2 |
| P13 | ¿El mecanismo de subagentes tiene timeout? | ❌ NO — agente bloqueado indefinidamente |

---

## Bloque 9 — Fixes candidatos (actualizado)

| Fix | Dónde | Qué | Prioridad |
|---|---|---|---|
| A | `phase-rules.md` | Experimenta antes de escribir tests | Alta |
| B | `phase-rules.md` | Lee el sistema bajo test | Alta |
| C | `ha-e2e-testing.skill.md` | Auth HA: 404, sidebar nav | Media |
| D | `playwright-session.skill.md` | No IIFEs en baseURL | Alta |
| E | `playwright-best-practices` skill | `hass-taste-test`, puertos dinámicos | Alta |
| F | `ha-ev-trip-planner/copilot-instructions.md` | Corregir infra inexistente | **Urgente** |
| G | `phase-rules.md` | Verificar que infra descrita existe | Alta |
| H | `phase-rules.md` | Timeout para subagentes + cómo proceder si no retornan | Media |

---

## Bloque 7 — ✅ Los dos sistemas de routing de HA

| Sistema | URLs | Auth |
|---|---|---|
| React Router (SPA) | `/`, `/config` | Redirect a login |
| Custom Panels | `/ev-trip-planner-{id}` | **404** si no auth |

**Regla:** NUNCA `page.goto('/panel-url')` directo. Confirmar si `navigateViaSidebar` existe o hay que crearlo.

---

*Última actualización: 2026-04-03 03:32 CEST — Phase 1 Explore completado. research-analyst bloqueado. Fix H añadido. Pregunta forense P12 añadida: ¿El agente actualiza Docker → hass-taste-test?*
