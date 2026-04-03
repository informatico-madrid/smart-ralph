# E2E HA Findings — Pizarra de Investigación Forense

> Rama de trabajo: `research/e2e-ha-findings`  
> **Objetivo de esta investigación:** Reducir el gap entre agentes escribiendo tests malos y tests correctos para HA custom components. Encontrar qué le falta al agente (información, metodología, o ambas) y cómo arreglarlo de forma minimal y reutilizable.  
> **No estamos arreglando el fork.** Estamos analizando por qué el agente falló y qué cambiar en el sistema para que no vuelva a fallar.

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

## LA PREGUNTA FORENSE CENTRAL

> **¿Por qué el agente lleva horas y rondas de depuración sin llegar solo a la causa raíz?**

**A) Le falta información** — no sabe cómo funciona HA por dentro.  
**B) Le falta metodología** — no tiene un protocolo de diagnóstico estructurado.

💬 **Hipótesis actualizada:** Hay un tercer factor emergido en esta sesión:

**C) Las instrucciones en `copilot-instructions.md` son contradictorias** — dicen `localhost:8123` como instancia de test PERO el docker-compose no existe. El agente lee la instrucción, asume que el entorno está montado, y falla. No es falta de metodología ni de información: es que la fuente de verdad del proyecto está rota.

---

## ⚠️ HALLAZGO CRÍTICO P10 — copilot-instructions.md es contradictor io

### Lo que dice `.github/copilot-instructions.md` en `ha-ev-trip-planner`

```markdown
## 🏠 HOME ASSISTANT INSTANCES - PRODUCTION VS TEST

### Test Instance (test-ha)
- **URL**: `http://localhost:8123`
- **Docker**: `test-ha/docker-compose.yml`
- **Credentials and Access**: In `$PROJECT_ROOT/.env`
- **Purpose**: E2E tests, verifications during development
```

También menciona **Shadow DOM** explícitamente:
```markdown
Interacción a través del Shadow DOM: Debes localizar los campos de entrada utilizando el combinador
de Shadow DOM de Playwright (ej. page.locator('ev-trip-planner-panel >> #campo-destino').fill('Madrid')).
```

### El problema

1. **`test-ha/docker-compose.yml` NO existe en el repositorio** (confirmado en sesión anterior).
2. **`localhost:8123` es la instancia de producción real del usuario**, no un contenedor de tests.
3. El agente lee `copilot-instructions.md` → ve `localhost:8123` como URL de tests → asume que el entorno está montado → escribe tests apuntando a producción → error arquitectónico grave.

### Implicación forense

**El agente no estaba completamente equivocado.** Estaba siguiendo las instrucciones del proyecto. El fallo no está únicamente en sus skills — está en que `copilot-instructions.md` describe una infraestructura que no existe.

Esto modifica nuestra hipótesis: es **A + B + C**. La información que el agente tiene (copilot-instructions) es incorrecta, y no tiene metodología para validar que el entorno descrito realmente existe antes de usarlo.

### Fix necesario: dos niveles

| Nivel | Fix | Dónde |
|---|---|---|
| Proyecto | Actualizar `copilot-instructions.md` para reflejar la realidad: `test-ha/` no existe, usar `hass-taste-test` | `ha-ev-trip-planner/.github/copilot-instructions.md` |
| Sistema | Añadir regla en `phase-rules.md`: "Antes de usar infraestructura descrita en instrucciones del proyecto, verifica que existe" | `phase-rules.md` en smart-ralph |

### Lo positivo del hallazgo

`copilot-instructions.md` SÍ menciona:
- Shadow DOM con ejemplo concreto (`>> #campo-destino`) ✔️
- Flujo completo requerido (click, fill, save, validate) ✔️
- Playwright como herramienta ✔️

**Conclusión:** El agente tiene la información sobre Shadow DOM disponible. Si no la usó bien, es problema de metodología (B), no de información (A).

---

## PLAN DE PRUEBA ACTIVO — Pipeline paso a paso desde `/start`

### Tabla de seguimiento de pasos

| Paso | Comando/Acción | Estado | Observaciones |
|---|---|---|---|
| 1 | `/start` — prompt inicial | ✅ Completado | Ver Bloque 11 |
| 2 | goal-interview — Q1 Scope | ✅ Completado | User: Happy-path only |
| 3 | goal-interview — Q2 Structure | ✅ Completado | User: POM. Agente NO mencionó Shadow DOM (aunque está en copilot-instructions) |
| 4 | goal-interview — Q3 Test data | ✅ Completado | User: per-test setup/teardown, localhost:8123 es real |
| 5 | goal-interview — Q4 Cleanup | ✅ Completado | User: delete after each test |
| 6 | goal-interview — Q5 Test HA | 🔍 En curso | Agente pregunta cómo levantar instancia dedicada. ¿Descubrirá `hass-taste-test`? |
| 7 | spec-executor Phase 1 (research) | 🔍 Pendiente | ¿Lee `panel.py`? ¿experimenta? |
| 8 | spec-executor Phase 2 (scaffold) | 🔍 Pendiente | ¿`baseURL` seguro? |
| 9 | spec-executor Phase 3 (implement) | 🔍 Pendiente | ¿Usa `navigateViaSidebar`? |
| 10 | qa-engineer verifica | 🔍 Pendiente | ¿Emite señal correcta? |

### Q5 — Opciones que ofrece el agente

1. **[Recommended] Docker compose with HA + ev_trip_planner** — Crear `test-ha/docker-compose.yml`. Clean, reproducible, CI-friendly.
2. **Use GitHub Actions HA instance** — HA's official test environment.
3. **Use a second bare-metal HA install** — puerto diferente (ej: 8124).
4. **Other**

