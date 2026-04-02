# E2E HA Findings — Pizarra de Investigación

> Rama de trabajo: `research/e2e-ha-findings`  
> Propósito: borrador vivo donde anotamos lo que investigamos, debatimos y rebatimos sobre e2e testing en proyectos HA custom component.
> **No es documentación definitiva.** Es una pizarra. Las entradas pueden estar en discusión, rebatidas o pendientes de verificar.

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

## Bloque 1 — ¿Qué herramienta de E2E debe usar el agente para HA?

### 1.1 Ecosistema oficial de testing HA

**Unit/Integration (Python):** ✅  
La documentación oficial de HA developers solo menciona `pytest` + `pytest-homeassistant-custom-component` para tests de integración. No hay referencia oficial a ninguna herramienta de E2E de browser.
- Fuente: https://developers.home-assistant.io/docs/development_testing/
- Esto cubre: config flows, entity states, service calls — todo via Python sin browser.
- Para E2E de *panel custom (frontend)*, pytest no llega. El agente necesita browser.

**E2E con browser:** `hass-taste-test` ✅ (de facto estándar para custom components)
- Es la única librería madura específica para HA E2E con browser.
- Framework-agnóstica: soporta Playwright (único browser integration actual), Jest, Vitest.
- Mecanismo: levanta HA como subprocess Python (no Docker), puerto dinámico, onboarding via REST API.
- Repo: https://github.com/rianadon/hass-taste-test
- ⚠️ CAVEAT: El repo tiene actividad baja (último commit relevante 2021-2023). Hay que verificar compatibilidad con versiones recientes de HA.
- 🔍 PENDIENTE: ¿Funciona con HA 2024.x/2025.x? ¿Hay alternativas más activas?

**Alternativas investigadas y descartadas:**
- `galata` (JupyterLab) ❌ — específico de JupyterLab, no aplica
- `pytest-homeassistant` ❌ — solo Python, sin browser
- Playwright puro sin `hass-taste-test` ⚠️ — viable pero requiere gestionar manualmente el levantado de HA, onboarding y puerto dinámico. Mayor complejidad.

### 1.2 ¿Debería el agente descubrir esto autónomamente?

💬 **En debate:**  
La hipótesis es que en la fase de research el agente debería:
1. Leer `global.setup.ts` del codebase → ver que usa `hass-taste-test` → entender el mecanismo
2. Usar MCP Playwright para navegar a la documentación de la versión concreta de HA del proyecto
3. Navegar el código fuente del componente antes de escribir cualquier test

**Problema identificado:** El skill `ha-e2e-testing` (cargado por el agente) tiene una instrucción contradictoria: prohíbe usar `hass-taste-test` (línea 204: "No importar hass-taste-test") pero el codebase ya lo usa. El agente siguió el codebase, lo cual fue correcto, pero la skill introduce ruido.

**Acción pendiente:** revisar `ha-e2e-testing.skill.md` — la prohibición puede estar desactualizada o mal redactada.

---

## Bloque 2 — El login form de HA no es un form HTML estándar

### 2.1 Realidad del onboarding/login de HA

✅ **Confirmado por investigación:**  
El flujo de login de Home Assistant NO es un formulario HTML estándar. Es un Web Component (`<ha-onboarding>` / login flow de LitElement) con múltiples pasos:
1. Step 1: Onboarding inicial (solo primera vez) — crea usuario admin
2. Step 2: Login form posterior — `<ha-auth-flow>` con campos de username/password

**El problema con `playwright-session.skill.md → authMode: form`:**  
`authMode: form` asume `<input type="text">` y `<input type="password">` accesibles directamente vía snapshot de accesibilidad. El login de HA usa shadow DOM de LitElement, lo que puede hacer que los selectores estándar no resuelvan correctamente sin `browser_generate_locator` o sin piercing del shadow DOM.

