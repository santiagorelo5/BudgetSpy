# Tasks

## 1. Modelo de la preferencia de apariencia

- [ ] 1.1 Crear `BudgetSpy/BudgetSpy/Features/Settings/Models/AppearancePreference.swift` con `enum AppearancePreference: String, CaseIterable, Identifiable` (`system`, `light`, `dark`), `displayName` ("Sistema", "Claro", "Oscuro"), `colorScheme: ColorScheme?` (`nil`, `.light`, `.dark`) y `static let storageKey = "appearancePreference"`; verificar que el proyecto compila
- [ ] 1.2 Crear `BudgetSpy/BudgetSpyTests/AppearancePreferenceTests.swift` con Swift Testing que cubra: conversión a `colorScheme` de las tres opciones, `displayName` de cada una, orden de `allCases` (Sistema, Claro, Oscuro), `rawValue` estables (`"system"`, `"light"`, `"dark"`) y que `AppearancePreference(rawValue: "otro")` es `nil`; verificar que las pruebas pasan en Xcode (⌘U)

## 2. Fila "Apariencia" en Configuración

- [ ] 2.1 En `BudgetSpy/BudgetSpy/Features/Settings/Views/SettingsView.swift`, agregar `@AppStorage(AppearancePreference.storageKey) private var appearance: AppearancePreference = .system` y, debajo de `NavigationLink("Datos Maestros")`, un `Picker("Apariencia", selection: $appearance)` con `.pickerStyle(.menu)` que liste `AppearancePreference.allCases` por `displayName`; verificar en el `#Preview` existente que la lista muestra "Datos Maestros" y "Apariencia" en ese orden, con "Sistema" al final de la fila, y que el menú ofrece Sistema, Claro y Oscuro (CA1)
- [ ] 2.2 Agregar a `SettingsView.swift` un segundo `#Preview` con modo oscuro (`.preferredColorScheme(.dark)`) y verificar que la fila se ve legible en ambas apariencias

## 3. Aplicar la preferencia en la raíz

- [ ] 3.1 En `BudgetSpy/BudgetSpy/App/ContentView.swift`, agregar el mismo `@AppStorage` y aplicar `.preferredColorScheme(appearance.colorScheme)` al `TabView`; verificar en el `#Preview` de `ContentView` que la app se muestra y compila sin cambios visibles con la preferencia por defecto
- [ ] 3.2 Ejecutar en el simulador: en Configuración elegir "Oscuro" estando en claro y verificar que Configuración y la barra cambian a oscuro sin salir de la pantalla, y que Inicio también se ve en oscuro; luego elegir "Claro" y verificar que toda la app vuelve a claro (CA2, CA3)
- [ ] 3.3 Con la preferencia "Oscuro" y el simulador en claro, abrir el formulario de Cuenta (hoja) y una alerta de la app (p. ej. confirmación de borrado) y verificar que se ven en oscuro

## 4. Verificación de integración en simulador

- [ ] 4.1 Instalación nueva: borrar la app del simulador, reinstalar y verificar que con el sistema en oscuro abre en oscuro y con el sistema en claro abre en claro, y que el selector muestra "Sistema" (CA4)
- [ ] 4.2 Con "Sistema", cambiar la apariencia del simulador de claro a oscuro con la app abierta (Ajustes de desarrollador o ⇧⌘A) y verificar que la app cambia a oscuro (CA5)
- [ ] 4.3 Con "Claro", cambiar el simulador a oscuro y verificar que la app, incluida la barra de navegación inferior, sigue en claro; con "Oscuro", cambiar a claro y verificar que la app y la barra siguen en oscuro (CA6)
- [ ] 4.4 Con "Claro" y el simulador en oscuro, elegir "Sistema" y verificar que la app pasa a oscuro de inmediato, incluida la barra (riesgo de design.md "Volver a Sistema")
- [ ] 4.5 Elegir "Oscuro", cerrar la app por completo desde el selector de apps, reabrirla con el simulador en claro y verificar que abre en oscuro y el selector muestra "Oscuro" (CA7)
- [ ] 4.6 Con VoiceOver activo (o Accessibility Inspector), enfocar la fila y verificar que se anuncia "Apariencia" con su valor actual; con un tamaño de texto de accesibilidad grande, verificar que "Apariencia" y el valor se leen completos (CA8)
- [ ] 4.7 Verificar que "Datos Maestros" sigue navegando a su pantalla y que la barra permanece visible en Configuración y sus pantallas internas
