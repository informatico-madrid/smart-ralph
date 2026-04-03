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

Hay dos posibles respuestas:

**A) Le falta información** — no sabe cómo funciona HA por dentro (los dos sistemas de routing, que los paneles custom son rutas estáticas, que el storageState no basta sin WebSocket auth). Nadie se lo dijo y no lo puede inferir del código solo.

**B) Le falta metodología** — no tiene un protocolo de diagnóstico que le diga "antes de escribir un test de navegación, experimenta manualmente lo que pasa al navegar sin auth". Sabe las herramientas pero no el orden en que usarlas.

💬 **Nuestra hipótesis de trabajo:** Es principalmente **B**, con un componente de A.

**Por qué esto importa para el sistema:** Si es B, el fix no es documentar más sobre HA — es añadir un paso de research experimental a `phase-rules.md` que aplique a TODOS los proyectos.

---

## PLAN DE PRUEBA ACTIVO — Pipeline paso a paso desde `/start`

### Foco de la prueba

No estamos testeando si el agente "pasa los tests". Estamos testeando si el agente:
1. **Lee el sistema bajo test antes de actuar** (¿lee `panel.py`? ¿`__init__.py`?)
2. **Experimenta antes de asumir** (¿navega manualmente antes de escribir tests de navegación?)
3. **Conoce el ciclo de vida de Playwright** (¿monta `baseURL` de forma segura con puertos dinámicos?)
4. **Emite las señales correctas** (`VERIFICATION_PASS/FAIL/DEGRADED`) para que el hook actúe bien

### Tabla de seguimiento de pasos

| Paso | Comando/Acción | Estado | Observaciones |
|---|---|---|---|
| 1 | `/start` — prompt inicial | ✅ Completado | Ver Bloque 11 |
| 2 | goal-interview — Q1 Scope | ✅ Completado | User: Happy-path only |
| 3 | goal-interview — Q2 Structure | ✅ Completado | User: POM. Agente NO mencionó Shadow DOM |
| 4 | goal-interview — Q3 Test data | ✅ Completado | Ver Bloque 11.5 — experimento CONTAMINADO |
| 5 | goal-interview — Q4 Cleanup | 🔍 En curso | Agente absorbió el dato de localhost:8123. ¿Sabrá qué hacer? |
| 6 | goal-interview — Q5+ | 🔍 Pendiente | ¿Preguntará sobre baseURL dinámico? |
| 7 | spec-executor Phase 1 (research) | 🔍 Pendiente | ¿Lee `panel.py`? ¿experimenta? |
| 8 | spec-executor Phase 2 (scaffold) | 🔍 Pendiente | ¿`baseURL` seguro? |
| 9 | spec-executor Phase 3 (implement) | 🔍 Pendiente | ¿Usa `navigateViaSidebar`? |
| 10 | qa-engineer verifica | 🔍 Pendiente | ¿Emite señal correcta? |

---

## Bloque 11 — Observaciones goal-interview (sesión 2026-04-03)

### 11.1 /start
- ✅ Rama detectada correctamente
- ✅ Skill discovery explícito: `e2e-testing-patterns` + `playwright-best-practices`, descartaró `home-assistant-best-practices` con justificación
- ✅ Leyó `copilot-instructions.md`, infirió `localhost:8123` sin preguntar
- ⚠️ No inspeccionó el único `.spec.ts` existente en el proyecto
- ⚠️ `playwright-results.json` leido de sesión anterior — posible contaminación

### 11.2 Q1 Scope → Happy-path only
- Pregunta bien formulada. User eligió Happy-path only. Correcto.

### 11.3 Q2 Structure → POM
- Opciones claras. User eligió POM.
- ❌ **Agente NO mencionó Shadow DOM** ni en las opciones ni en la descripción del POM.
- **Señal:** Sus skills de POM no contienen el constraint específico de Shadow DOM para HA panels. Esto predice problemas en Phase 3 (implement).

### 11.4 Q3 Test data → CONTAMINACIóN DEL EXPERIMENTO

> **⚠️ HALLAZGO CRÍTICO — Metodología de la prueba**

