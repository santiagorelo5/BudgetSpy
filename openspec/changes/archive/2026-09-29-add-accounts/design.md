# Design: add-accounts

## Context

Ver proposal.md (Why) y los specs `accounts`, `account-types` y `app-navigation` de este change para los requisitos.

Estado actual observado en el repositorio:
- `BudgetSpy/BudgetSpy/Persistence.swift` y `BudgetSpy/BudgetSpy/BudgetSpy.xcdatamodeld` están en la raíz del target, no en `Core/Persistence/`. `PersistenceController` es la plantilla de Xcode (`NSPersistentContainer(name: "BudgetSpy")`, `preview` en memoria sin datos).
- El modelo `.xcdatamodeld` tiene una sola versión con la entidad plantilla `Item` (sin atributos, sin uso).
- `BudgetSpyApp` crea `PersistenceController.shared` pero no inyecta el `viewContext` en el entorno.
- `ContentView` tiene un `TabView` con una `NavigationStack` por sección. `HomeView` es un `ScrollView` vacío sin título; `SettingsView` es un `ScrollView` vacío con `.navigationTitle("Configuración")`.
- No existe target de pruebas: la carpeta `BudgetSpy/BudgetSpyTests/` existe pero está vacía y el `.pbxproj` no la referencia.
- No existe `Core/Shared/` ni formateadores de moneda.
- `SWIFT_VERSION = 5.0` con `SWIFT_APPROACHABLE_CONCURRENCY = YES`; carpetas sincronizadas (los archivos nuevos se detectan solos).

Decisión del usuario (2026-09-29): la persistencia es **Core Data**, como fija `config.yaml`, aunque el pedido original mencionaba SwiftData. Se conserva la semántica pedida: entidad Tipo de cuenta con relación Cuenta → Tipo de cuenta, siembra idempotente verificando por abreviación, importes en `Decimal`.

## Goals / Non-Goals

**Goals:**
- Modelo de Core Data para Cuentas y Tipos de cuenta, preparado para que `add-transactions` actualice el balance almacenado.
- Utilidades de moneda reutilizables (formato, parseo y campo de importe con efecto de digitación) en `Core/Shared/`, que usarán los changes futuros.
- Un componente de tarjeta gráfica único, usado tanto en el carrusel como en la vista previa del formulario.
- Crear el target de pruebas con Swift Testing.

**Non-Goals:**
- Capa de repositorio/protocolos de acceso a datos (ver Decisión 6).
- Restricciones de unicidad de Core Data ni políticas de merge (la siembra verifica por abreviación).
- Cambiar la familia de dispositivos del target (sigue pendiente desde `add-app-shell`).
- String Catalog / localización.

## Decisions

### 1. Modelo de Core Data (nueva versión del modelo)

Se agrega una nueva versión del modelo, `BudgetSpy 2`, y se marca como actual (Editor → Add Model Version en Xcode). En la nueva versión se elimina `Item` y se agregan:

**`AccountType`** (codegen: Class Definition)

| Atributo | Tipo | Opcional | Notas |
|---|---|---|---|
| `name` | String | No | "Cuenta de Ahorros", "Tarjeta de Crédito" |
| `abbreviation` | String | No | "CA", "TC"; clave lógica para la siembra y para el comportamiento |

| Relación | Destino | Tipo | Inversa | Regla de borrado |
|---|---|---|---|---|
| `accounts` | `Account` | To-many | `accountType` | **Deny** (un Tipo de cuenta con Cuentas no se puede borrar) |

**`Account`** (codegen: Class Definition)

| Atributo | Tipo | Opcional | Notas |
|---|---|---|---|
| `id` | UUID | No | identidad estable para `ForEach` y futuras Transacciones |
| `name` | String | No | máx. 20 caracteres (validado en la app) |
| `lastFourDigits` | String | No | exactamente 4 dígitos; nunca el número completo |
| `balance` | Decimal | No | default 0; saldo (CA) o deuda en positivo (TC) |
| `creditLimit` | Decimal | **Sí** | solo TC; `nil` en CA |
| `createdAt` | Date | No | orden del carrusel |

| Relación | Destino | Tipo | Inversa | Regla de borrado |
|---|---|---|---|---|
| `accountType` | `AccountType` | To-one, **no opcional** | `accounts` | **Nullify** (borrar una Cuenta no toca su Tipo) |

- Nombres de entidades y atributos en inglés (principio 1: código en inglés); los textos visibles se mantienen en español.
- `Decimal` de Core Data se expone como `NSDecimalNumber?`; una extensión en `Features/Accounts/Models/Account+Display.swift` expone `Decimal` y el contenido de la tarjeta para no repetir conversiones.
- **Alternativa descartada:** guardar el tipo como `String` en `Account` (enum en código). El pedido pide explícitamente Tipo de cuenta como entidad y los Datos Maestros lo listan desde la base.

