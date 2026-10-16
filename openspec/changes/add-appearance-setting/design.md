# Design

## Context

- La raíz de la app es `BudgetSpy/BudgetSpy/App/ContentView.swift` (`TabView` con Inicio y Configuración, cada una en su `NavigationStack`), creada desde `App/BudgetSpyApp.swift`. Hoy ninguna vista fija un esquema de color: toda la app sigue la apariencia del sistema.
- `BudgetSpy/BudgetSpy/Features/Settings/Views/SettingsView.swift` muestra una `List` con un solo `NavigationLink("Datos Maestros")`. La feature Settings hoy solo tiene `Views/`.
- La app no usa colores personalizados por modo; los componentes del sistema ya se adaptan a claro y oscuro.
- Motivación y alcance: ver proposal.md. Comportamiento: ver `specs/appearance/spec.md` y el delta de `specs/app-navigation/spec.md`.

## Goals / Non-Goals

**Goals:**
- Un único punto en la raíz donde la preferencia de apariencia se convierte en esquema de color, para que pantallas, barra, hojas y alertas cambien juntas.
- Lógica de conversión (preferencia → esquema de color, interruptor → preferencia) aislada en un tipo pequeño y probable con Swift Testing.

**Non-Goals:**
- ViewModel para Configuración: solo se lee y escribe un ajuste (regla del proyecto: ViewModel solo con estado o lógica propia).
- Tocar `overrideUserInterfaceStyle` de UIKit o las ventanas directamente.
- Cambios en Core Data.

## Decisions

### D1. Modelo `AppearancePreference`
Nuevo archivo `BudgetSpy/BudgetSpy/Features/Settings/Models/AppearancePreference.swift`:

- `enum AppearancePreference: String, CaseIterable, Identifiable` con `system`, `light`, `dark`. `system` significa "sin decisión guardada" (seguir al sistema); no se muestra al usuario ni se puede volver a elegir desde la interfaz (DECIDIR 1).
- `init(isDarkMode: Bool)`: `true → .dark`, `false → .light`. Es la traducción del interruptor a la preferencia que se guarda.
- `colorScheme: ColorScheme?`: `system → nil`, `light → .light`, `dark → .dark`.
- `static let storageKey = "appearancePreference"` para que la lectura (raíz) y la escritura (Configuración) usen la misma clave.

Sigue el patrón existente de `AccountKind` (enum con `rawValue` estable). Los `rawValue` en inglés son los que se guardan. No lleva `displayName`: ningún texto de la interfaz depende de la preferencia.

*Alternativas descartadas:* guardar un `Bool` "oscuro" — no distingue "sin decisión guardada" de "eligió claro"; un `Bool?` lo haría, pero el enum ya da nombres claros a los tres estados y `colorScheme` en un solo lugar.

### D2. Persistencia con `@AppStorage` (UserDefaults)
La preferencia de apariencia es un ajuste de la app, no un dato de negocio, así que se guarda en UserDefaults vía `@AppStorage(AppearancePreference.storageKey)` con valor por defecto `.system`. Los datos siguen solo en el dispositivo (principio de privacidad).

`@AppStorage` con un tipo `RawRepresentable<String>` devuelve el valor por defecto si no hay valor guardado o si el guardado no es válido, lo que cubre "Estado inicial sin preferencia guardada" sin código extra.

*Alternativa descartada:* atributo en Core Data — exigiría entidad o migración para un ajuste de UI; viola "simplicidad ante todo".

### D3. Aplicación en la raíz con `.preferredColorScheme`
`ContentView` declara `@AppStorage(AppearancePreference.storageKey) private var appearance: AppearancePreference = .system` y aplica `.preferredColorScheme(appearance.colorScheme)` al `TabView`. `preferredColorScheme` propaga a la ventana contenedora, por lo que la barra de navegación, las hojas y las alertas también cambian; con `nil` la app vuelve a seguir la apariencia del sistema, incluidos sus cambios en vivo.

Como `@AppStorage` observa UserDefaults, el cambio hecho en Configuración re-renderiza la raíz al instante, sin reiniciar ni salir de la pantalla.

Se ubica en `ContentView` y no en `BudgetSpyApp` para que el `#Preview` de `ContentView` también refleje la preferencia; `BudgetSpyApp` no cambia.

### D4. Fila "Apariencia" en `SettingsView`
`SettingsView` declara el mismo `@AppStorage`, lee `@Environment(\.colorScheme)` y agrega, debajo de "Datos Maestros", una fila con el texto "Apariencia" y, al final, sol, interruptor y luna:

```swift
ViewThatFits(in: .horizontal) {
    HStack {
        Text("Apariencia")
        Spacer()
        appearanceSwitch
    }
    VStack(alignment: .leading) {
        Text("Apariencia")
        appearanceSwitch
    }
}

private var appearanceSwitch: some View {
    HStack {
        Image(systemName: "sun.max.fill").accessibilityHidden(true)
        Toggle("Apariencia, modo oscuro", isOn: isDarkMode).labelsHidden()
        Image(systemName: "moon.fill").accessibilityHidden(true)
    }
    .foregroundStyle(.secondary)
}
```

