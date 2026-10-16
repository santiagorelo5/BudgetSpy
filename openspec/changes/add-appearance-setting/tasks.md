# Tasks

## 1. Modelo de la preferencia de apariencia

- [x] 1.1 Ajustar `BudgetSpy/BudgetSpy/Features/Settings/Models/AppearancePreference.swift`: `enum AppearancePreference: String, CaseIterable, Identifiable` (`system`, `light`, `dark`), `init(isDarkMode: Bool)` (`true` → `.dark`, `false` → `.light`), `colorScheme: ColorScheme?` (`nil`, `.light`, `.dark`) y `static let storageKey = "appearancePreference"`; quitar `displayName`; verificar que el proyecto compila
- [x] 1.2 Ajustar `BudgetSpy/BudgetSpyTests/AppearancePreferenceTests.swift` con Swift Testing para que cubra: conversión a `colorScheme` de los tres casos, `init(isDarkMode:)` con `true` y `false`, `rawValue` estables (`"system"`, `"light"`, `"dark"`) y que `AppearancePreference(rawValue: "otro")` es `nil`; quitar las pruebas de `displayName` y del orden de `allCases`; verificar que las pruebas pasan en Xcode (⌘U)

## 2. Fila "Apariencia" en Configuración

- [x] 2.1 En `BudgetSpy/BudgetSpy/Features/Settings/Views/SettingsView.swift`, reemplazar el `Toggle("Modo oscuro")` por la fila "Apariencia" de design.md D4: texto "Apariencia" y, al final, `sun.max.fill`, `Toggle("Apariencia, modo oscuro", isOn: isDarkMode).labelsHidden()` y `moon.fill` (íconos en `.secondary` y ocultos para VoiceOver), dentro de un `ViewThatFits` que pase íconos e interruptor a una segunda línea si no caben; conservar el binding `isDarkMode` actual; verificar en el `#Preview` que la lista muestra "Datos Maestros" y "Apariencia" en ese orden, con sol, interruptor apagado y luna al final de la fila (CA1)
- [x] 2.2 Verificar en el segundo `#Preview` (`.preferredColorScheme(.dark)`) que el interruptor se ve encendido (del lado de la luna) y que la fila y los íconos son legibles en ambas apariencias

## 3. Aplicar la preferencia en la raíz

- [x] 3.1 En `BudgetSpy/BudgetSpy/App/ContentView.swift`, agregar el mismo `@AppStorage` y aplicar `.preferredColorScheme(appearance.colorScheme)` al `TabView`; verificar en el `#Preview` de `ContentView` que la app se muestra y compila sin cambios visibles con la preferencia por defecto
- [x] 3.2 Ejecutar en el simulador: en Configuración, con la app en claro, encender el interruptor de "Apariencia" y verificar que Configuración y la barra cambian a oscuro sin salir de la pantalla, y que Inicio también se ve en oscuro; luego apagarlo y verificar que toda la app vuelve a claro (CA2, CA3)
- [x] 3.3 Con el interruptor de "Apariencia" encendido y el simulador en claro, abrir el formulario de Cuenta (hoja) y una alerta de la app (p. ej. confirmación de borrado) y verificar que se ven en oscuro

## 4. Verificación de integración en simulador

- [x] 4.1 Instalación nueva: borrar la app del simulador, reinstalar y verificar que con el sistema en oscuro abre en oscuro con el interruptor encendido, y con el sistema en claro abre en claro con el interruptor apagado (CA4)
- [x] 4.2 Sin decisión guardada, cambiar la apariencia del simulador de claro a oscuro con la app abierta (Ajustes de desarrollador o ⇧⌘A) y verificar que la app cambia a oscuro (CA5)
- [x] 4.3 Con decisión "claro", cambiar el simulador a oscuro y verificar que la app, incluida la barra de navegación inferior, sigue en claro; con decisión "oscuro", cambiar a claro y verificar que la app y la barra siguen en oscuro (CA6)
- [x] 4.4 Sin decisión guardada y con Configuración abierta, cambiar la apariencia del simulador y verificar que el interruptor de "Apariencia" se enciende y se apaga solo según el sistema; luego tocarlo una vez, cambiar el simulador y verificar que el interruptor y la app ya no cambian
- [x] 4.5 Encender el interruptor de "Apariencia", cerrar la app por completo desde el selector de apps, reabrirla con el simulador en claro y verificar que abre en oscuro y el interruptor se ve encendido (CA7)
- [x] 4.6 Con VoiceOver activo (o Accessibility Inspector), enfocar el interruptor y verificar que se anuncia "Apariencia, modo oscuro" con su estado (activado o desactivado) y que los íconos de sol y luna no se anuncian; con un tamaño de texto de accesibilidad grande, verificar que "Apariencia" se lee completo y que los íconos y el interruptor siguen visibles (CA8)
- [x] 4.7 Verificar que "Datos Maestros" sigue navegando a su pantalla y que la barra permanece visible en Configuración y sus pantallas internas
