# Design: add-accounts

## Context

La motivación está en proposal.md (Why). Los requisitos están en `specs/accounts`, `specs/account-types` y `specs/app-navigation`.

Estado actual del repositorio:
- `App/ContentView.swift` tiene un `TabView` con una `NavigationStack` por sección. `HomeView` y `SettingsView` son un `ScrollView` vacío con `.navigationTitle`.
- `Persistence.swift` y `BudgetSpy.xcdatamodeld` están en la raíz del target, no en `Core/Persistence/`. El modelo solo tiene la entidad de plantilla `Item`, que no se usa.
- `BudgetSpyApp` crea `PersistenceController.shared`, pero no inyecta el contexto en el entorno.
- No existen `Core/`, `Features/Accounts/`, formateadores ni target de pruebas.
- El proyecto usa carpetas sincronizadas. Build settings relevantes: `SWIFT_VERSION = 5.0` y `SWIFT_APPROACHABLE_CONCURRENCY = YES`.
- `add-app-shell` ya está archivado y `openspec/specs/app-navigation/spec.md` existe. Este change reemplaza su requisito "Pantallas principales vacías con título" (REMOVED + ADDED).

## Goals / Non-Goals

**Goals:**
- Montar la primera capa de datos (Core Data) con la estructura que fija el proyecto (`Core/Persistence/`), para que los próximos changes (Transacciones) solo agreguen entidades.
- Separar la lógica de dominio de la UI para poder probarla con Swift Testing:
  - validación de Cuenta;
  - conversión de importes;
  - lógica de los ViewModels.
- Crear un campo monetario y un formateador reutilizables que cumplan los principios 5, 7 y 8.

**Non-Goals:**
- Localización a otros idiomas o String Catalog.
- Animaciones o diseños de tarjeta personalizables por el usuario (colores, logos de franquicia).
- Cambios de configuración del target (familia de dispositivos, orientación).

## Decisions

### 1. Modelo de Core Data (nombres en inglés)
Los nombres de entidades y atributos van en inglés, igual que el resto del código (principio 1). La codegen es `Class Definition`, la misma que usa hoy el modelo.

**`AccountType`**

| Atributo | Tipo | Opcional | Notas |
|---|---|---|---|
| `name` | String | No | "Cuenta de Ahorros", "Tarjeta de Crédito" |
| `abbreviation` | String | No | "CA", "TC". Tiene restricción de unicidad (*constraint*) |
| `accounts` | To-many → `Account` | Sí | Inversa de `accountType`. Regla de borrado **Deny** |

**`Account`**

| Atributo | Tipo | Opcional | Notas |
|---|---|---|---|
| `id` | UUID | No | |
| `name` | String | No | |
| `cardLastDigits` | String | No | Es String para conservar ceros a la izquierda ("0042") |
| `balance` | Decimal | No | Default 0 |
| `creditLimit` | Decimal | **Sí** | `nil` en Cuenta de Ahorros |
| `createdAt` | Date | No | Ordena el carrusel |
| `accountType` | To-one → `AccountType` | No | Regla de borrado **Nullify** |

- Se usa `creditLimit` en vez de `limit` para evitar ambigüedad con términos de consultas.
- Core Data expone `Decimal` como `NSDecimalNumber`. Una extensión `Account+Convenience.swift` ofrece propiedades `Decimal` y `String` no opcionales, y el `AccountTypeCode` de la Cuenta.
- Se elimina la entidad `Item`.
- **Alternativa descartada:** guardar el tipo como un enum en `Account`. La regla de negocio pide que Tipo de cuenta sea un dato maestro consultable, con nombre y abreviación.

### 2. Migración: se edita el modelo actual, sin versión nueva
La app nunca se ha distribuido y el modelo actual solo tiene `Item`, que no guarda datos reales. Crear una versión nueva del modelo solo para migrar desde `Item` agrega un archivo sin beneficio. Por eso se edita la versión existente.

Esto es una **excepción justificada** a "migración ligera": un store de desarrollo creado con el modelo anterior no carga. La mitigación es borrar la app del simulador o dispositivo antes de ejecutar este change. A partir de este change, cualquier cambio al modelo MUST agregar una versión nueva y usar migración ligera. `NSPersistentContainer` ya la infiere por defecto.