`isDarkMode` es un binding:
- *get*: `colorScheme == .dark`. `colorScheme` del entorno es la apariencia con que se ve la app, que ya incluye la preferencia aplicada en la raíz (D3). Sin decisión guardada refleja al sistema, también en vivo, sin código extra; con decisión guardada refleja esa decisión.
- *set*: guarda `AppearancePreference(isDarkMode: $0)`; desde ese momento la raíz fija el esquema de color y la app deja de seguir al sistema.

Decisiones de la fila:
- **Sol a la izquierda, luna a la derecha:** coinciden con la posición de la perilla del `Toggle` (apagado a la izquierda = claro, encendido a la derecha = oscuro). Son SF Symbols en `.secondary`, para que se adapten a claro y oscuro sin colores propios.
- **Accesibilidad (CA8):** el `Toggle` conserva la etiqueta "Apariencia, modo oscuro" (oculta a la vista con `.labelsHidden()` pero leída por VoiceOver), así el estado activado/desactivado tiene sentido; los íconos se ocultan para VoiceOver porque son decorativos y el texto visible "Apariencia" queda como texto estático.
- **Dynamic Type:** `ViewThatFits` usa la disposición en una línea mientras quepa y, con tamaños de accesibilidad grandes, pasa el sol, el interruptor y la luna a una segunda línea, sin cortar texto.

*Alternativas descartadas:* `Picker` `.menu` con Sistema, Claro y Oscuro (el usuario prefirió un interruptor de dos estados); `Toggle("Modo oscuro")` estándar sin íconos (el usuario prefirió la etiqueta "Apariencia" con sol y luna para que se entienda cada posición); colores propios para sol y luna (se usan los colores del sistema por simplicidad).

### D5. Pruebas
`BudgetSpy/BudgetSpyTests/AppearancePreferenceTests.swift` con Swift Testing: conversión a `colorScheme` (`system`→`nil`, `light`→`.light`, `dark`→`.dark`), `init(isDarkMode:)` (`true`→`.dark`, `false`→`.light`), y `rawValue` estables (`"system"`, `"light"`, `"dark"`) para proteger lo ya guardado. El resto (propagación, estado del interruptor, disposición de la fila, persistencia real, VoiceOver) se verifica en simulador.

### Archivos

| Ruta | Cambio |
|---|---|
| `BudgetSpy/BudgetSpy/Features/Settings/Models/AppearancePreference.swift` | Nuevo |
| `BudgetSpy/BudgetSpy/Features/Settings/Views/SettingsView.swift` | Modificado: fila "Apariencia" con sol, interruptor y luna |
| `BudgetSpy/BudgetSpy/App/ContentView.swift` | Modificado: `@AppStorage` + `.preferredColorScheme` |
| `BudgetSpy/BudgetSpyTests/AppearancePreferenceTests.swift` | Nuevo |

Sin cambios al modelo de Core Data ni migraciones. Sin dependencias nuevas.

## Risks / Trade-offs

- [Una vez tocado el interruptor, el usuario no puede volver a seguir la apariencia del sistema] → Decisión de negocio aceptada (DECIDIR 1) por simplicidad; la spec lo deja explícito. Si se pide en el futuro, se agrega como cambio nuevo.
- [La fila es una composición propia (texto + íconos + `Toggle` sin etiqueta visible) y no el `Toggle` estándar de Ajustes] → Se mantiene el `Toggle` nativo como control y solo se agregan SF Symbols; la tarea 4.6 verifica VoiceOver y texto grande.
- [El interruptor lee `colorScheme` del entorno; si una vista intermedia lo forzara, mostraría un estado incorrecto] → Ninguna vista fija un esquema de color salvo la raíz; la tarea 4.4 verifica que el interruptor se mueve solo cuando cambia el sistema sin decisión guardada.
- [Dos lugares declaran `@AppStorage` con la misma clave] → La clave vive en una sola constante (`AppearancePreference.storageKey`) y el valor por defecto `.system` se repite solo en esos dos puntos.
- [Que alguna parte de la app (barra, hoja o alerta) quede con una apariencia distinta al resto] → La apariencia se aplica en un único punto, la raíz (D3), del que heredan todas las pantallas y presentaciones; el delta de `app-navigation` exige que la barra se vea igual que el resto de la app, y las tareas 3.3 y 4.3 lo verifican en simulador.

## Migration Plan

No aplica: sin cambios de datos. Usuarios existentes no tienen valor guardado, así que quedan en `system` (seguir al sistema), que es el comportamiento actual. Rollback: revertir el cambio; la clave huérfana en UserDefaults no tiene efecto.