**Migración:** migración ligera inferida. `NSPersistentContainer` ya tiene `shouldMigrateStoreAutomatically` y `shouldInferMappingModelAutomatically` en `true` por defecto; con la versión anterior conservada en el `.xcdatamodeld`, Core Data infiere el mapeo (borrar `Item`, agregar entidades nuevas). No hay datos reales de usuarios.

### 2. `AccountKind`: el comportamiento se deriva de la abreviación

`enum AccountKind: String, CaseIterable { case savings = "CA", creditCard = "TC" }` con `displayName`, `balanceTitle` ("Saldo disponible" / "Deuda a la fecha"; es el título del campo en el formulario y el rótulo del balance en la tarjeta) y `requiresCreditLimit`. `AccountType.kind` lo resuelve desde `abbreviation`.

- Toda la lógica que depende del tipo (títulos, límite, colores de tarjeta, validación) usa `AccountKind`, no comparaciones de texto dispersas (abierto/cerrado: un tipo nuevo se agrega en un solo lugar).
- La siembra recorre `AccountKind.allCases`, así los datos semilla y el código no pueden desincronizarse.

### 3. Siembra idempotente de Tipos de cuenta

`AccountTypeSeeder.seed(in:)` busca los `AccountType` existentes, y por cada `AccountKind` cuya abreviación no exista inserta uno; guarda solo si insertó algo. Se llama en `PersistenceController.init` justo después de cargar el store (también en `preview` y en los contenedores en memoria de las pruebas). Si falla, se registra con `Logger` y se continúa: el formulario mostrará el aviso de error al guardar (spec "Falla al guardar").

- **Alternativa descartada:** bandera en `UserDefaults` ("ya sembré"). Verificar por abreviación es idempotente por construcción y además repara un tipo faltante.

### 4. Persistencia centralizada y entorno

- `Persistence.swift` → `Core/Persistence/Persistence.swift`; `BudgetSpy.xcdatamodeld` → `Core/Persistence/BudgetSpy.xcdatamodeld` (movidos desde Xcode). El nombre del contenedor sigue siendo `"BudgetSpy"` porque el `.momd` compilado conserva el nombre del archivo.
- `BudgetSpyApp` inyecta `.environment(\.managedObjectContext, persistenceController.container.viewContext)` sobre `ContentView`.
- `PersistenceController.preview` siembra los tipos y crea 2 Cuentas de ejemplo (una CA, una TC) para los `#Preview`.

### 5. Moneda en `Core/Shared/`

- `CurrencyFormatter.string(from: Decimal) -> String`: `NumberFormatter` con separador de miles `.`, decimal `,`, 2 decimales fijos y prefijo `"$ "` → `$ 1.000,00` y `$ -1.000,00` (principio 5).
- `CurrencyParser.amount(fromDigits: String) -> Decimal`: toma solo los caracteres numéricos, los interpreta como centavos (`"125000"` → `1250.00`) y limita a 13 dígitos (hasta `$ 99.999.999.999,99`) para evitar desbordes. Ignora signos: el importe nunca es negativo (principio 8).
- `CurrencyField` (vista reutilizable, `Core/Shared/Components/`): `TextField` con `.keyboardType(.numberPad)` y un `Binding<String>` cuyo `get` devuelve el texto formateado y cuyo `set` extrae los dígitos y llama a `CurrencyParser`. Así, cada dígito se agrega a la derecha y cada borrado quita el último dígito hasta `$ 0,00` (principio 7).
- **Alternativa descartada:** `TextField(value:format: .currency(code: "COP"))` — no produce el efecto de digitación ni el formato exigido.

### 6. MVVM: dos ViewModels, validación pura aparte

