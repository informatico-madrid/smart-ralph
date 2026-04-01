# Skill: selector-map

> Estrategia de selectores estables para tests Playwright en ralph-specum.
> Usar en tareas E2E del `tasks.md`. No incluye lógica de señales — eso es
> responsabilidad de `qa-engineer` y `stop-watcher`.

---

## Regla principal

Un selector inestable rompe el test aunque el código esté bien.
Elige siempre el selector más semántico y resistente a cambios de UI.

---

## Jerarquía de selectores (orden de preferencia)

```
1. getByRole()          — accesibilidad semántica, más estable
2. getByLabel()         — asociado al label del formulario
3. getByTestId()        — data-testid explícito, sin semántica UI
4. getByText()          — solo para texto visible único y estable
5. locator('css')       — último recurso, solo si no hay alternativa
```

### Cuándo usar cada uno

| Selector | Cuándo | Ejemplo |
|---|---|---|
| `getByRole` | Botones, links, inputs, headings | `getByRole('button', { name: 'Guardar' })` |
| `getByLabel` | Inputs con `<label>` asociado | `getByLabel('Email')` |
| `getByTestId` | Componentes complejos sin rol claro | `getByTestId('route-card-MAD')` |
| `getByText` | Mensajes de estado, badges únicos | `getByText('Ruta guardada')` |
| `locator('css')` | Nunca en tests nuevos — solo legado | — |

---

## Convención `data-testid`

Formato: `{entidad}-{variante}-{acción}`

```html
<!-- Entidad sola -->
<div data-testid="route-card">

<!-- Entidad con variante -->
<div data-testid="route-card-MAD-BCN">

<!-- Acción sobre entidad -->
<button data-testid="route-card-delete">

<!-- Listado -->
<ul data-testid="route-list">
<li  data-testid="route-list-item">
```

Reglas:
- Minúsculas con guiones
- Sin IDs de base de datos (son inestables)
- Nombrar por dominio, no por posición (`route-card-first` ❌)
- No usar el mismo testid en más de un elemento visible simultáneamente

---

## Anti-patrones — nunca usar

```typescript
// ❌ Posición frágil
page.locator('ul > li:nth-child(2)')

// ❌ Clase CSS (cambia con refactors de estilo)
page.locator('.btn-primary')

// ❌ XPath
page.locator('//div[@class="card"]//button')

// ❌ Texto parcial sin contexto
page.getByText('ar')  // coincide con demasiadas cosas

// ❌ ID autogenerado
page.locator('#input-1234abcd')
```

---

## Patrones correctos

```typescript
// Botón por rol y nombre visible
await page.getByRole('button', { name: 'Calcular ruta' }).click()

// Input por label
await page.getByLabel('Origen').fill('Madrid')

// Componente complejo por testid
const card = page.getByTestId('route-card-MAD-BCN')
await expect(card).toBeVisible()

// Texto de confirmación
await expect(page.getByText('Ruta guardada correctamente')).toBeVisible()

// Scope: buscar dentro de un contenedor
const modal = page.getByRole('dialog')
await modal.getByRole('button', { name: 'Confirmar' }).click()
```

---

## Assertions recomendadas

```typescript
// Estado visible
await expect(locator).toBeVisible()
await expect(locator).toBeHidden()

// Contenido
await expect(locator).toHaveText('Texto esperado')
await expect(locator).toContainText('parcial')

// Atributos
await expect(locator).toHaveAttribute('aria-disabled', 'true')
await expect(locator).toHaveValue('Madrid')

// URL tras navegación
await expect(page).toHaveURL(/\/rutas\/\d+/)

// Cantidad de elementos
await expect(page.getByTestId('route-list-item')).toHaveCount(3)
```

---

## Esperas — nunca `waitForTimeout`

```typescript
// ✅ Espera a que algo sea visible
await page.getByRole('status').waitFor({ state: 'visible' })

// ✅ Espera a que una petición termine
await page.waitForResponse(resp =>
  resp.url().includes('/api/rutas') && resp.status() === 200
)

// ✅ Espera a que la URL cambie
await page.waitForURL(/\/rutas/)

// ❌ Nunca
await page.waitForTimeout(2000)
```

---

## Checklist antes de entregar un test E2E

- [ ] Todos los selectores usan `getByRole`, `getByLabel` o `getByTestId`
- [ ] Ningún `locator('.clase')` ni XPath
- [ ] Ningún `waitForTimeout`
- [ ] Cada assertion usa el método semántico correcto
- [ ] Los `data-testid` siguen el formato `{entidad}-{variante}-{acción}`
- [ ] No hay testids duplicados en la misma vista