### 3. `Persistence` en `Core/Persistence/` y datos semilla
- Se mueven `Persistence.swift` y `BudgetSpy.xcdatamodeld` a `Core/Persistence/`.
  - El nombre del contenedor sigue siendo `"BudgetSpy"`, así que la ruta del store no cambia.
  - Es un movimiento dentro de carpetas sincronizadas, así que no requiere tocar el `.pbxproj`.
- `AccountTypeCode` (`enum: String { case savings = "CA", creditCard = "TC" }`) es la clave estable de la lógica de negocio. La lógica compara por `abbreviation`, nunca por el nombre visible.
- `AccountTypeSeeder.seedIfNeeded(in:)` busca cada código semilla y crea solo los que faltan (idempotente). `PersistenceController.init` lo llama después de `loadPersistentStores`, así los datos semilla existen también en previews y pruebas en memoria.
- `PersistenceController.preview` agrega además 2 Cuentas de ejemplo (una de cada tipo) para los `#Preview`.
- `BudgetSpyApp` inyecta `.environment(\.managedObjectContext, persistenceController.container.viewContext)`.
- **Alternativa descartada:** sembrar desde la vista de Inicio con `.task`. Mezcla responsabilidades y no cubre las previews.

### 4. Capas de la feature Accounts (MVVM + SOLID)
- **`AccountDraft`** (struct DTO): borrador del formulario.
  - Campos: `name`, `cardLastDigits`, `balance: Decimal`, `creditLimit: Decimal`, `typeCode: AccountTypeCode`.
  - Es `Equatable`. Comparar el borrador actual con el original da `hasChanges`.
- **`AccountValidator`**: struct puro.
  - `validate(_ draft: AccountDraft) -> [AccountValidationError]`, con los errores `emptyName`, `nameTooLong`, `invalidCardDigits` y `limitBelowBalance`.
  - Es la única fuente de las reglas de negocio de la spec y es fácil de probar.
- **`AccountRepository`**: protocolo con `accountTypes()`, `draft(for:)`, `create(_:)`, `update(_:with:)` y `delete(_:)`.
  - Lo implementa `CoreDataAccountRepository(context:)`, que al crear o guardar convierte `creditLimit` a `nil` si el tipo es `.savings`.
  - `update(_:with:)` nunca modifica `accountType`, aunque el borrador traiga otro `typeCode`. Así la regla "el Tipo de cuenta no cambia después de creada" se cumple también en la capa de datos, no solo en la UI.
  - Los ViewModels dependen del protocolo (inversión de dependencias), así que las pruebas pueden usar un contexto en memoria o un *fake*.
- **`AccountFormViewModel`** (`@Observable`, `@MainActor`).
  - Recibe `mode: AccountFormMode` (`.create` o `.edit(NSManagedObjectID)`) y el repositorio.
  - Expone `draft`, `hasChanges`, `canSave`, `validationErrors`, `balanceLabel`, `showsCreditLimit`, `canChangeType`, `title`, `saveButtonTitle` y `save() throws`.
  - `canChangeType` es verdadero solo en `.create`.
- **`AccountCarouselViewModel`** (`@Observable`, `@MainActor`).
  - Expone `accountPendingDeletion`, `requestDeletion(_:)`, `confirmDeletion()` y `cancelDeletion()`.
  - Existe porque las vistas no escriben en Core Data.
- **Lectura:**
  - `AccountCarouselView` usa `@FetchRequest` de `Account` ordenado por `createdAt` ascendente.
  - `AccountTypeListView` usa `@FetchRequest` de `AccountType` ordenado por `name`.
  - Ninguna de las dos usa DTO (regla del proyecto).
- **Alternativa descartada:** que el ViewModel acceda directo a `NSManagedObjectContext`. Acopla la lógica a Core Data y complica las pruebas.

### 5. Tarjeta gráfica reutilizable con un DTO de presentación
- `AccountCardView` recibe un `AccountCardModel` (struct: `typeName`, `accountName`, `cardLastDigits`, `balance`, `typeCode`). Así la misma vista sirve para:
  - el formulario, en vivo desde `AccountDraft`;
  - el carrusel, desde `Account`.