- **`AccountValidator`** (struct pura, sin Core Data): recibe un `AccountDraft` y devuelve un diccionario `AccountField → AccountValidationError` con los mensajes en español del spec. Es la única fuente de las reglas de negocio, fácil de probar con los ejemplos del pedido.
- **`AccountDraft`** (struct DTO, `Equatable`): `kind`, `name`, `lastFourDigits`, `balance`, `creditLimit`. Es el borrador del formulario y también alimenta la tarjeta gráfica de vista previa.
- **`AccountFormViewModel`** (`@Observable @MainActor final class`): recibe el `AccountFormRoute` (`.create` / `.edit(Account)`) y el `NSManagedObjectContext`.
  - `draft` y `initialDraft` (valores con que se abrió). `hasChanges = draft != initialDraft` → cumple "preguntar solo si hubo cambios", incluido revertir a los valores iniciales.
  - `editedFields: Set<AccountField>`: los errores solo se muestran en campos que el usuario ya modificó; `canSave` usa todos los errores (el botón está deshabilitado desde el inicio sin mostrar errores).
  - `select(kind:)`: si el nuevo tipo no requiere límite, pone `creditLimit = 0` (descarta el valor). No hace nada en modo edición (`isKindLocked`).
  - `updateName` / `updateLastFourDigits` sanean la entrada (máx. 20 caracteres; solo dígitos, máx. 4).
  - `save() -> Bool`: crea o actualiza la `Account` (busca el `AccountType` por abreviación; `createdAt = .now` y `id = UUID()` solo al crear; `creditLimit = nil` si es CA) y guarda. Si falla, hace `rollback()`, activa `saveErrorIsPresented` y devuelve `false`.
  - `primaryButtonTitle`: "Crear cuenta" / "Guardar cambios".
- **`AccountCarouselViewModel`** (`@Observable @MainActor final class`): `accountPendingDeletion: Account?`, `requestDeletion(of:)`, `confirmDeletion()`, `cancelDeletion()`, `deleteErrorIsPresented`. Existe porque las vistas no pueden escribir en Core Data (regla del proyecto).
- Las vistas de lectura (carrusel, Tipos de cuenta) usan `@FetchRequest` directamente.
- **Alternativa descartada:** protocolo `AccountRepository` + implementación Core Data. Agrega una capa sin segundo consumidor; los ViewModels se prueban con el contenedor en memoria (`PersistenceController(inMemory: true)`). Se puede extraer cuando `add-transactions` lo justifique.

### 7. Navegación al formulario y ocultar la barra

- `HomeView` guarda `@State private var formRoute: AccountFormRoute?` y usa `.navigationDestination(item: $formRoute)` dentro de la `NavigationStack` de Inicio que ya crea `ContentView` (no se toca `ContentView`). La tarjeta "+" asigna `.create`; "Editar" del menú asigna `.edit(account)`.
- `AccountFormView` aplica `.toolbar(.hidden, for: .tabBar)` → la barra se oculta al entrar y el sistema la restaura al salir. Las pantallas de Configuración no aplican ningún modificador, así la barra siempre se ve.
- Botones: `ToolbarItem(placement: .confirmationAction)` para el botón principal (`.disabled(!canSave)`), `ToolbarItem(placement: .cancellationAction)` con un botón `chevron.backward` (etiqueta accesible "Regresar") y `.navigationBarBackButtonHidden(true)`. Ocultar el botón atrás del sistema también desactiva el gesto de deslizar para volver, así no se puede salir sin pasar por la pregunta.
- Regresar: si `hasChanges`, `confirmationDialog("¿Descartar los cambios?")` con "Descartar cambios" (destructivo) y "Seguir editando" (cancelar); si no, `dismiss()`. Guardar exitoso también llama `dismiss()`.
- `AccountFormView` recibe la ruta y el contexto y crea su ViewModel con `State(initialValue:)`; SwiftUI conserva la primera instancia aunque la vista se re-evalúe.
- **Alternativa descartada:** presentar el formulario en `.sheet`. El pedido pide push con la barra oculta y botón de regresar a la izquierda.

### 8. Formulario

`Form` nativo con secciones:
1. Vista previa: `AccountCardView` alimentada por el `draft` (fondo de fila transparente).
2. "Tipo de cuenta": `Picker` en fila (estilo menú) con `AccountKind.allCases`; `.disabled(isKindLocked)`.
3. Datos: "Nombre" (`TextField`), "Últimos 4 dígitos" (`TextField`, `.numberPad`), `balanceTitle` (`CurrencyField`) y, solo si `requiresCreditLimit`, "Límite" (`CurrencyField`). Cada campo usa `LabeledContent` para que su título se vea, y debajo un `Text` en rojo (`.foregroundStyle(.red)`, `.font(.footnote)`) con el error cuando corresponda.
- Título de navegación: "Nueva cuenta" / "Editar cuenta" (modo en línea).
- Aviso de error de guardado: `.alert("No se pudo guardar la cuenta. Intenta de nuevo.")`.

### 9. Tarjeta gráfica y carrusel