El observador (Perplexity) sugirió responder Q3 con información técnica que el usuario NO debía conocer a priori:
- Que se usa `hass-taste-test`
- Que el puerto es dinámico
- Cómo usar `process.env` en `baseURL`

El usuario corrigió esto correctamente: **"yo no tengo por qué saber eso, el agente debería buscarlo en sus skills"**.

El usuario respondió solo: *"Per-test setup/teardown, pero importante: el HA de localhost:8123 es mi instancia real, no un contenedor de tests"* — solo el dato que un usuario real conocería.

**Implicación para la investigación:**
- El experimento sigue siendo válido — el agente no recibió información técnica contaminante
- La señal clave se traslada a Phase 1: ¿buscara el agente `hass-taste-test` y el puerto dinámico por sí solo?
- **Nueva pregunta forense emergida:** ¿Contiene la skill `playwright-best-practices` información sobre `hass-taste-test` y puertos dinámicos? Si no → el Fix D (Bloque 9) es imprescindible.

### 11.5 Q4 Cleanup → En curso

El agente procesó correctamente que `localhost:8123` es real y subió una pregunta de seguimiento sobre cleanup.
Opciones ofrecidas:
1. Delete created data after each test (afterEach) — recomendada
2. Manual cleanup only
3. Unique naming + manual review

**¿Qué debería responder el usuario?** La opción 1 es correcta para un entorno real. El usuario puede responder directamente sin dar información técnica adicional.

**Pregunta forense pendiente:** El agente siguió con cleanup asumiendo `localhost:8123` como target de tests. ¿En algún punto de la interview va a preguntar sobre el runner de tests o el baseURL dinámico? Si no pregunta → no tiene esa información en sus skills → Fix D urgente.

---

## Plan de investigación original: estado actual

| # | Pregunta | Estado | Bloque |
|---|---|---|---|
| P1 | ¿Cómo funciona realmente el auth de HA con Playwright? ¿storageState es suficiente? | ✅ Resuelto | Bloque 2 + 7 |
| P2 | ¿Por qué los paneles custom de HA devuelven 404 sin auth en lugar de redirigir? | ✅ Resuelto | Bloque 7 |
| P3 | ¿Por qué `goto` directo a panel falla aunque estemos autenticados? | ✅ Resuelto | Bloque 7 |
| P4 | ¿El bug de `storageState` no guardado era el único bug o había más? | ✅ Resuelto: había más | Bloque 0 |
| P5 | ¿El agente tenía la información disponible o realmente no podía saberlo? | 🔍 A observar en Phase 1 | Bloque 8 |
| P6 | ¿Qué cambio minimal en el sistema habría evitado todos estos fallos? | 💬 En debate | Bloque 9 |
| P7 | ¿El agente sin empújón del usuario habría llegado a la hipótesis del 404/sidebar? | 🔍 A observar en Phase 1 | Bloque 8 |
| P8 | ¿Por qué el agente sigue fallando incluso después de conocer la causa raíz del 404? | ✅ Resuelto | Bloque 10 |
| P9 | ¿Contiene `playwright-best-practices` skill info sobre `hass-taste-test` y puerto dinámico? | 🔍 Nueva — pendiente revisar skill | Bloque 9 |

---

## Bloque 0 — Timeline sesión original (referencia)

**Ronda 1:** `auth.setup.ts` no guarda `storageState`. Fix aplicado. 11 tests siguen fallando.  
**Ronda 2:** Agente teoriza workers/puertos — **hipótesis incorrectas**, tiempo perdido.  
**Ronda 3:** Usuario da el empújón: *"quizás HA te da 404 en lugar de redirigir"*.  
**Ronda 4:** Agente experimenta, confirma, llega a causa raíz.  
**Ronda 5:** Cambia a `navigateViaSidebar()`. Sigue fallando: `sidebar.waitFor()` timeout.  
**Ronda 6:** Diagnostica erróneamente dos instancias HA.

---

## Bloque 10 — ✅ Segundo bug: `baseURL` evaluado antes de `globalSetup`

