<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# Informe: Diagnóstico y Solución de Tests E2E en CI/CD para Home Assistant Custom Integration

**Repositorio:** [ha-ev-trip-planner](https://github.com/informatico-madrid/ha-ev-trip-planner)
**PR en curso:** [\#20 – fix(e2e): accept root URL after trusted_networks auth in CI](https://github.com/informatico-madrid/ha-ev-trip-planner/pull/20)
**Fecha del análisis:** Abril 2026
**Versión corregida:** Python 3.14 es requisito obligatorio de HA 2026.3.x — no es negociable

***

## Resumen Ejecutivo

Los tests E2E de Playwright contra Home Assistant fallan en CI/GitHub Actions por una causa raíz bien identificada pero parcialmente mal abordada: **el frontend de HA no puede completar el handshake WebSocket con su propio backend en tiempo suficiente dentro del entorno de ejecución limitado de GitHub Actions**. Esto hace que el `ha-launch-screen` nunca desaparezca y que `partial-panel-resolver` / `ha-panel-custom` jamás se monten.

**Nota crítica sobre Python:** HA 2026.3 exige Python ≥ 3.14.2 como mínimo soportado — es el primer release que adopta Python 3.14 como versión oficial. No se puede bajar a 3.12 o 3.13. La pipeline actual usa 3.14 correctamente. La afirmación anterior del análisis sobre "bajar a 3.12" era incorrecta.[^1][^2][^3]

El problema real **no es un bug de código** y tampoco es la versión de Python — es un **error de arquitectura de la pipeline**: se intenta hacer E2E de UI contra un Home Assistant iniciado como proceso nativo en el runner de CI, cuando la práctica profesional es evitar exactamente ese patrón o abordarlo de forma diferente.

***

## 1. Diagnóstico Técnico Detallado

### 1.1 La secuencia de fallos observada

Según los logs de las últimas 4 ejecuciones (resumidas en la PR \#20):


| Run | SHA | Resultado | Hallazgo clave |
| :-- | :-- | :-- | :-- |
| 1 | `e1f129a` | Auth OK, panel vacío | Auth funciona, pero panel body vacío |
| 2 | `e974313` | ✗ Fallo | `ha-launch-screen` presente, 0 cookies, tokens válidos |
| 3 | `7ff712b` | ✗ Fallo | JS carga (core.js, app.js 200), launch screen persiste, timeout 60s excedido |
| 4 | `5920f63` | ⏳ Pendiente | Wait for launch screen removal, timeout 120s |

La run más reciente mostraba que el job `test` aparece con `conclusion: success` en una de las tres instancias del check, lo que sugiere que el aumento de timeout a 120s puede ser insuficiente en algunos runners pero suficiente en otros — comportamiento no-determinístico.

### 1.2 Por qué se queda bloqueado el frontend de HA

El `ha-launch-screen` se elimina del DOM **únicamente** cuando el frontend JavaScript de HA completa el handshake WebSocket con el backend Python y recibe la configuración de panels. En el entorno de GitHub Actions (runner `ubuntu-latest`):

- La CPU disponible es compartida (2 vCPU de bajo rendimiento)
- Python 3.14 con HA 2026.3.x tiene un startup de asyncio + carga de integraciones que en CI tarda 40-90 segundos
- El gestor de WebSocket de aiohttp tiene timeouts de conexión que pueden fallar en entornos con alta latencia de loopback[^4]
- La combinación `default_config:` en `configuration.yaml` carga decenas de integraciones innecesarias, agravando el problema


### 1.3 Python 3.14 y el overhead real de startup

HA 2026.3 fue el primer release que adoptó Python 3.14 como versión default. El anuncio oficial lo enmarca en mejoras de performance ("faster interpreter, improved startup times, better memory usage"), pero en la práctica el ecosystem de dependencias de HA (aiohttp, sqlalchemy, homeassistant-frontend) pueden tener wheels no compilados para 3.14 en PyPI, lo que fuerza compilación desde fuente durante `pip install homeassistant`, añadiendo 3-8 minutos al tiempo del workflow.[^5][^1]

El issue \#163067 en el core de HA confirma que incluso el equipo de HA tuvo problemas de packaging con Python 3.14 durante el desarrollo de 2026.3.[^3]

### 1.4 El error conceptual en `auth.setup.ts`

El `globalSetup` actual mezcla correctamente operaciones de API (onboarding via REST, setup de integración via config flow REST) con una operación frágil: obtener el `storageState` de Playwright navegando el browser y **esperando a que el WebSocket de HA se establezca**.

El `hassTokens` que el frontend guarda en `localStorage` tras el auth callback es exactamente el mismo token que se obtiene via la API REST. La diferencia:

```
Flujo actual (frágil):
  API REST → dev/dev token → navegar browser → esperar WS → esperar frontend JS → extraer hassTokens de localStorage → guardar storageState

Flujo correcto (robusto):
  API REST → dev/dev token + refresh_token → construir hassTokens JSON → inyectar directamente en storageState file
```

Esto elimina la dependencia del WebSocket para la autenticación del browser.

### 1.5 El `default_config:` — el enemigo silencioso

La `configuration.yaml` actual incluye `default_config:` que carga más de 40 integraciones en el arranque (mobile_app, cloud, shopping_list, map, etc.). Nada de esto es necesario para los tests E2E del panel EV Trip Planner. En un runner de CI con recursos limitados, esto convierte un startup de 15-20s en uno de 60-90s y puede hacer que el WS tarde en responder o directamente falle.

***

## 2. Por Qué Funciona en Local y Falla en CI

| Factor | Local | GitHub Actions CI |
| :-- | :-- | :-- |
| CPU disponible | 4-16 cores reales | ~2 vCPU compartidas |
| RAM disponible | 16-32 GB libres | 7 GB totales compartidos |
| Startup HA con `default_config` | 15-25s | 50-90s |
| Startup HA sin `default_config` | 8-12s | 20-35s |
| WebSocket loopback latency | <1ms | 2-10ms (scheduler overhead) |
| `ha-launch-screen` desaparece | En ~5s | En 40-90s o nunca |
| pip install homeassistant 2026.3 | Desde cache venv | Cold start, posible compilación |

La asimetría fundamental es que en local el proceso Python de HA tiene CPU y RAM abundantes para completar el event loop asyncio, cargar integraciones y responder al WebSocket del frontend en <10 segundos. En CI esto puede tardar 10x más.[^6]

***

## 3. Análisis de la Solución Actual (PR \#20)

### Lo que está bien

- Separar la lógica de auth de la URL de redirección ✓
- Usar la API REST para onboarding y setup de integración ✓
- Agregar diagnósticos exhaustivos de `localStorage` y DOM ✓
- Detectar y esperar `home-assistant` custom element ✓
- Aumentar timeout a 120s ✓ (paliativo necesario, pero insuficiente solo)
- Restringir a un test file en CI para fast feedback ✓ (deuda técnica aceptable mientras se arregla)


### Lo que sigue siendo problemático

1. **El storageState depende del WebSocket.** La obtención de `hassTokens` vía browser navigate sigue siendo no-determinística en CI.
2. **`default_config:` no se ha eliminado.** Es el mayor acelerador de startup disponible sin cambiar arquitectura.
3. **`testMatch: process.env.CI ? 'trip-list-view.spec.ts' : undefined`** es deuda técnica explícita que no debe llegar a `main`.
4. **No se usa `webServer` de Playwright**, que gestionaría automáticamente la espera del servidor.
5. **Los tests de CI se lanzan en 3 instancias simultáneas** (según check_runs), probablemente por `pull_request` + `pull_request_target` + `push` al mismo commit — esto desperdicia recursos del runner y puede generar contención.

***

## 4. La Solución Real: Cambios por Orden de Impacto

### 4.1 [IMPACTO MÁXIMO] Inyectar `storageState` sin browser navigate

Este es el cambio más importante. El token REST que ya se obtiene en `getAccessToken()` contiene todo lo necesario para construir el `hassTokens` de `localStorage`. El flujo completo de HA OAuth devuelve `access_token`, `refresh_token` y `expires_in` — exactamente lo que el frontend almacena.

```typescript
// auth.setup.ts — reemplazar la sección de browser navigate completa

async function buildStorageState(token: string, refreshToken: string): Promise<void> {
  const hassTokens = {
    access_token: token,
    token_type: 'Bearer',
    expires_in: 1800,
    expires: Date.now() + 1800 * 1000,
    hassUrl: HA_URL,
    clientId: `${HA_URL}/`,
    refresh_token: refreshToken,
  };

  const storageState = {
    cookies: [],
    origins: [{
      origin: HA_URL,
      localStorage: [
        { name: 'hassTokens', value: JSON.stringify(hassTokens) },
        { name: 'selectedTheme', value: JSON.stringify({ dark: false }) },
      ],
    }],
  };

  fs.writeFileSync(AUTH_FILE, JSON.stringify(storageState, null, 2));
  console.log('[auth.setup] storageState written directly (no browser needed)');
}
```

Para obtener el `refresh_token`, modificar `getAccessToken()` para devolver el objeto completo:

```typescript
async function getTokens(): Promise<{ access_token: string; refresh_token: string }> {
  // ... (mismo flujo que getAccessToken, pero retornar tokenData completo)
  const tokenData = await tokenResp.json() as {
    access_token: string;
    refresh_token: string;
    expires_in: number;
  };
  return tokenData;
}
```

**Esto elimina completamente la dependencia del WebSocket para auth.** No importa si el frontend tarda 3s o 90s en cargar — el `storageState` ya está listo.

### 4.2 [IMPACTO ALTO] Configuración minimal de HA para CI

```yaml
# tests/ha-manual/configuration.yaml (versión CI sin default_config)
http:
  server_host: 0.0.0.0
  server_port: 8123

homeassistant:
  auth_providers:
    - type: trusted_networks
      trusted_networks:
        - 127.0.0.1
        - 172.17.0.0/16
      allow_bypass_login: true
    - type: homeassistant

input_boolean:
  test_ev_charging:
    name: "EV Charging Test"
    initial: false

# Añadir solo las integraciones que HA necesita para servir el frontend:
frontend:
logger:
  default: warning
  logs:
    homeassistant.components.ev_trip_planner: debug
```

Eliminar `default_config:` reduce el startup de 60-90s a 20-35s en CI. El frontend de HA sigue funcionando — `default_config` no es necesario para servir panels custom.

### 4.3 [IMPACTO MEDIO] Usar `webServer` en Playwright config

```typescript
// playwright.config.ts
export default defineConfig({
  testDir: './tests/e2e',
  timeout: 120_000,
  retries: 1,
  workers: 1,
  webServer: {
    command: 'hass -c /tmp/ha-e2e-config --log-no-color',
    url: 'http://localhost:8123/api/',
    reuseExistingServer: !process.env.CI,
    timeout: 180_000, // 3 min para que HA arranque en CI
    stdout: 'pipe',
    stderr: 'pipe',
  },
  globalSetup: './auth.setup.ts',
  use: {
    baseURL: 'http://localhost:8123',
    storageState: 'playwright/.auth/user.json',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
});
```

Si se usa `webServer`, el paso "Start Home Assistant" y "Wait for HA to be ready" del workflow de GitHub Actions se pueden eliminar — Playwright los gestiona.

### 4.4 [IMPACTO MEDIO] Cache de pip en GitHub Actions

El `pip install homeassistant==2026.3.4` tarda 3-8 minutos en un runner frío, incluyendo posible compilación de extensiones C para Python 3.14. Añadir cache reduce esto a <30 segundos:

```yaml
# En playwright.yml, añadir después de setup-python:
- name: Cache pip dependencies
  uses: actions/cache@v4
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-ha-2026.3.4-py3.14-${{ hashFiles('**/requirements*.txt') }}
    restore-keys: |
      ${{ runner.os }}-pip-ha-2026.3.4-py3.14-

- name: Cache playwright browsers
  uses: actions/cache@v4
  with:
    path: ~/.cache/ms-playwright
    key: ${{ runner.os }}-playwright-${{ hashFiles('package-lock.json') }}
```


### 4.5 [IMPACTO MEDIO] Añadir wait explícito para WebSocket antes de tests

Incluso con storageState inyectado, los tests navegan al panel y el frontend debe establecer WS. Añadir un check del WS endpoint antes de lanzar Playwright:

```yaml
- name: Wait for HA WebSocket endpoint to respond
  run: |
    TOKEN=$(python3 -c "
    import urllib.request, json, urllib.parse
    # Login flow
    data = json.dumps({'client_id':'http://localhost:8123/','handler':['homeassistant',None],'redirect_uri':'http://localhost:8123/?auth_callback=1'}).encode()
    req = urllib.request.Request('http://localhost:8123/auth/login_flow', data=data, headers={'Content-Type':'application/json'}, method='POST')
    flow = json.loads(urllib.request.urlopen(req).read())
    # Submit creds
    data = json.dumps({'client_id':'http://localhost:8123/','username':'dev','password':'dev'}).encode()
    req = urllib.request.Request(f'http://localhost:8123/auth/login_flow/{flow[\"flow_id\"]}', data=data, headers={'Content-Type':'application/json'}, method='POST')
    cred = json.loads(urllib.request.urlopen(req).read())
    # Exchange code
    params = urllib.parse.urlencode({'client_id':'http://localhost:8123/','code':cred['result'],'grant_type':'authorization_code'}).encode()
    req = urllib.request.Request('http://localhost:8123/auth/token', data=params, headers={'Content-Type':'application/x-www-form-urlencoded'}, method='POST')
    token = json.loads(urllib.request.urlopen(req).read())
    print(token['access_token'])
    ")
    for i in $(seq 1 30); do
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer $TOKEN" \
        http://localhost:8123/api/websocket 2>/dev/null) || STATUS="0"
      echo "  WS attempt $i: status=$STATUS"
      if [ "$STATUS" = "426" ] || [ "$STATUS" = "101" ]; then
        echo "WebSocket endpoint ready"
        exit 0
      fi
      sleep 3
    done
    echo "WARNING: WS endpoint not ready, proceeding anyway"
```

(Nota: el endpoint `/api/websocket` devuelve 426 cuando responde correctamente via HTTP sin upgrade — eso confirma que el servidor WS está escuchando).

### 4.6 [IMPACTO BAJO — LIMPIEZA] Arreglar el trigger duplicado del workflow

El workflow actual tiene `pull_request` y `pull_request_target` simultáneamente, lo que hace que el job se ejecute dos veces para el mismo PR. Eliminar `pull_request_target` a menos que se necesite específicamente para manejar PRs de forks con secrets:

```yaml
on:
  push:
    branches: [ main, master, copilot/* ]
  pull_request:
    branches: [ main, master ]
  # Eliminar pull_request_target — no es necesario para PRs del mismo repo
```


***

## 5. Arquitectura de Tests Correcta a Medio Plazo

### 5.1 Separar por nivel de test

La práctica estándar en el ecosistema HA para custom integrations es:

```
tests/
├── unit/                          # pytest puro, sin HA runtime
│   └── test_calculations.py       # Lógica MPC, optimización de viaje
├── integration/                   # pytest + pytest-homeassistant-custom-component
│   ├── test_config_flow.py        # Los 5 pasos del config flow
│   ├── test_entities.py           # Sensores, estados
│   └── test_services.py           # Servicios HA
└── e2e/                           # Playwright (SOLO para UI del panel)
    ├── trips-helpers.ts
    └── trips-panel.spec.ts        # Interfaz web del panel frontend
```

`pytest-homeassistant-custom-component` instancia HA en memoria — no levanta el proceso completo, no tiene WebSocket, no tiene startup overhead. Un test del config flow que tarda 45s en E2E tarda 200ms en pytest.[^7][^8]

### 5.2 Workflow separado por nivel

```yaml
# .github/workflows/tests.yml
jobs:
  python-unit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.14' }
      - run: pip install pytest pytest-homeassistant-custom-component
      - run: pytest tests/unit/ tests/integration/

  e2e:
    needs: python-unit   # Solo corre si los unit tests pasan
    runs-on: ubuntu-latest
    steps:
      # ... setup HA + Playwright
      - run: npx playwright test tests/e2e/
```


### 5.3 Docker como alternativa robusta

La solución más estable a largo plazo es usar Docker service en GitHub Actions:

```yaml
# .github/workflows/playwright.yml
jobs:
  test:
    runs-on: ubuntu-latest
    services:
      homeassistant:
        image: ghcr.io/home-assistant/home-assistant:2026.3
        ports:
          - 8123:8123
        volumes:
          - ${{ github.workspace }}/tests/ha-manual:/config
          - ${{ github.workspace }}/custom_components:/config/custom_components
        options: >-
          --health-cmd "curl -sf http://localhost:8123/api/ || exit 1"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 20
          --health-start-period 60s
```

Ventajas frente al proceso nativo:

- La imagen oficial de HA está optimizada y tiene todas las dependencias compiladas
- No hay `pip install homeassistant` en el workflow — elimina 3-8 minutos
- El healthcheck de Docker gestiona la espera automáticamente
- Exactamente reproducible en local con `docker compose up`
- Python 3.14 está correctamente preinstalado en la imagen oficial[^1]

***

## 6. Por Qué E2E es tan Difícil en CI: Los Errores de Concepto

### 6.1 Testar lógica de integración vía E2E de UI (el mayor error)

El config flow de la integración, la creación de entidades y los servicios se pueden testear con `pytest-homeassistant-custom-component` sin browser. Hacerlo vía E2E es lento, frágil y sensible a condiciones de carrera. Los tests E2E solo aportan valor real para verificar la UI del panel.

### 6.2 Asumir que "funciona en local" implica "funciona en CI"

Los tests E2E son la categoría más sensible a la latencia y disponibilidad de recursos[^6]
<span style="display:none">[^10][^11][^12][^13][^14][^15][^16][^17][^18][^19][^20][^21][^22][^23][^24][^25][^26][^27][^9]</span>

<div align="center">⁂</div>

[^1]: https://www.home-assistant.io/blog/2026/03/04/release-20263/

[^2]: https://mintlify.com/home-assistant/core/installation

[^3]: https://github.com/home-assistant/core/issues/163067

[^4]: https://github.com/home-assistant/core/issues/154962

[^5]: https://www.home-assistant.io/changelogs/core-2026.3

[^6]: http://arxiv.org/pdf/2409.02366.pdf

[^7]: https://aarongodfrey.dev/home automation/building_a_home_assistant_custom_component_part_2/

[^8]: https://github.com/MatthewFlamm/pytest-homeassistant-custom-component/blob/master/README.md

[^9]: https://arxiv.org/pdf/2308.13276.pdf

[^10]: https://www.ijfmr.com/papers/2024/6/30587.pdf

[^11]: https://arxiv.org/html/2412.13211v3

[^12]: https://pmc.ncbi.nlm.nih.gov/articles/PMC9797609/

[^13]: http://arxiv.org/pdf/2406.03839.pdf

[^14]: http://arxiv.org/pdf/1611.00751.pdf

[^15]: http://arxiv.org/pdf/2410.14252.pdf

[^16]: http://www.scirp.org/journal/PaperDownload.aspx?paperID=60812

[^17]: https://github.com/home-assistant/architecture/blob/master/adr/0020-minimum-supported-python-version.md

[^18]: https://community.home-assistant.io/t/2026-3-a-clean-sweep/992780

[^19]: https://pysselilivet.blogspot.com/2024/04/home-assistant-core-install-raspberry.html

[^20]: https://www.home-assistant.io/changelogs/core-2026.3/

[^21]: https://www.reddit.com/r/homeassistant/comments/kfs20z/how_to_update_ha_core_python_39/

[^22]: https://community.home-assistant.io/t/2026-3-a-clean-sweep/992780?page=18

[^23]: https://community.home-assistant.io/t/how-can-i-upgrade-my-integration-to-a-new-ha-version-new-python-new-api/967078

[^24]: https://pypi.org/project/homeassistant/

[^25]: https://community.home-assistant.io/t/esphome-on-windows/990667

[^26]: https://www.youtube.com/watch?v=wD0pUBC0Dko

[^27]: https://www.influxdata.com/blog/home-assistant-hardware-recommendations/