⚠️ **La skill no tiene un authMode específico para HA onboarding multi-paso.**  
El agente llegó a `authMode: form`, no encontró el patrón esperado, e improvisó. No es culpa del agente — es un gap de la skill.

### 2.2 ¿Hay algo definido/probado para el login de HA con Playwright?

✅ **hass-taste-test gestiona el onboarding via REST API**, no via browser:  
- Llama a `/api/onboarding/users` para crear el usuario inicial
- Llama a `/auth/token` para obtener tokens
- El browser solo se usa DESPUÉS del onboarding, con la sesión ya autenticada
- Esto es la práctica correcta: no simular el login en el browser, obtener el token por API y cargarlo como cookie/storage-state

🔍 **PENDIENTE:** Verificar exactamente cómo `hass-taste-test` inyecta el token en el browser context — ¿cookie? ¿localStorage? ¿storage-state?

### 2.3 Implicación para `playwright-session.skill.md`

💬 **Propuesta en debate:**  
No añadir un `authMode: ha-onboarding` — eso sería demasiado acoplado a HA.  
En cambio, documentar en `playwright-session.skill.md` que para apps con Web Components / shadow DOM, `authMode: form` puede fallar y la alternativa preferida es obtener el token por API y usar `authMode: token` o `authMode: storage-state`.

Esto es genérico (aplica a cualquier app LitElement/shadow DOM) y no está acoplado a HA.

---

## Bloque 3 — `goto` vs `click` en navegación Playwright

### 3.1 ¿Cuándo usar `page.goto()` vs `locator.click()`?

✅ **Documentación oficial Playwright (microsoft/playwright/docs/navigations.md):**

| Situación | Método recomendado | Razón |
|---|---|---|
| Navegación inicial / URL directa conocida | `page.goto(url)` | No hay elemento en el que hacer click, es la entrada al flujo |
| Navegación causada por interacción del usuario (link, botón) | `locator.click()` | Auto-waits: espera a que el elemento sea visible, estable, habilitado y reciba eventos. Luego espera a que la navegación complete. |
| Navegar a un panel HA después del Config Flow | `locator.click()` **si existe el link en el sidebar** | Simula el comportamiento real del usuario |
| Navegar a un panel HA cuando la URL ya se conoce y no hay link accesible | `page.goto(url)` | Aceptable como último recurso |

**El problema del agente:** usó `page.goto()` para navegar al panel `ev-trip-planner-coche2` **sin verificar que la URL existía** — navegó a ciegas. Si el panel no estaba registrado aún, el goto devuelve un 404 silencioso (HA no hace redirect de error estándar, simplemente muestra la UI de HA sin el panel).

✅ **Práctica recomendada para panels HA:**  
1. Preferir click en el sidebar (más realista, verifica que el panel está registrado Y visible)  
2. Si se usa `goto`, hacer `browser_snapshot` inmediatamente después y verificar que el web component del panel está en el DOM — no asumir que el goto fue exitoso.

### 3.2 Implicación para el skill

💬 Esta regla debería vivir en `playwright-session.skill.md → Stable State Detection` como un caso adicional: **verificar que el target de la navegación existe antes o después del goto**. No es una regla HA-específica.

---

## Bloque 4 — La URL del panel es un contrato implícito

### 4.1 Cómo se construye la URL del panel

✅ **Confirmado por lectura de `panel.py`:**
```python
frontend_url_path = f"{PANEL_URL_PREFIX}-{vehicle_id}"
vehicle_id = vehicle_name.lower().replace(" ", "_")
# vehicle_name="Coche2" → vehicle_id="coche2" → path="ev-trip-planner-coche2"
```

**El agente no leyó `panel.py` durante Phase 3.** Lo infirió del nombre del vehículo pero no verificó la transformación exacta. Si el nombre hubiera tenido espacios ("Coche 2"), el goto habría fallado silenciosamente con `ev-trip-planner-coche 2` (URL inválida) en lugar de `ev-trip-planner-coche_2`.

### 4.2 Fix mínimo propuesto