```typescript
baseURL: (() => {
  // IIFE se ejecuta al CARGAR el fichero — server-info.json no existe aún
  return 'http://localhost:8123';  // ← SIEMPRE cae aquí en primera ejecución
})()
```

Resultado: `baseURL = localhost:8123`, servidor real en puerto dinámico. 31/32 tests fallan.

🔍 **Pregunta clave Paso 8:** ¿El agente monta `baseURL` con `process.env` o cae en IIFE de nuevo?

---

## Bloque 7 — ✅ Los dos sistemas de routing de HA

| Sistema | URLs | Auth |
|---|---|---|
| React Router (SPA) | `/`, `/config`, `/lovelace` | Redirect a login |
| Custom Panels (rutas estáticas) | `/ev-trip-planner-{id}` | **404** si no auth |

**Regla:** Para HA custom panels, NUNCA `page.goto('/panel-url')`. Siempre `navigateViaSidebar()`.

🔍 **Pregunta clave Paso 7:** ¿El agente descubre esto leyendo `panel.py` o escribe tests con `goto` directo?

---

## Bloque 9 — Fixes candidatos

| Fix | Dónde | Qué | Impacto | Costo |
|---|---|---|---|---|
| A | `phase-rules.md` Phase 1 | Experimenta antes de escribir tests para servidores efímeros | Alto | Bajo |
| B | `phase-rules.md` Phase 1 | Lee el sistema bajo test, no solo los tests existentes | Alto | Bajo |
| C | `ha-e2e-testing.skill.md` | Auth HA: 404 vs redirect, sidebar nav obligatoria | Medio | Medio |
| D | `playwright-session.skill.md` | No IIFEs en baseURL. `process.env` desde `globalSetup` | Alto | Bajo |
| E | `playwright-best-practices` skill | Añadir sección: `hass-taste-test`, puertos dinámicos, setup/teardown REST API | Alto | Medio |

> Fix E emergido en esta sesión: la skill `playwright-best-practices` no parece contener información sobre el runner `hass-taste-test` — de lo contrario el agente habría preguntado sobre puerto dinámico en Q3.

---

## Bloque 1 — Ecosistema de testing HA

**Unit/Integration (Python):** `pytest` + `pytest-homeassistant-custom-component`. Sin browser.  
**E2E con browser:** `hass-taste-test` — de facto estándar. Puerto dinámico, onboarding via REST API.  
⚠️ `ha-e2e-testing.skill.md` línea 204 prohíbe usar `hass-taste-test` — contradice el codebase. 🔍 Revisar.

---

## Decisiones tomadas

| # | Decisión | Fecha | Razonamiento |
|---|---|---|---|
| D1 | Prueba nueva desde `/start` con proyecto limpio | 2026-04-03 | Empezamos desde cero para observar comportamiento completo. |
| D2 | Prompt inicial intencionalmente escueto | 2026-04-03 | Caja negra: el agente debe descubrir patrones de HA por sí solo. |
| D3 | Fix mínimo: Panel URL Contract a `requirements.md` | 2026-04-03 | Dato del proyecto, no del sistema. |
| D4 | Fix mínimo: 2 líneas en `phase-rules.md → GREENFIELD Phase 3` | 2026-04-03 | Regla genérica de verificación de URLs. |
| D5 | NO crear `ha-panel-contract.skill.md` | 2026-04-03 | Demasiado acoplado. |
| D6 | Fix principal: regla "experimenta antes de depurar" en `phase-rules.md` | 2026-04-03 | Gatillo metodológico ausente. |
| D7 | Fix D: ciclo de vida Playwright en `playwright-session.skill.md` | 2026-04-03 | Agente no detectó bug IIFE con el código delante. |
| D8 | Mantener experimento limpio: usuario solo da info que conocería un usuario real | 2026-04-03 | El observador (Perplexity) contaminó Q3 sugiriendo info técnica. Corregido. |

---

*Última actualización: 2026-04-03 03:07 CEST — Q3-Q4 completados. Hallazgo: contaminación del experimento en Q3 corregida. Fix E añadido. Pregunta forense P9 añadida.*