- `AccountCardModel` calcula:
  - `maskedNumber`: `"**** 1234"`, o `"**** ••••"` si faltan dígitos;
  - `balanceLabel`: "Saldo disponible" / "Deuda a la fecha";
  - el texto de ejemplo cuando el nombre está vacío.
- Diseño de la tarjeta:
  - Rectángulo redondeado (radio continuo) con proporción de tarjeta ISO (1,586:1).
  - Degradado de color sólido por tipo: azul para Ahorros, grafito para Tarjeta de Crédito.
  - Texto blanco con tipografía del sistema. La fuente es monoespaciada para el número (`.monospaced()`).
  - **Sin Liquid Glass ni materiales**, porque la tarjeta es contenido principal.
- Accesibilidad:
  - `.accessibilityElement(children: .ignore)` con una etiqueta compuesta, según la spec.
  - Con tamaños de accesibilidad de Dynamic Type, la tarjeta deja de fijar la proporción y crece en alto, para que el texto no se corte.
- `AddAccountCardView` es la misma forma, con borde discontinuo y un símbolo `plus` de SF Symbols. Usa `.accessibilityLabel("Agregar cuenta")` y se comporta como botón.

### 6. Carrusel horizontal nativo
- Estructura: `ScrollView(.horizontal)` + `LazyHStack` + `.scrollTargetLayout()` + `.scrollTargetBehavior(.viewAligned)` + `.contentMargins(.horizontal, 16)`.
- Cada tarjeta mide `.containerRelativeFrame(.horizontal) { w, _ in w * 0.85 }`, así se asoma la siguiente e invita a deslizar.
- Menú:
  - Cada tarjeta de Cuenta lleva `.contextMenu { Editar; Eliminar (role: .destructive) }`. Es el gesto nativo de mantener presionado y VoiceOver lo expone como acciones.
  - La tarjeta de Cuenta no tiene `onTapGesture`, así se cumple RF4.
  - La tarjeta "+" no tiene `contextMenu`.
- Eliminar muestra `.confirmationDialog("¿Eliminar la cuenta «Nombre»?")`, con "Eliminar" (destructiva) y "Cancelar".
- **Alternativa descartada:** `TabView` con `.page`. Muestra una tarjeta a la vez, agrega indicadores de página y no deja ver la siguiente.

### 7. Navegación al formulario sin tocar `ContentView`
- `HomeView` guarda `@State private var formMode: AccountFormMode?` y usa `.navigationDestination(item: $formMode) { AccountFormView(mode: $0) }` dentro de la `NavigationStack` de Inicio que ya existe.
  - La tarjeta "+" asigna `.create`.
  - "Editar" asigna `.edit(account.objectID)`.
- Regresar:
  - `AccountFormView` oculta el botón atrás del sistema (`.navigationBarBackButtonHidden()`) y pone un botón propio en la toolbar (`chevron.backward`, "Inicio").
  - Si `hasChanges` es verdadero, el botón muestra `.confirmationDialog("¿Deseas descartar los cambios?")`, con "Descartar cambios" (destructiva) y "Seguir editando". Si no hay cambios, hace `dismiss()` directo.
  - Al ocultar el botón del sistema también se desactiva el gesto de deslizar desde el borde, que evitaría la confirmación.
- Guardar:
  - El botón principal "Crear cuenta" / "Guardar cambios" es un `Button` con `.buttonStyle(.glassProminent)`, en la toolbar inferior del formulario (capa de controles, donde se permite Liquid Glass).
  - Se deshabilita con `!canSave`.
  - Si `save()` tiene éxito, hace `dismiss()`. Si falla, muestra un `.alert` y no cierra el formulario.
- La barra inferior se oculta mientras el formulario está abierto (`.toolbar(.hidden, for: .tabBar)`).
  - Así, tocar "Inicio" en la barra (que en iOS vuelve a la raíz de la pila) no puede saltarse la confirmación de descartar cambios.
  - No modifica la barra en sí: sus opciones y su comportamiento en las pantallas principales no cambian.
- Inicio se actualiza solo: `@FetchRequest` observa el contexto.

