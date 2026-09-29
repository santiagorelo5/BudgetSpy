# Design: add-app-shell

## Context

Ver proposal.md (Why) y `specs/app-navigation/spec.md` para los requisitos.

Estado actual observado en el repositorio:
- `BudgetSpy/BudgetSpy/BudgetSpyApp.swift` está en la raíz del target (no en `App/`) y su `WindowGroup` muestra `Text("Hola Mundo")`. Crea `PersistenceController.shared` pero no lo inyecta en el entorno.
- No existe `ContentView`, ni carpetas `App/`, `Features/` o `Core/`.
- El proyecto usa carpetas sincronizadas (`PBXFileSystemSynchronizedRootGroup`): los archivos nuevos o movidos bajo `BudgetSpy/BudgetSpy/` se detectan sin tocar el `.pbxproj`.
- `IPHONEOS_DEPLOYMENT_TARGET = 26.5` (cumple el mínimo iOS 26; no se modifica).
- `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone` permite hoy vertical y horizontal (izquierda/derecha).
- `TARGETED_DEVICE_FAMILY = "1,2"` (iPhone + iPad).
- No existe target de pruebas.

## Goals / Non-Goals

**Goals:**
- Estructura raíz de navegación con `TabView` nativo, sobre la cual se agregarán las funcionalidades futuras sin reestructurar.
- Cada sección con su propia `NavigationStack`, lista para recibir pantallas internas.
- Alinear la ubicación de los archivos de app con la estructura acordada (`App/`, `Features/<Feature>/Views/`).

**Non-Goals:**
- Inyectar `PersistenceController` en el entorno ni mover `Persistence.swift`/`.xcdatamodeld` a `Core/Persistence/` (llegará con el primer cambio que use datos).
- Cambiar la familia de dispositivos del target a solo iPhone.
- Catálogo de cadenas (String Catalog) o localización a otros idiomas.
- Crear un target de pruebas.

## Decisions

### 1. `TabView` nativo con la API `Tab` y selección tipada
`ContentView` usa `TabView(selection:)` con `Tab("Inicio", systemImage: "house", value: AppTab.home)` y `Tab("Configuración", systemImage: "gearshape", value: AppTab.settings)`. La selección es un `@State private var selectedTab: AppTab = .home`.

- El sistema aplica Liquid Glass, el estado seleccionado/no seleccionado, modo claro/oscuro, "Reducir transparencia", Dynamic Type y las etiquetas de VoiceOver (el título del `Tab` es la etiqueta accesible). No se requiere código adicional para RF1, RF2, CA4, CA5 ni CA6.
- `@State` (no `@SceneStorage`) garantiza que al abrir la app siempre se muestre Inicio (regla de negocio).
- `AppTab` es un `enum AppTab: Hashable { case home, settings }` en `App/`. Se tipa la selección en vez de usar índices para que agregar/reordenar secciones en el futuro no rompa la lógica.
- **Alternativas descartadas:** barra personalizada con `.glassEffect()` (lo prohíben las notas técnicas y las HIG; duplicaría comportamiento del sistema); `TabView` sin selección (funciona hoy, pero no deja explícita la sección por defecto ni permite cambiar de sección programáticamente en el futuro).

### 2. Una `NavigationStack` por sección, declarada en el shell
Cada `Tab` envuelve su vista en su propia `NavigationStack` dentro de `ContentView`:

```swift
Tab("Inicio", systemImage: "house", value: AppTab.home) {
    NavigationStack { HomeView() }
}
```

- `TabView` mantiene vivas las jerarquías de cada tab, por lo que cada pila conserva su estado al cambiar de sección (navegación independiente por sección).
- Declararla en el shell mantiene las vistas de feature independientes del contenedor de navegación (se pueden previsualizar o reutilizar dentro de otra pila), respetando responsabilidad única.
- **Alternativa descartada:** una sola `NavigationStack` que envuelva el `TabView` — las pantallas internas taparían la barra y se perdería la navegación independiente.

### 3. Pantallas de sección sin ViewModel
`HomeView` es un `ScrollView` vacío **sin** `.navigationTitle`, por lo que la barra superior queda vacía y transparente; sigue dentro de su `NavigationStack` para recibir pantallas internas en el futuro. `SettingsView` muestra su título mediante `.navigationTitle("Configuración")` (título grande del sistema) sobre un `ScrollView` vacío. No tienen estado ni lógica, así que no llevan ViewModel (regla del proyecto). El `ScrollView` vacío no muestra contenido visible; deja la pantalla preparada para que el contenido futuro se desplace por detrás de la barra y colapse el título grande según las HIG.

### 4. Textos en español como literales
Los textos visibles ("Inicio", "Configuración") se escriben como literales de `LocalizedStringKey` en español; los identificadores del código van en inglés (`HomeView`, `SettingsView`, `AppTab.home`, `AppTab.settings`). No se introduce String Catalog en este cambio (simplicidad).

### 5. Orientación solo vertical vía ajustes del target
Se cambia en Xcode → target BudgetSpy → General → Deployment Info → iPhone Orientation, dejando solo "Portrait". Esto actualiza `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone` a `UIInterfaceOrientationPortrait` en Debug y Release. Se hace desde la interfaz de Xcode, no editando el `.pbxproj` a mano. La configuración de iPad no se toca (fuera de alcance).
- **Alternativa descartada:** bloquear la orientación en código (`AppDelegate`/`supportedInterfaceOrientations`) — más código para el mismo resultado.

### Archivos

Nuevos:
- `BudgetSpy/BudgetSpy/App/ContentView.swift` — `TabView` raíz con las dos secciones y sus `NavigationStack`. Incluye `#Preview`.
- `BudgetSpy/BudgetSpy/App/AppTab.swift` — `enum AppTab` con los casos `home` y `settings`.
- `BudgetSpy/BudgetSpy/Features/Home/Views/HomeView.swift` — pantalla Inicio completamente vacía, sin título. Incluye `#Preview` envuelto en `NavigationStack`.
- `BudgetSpy/BudgetSpy/Features/Settings/Views/SettingsView.swift` — pantalla Configuración vacía con título. Incluye `#Preview` envuelto en `NavigationStack`.

Movidos / modificados:
- `BudgetSpy/BudgetSpy/BudgetSpyApp.swift` → `BudgetSpy/BudgetSpy/App/BudgetSpyApp.swift`; su `WindowGroup` muestra `ContentView()` en lugar de `Text("Hola Mundo")`.
- Ajustes del target (orientación iPhone), vía interfaz de Xcode.

Modelo de Core Data: sin cambios. Dependencias nuevas: ninguna.

## Risks / Trade-offs

- [Sin título, Inicio queda sin ninguna referencia visual propia] → La opción "Inicio" seleccionada en la barra indica la sección actual.
- [Pantallas vacías: no hay contenido que desplazar para comprobar CA6] → El efecto lo aplica el sistema al `TabView`; se verifica temporalmente en el `#Preview` o en el simulador con contenido de prueba que no se confirma en el repositorio.
- [El target sigue soportando iPad con todas las orientaciones, contrario al stack "Solo iPhone"] → Fuera de alcance; se registra para un cambio de configuración posterior.
- [Mover `BudgetSpyApp.swift` puede dejar referencias rotas si Xcode no reconoce el movimiento] → Las carpetas sincronizadas lo detectan; se verifica compilando el proyecto.
- [Sin target de pruebas, la verificación es manual] → No hay ViewModels ni lógica de dominio en este cambio; los criterios CA1–CA7 se verifican en simulador y previews.

## Migration Plan

No aplica: no hay datos ni usuarios existentes. Rollback = revertir el commit.
