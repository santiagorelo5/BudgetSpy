# Tasks

## 1. Estructura de carpetas y punto de entrada

- [ ] 1.1 Mover `BudgetSpy/BudgetSpy/BudgetSpyApp.swift` a `BudgetSpy/BudgetSpy/App/BudgetSpyApp.swift` y verificar que el proyecto compila en Xcode sin referencias rotas
- [ ] 1.2 Crear `BudgetSpy/BudgetSpy/App/AppTab.swift` con `enum AppTab: Hashable { case home, settings }` y verificar que compila

## 2. Pantallas de sección

- [ ] 2.1 Crear `BudgetSpy/BudgetSpy/Features/Home/Views/HomeView.swift`: `ScrollView` vacío con `.navigationTitle("Inicio")` y `#Preview` envuelto en `NavigationStack`; verificar en el preview que solo se ve el título "Inicio"
- [ ] 2.2 Crear `BudgetSpy/BudgetSpy/Features/Settings/Views/SettingsView.swift`: `ScrollView` vacío con `.navigationTitle("Configuración")` y `#Preview` envuelto en `NavigationStack`; verificar en el preview que solo se ve el título "Configuración"

## 3. Shell de navegación

- [ ] 3.1 Crear `BudgetSpy/BudgetSpy/App/ContentView.swift` con `TabView(selection:)`, `@State private var selectedTab: AppTab = .home` y los `Tab` "Inicio" (`house`) y "Configuración" (`gearshape`) en ese orden, cada uno envolviendo su vista en su propia `NavigationStack`; incluir `#Preview` y verificar en él que se muestra Inicio seleccionado
- [ ] 3.2 Reemplazar `Text("Hola Mundo")` por `ContentView()` en el `WindowGroup` de `App/BudgetSpyApp.swift` y verificar que al ejecutar en el simulador se ve la barra con Inicio seleccionado (CA1)

## 4. Orientación

- [ ] 4.1 En Xcode → target BudgetSpy → General → Deployment Info, dejar solo "Portrait" en iPhone Orientation (sin editar el `.pbxproj` a mano) y verificar con `git diff` que `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone` quedó en `UIInterfaceOrientationPortrait` para Debug y Release
- [ ] 4.2 Girar el simulador de iPhone a horizontal y verificar que la app permanece en vertical (CA7)

## 5. Verificación de integración en simulador

- [ ] 5.1 Tocar Configuración y luego Inicio, verificando que cambia la pantalla y la opción seleccionada en cada caso, y que tocar la opción ya seleccionada no produce errores (CA2, CA3)
- [ ] 5.2 Verificar la barra en modo claro y en modo oscuro, y con "Reducir transparencia" activado (CA4)
- [ ] 5.3 Con VoiceOver activo, verificar que las opciones se anuncian como "Inicio" y "Configuración" con su estado de selección; con un tamaño de texto de accesibilidad grande, verificar que los títulos se muestran completos (CA5)
- [ ] 5.4 Agregar temporalmente contenido desplazable a `HomeView` (sin confirmarlo en el repositorio) y verificar que pasa por detrás de la barra con el efecto Liquid Glass; revertir el contenido temporal y confirmar con `git diff` que no quedó (CA6)