Añadir 3 líneas a `requirements.md` del proyecto (no tocar los skills):
```markdown
## Panel URL Contract
- Panel URL pattern: `ev-trip-planner-{vehicle_id}`
- vehicle_id derivation: `vehicle_name.lower().replace(' ', '_')`
- Example: vehicle "Coche2" → `/ev-trip-planner-coche2` 
- Source of truth: `custom_components/ev_trip_planner/panel.py → async_register_panel`
```

💬 **Debate:** ¿Esto es suficiente o el agente también debería tener instrucción de leer el código fuente del componente antes de escribir tests de navegación?

---

## Bloque 5 — ¿Demasiados skills? El problema de la deuda de texto

### 5.1 La trampa de resolver cada problema con un nuevo skill

💬 **Preocupación válida planteada en sesión:**  
El patrón de "cada problema → nuevo skill/gate/texto" crea:
- Prompts gigantes que el agente no lee completo
- Skills muy acopladas a casos de uso específicos (anti-reutilización)
- Deuda de mantenimiento: cuando HA cambia, los skills quedan desactualizados

**Principio propuesto (en debate):**  
> Antes de crear un skill nuevo, preguntarse: ¿esto es un dato específico del proyecto (→ va a `requirements.md`) o es una regla general reutilizable (→ puede ir en un skill existente como 1-2 líneas)?

### 5.2 El agente como investigador autónomo

💬 **Hipótesis en debate:**  
La solución más robusta no es documentar todo de antemano, sino que el agente, en la fase de research, **use MCP Playwright para navegar a la documentación real** de la versión concreta que está testeando:
- Navegar a `developers.home-assistant.io` para la versión instalada
- Leer el código fuente del componente que va a testear
- Consultar el README de `hass-taste-test` para ver el patrón correcto de auth

✅ **Esto ya está parcialmente soportado** — el agente puede usar MCP tools durante research. El gap es que nadie le dijo explícitamente que DEBE hacerlo antes de escribir tests de navegación.

**Fix mínimo propuesto para `phase-rules.md → Phase 3`:**
```markdown
> Before writing any test that navigates to a URL, locate in source code 
> how that URL is constructed. Do not assume URLs from requirements.md.
```

---

## Pendientes de investigar

- [ ] ¿`hass-taste-test` inyecta el token como cookie, localStorage o storage-state? Leer código fuente.
- [ ] ¿Hay alguna librería más activa/mantenida que `hass-taste-test` en 2025?
- [ ] ¿El onboarding REST API de HA ha cambiado en versiones 2024.x/2025.x?
- [ ] Revisar `ha-e2e-testing.skill.md` línea 204 — la prohibición de `hass-taste-test` ¿está justificada o es un error?
- [ ] ¿El skill `playwright-session.skill.md` necesita un authMode específico para shadow DOM / Web Components?
- [ ] Verificar qué hace exactamente `auth.setup.ts` generado por el agente con el storageState — confirmado que NO guarda storageState, ¿es intencional?

---

## Decisiones tomadas

| # | Decisión | Fecha | Razonamiento |
|---|---|---|---|
| D1 | Borrar tests e2e generados por el agente y empezar desde 0 | 2026-04-03 | Los tests tienen bugs fundamentales (URL incorrecta, auth sin storageState). Mejor base limpia que parchear. |
| D2 | Fix mínimo: añadir Panel URL Contract a `requirements.md` del proyecto | 2026-04-03 | Dato específico del proyecto, no del sistema. No merece un skill. |
| D3 | Fix mínimo: añadir nota de 2 líneas a `phase-rules.md → GREENFIELD Phase 3` | 2026-04-03 | Regla genérica, aplica a todos los futuros GREENFIELD. 2 líneas, no un skill. |
| D4 | NO crear skill `ha-panel-contract.skill.md` | 2026-04-03 | Demasiado acoplado al caso de uso. Ver D2. |

---

*Última actualización: 2026-04-03 — sesión de investigación con Perplexity*