### 8. Campos del formulario
- `Form` nativo con estas secciones:
  1. **Tipo**:
     - Al crear (`canChangeType`): `Picker` `.segmented` sobre los Tipos de cuenta que carga el repositorio. Muestra el nombre completo y usa `AccountTypeCode` como valor.
     - Al editar: `LabeledContent("Tipo de cuenta", value: nombre del tipo)`, en solo lectura.
     - **Alternativa descartada:** un `Picker` deshabilitado. Parece un error de la app, y VoiceOver lo anuncia como un control inactivo en vez de como un dato.
  2. **Datos**:
     - Nombre: `TextField` con límite de 30 caracteres aplicado en `onChange`.
     - Últimos 4 dígitos: `TextField` con `.keyboardType(.numberPad)`. Un filtro deja solo dígitos y corta a 4.
  3. **Importes**:
     - `CurrencyField` con la etiqueta dinámica (`balanceLabel`).
     - `CurrencyField` "Límite", solo si `showsCreditLimit`.
- La tarjeta gráfica va como encabezado del `Form`: una primera sección sin fondo con `listRowBackground(Color.clear)`, para que haga scroll con el formulario.
- Los mensajes de validación aparecen como `footer` en rojo (`.foregroundStyle(.red)`) de la sección correspondiente, y solo después de que el campo se ha editado. Así el formulario no abre lleno de errores.

### 9. Importes: `CurrencyFormatter`, `CurrencyParser` y `CurrencyField` en `Core/Shared/`
- **`CurrencyFormatter.string(from: Decimal) -> String`**.
  - Usa `Decimal.FormatStyle` con locale `es_CO`, agrupación y `.precision(.fractionLength(2))`, con el prefijo `"$ "` fijo.
  - Resultado: `$ 1.000,00` y `$ -1.000,00`.
  - **Alternativa descartada:** `.currency(code: "COP")`. Su salida (espacio duro, decimales por defecto) cambia según el SO y no garantiza el formato exacto de la spec.
- **`CurrencyParser`**: implementa la lógica de entrada "por la derecha" (principios 7 y 8), sin estado.
  - `amount(fromDigits:) -> Decimal` y `digits(from: String) -> String`.
  - Como máximo 15 dígitos significativos (hasta $ 9.999.999.999.999,99). Los dígitos extra se ignoran.
- **`CurrencyField`**: vista reutilizable con un `Binding<Decimal>`.
  - Por dentro es un `TextField` con `.keyboardType(.numberPad)` que siempre muestra el importe formateado.
  - En cada cambio de texto: extrae los dígitos → `amount(fromDigits:)` → reformatea. Por ejemplo:
    - Al escribir "5" al final de `$ 1,25`, el texto queda `$ 1,255`, con dígitos `1255`, y se muestra `$ 12,55`.
    - Al borrar el último carácter de `$ 12,50`, el texto queda `$ 12,5`, con dígitos `125`, y se muestra `$ 1,25`.
  - Todo carácter no numérico se descarta, así que el signo no se puede escribir ni cambiar.
  - Siempre muestra valores positivos. El signo, cuando exista en el futuro (Transacciones), lo decide la lógica de negocio fuera del campo.

### 10. Configuración → Datos Maestros → Tipos de cuenta
- `SettingsView` cambia su `ScrollView` por `List` con un `NavigationLink("Datos Maestros")` → `MasterDataView`.
- `MasterDataView` es un `List` con `NavigationLink("Tipos de cuenta")` → `AccountTypeListView`.
- `AccountTypeListView` usa `@FetchRequest` y muestra un `LabeledContent(name, value: abbreviation)` por Tipo de cuenta. Si no hay datos, muestra `ContentUnavailableView("No hay tipos de cuenta", …)`.
- Ninguna de las tres pantallas tiene estado ni lógica, así que no llevan ViewModel.
- Las tres usan `NavigationLink` con destino directo porque son pantallas estáticas. Es lo más simple.

### 11. Target de pruebas
- Se crea el target `BudgetSpyTests` (Unit Testing Bundle, framework Swift Testing) desde la interfaz de Xcode, sin editar el `.pbxproj` a mano.
- Las pruebas usan `PersistenceController(inMemory: true)`, que ya siembra los Tipos de cuenta.
- Esto no agrega dependencias externas: Swift Testing es de Apple.

### Archivos