- **`AccountCardContent`** (struct DTO): `kind`, `name`, `lastFourDigits`, `balance`. Se construye desde `Account` (carrusel) o desde `AccountDraft` (formulario). Con nombre vacío muestra un nombre de ejemplo atenuado ("Nombre de la cuenta") y con dígitos incompletos rellena con `-` ("**** 48--").
- **`AccountCardView`**: rectángulo redondeado (radio 20) con proporción de tarjeta de crédito (1,586:1) como alto mínimo —crece si el texto dinámico lo necesita— y texto blanco. Fondo oscuro fijo por `AccountKind`: CA azul marino (≈ `#1E3A8A` → `#0F1F5C`), TC grafito (≈ `#4A4A4F` → `#2A2A2E`); el gradiente va de `.topLeading` a `.trailing` y una capa encima oscurece el borde derecho, para simular luz desde la izquierda. Colores fijos con buen contraste en ambos modos; no usa Liquid Glass (es contenido, no navegación). Contenido: arriba el tipo (`displayName`) y, a la derecha, el ícono del tipo (SF Symbol `banknote` en CA, `creditcard` en TC); el nombre en `.title3`; "**** 4821" en monoespaciado junto al ícono de pago sin contacto (`wave.3.right`); y abajo el rótulo `balanceTitle` en `.caption` sobre el balance formateado. Los íconos son decorativos (`.accessibilityHidden`). Accesibilidad: `.accessibilityElement(children: .ignore)` con etiqueta "Cuenta de Ahorros, Nómina, terminada en 4821, saldo $ 1.250.000,00" (o "deuda" en TC).
- **`AddAccountCardView`**: mismo tamaño, borde punteado `.secondary`, ícono `plus` y es un `Button` con etiqueta accesible "Agregar cuenta".
- **`AccountCarouselView`**: `@FetchRequest(sortDescriptors: [SortDescriptor(\.createdAt, order: .forward)])`, `ScrollView(.horizontal)` con `LazyHStack` + `.scrollTargetLayout()`, `.scrollTargetBehavior(.viewAligned)`, `.contentMargins(.horizontal, 16)`, `.scrollIndicators(.hidden)` y ancho de tarjeta con `.containerRelativeFrame(.horizontal)` (~85 % para que asome la siguiente). Cada `AccountCardView` lleva `.contextMenu` con "Editar" (`pencil`) y "Eliminar" (`trash`, rol destructivo) y **ningún** gesto de toque (RF8). Eliminar abre `confirmationDialog("¿Eliminar la cuenta «Nombre»?", message: "Esta acción no se puede deshacer.")` con "Eliminar cuenta" (destructivo) y "Cancelar".
- `HomeView` pone el carrusel arriba dentro de su `ScrollView` vertical, sin título, y le pasa el contexto y el callback para abrir el formulario.

### 10. Configuración → Datos Maestros → Tipos de cuenta

Vistas de solo lectura, sin ViewModel:
- `SettingsView`: `List` con un `NavigationLink("Datos Maestros")` hacia `MasterDataView`.
- `MasterDataView`: `.navigationTitle("Datos Maestros")`, `List` con `NavigationLink("Tipos de cuenta")` hacia `AccountTypeListView`.
- `AccountTypeListView`: `@FetchRequest` ordenado por `name`, filas `LabeledContent(name, value: abbreviation)`, sin `onDelete`, sin toolbar de edición, sin navegación al tocar.

### 11. Pruebas

Se crea el target `BudgetSpyTests` (Unit Testing Bundle, Swift Testing) desde Xcode usando la carpeta vacía existente `BudgetSpy/BudgetSpyTests/`. **Excepción justificada** a "todo el código Swift vive bajo `BudgetSpy/BudgetSpy/`": los archivos de prueba no pueden vivir en la carpeta del target de la app porque se compilarían dentro de ella; la carpeta hermana es la convención de Xcode y ya existe.

### Archivos

