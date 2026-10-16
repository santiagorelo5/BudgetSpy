# Design

## Context

- La raíz de la app es `BudgetSpy/BudgetSpy/App/ContentView.swift` (`TabView` con Inicio y Configuración, cada una en su `NavigationStack`), creada desde `App/BudgetSpyApp.swift`. Hoy ninguna vista fija un esquema de color: toda la app sigue la apariencia del sistema.
- `BudgetSpy/BudgetSpy/Features/Settings/Views/SettingsView.swift` muestra una `List` con un solo `NavigationLink("Datos Maestros")`. La feature Settings hoy solo tiene `Views/`.
- La app no usa colores personalizados por modo; los componentes del sistema ya se adaptan a claro y oscuro.
- Motivación y alcance: ver proposal.md. Comportamiento: ver `specs/appearance/spec.md` y el delta de `specs/app-navigation/spec.md`.

## Goals / Non-Goals

**Goals:**
- Un único punto en la raíz donde la preferencia de apariencia se convierte en esquema de color, para que pantallas, barra, hojas y alertas cambien juntas.
- Lógica de conversión (preferencia → esquema de color) aislada en un tipo pequeño y probable con Swift Testing.

**Non-Goals:**
- ViewModel para Configuración: solo se lee y escribe un ajuste (regla del proyecto: ViewModel solo con estado o lógica propia).
- Tocar `overrideUserInterfaceStyle` de UIKit o las ventanas directamente.
- Cambios en Core Data.

## Decisions

### D1. Modelo `AppearancePreference`
Nuevo archivo `BudgetSpy/BudgetSpy/Features/Settings/Models/AppearancePreference.swift`:

- `enum AppearancePreference: String, CaseIterable, Identifiable` con `system`, `light`, `dark` (orden de declaración = orden del selector).
- `displayName`: "Sistema", "Claro", "Oscuro".
- `colorScheme: ColorScheme?`: `system → nil`, `light → .light`, `dark → .dark`.
- `static let storageKey = "appearancePreference"` para que la lectura (raíz) y la escritura (Configuración) usen la misma clave.

Sigue el patrón existente de `AccountKind` (enum con `rawValue` estable y textos de presentación). Los `rawValue` en inglés son los que se guardan, de modo que cambiar un texto visible no rompe lo guardado.

*Alternativa descartada:* guardar un `Bool` "oscuro" — no representa "Sistema" (DECIDIR 1).

### D2. Persistencia con `@AppStorage` (UserDefaults)
La preferencia de apariencia es un ajuste de la app, no un dato de negocio, así que se guarda en UserDefaults vía `@AppStorage(AppearancePreference.storageKey)` con valor por defecto `.system`. Los datos siguen solo en el dispositivo (principio de privacidad).

`@AppStorage` con un tipo `RawRepresentable<String>` devuelve el valor por defecto si no hay valor guardado o si el guardado no es válido, lo que cubre "Estado inicial sin preferencia guardada" sin código extra.

*Alternativa descartada:* atributo en Core Data — exigiría entidad o migración para un ajuste de UI; viola "simplicidad ante todo".

### D3. Aplicación en la raíz con `.preferredColorScheme`
`ContentView` declara `@AppStorage(AppearancePreference.storageKey) private var appearance: AppearancePreference = .system` y aplica `.preferredColorScheme(appearance.colorScheme)` al `TabView`. `preferredColorScheme` propaga a la ventana contenedora, por lo que la barra de navegación, las hojas y las alertas también cambian; con `nil` la app vuelve a seguir la apariencia del sistema, incluidos sus cambios en vivo.

Como `@AppStorage` observa UserDefaults, el cambio hecho en Configuración re-renderiza la raíz al instante, sin reiniciar ni salir de la pantalla.

Se ubica en `ContentView` y no en `BudgetSpyApp` para que el `#Preview` de `ContentView` también refleje la preferencia; `BudgetSpyApp` no cambia.

### D4. Fila "Apariencia" en `SettingsView`
`SettingsView` declara el mismo `@AppStorage` y agrega, debajo de "Datos Maestros":

```swift
Picker("Apariencia", selection: $appearance) {
    ForEach(AppearancePreference.allCases) { Text($0.displayName).tag($0) }
}
.pickerStyle(.menu)
```

Un `Picker` `.menu` dentro de `List` muestra la etiqueta a la izquierda y el valor seleccionado al final de la fila, no navega a otra pantalla y VoiceOver lo anuncia como "Apariencia" con su valor (CA8) sin modificadores extra. Es un componente nativo, con Dynamic Type.

*Alternativas descartadas:* `Toggle` (solo dos estados, no cubre "Sistema"); `Picker` `.navigationLink` (abre otra pantalla, contra RF1); `.segmented` (ocupa la fila y no es el patrón de Ajustes de iOS para una fila de lista).

### D5. Pruebas
`BudgetSpy/BudgetSpyTests/AppearancePreferenceTests.swift` con Swift Testing: conversión a `colorScheme` (Sistema→`nil`, Claro→`.light`, Oscuro→`.dark`), `displayName`, orden de `allCases`, y `rawValue` estables (`"system"`, `"light"`, `"dark"`) para proteger lo ya guardado. El resto (propagación, persistencia real, VoiceOver) se verifica en simulador.

### Archivos

| Ruta | Cambio |
|---|---|
| `BudgetSpy/BudgetSpy/Features/Settings/Models/AppearancePreference.swift` | Nuevo |
| `BudgetSpy/BudgetSpy/Features/Settings/Views/SettingsView.swift` | Modificado: fila "Apariencia" |
| `BudgetSpy/BudgetSpy/App/ContentView.swift` | Modificado: `@AppStorage` + `.preferredColorScheme` |
| `BudgetSpy/BudgetSpyTests/AppearancePreferenceTests.swift` | Nuevo |

Sin cambios al modelo de Core Data ni migraciones. Sin dependencias nuevas.

## Risks / Trade-offs

- [Volver de una apariencia fija a "Sistema" no restablece el modo en alguna presentación ya abierta] → En la verificación en simulador se prueba Claro/Oscuro → Sistema con el iPhone en el modo contrario (escenario "Volver a Sistema"); si fallara, se documenta y se corrige antes de cerrar el cambio.
- [Dos lugares declaran `@AppStorage` con la misma clave] → La clave vive en una sola constante (`AppearancePreference.storageKey`) y el valor por defecto `.system` se repite solo en esos dos puntos.
- [Que alguna parte de la app (barra, hoja o alerta) quede con una apariencia distinta al resto] → La apariencia se aplica en un único punto, la raíz (D3), del que heredan todas las pantallas y presentaciones; el delta de `app-navigation` exige que la barra se vea igual que el resto de la app, y las tareas 3.3 y 4.3 lo verifican en simulador.

## Migration Plan

No aplica: sin cambios de datos. Usuarios existentes no tienen valor guardado, así que quedan en "Sistema", que es el comportamiento actual. Rollback: revertir el cambio; la clave huérfana en UserDefaults no tiene efecto.
