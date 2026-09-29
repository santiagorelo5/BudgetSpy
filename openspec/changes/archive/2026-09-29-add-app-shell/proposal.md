# Propuesta: add-app-shell

## Why

Hoy la app solo muestra un texto "Hola Mundo" y no tiene ninguna estructura de navegación. Antes de construir cualquier funcionalidad (cuentas, transacciones, informes) se necesita la estructura base de navegación: una barra inferior que permita moverse entre las secciones principales, sobre la cual se montarán las funcionalidades futuras.

## What Changes

- Se reemplaza la vista raíz "Hola Mundo" por una estructura de navegación con barra inferior (tab bar del sistema, estilo Liquid Glass).
- La barra tiene exactamente 2 opciones, en este orden: **Inicio** (ícono de casa) y **Configuración** (ícono de engranaje).
- Al abrir la app, la opción seleccionada por defecto es **Inicio**.
- Cada sección conserva su propia pila de navegación de forma independiente.
- Se crean las pantallas **Inicio** y **Configuración**, vacías, solo con su título.
- La app queda restringida a orientación vertical en iPhone.

### Decisiones de negocio

| Fecha | Decisión |
|---|---|
| 2026-09-29 | La barra de navegación tiene exactamente 2 opciones: Inicio y Configuración, en ese orden. |
| 2026-09-29 | La sección seleccionada por defecto al abrir la app es Inicio. |
| 2026-09-29 | Cada sección conserva su propia navegación interna al cambiar de sección. |
| 2026-09-29 | Las pantallas Inicio y Configuración se entregan vacías, solo con su título. |
| 2026-09-29 | La app funciona solo en orientación vertical. |

### Fuera de alcance

- Cualquier contenido dentro de Inicio o de Configuración: solo pantallas vacías con título.
- Cuentas, tarjetas, carrusel, Datos Maestros y persistencia de datos.
- Opciones adicionales en la barra de navegación.
- Pantallas internas de Configuración (la conservación de la navegación por sección se deja preparada, pero no hay pantallas internas todavía).
- Cambiar la familia de dispositivos del target (hoy iPhone + iPad) y reorganizar `Persistence.swift`/`.xcdatamodeld` en `Core/Persistence/`.

## Capabilities

### New Capabilities
- `app-navigation`: estructura base de navegación de la app — barra inferior con las secciones Inicio y Configuración, sección por defecto, navegación independiente por sección, pantallas vacías con título, accesibilidad y orientación vertical.

### Modified Capabilities
- Ninguna.

## Impact

- Código: `BudgetSpy/BudgetSpy/BudgetSpyApp.swift` (vista raíz) y nuevas vistas bajo `BudgetSpy/BudgetSpy/App/` y `BudgetSpy/BudgetSpy/Features/`.
- Configuración del target en Xcode: orientaciones soportadas en iPhone (solo vertical).
- Sin cambios al modelo de Core Data, sin dependencias nuevas.