Nuevos (todos bajo `BudgetSpy/BudgetSpy/`):
- `Core/Persistence/AccountTypeSeeder.swift`: `AccountTypeCode` y la siembra idempotente.
- `Core/Shared/CurrencyFormatter.swift`
- `Core/Shared/CurrencyParser.swift`
- `Core/Shared/Views/CurrencyField.swift`: incluye `#Preview`.
- `Features/Accounts/Models/Account+Convenience.swift`
- `Features/Accounts/Models/AccountDraft.swift`
- `Features/Accounts/Models/AccountFormMode.swift`
- `Features/Accounts/Models/AccountValidator.swift`: incluye `AccountValidationError`.
- `Features/Accounts/Models/AccountCardModel.swift`
- `Features/Accounts/Models/AccountRepository.swift`: protocolo y `CoreDataAccountRepository`.
- `Features/Accounts/ViewModels/AccountFormViewModel.swift`
- `Features/Accounts/ViewModels/AccountCarouselViewModel.swift`
- `Features/Accounts/Views/AccountCardView.swift`: `#Preview` de ambos tipos y del estado vacío.
- `Features/Accounts/Views/AddAccountCardView.swift`: `#Preview`.
- `Features/Accounts/Views/AccountCarouselView.swift`: `#Preview` con datos y sin datos.
- `Features/Accounts/Views/AccountFormView.swift`: `#Preview` de crear y editar.
- `Features/Settings/Views/MasterDataView.swift`: `#Preview`.
- `Features/Settings/Views/AccountTypeListView.swift`: `#Preview`.
- `BudgetSpy/BudgetSpyTests/` (target nuevo):
  - `CurrencyFormatterTests.swift`
  - `CurrencyParserTests.swift`
  - `AccountValidatorTests.swift`
  - `AccountTypeSeederTests.swift`
  - `AccountRepositoryTests.swift`
  - `AccountFormViewModelTests.swift`
  - `AccountCarouselViewModelTests.swift`

Movidos / modificados:
- `Persistence.swift` → `Core/Persistence/Persistence.swift`: siembra y datos de preview.
- `BudgetSpy.xcdatamodeld` → `Core/Persistence/BudgetSpy.xcdatamodeld`: entidades nuevas; se elimina `Item`.
- `App/BudgetSpyApp.swift`: inyecta `managedObjectContext`.
- `App/ContentView.swift`: solo su `#Preview` inyecta el contexto de preview.
- `Features/Home/Views/HomeView.swift`: carrusel y `navigationDestination`. `#Preview` con contexto de preview.
- `Features/Settings/Views/SettingsView.swift`: `List` con "Datos Maestros". Se actualiza su `#Preview`.

Dependencias nuevas: ninguna.

## Risks / Trade-offs

- **[El store de desarrollo existente no carga con el modelo editado]** → Borrar la app del simulador antes de probar. Se documenta en tasks. No afecta a usuarios porque la app no se ha distribuido.
- **[`CurrencyField` con `TextField`: si el usuario mueve el cursor al medio del texto, el dígito entra en otra posición]** → Tras cada cambio se reformatea el texto completo, y el valor sigue siendo válido y positivo. Si en pruebas manuales resulta confuso, se puede cambiar a un campo con cursor fijo sin cambiar la spec.
- **[Ocultar la barra inferior en el formulario]** → Es un comportamiento contextual del formulario, no un cambio a la barra. Queda en la spec de `accounts`. La barra reaparece al volver a Inicio.
- **[Dynamic Type grande dentro de una tarjeta de proporción fija]** → En tamaños de accesibilidad la tarjeta crece en alto y los textos admiten 2 líneas. Se verifica en previews con `.dynamicTypeSize(.accessibility3)`.
- **[Contraste del texto blanco sobre los degradados en modo claro/oscuro]** → Se usan colores oscuros y saturados que no dependen del modo. Se verifica con la herramienta de contraste de Accessibility Inspector.
- **[Eliminar un Tipo de cuenta con Cuentas asociadas]** → La regla Deny lo impide a nivel de datos. De todas formas, la UI no permite eliminar Tipos de cuenta.

## Migration Plan

1. Borrar la app del simulador o dispositivo de desarrollo antes de la primera ejecución con el nuevo modelo.
2. Rollback: revertir el commit y borrar la app de nuevo, porque el store quedaría con el modelo nuevo.