**Observación crítica:** El agente propone Docker como recomendado — esto coincide con lo que dice `copilot-instructions.md` (`test-ha/docker-compose.yml`). El agente está siguiendo las instrucciones del proyecto. Pero **NO menciona `hass-taste-test`**, que es lo que ya está en `package.json` como dependencia instalada.

**Pregunta forense:** ¿Leyó el agente `package.json` donde está `hass-taste-test`? Si sí lo leyó pero no lo propone → no sabe qué es. Si no lo leyó → falta de exploración del codebase.

### ¿Qué debe responder el usuario en Q5?

Opción 1 (Docker) es la más correcta arquitecturalmente y coincide con `copilot-instructions.md`. El usuario puede seleccionarla directamente — es lo que un usuario normal diría ("quiero Docker, es lo más limpio"). **No necesita mencionar `hass-taste-test`** — el agente debe descubrirlo en Phase 1 al leer `package.json`.

---

## Bloque 11 — Observaciones goal-interview (sesión 2026-04-03)

### 11.1 /start
- ✅ Skill discovery explícito y correcto
- ✅ Leyó `copilot-instructions.md`, infirió `localhost:8123`
- ⚠️ No inspeccionó el único `.spec.ts` existente
- ⚠️ Leyó `playwright-results.json` de sesión anterior

### 11.3 Q2 → POM
- ❌ **Agente NO mencionó Shadow DOM** en la descripción del POM
- **PERO:** `copilot-instructions.md` sí tiene Shadow DOM con ejemplo. El agente lo leyó. ¿Por qué no lo incluyó en la pregunta? ⇒ Posible problema de contexto window: leyó el archivo pero no lo vinculó al diseño del POM.

### 11.4 Q3 → Contaminación corregida
- El observador (Perplexity) sugirió info técnica que el usuario no debía dar. Corregido. Anotado como D8.

### 11.5 Q5 → Test HA instance
- Agente propone Docker (correcto) pero no menciona `hass-taste-test` (ya instalado)
- Confirma que copilot-instructions guia al agente hacia Docker — la contradicción está en que el docker-compose no existe

---

## Plan de investigación: estado actual

| # | Pregunta | Estado | Bloque |
|---|---|---|---|
| P1-P4 | Auth, 404, routing, bugs | ✅ Resueltos | Bloques 2,7,10 |
| P5 | ¿El agente tenía información disponible? | 💬 Parcialmente respondido — copilot-instructions sí tenía Shadow DOM pero agente no lo usó en Q2 | Bloque 11.3 |
| P6 | ¿Qué cambio minimal habría evitado los fallos? | 💬 En debate — ahora incluye fix en copilot-instructions | Bloque 9 |
| P7 | ¿Habría llegado solo a la hipótesis del 404? | 🔍 A observar en Phase 1 | Bloque 8 |
| P8 | ¿Por qué falló incluso después de conocer la causa? | ✅ Resuelto | Bloque 10 |
| P9 | ¿Contiene `playwright-best-practices` info sobre `hass-taste-test`? | 🔍 Pendiente — agente no lo mencionó en Q5 aunque está en package.json | Bloque 11.5 |
| P10 | ¿`copilot-instructions.md` describe infraestructura que no existe? | ✅ CONFIRMADO — `test-ha/docker-compose.yml` no existe, URL es producción | Bloque P10 |

---

## Bloque 9 — Fixes candidatos

| Fix | Dónde | Qué | Impacto | Costo |
|---|---|---|---|---|
| A | `phase-rules.md` Phase 1 | Experimenta antes de escribir tests para servidores efímeros | Alto | Bajo |
| B | `phase-rules.md` Phase 1 | Lee el sistema bajo test, no solo los tests existentes | Alto | Bajo |
| C | `ha-e2e-testing.skill.md` | Auth HA: 404 vs redirect, sidebar nav obligatoria | Medio | Medio |
| D | `playwright-session.skill.md` | No IIFEs en baseURL | Alto | Bajo |
| E | `playwright-best-practices` skill | Añadir sección `hass-taste-test`, puertos dinámicos | Alto | Medio |
| F | `ha-ev-trip-planner/copilot-instructions.md` | Corregir contradicción: `test-ha/` no existe, usar `hass-taste-test` | Alto | Bajo |
| G | `phase-rules.md` Phase 1 | Verificar que la infraestructura descrita en instrucciones realmente existe antes de usarla | Alto | Bajo |

---

## Bloque 10 — ✅ Segundo bug: `baseURL` IIFE

```typescript
baseURL: (() => { return 'http://localhost:8123'; })()
// IIFE al cargar config — antes de globalSetup — siempre falla
```

---

## Bloque 7 — ✅ Los dos sistemas de routing de HA

| Sistema | URLs | Auth |
|---|---|---|
| React Router (SPA) | `/`, `/config`, `/lovelace` | Redirect a login |
| Custom Panels | `/ev-trip-planner-{id}` | **404** si no auth |

**Regla:** NUNCA `page.goto('/panel-url')`. Siempre `navigateViaSidebar()`.

---

## Decisiones tomadas

| # | Decisión | Fecha | Razonamiento |
|---|---|---|---|
| D1-D7 | (ver historial) | 2026-04-03 | |
| D8 | Mantener experimento limpio: usuario solo da info que conocería un usuario real | 2026-04-03 | Perplexity contaminó Q3. Corregido. |
| D9 | Fix F prioritario: corregir `copilot-instructions.md` del proyecto | 2026-04-03 | Fuente de verdad rota — el agente sigue instrucciones incorrectas. |

---

*Última actualización: 2026-04-03 03:14 CEST — P10 CONFIRMADO: copilot-instructions describe infraestructura inexistente. Fix F+G añadidos. Hipótesis expandida a A+B+C.*