Nuevos:
- `BudgetSpy/BudgetSpy/Core/Persistence/AccountTypeSeeder.swift`
- `BudgetSpy/BudgetSpy/Core/Shared/Formatters/CurrencyFormatter.swift`
- `BudgetSpy/BudgetSpy/Core/Shared/Formatters/CurrencyParser.swift`
- `BudgetSpy/BudgetSpy/Core/Shared/Components/CurrencyField.swift` (incluye `#Preview`)
- `BudgetSpy/BudgetSpy/Features/Accounts/Models/AccountKind.swift`
- `BudgetSpy/BudgetSpy/Features/Accounts/Models/AccountDraft.swift`
- `BudgetSpy/BudgetSpy/Features/Accounts/Models/AccountField.swift` (enum de campos + `AccountValidationError` con mensajes)
- `BudgetSpy/BudgetSpy/Features/Accounts/Models/AccountValidator.swift`
- `BudgetSpy/BudgetSpy/Features/Accounts/Models/AccountCardContent.swift`
- `BudgetSpy/BudgetSpy/Features/Accounts/Models/AccountFormRoute.swift`
- `BudgetSpy/BudgetSpy/Features/Accounts/Models/Account+Display.swift` (y `AccountType.kind`)
- `BudgetSpy/BudgetSpy/Features/Accounts/ViewModels/AccountFormViewModel.swift`
- `BudgetSpy/BudgetSpy/Features/Accounts/ViewModels/AccountCarouselViewModel.swift`
- `BudgetSpy/BudgetSpy/Features/Accounts/Views/AccountCardView.swift` (incluye `#Preview` CA/TC/vacía, claro y oscuro)
- `BudgetSpy/BudgetSpy/Features/Accounts/Views/AddAccountCardView.swift` (incluye `#Preview`)
- `BudgetSpy/BudgetSpy/Features/Accounts/Views/AccountCarouselView.swift` (incluye `#Preview` con y sin Cuentas)
- `BudgetSpy/BudgetSpy/Features/Accounts/Views/AccountFormView.swift` (incluye `#Preview` crear y editar)
- `BudgetSpy/BudgetSpy/Features/Settings/Views/MasterDataView.swift` (incluye `#Preview`)
- `BudgetSpy/BudgetSpy/Features/Settings/Views/AccountTypeListView.swift` (incluye `#Preview`)
- `BudgetSpy/BudgetSpyTests/…` (ver tasks.md)

Movidos / modificados:
- `BudgetSpy/BudgetSpy/Persistence.swift` → `BudgetSpy/BudgetSpy/Core/Persistence/Persistence.swift` (siembra, datos de `preview`, limpieza de comentarios de plantilla).
- `BudgetSpy/BudgetSpy/BudgetSpy.xcdatamodeld` → `BudgetSpy/BudgetSpy/Core/Persistence/BudgetSpy.xcdatamodeld` (nueva versión `BudgetSpy 2`).
- `BudgetSpy/BudgetSpy/App/BudgetSpyApp.swift` (inyecta el contexto).
- `BudgetSpy/BudgetSpy/Features/Home/Views/HomeView.swift` (carrusel + destino del formulario; `#Preview` con contexto de preview).
- `BudgetSpy/BudgetSpy/Features/Settings/Views/SettingsView.swift` (lista "Datos Maestros"; `#Preview`).

Dependencias nuevas: ninguna.

## Risks / Trade-offs

- [`CurrencyField` con `Binding` formateado: si el usuario mueve el cursor al medio del texto, el dígito se inserta ahí y el valor salta] → Los dígitos se reinterpretan siempre como centavos, así el valor sigue siendo válido y ≥ 0. Si en pruebas manuales resulta confuso, alternativa: `TextField` de dígitos invisible con un `Text` formateado encima (mismo `CurrencyParser`, sin cambios en specs).
- [`.toolbar(.hidden, for: .tabBar)` puede animar con un pequeño salto al entrar/salir] → Comportamiento estándar del sistema; se verifica en simulador.
- [Ocultar el botón atrás desactiva el gesto de deslizar para volver, algo que el usuario de iOS espera] → Es intencional para garantizar la pregunta de descartar cambios (spec "Regresar desde el formulario").
- [Dos tipos creados en paralelo sin restricción de unicidad podrían duplicarse] → La siembra corre una sola vez, en el hilo principal, al iniciar; una restricción de unicidad se puede agregar después sin cambiar specs.
- [La regla Deny en `AccountType.accounts` hará fallar un borrado de Tipo de cuenta con Cuentas] → El usuario no puede borrar Tipos de cuenta en este change; la regla protege la integridad a futuro.
- [Texto dinámico muy grande en la tarjeta] → La proporción es un alto mínimo; la tarjeta crece en alto y el nombre puede ocupar 2 líneas.
- [El `Picker` de tipo en modo edición deshabilitado puede no leerse como "bloqueado"] → Se ve atenuado según las HIG; VoiceOver anuncia "atenuado".
- [Crear el target de pruebas y la versión del modelo requieren la interfaz de Xcode] → Tareas explícitas; no se edita el `.pbxproj` a mano.

## Migration Plan

1. Agregar la versión `BudgetSpy 2` del modelo y marcarla como actual; la migración ligera inferida actualiza cualquier store de desarrollo existente.
2. En la primera apertura tras actualizar, la siembra crea "Cuenta de Ahorros" (CA) y "Tarjeta de Crédito" (TC).
3. Rollback: revertir el commit. Un store ya migrado a `BudgetSpy 2` no abre con el modelo anterior → en dispositivos de desarrollo, borrar la app. No hay usuarios reales.
