# Propuesta: add-appearance-setting

## Why

Hoy BudgetSpy siempre sigue la apariencia del sistema y el usuario no puede elegir otra. Hay usuarios que prefieren ver la app siempre en modo claro o siempre en modo oscuro, sin cambiar la apariencia de todo su iPhone. Este cambio les permite elegir la apariencia desde Configuración, y conserva el comportamiento actual (seguir al sistema) como valor por defecto.

## What Changes

- En la pantalla Configuración, la lista pasa a tener dos ítems: "Datos Maestros" (sin cambios) y, debajo, **"Apariencia"**.
- La fila "Apariencia" tiene al final un selector nativo con tres opciones: **Sistema**, **Claro** y **Oscuro**. La fila no abre otra pantalla.
- Al elegir una opción, toda la app (pantallas, barra de navegación inferior, hojas y alertas) cambia de apariencia de inmediato, sin reiniciar la app, sin salir de Configuración y sin botón Guardar ni Cancelar.
- Con "Sistema", la app sigue la apariencia del sistema, también cuando esta cambia con la app abierta. Con "Claro" u "Oscuro", la app mantiene esa apariencia aunque cambie la apariencia del sistema.
- La preferencia de apariencia se conserva al cerrar y reabrir la app. Sin preferencia guardada, el valor es "Sistema".

### Decisiones de negocio

| Fecha | Decisión |
|---|---|
| 2026-10-16 | La preferencia de apariencia tiene tres opciones: "Sistema", "Claro" y "Oscuro". El valor por defecto es "Sistema". (DECIDIR 1) |
| 2026-10-16 | El control es un selector con las tres opciones, al final de la fila "Apariencia"; no abre otra pantalla. (DECIDIR 1) |
| 2026-10-16 | La preferencia de apariencia se conserva al cerrar y reabrir la app. (DECIDIR 2) |
| 2026-10-16 | "Apariencia" se ubica en la lista de Configuración debajo de "Datos Maestros". (DECIDIR 3) |
| 2026-10-16 | Con una apariencia fija (Claro u Oscuro), la app no sigue los cambios de la apariencia del sistema. |
| 2026-10-16 | El cambio se aplica al instante, sin confirmaciones ni botones Guardar/Cancelar. |
| 2026-10-16 | La apariencia es consistente en toda la app: la barra de navegación inferior, las pantallas, las hojas y las alertas siempre se ven con la misma apariencia. |

### Fuera de alcance

- Colores, temas o paletas propias: solo se usan los modos claro y oscuro estándar de iOS.
- Colores de acento, iconos alternativos de la app y temas por pantalla.
- Cambio automático de apariencia por horario dentro de la app.
- Cambios en "Datos Maestros" y en las pantallas de Inicio, Cuentas y Movimientos (solo cambian de apariencia).
- Otros ítems nuevos en la lista de Configuración.
- Sincronizar la preferencia de apariencia entre dispositivos.

## Capabilities

### New Capabilities
- `appearance`: preferencia de apariencia de la app — opciones Sistema/Claro/Oscuro, valor por defecto, aplicación inmediata a toda la app, comportamiento ante cambios de la apariencia del sistema, persistencia y accesibilidad del control.

### Modified Capabilities
- `app-navigation`: el requisito "Contenido de las pantallas principales" cambia: la lista de Configuración pasa de tener el único ítem "Datos Maestros" a tener "Datos Maestros" y "Apariencia", en ese orden. El requisito "Barra de navegación inferior con secciones principales" cambia: la barra se ve con la misma apariencia que el resto de la app (según la preferencia de apariencia), en lugar de seguir siempre la apariencia del sistema.

## Impact

- Código: `BudgetSpy/BudgetSpy/App/BudgetSpyApp.swift` o `App/ContentView.swift` (aplicar la apariencia en la raíz), `BudgetSpy/BudgetSpy/Features/Settings/Views/SettingsView.swift` (nueva fila) y nuevos archivos bajo `BudgetSpy/BudgetSpy/Features/Settings/`.
- Persistencia: la preferencia se guarda en UserDefaults en el dispositivo; sin cambios al modelo de Core Data.
- Pruebas: nuevas pruebas con Swift Testing en `BudgetSpy/BudgetSpyTests/`.
- Sin dependencias nuevas, sin red.
