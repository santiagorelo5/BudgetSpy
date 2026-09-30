# Design: add-movements

## Context

La motivación está en proposal.md (Why). Los requisitos están en `specs/movements`, en `specs/movement-types` y en los deltas de `accounts`, `account-types` y `app-navigation`.

Estado actual observado en el código:

- **Navegación**: `ContentView` usa `TabView(selection:)` con 2 `Tab` (`AppTab.home`, `.settings`), cada uno con su propio `NavigationStack`. `HomeView` es un `ScrollView` vertical que solo contiene `AccountCarouselView` y abre `AccountFormView` con `navigationDestination(item:)`. El formulario oculta la barra con `.toolbar(.hidden, for: .tabBar)`.
- **Persistencia**: el modelo está en la versión `BudgetSpy 2.xcdatamodel`. Tiene `Account` (balance `Decimal`, `creditLimit` opcional, `createdAt` y relación con `AccountType`) y `AccountType` (nombre y abreviación). `PersistenceController` ejecuta `AccountTypeSeeder` al iniciar. El codegen es `class`.
- **Cuentas**:
  - `AccountFormViewModel.save()` escribe el balance directamente y llama a `context.save()`.
  - `AccountCarouselViewModel.confirmDeletion` llama a `context.delete(account)` y luego a `save()`.
  - `AccountValidator` ya garantiza balance ≥ 0 y límite ≥ deuda.
- **Utilidades compartidas**:
  - `CurrencyFormatter` formatea los negativos como `$ -1.000,00` (`negativePrefix = "$ -"`), y hay una prueba que lo exige.
  - `CurrencyField` implementa la digitación desde `$ 0,00`, sin signos.
- **Pruebas**: el target `BudgetSpyTests` usa Swift Testing y tiene `makeInMemoryContext()` en `TestSupport.swift`.
- **Carrusel**: `AccountCarouselView` no expone qué Cuenta está enfocada (no usa `scrollPosition`).

## Goals / Non-Goals

**Goals:**
- Un único componente de dominio es dueño del signo, el efecto y la validación de RF3, y es el único que modifica `Account.balance`.
- Toda operación que toque balances guarda todo o nada con un solo `context.save()`. Esto aplica a crear, editar y eliminar un Movimiento, y a crear, editar y eliminar una Cuenta.
- El "+" de la barra usa el `TabView` del sistema y conserva Liquid Glass, sin una barra personalizada.
- El Inicio no tiene scroll vertical anidado.

**Non-Goals:**
- Recalcular balances a partir de los Movimientos (el balance sigue almacenado).
- Migrar o limpiar las Cuentas creadas antes de este change (el usuario borra la app).
- Generalizar los seeders en una abstracción común (son solo dos y cada uno es trivial).

## Decisions

### 1. Modelo de Core Data: nueva versión `BudgetSpy 3`

Se crea la versión `BudgetSpy 3.xcdatamodel` y se marca como actual en `.xccurrentversion`. El codegen sigue siendo `class`.

**Entidad `MovementType`**

| Atributo / relación | Tipo | Regla |
|---|---|---|
| `name` | String, obligatorio | Identifica el tipo: "Gasto", "Ingreso" o "Transferencia". |
| `movements` | to-many → `Movement`, opcional | Regla de borrado **Deny**. |

**Entidad `Movement`**

| Atributo / relación | Tipo | Regla |
|---|---|---|
| `id` | UUID, obligatorio | |
| `amount` | Decimal, obligatorio, por defecto 0 | Lleva el signo respecto a la Cuenta origen (ver Decisión 2). |
| `movementDescription` | String, obligatorio | No se llama `description` porque choca con `NSObject.description`. |
| `date` | Date, obligatorio | Inicio del día (`Calendar.current.startOfDay`). |
| `createdAt` | Date, obligatorio | Último criterio de desempate en el orden. |
| `originAccount` | to-one → `Account`, obligatorio | Inversa `originMovements`. |
| `destinationAccount` | to-one → `Account`, opcional | Inversa `destinationMovements`. |
| `movementType` | to-one → `MovementType`, obligatorio | Inversa `movements`, regla Nullify. |

**Entidad `Account`** (relaciones nuevas)

| Relación | Tipo | Regla |
|---|---|---|
| `originMovements` | to-many → `Movement`, opcional | Regla de borrado **Cascade**. Elimina los Gastos e Ingresos de la Cuenta; las Transferencias se tratan antes (Decisión 4). |
| `destinationMovements` | to-many → `Movement`, opcional | Regla de borrado **Nullify**. Es solo una red de seguridad, porque el ledger convierte antes esas Transferencias. |

**Migración**: ligera. Solo se agregan entidades y relaciones opcionales en entidades existentes. `NSPersistentContainer` ya activa por defecto `shouldMigrateStoreAutomatically` y `shouldInferMappingModelAutomatically`, así que `Persistence` no necesita cambios para esto. Como se acordó, las Cuentas anteriores al change quedan con balance y sin Movimientos, y el usuario borra la app a mano.

Alternativa descartada: guardar `amount` siempre positivo, con un atributo de "dirección". Se descarta por dos razones:
- Las notas técnicas piden guardar el valor con signo respecto a la Cuenta origen.
- La invariante de la Decisión 2 (signo = delta) simplifica todos los cálculos.

### 2. Invariante clave: el valor con signo es el delta del balance

Con la tabla de RF3, en **los dos** Tipos de cuenta el valor con signo es exactamente el cambio que produce en el balance almacenado de esa Cuenta:

- **Cuenta de Ahorros**: un Gasto de −v deja el balance en balance − v, y un Ingreso de +v lo deja en balance + v.
- **Tarjeta de Crédito** (el balance es la deuda): un Gasto de +v deja la deuda en deuda + v, y un Ingreso de −v la deja en deuda − v.
- **Transferencia**: la Cuenta origen recibe −v (siempre es de Ahorros). La Cuenta destino recibe +v si es de Ahorros y −v si es Tarjeta de Crédito.

Por eso todo el motor se reduce a "sumar el valor con signo de cada Cuenta afectada". El valor se guarda respecto a la Cuenta origen. El de la Cuenta destino se deriva con `destinationSignedAmount(amount:destinationKind:)`.

Ese mismo valor con signo es el que muestra la lista (RF13). El **color** no sale del signo sino del rol:
- `outgoing` (rojo): un Gasto, o una Transferencia vista desde su Cuenta origen.
- `incoming` (verde): un Ingreso, o una Transferencia vista desde su Cuenta destino.

Así se cumple CA26: un Gasto en Tarjeta de Crédito se ve rojo y con `$ 10.000,00`.

### 3. Componente de dominio: `MovementRules` (puro) + `MovementLedger` (Core Data)

La lógica de RF3 se separa en dos partes para probarla sin Core Data, manteniendo un único punto de verdad.

**`MovementRules`** es un struct sin dependencias de Core Data. Trabaja con dos tipos valor:
- `AccountSnapshot`: `id`, `kind`, `name`, `balance`, `creditLimit`.
- `MovementEffect`: `kind`, `amount` sin signo, `originID`, `destinationID?`.

Expone estas funciones:
- `signedAmount(kind:originKind:)`.
- `destinationSignedAmount(amount:destinationKind:)`.
- `deltas(of: MovementEffect, accounts:) -> [UUID: Decimal]`.
- `balanceError(applying new: MovementEffect, replacing old: MovementEffect?, accounts:) -> MovementBalanceError?`. Revierte `old`, aplica `new` y valida cada Cuenta afectada, primero la origen y luego la destino.
- `deletionError(of: MovementEffect, accounts:) -> MovementDeletionError?`.
- `adjustment(for kind: AccountKind, from old: Decimal, to new: Decimal) -> (MovementKind, signedAmount)?`, para RF16. El valor con signo es `new − old`. Es un Ingreso si el delta es positivo en Cuenta de Ahorros o negativo en Tarjeta de Crédito; en los demás casos es un Gasto.

`MovementBalanceError` tiene tres casos, y cada uno produce el mensaje exacto de la spec:
- `insufficientFunds(accountName, available)`: `available` es el balance tras revertir el efecto original.
- `exceedsCreditLimit(accountName, availableCredit)`: `availableCredit` es el límite menos la deuda, tras revertir.
- `exceedsDebt(accountName, debt)`.

**`MovementLedger`** es una clase final que recibe un `NSManagedObjectContext`. Es el **único** lugar que escribe `Account.balance` o crea, modifica o elimina un `Movement`. Sus métodos:
- `create(_ draft: MovementDraft)`, `update(_ movement:, with draft:)` y `delete(_ movement:)`.
- `recordInitialBalance(for account:)` (RF15), `recordAdjustment(for account:, from old:)` (RF16) y `prepareDeletion(of account:)` (RF17).

Cada método:
1. Vuelve a validar con `MovementRules` justo antes de mutar. La interfaz pudo haber habilitado el botón, pero la regla se hace cumplir en el dominio.
2. Aplica los deltas.
3. **No guarda.** El ViewModel que lo llama hace un único `context.save()`, y `rollback()` si hay error. Así se mantiene el "todo o nada" incluso cuando el formulario de Cuenta combina un cambio de Cuenta y un Movimiento en un solo guardado.

Alternativas descartadas:
- Una sola clase que mezcle reglas y Core Data. Probar cada celda de la tabla exigiría un contenedor en memoria por caso, y rompe el principio de responsabilidad única (SRP).
- Poner la lógica en cada ViewModel. Lo descarta el requisito de un componente único.

Ubicación: `Features/Movements/Models/`. La feature Accounts depende de ella, lo cual es aceptable porque Movements es el dominio del balance. La configuración no define una carpeta `Core/Domain` y la disposición no debe cambiarse.

### 4. RF17: eliminar una Cuenta

`MovementLedger.prepareDeletion(of account)` se ejecuta antes de `context.delete(account)`, dentro del mismo guardado:

1. Transferencias hacia la Cuenta eliminada (cada Movimiento en `destinationMovements`):
   - `movementType` pasa a Gasto y `destinationAccount` a nil.
   - `amount` no cambia: ya es negativo respecto a la Cuenta origen de Ahorros, que es lo que corresponde a un Gasto.
   - El balance de la Cuenta origen no cambia.
2. Transferencias desde la Cuenta eliminada (cada Transferencia en `originMovements`):
   - `originAccount` pasa a la antigua Cuenta destino, y `destinationAccount` a nil.
   - `movementType` pasa a Ingreso.
   - `amount` pasa a `destinationSignedAmount`: +v si la Cuenta es de Ahorros y −v si es Tarjeta de Crédito, que es lo que corresponde a un Ingreso en ese Tipo de cuenta.
   - El balance no cambia.
3. `context.delete(account)`. La regla Cascade de `originMovements` elimina los Gastos e Ingresos restantes.

El balance de las demás Cuentas nunca cambia: los Movimientos solo cambian de clasificación, y su efecto sobre la Cuenta que los conserva es el mismo.

### 5. Botón "+" en la barra: un `Tab` que intercepta la selección

`AppTab` agrega el caso `.newMovement`. `ContentView` declara 3 `Tab`, en el orden Inicio, "+" y Configuración. El `Tab` del "+" es `Tab(value: .newMovement) { EmptyView() } label: { Label("Agregar movimiento", systemImage: "plus") }`, con contenido vacío.

El `TabView` recibe un `Binding` propio:
- Si el valor que se asigna es `.newMovement`, **no** cambia `selectedTab`: pone `selectedTab = .home` y `movementFormRoute = .create`.
- Cualquier otro valor se asigna normalmente.

Con esto, el "+" nunca queda seleccionado (RF1) y la barra sigue siendo el `TabView` del sistema, con su Liquid Glass nativo. El texto de la etiqueta solo lo usa VoiceOver ("Agregar movimiento"). En el simulador se verifica si la barra muestra ese texto bajo el "+"; si lo muestra, se deja solo el ícono con `.labelStyle(.iconOnly)`, que conserva la etiqueta de accesibilidad.

El formulario **se apila en el `NavigationStack` del Inicio**, no se presenta como hoja:
- `movementFormRoute: MovementFormRoute?` vive en `ContentView` y se pasa a `HomeView` como `Binding`.
- `HomeView` agrega `.navigationDestination(item: $movementFormRoute)`, junto al del formulario de Cuenta.

Resultado:
- Regresar y guardar siempre vuelven al Inicio (RF5 y RF7).
- La barra se oculta con el mismo `.toolbar(.hidden, for: .tabBar)` del formulario de Cuenta (RF6).
- La pila de Configuración queda intacta, así que cada sección conserva su navegación.

Alternativas descartadas:
- `Tab(role: .search)`: el sistema lo ubica aparte, a la derecha, así que no queda en el centro.
- Un botón flotante con `.glassEffect()` sobre la barra: duplica lo que ya hace el sistema, no se integra con el layout de la barra y contradice "preferir componentes nativos".
- `fullScreenCover`: al abrirlo desde Configuración no vuelve al Inicio por sí solo, y es un patrón distinto al del formulario de Cuenta.

### 6. Inicio: foco del carrusel y lista sin scroll anidado

**Foco del carrusel**
- `HomeView` guarda `@State focusedAccountID: UUID?`.
- `AccountCarouselView` lo recibe como `Binding` y usa `.scrollPosition(id:)` sobre su `ScrollView(.horizontal)`. Cada tarjeta lleva `.id(account.id)` y la tarjeta "+" tiene la identidad `nil`.
- Al abrir el Inicio se enfoca la primera Cuenta. Sin Cuentas, el foco es `nil`: tarjeta "+" y sin sección de Movimientos.
- Al eliminar una Cuenta, el foco pasa a la primera Cuenta que quede.
- El formulario de Movimiento recibe un cierre `onSaved: (UUID) -> Void`. `HomeView` lo usa para poner en `focusedAccountID` la Cuenta origen (RF7).

**Sin scroll anidado**
- Se **elimina** el `ScrollView` vertical externo de `HomeView`. El Inicio pasa a ser un `VStack` con el carrusel, el encabezado "Movimientos" y `MovementListView`.
- La lista es un `List(.plain)` con `.frame(maxHeight: rowHeight * 6)`. `rowHeight` es un `@ScaledMetric`, así que sigue el tamaño de texto dinámico.
- Con tamaños de texto muy grandes, el `List` se reduce al espacio disponible y sigue desplazándose por dentro.
- Solo existe un scroll vertical, así que no hay conflicto de scroll anidado. El carrusel horizontal no compite en el eje vertical.
- Alternativa descartada: todo el Inicio como un único `List`, con el carrusel como fila. RF8 pide un área acotada con scroll propio.

**Datos de la lista**
- `MovementListView(account:)` usa `@FetchRequest` con el predicado `originAccount == %@ OR destinationAccount == %@`.
- Ordena en memoria con `MovementOrdering.sorted(_:for:)`, que es puro y tiene pruebas. El segundo criterio (el valor con signo **visto desde la Cuenta enfocada**) no se puede expresar como `NSSortDescriptor` en las Transferencias.
- Ordenar en memoria no tiene un costo relevante, porque el volumen por Cuenta es pequeño.

### 7. Fila, detalle y acciones

**Contenido de la fila**
- `MovementRowContent` es un struct que se construye con `(Movement, perspective: Account)`.
- Contiene `kind`, `systemImage`, `formattedDate` ("30 sep 2026"), `signedAmount`, `formattedAmount`, `role` (outgoing en rojo, incoming en verde) y `description`.
- También contiene `accessibilityLabel`, por ejemplo: "Gasto, Compra de café, 30 de septiembre de 2026, menos 10.000 pesos".
- El detalle usa el mismo contenido, con `perspective = origen`.

**Íconos (SF Symbols)**, teñidos con el color del rol:
- Gasto: `arrow.up.right.circle.fill`.
- Ingreso: `arrow.down.left.circle.fill`.
- Transferencia: `arrow.left.arrow.right.circle.fill`.

**Fecha**: `MovementDateFormatter`, en `Core/Shared/Formatters/`.
- Formato visible `d MMM yyyy` con una lista fija de abreviaturas de mes en español ("ene", "feb", …, "sep", …, "dic"). El locale `es` de ICU produce "sept." y la spec pide "sep".
- Fecha para VoiceOver: locale `es_CO` con `dateStyle = .long` ("30 de septiembre de 2026").

**Deslizar**
- Izquierda: `.swipeActions(edge: .trailing, allowsFullSwipe: true)` con un botón de basura teñido con `.tint(.red)`. **No** usa `role: .destructive`, porque con ese rol el `List` anima la eliminación de la fila antes de la confirmación.
- Derecha: `.swipeActions(edge: .leading, allowsFullSwipe: true)` con un botón de editar teñido con `.tint(.blue)`.
- SwiftUI expone las acciones de deslizar de un `List` como acciones de VoiceOver. Se verifica; si no aparecen, se declaran con `.accessibilityAction(named:)`.

**Detalle (RF11)**: `.contextMenu { } preview: { MovementDetailView(...) }`, sin ítems de menú. Ver Riesgos.

**Eliminación**: un `.confirmationDialog` con "Eliminar movimiento" / "Cancelar", manejado por `MovementListViewModel`.
- El ViewModel guarda el Movimiento pendiente y sus avisos.
- `confirmDeletion()` llama a `ledger.delete` y luego a `save`.
- Avisos posibles: "No se puede eliminar el movimiento: \<justificación\>" y "No se pudo eliminar el movimiento. Intenta de nuevo."

**Justificaciones de la eliminación bloqueada.** La spec solo fija el ejemplo de Cuenta de Ahorros; los demás siguen el mismo patrón:
- Cuenta de Ahorros menor que 0: "el saldo de \<Cuenta\> quedaría en \<valor\>".
- Tarjeta de Crédito menor que 0: "la deuda de \<Cuenta\> quedaría en \<valor\>".
- Tarjeta de Crédito por encima del Límite: "la deuda de \<Cuenta\> quedaría en \<valor\> y supera el límite de \<Límite\>".

### 8. Formulario de Movimiento

**`MovementDraft`** es un struct `Equatable` con `kind`, `amount` (`Decimal` sin signo), `description`, `date`, `originAccountID: UUID?` y `destinationAccountID: UUID?`. `hasChanges` es `draft != initialDraft`.

**`MovementFormViewModel`** (`@Observable`):
- **Datos de entrada**: recibe la ruta (`.create` o `.edit(Movement)`), el contexto y el ledger. Carga las Cuentas ordenadas por `createdAt` y las convierte en `AccountSnapshot`.
- **Opciones de Cuenta**: expone `originOptions` y `destinationOptions` según RF2. `select(kind:)` y `selectOrigin(_:)` aplican las reglas de reasignación.
- **Errores**:
  - `errors`: errores por campo, calculados por `MovementValidator`.
  - `balanceError`: calculado por `MovementRules` y mostrado bajo `.amount`. Al editar, se le pasa el efecto original como `replacing`.
  - `editedFields` controla qué errores se ven, con el mismo patrón que `AccountFormViewModel`.
- **Guardado**: `save()` llama a `ledger.create` o `ledger.update` y luego a `context.save()`. Si falla, hace `rollback()` y muestra el aviso. Devuelve el ID de la Cuenta origen para `onSaved`.
- **Edición**: el borrador se construye desde el Movimiento con `amount = |amount|`. El formulario se abre igual desde la lista de la Cuenta origen o de la destino, y siempre muestra la Cuenta origen como "Cuenta origen".

**Vista `MovementFormView`**: un `Form` con estos elementos.
- Arriba, `Picker(.segmented)` con los tres Tipos de movimiento.
- `CurrencyField` para el valor, con `.foregroundStyle` según el tipo: rojo, verde o `.primary`.
- `TextField` para la descripción. El ViewModel la trunca a 20 caracteres, igual que el nombre de Cuenta.
- `DatePicker(in: ...Date.now, displayedComponents: .date)`.
- `Picker(.menu)` para las Cuentas. Si no hay opciones disponibles, se muestra un `LabeledContent` con "No hay cuentas disponibles".
- La toolbar, el diálogo de descartar y `.toolbar(.hidden, for: .tabBar)` siguen el patrón de `AccountFormView`.

### 9. Cambios en Cuentas

**`AccountFormViewModel.save()`**
- Al crear: crea la Cuenta con balance 0 y llama a `ledger.recordInitialBalance(for:targetBalance:)`. Esa llamada crea el Movimiento "Saldo inicial" con la fecha `createdAt` y lo aplica, así que el balance queda igual al digitado.
- Al editar: llama a `ledger.recordAdjustment(for:from: oldBalance)` en lugar de asignar el balance directamente. Solo el ledger toca el balance.
- En los dos casos hay un único `save()`.

**`AccountCarouselViewModel.confirmDeletion`**: llama a `ledger.prepareDeletion(of:)`, luego a `context.delete` y luego a `save()`. Si falla, `rollback()` también revierte las Transferencias convertidas.

### 10. Tipos de movimiento: semilla y pantalla

- `MovementTypeSeeder`, en `Core/Persistence/`, copia el patrón de `AccountTypeSeeder`: busca por `name` contra `MovementKind.allCases`. `PersistenceController.init` lo llama después de `AccountTypeSeeder`.
- `MovementKind` es un enum `String` cuyo `rawValue` es el nombre semilla. Resuelve el comportamiento a partir de `MovementType.name`, igual que `AccountKind` lo hace con la abreviación.
- `MovementTypeListView` usa `@FetchRequest` ordenado por `name`. El orden alfabético ("Gasto" < "Ingreso" < "Transferencia") coincide con el orden exigido, así que no se agrega un atributo `order`.
- `MasterDataView` agrega un segundo `NavigationLink`.

### 11. Formato de negativos (excepción al principio 5 de config.yaml)

`CurrencyFormatter.negativePrefix` pasa de `"$ -"` a `"-$ "`, y su prueba pasa a esperar `-$ 1.000,00`.

- **Justificación escrita**: la decisión de negocio del usuario (2026-09-30, proposal) fija `-$ 10.000,00` como formato visible de los Movimientos. Para mantener el formato centralizado se cambia el formateador existente en lugar de crear uno segundo.
- **Alcance**: ninguna pantalla existente muestra negativos, porque las Cuentas siempre tienen balance ≥ 0. No hay regresión visible.
- **Seguimiento**: el principio 5 de `openspec/config.yaml` aún dice `$ -1.000,00`. El usuario debe actualizarlo.

### 12. Archivos nuevos y modificados

**Archivos nuevos** (todos bajo `BudgetSpy/BudgetSpy/`):
- `Core/Persistence/BudgetSpy.xcdatamodeld/BudgetSpy 3.xcdatamodel/contents`
- `Core/Persistence/MovementTypeSeeder.swift`
- `Core/Shared/Formatters/MovementDateFormatter.swift`
- `Features/Movements/Models/MovementKind.swift`
- `Features/Movements/Models/AccountSnapshot.swift`
- `Features/Movements/Models/MovementEffect.swift`
- `Features/Movements/Models/MovementRules.swift`
- `Features/Movements/Models/MovementBalanceError.swift` (incluye `MovementDeletionError`)
- `Features/Movements/Models/MovementLedger.swift`
- `Features/Movements/Models/MovementDraft.swift`
- `Features/Movements/Models/MovementField.swift` (campos y errores de validación)
- `Features/Movements/Models/MovementValidator.swift`
- `Features/Movements/Models/MovementFormRoute.swift`
- `Features/Movements/Models/MovementRowContent.swift`
- `Features/Movements/Models/MovementOrdering.swift`
- `Features/Movements/Models/Movement+Display.swift` (`amountValue`, `kind`, `effect`)
- `Features/Movements/ViewModels/MovementFormViewModel.swift`
- `Features/Movements/ViewModels/MovementListViewModel.swift`
- `Features/Movements/Views/MovementFormView.swift`
- `Features/Movements/Views/MovementListView.swift`
- `Features/Movements/Views/MovementRowView.swift`
- `Features/Movements/Views/MovementDetailView.swift`
- `Features/Settings/Views/MovementTypeListView.swift`

**Pruebas nuevas** (en `BudgetSpy/BudgetSpyTests/`):
- `MovementRulesTests.swift`
- `MovementLedgerTests.swift`
- `MovementValidatorTests.swift`
- `MovementFormViewModelTests.swift`
- `MovementListViewModelTests.swift`
- `MovementOrderingTests.swift`
- `MovementRowContentTests.swift`
- `MovementTypeSeederTests.swift`
- `MovementDateFormatterTests.swift`

**Archivos modificados**:
- `App/AppTab.swift`
- `App/ContentView.swift`
- `Core/Persistence/BudgetSpy.xcdatamodeld/.xccurrentversion`
- `Core/Persistence/Persistence.swift` (seeder y Movimientos de ejemplo en `preview`)
- `Core/Shared/Formatters/CurrencyFormatter.swift`
- `Features/Home/Views/HomeView.swift`
- `Features/Accounts/Views/AccountCarouselView.swift`
- `Features/Accounts/ViewModels/AccountFormViewModel.swift`
- `Features/Accounts/ViewModels/AccountCarouselViewModel.swift`
- `Features/Settings/Views/MasterDataView.swift`
- Pruebas `CurrencyFormatterTests`, `AccountFormViewModelTests` y `AccountCarouselViewModelTests`

**Dependencias**: ninguna nueva.

## Risks / Trade-offs

- **[Riesgo] En iOS 26, `contextMenu` sin ítems de menú podría no presentar la vista previa.** → Mitigación: se verifica en la primera tarea de interfaz. Si falla, `.onLongPressGesture` presenta `MovementDetailView` como `.popover` con `.presentationCompactAdaptation(.popover)`. Sigue siendo de solo lectura y no choca con `swipeActions`, que usa arrastre horizontal.
- **[Riesgo] El `Tab` del "+" podría mostrar el texto "Agregar movimiento" bajo el ícono, o parpadear como seleccionado antes de que el `Binding` lo revierta.** → Mitigación: el `Binding` nunca asigna `.newMovement`, así que no hay estado intermedio visible. La etiqueta se revisa en el simulador y se aplica `.labelStyle(.iconOnly)` si hace falta.
- **[Riesgo] El balance almacenado se descuadra frente a los Movimientos por una escritura directa que evite el ledger.** → Mitigación: `MovementLedger` es el único que escribe `balance`, y las pruebas verifican que el balance sea igual a la suma de los deltas después de cada operación. Los changes futuros deben usar el mismo componente (ver proposal, Impact).
- **[Riesgo] `.scrollPosition(id:)` sobre un `LazyHStack` con `viewAligned` podría no reportar el foco mientras el deslizamiento desacelera.** → Mitigación: el foco es definitivo cuando el deslizamiento se detiene, y eso basta para la lista. Se verifica a mano con CA18.
- **[Trade-off] Se elimina el `ScrollView` externo del Inicio.** Con tamaños de texto de accesibilidad, la lista queda más baja (menos de 6 filas visibles), pero sigue siendo usable y evita el scroll anidado. Se prefiere esto a coordinar dos scrolls verticales.
- **[Trade-off] El orden se hace en memoria**, no en el `@FetchRequest`. Es aceptable por el poco volumen por Cuenta en una app personal.
- **[Trade-off] El usuario no definió los mensajes de justificación para Tarjeta de Crédito.** Se propone el patrón de la Decisión 7. Si el usuario prefiere otra redacción, solo cambian los textos de `MovementDeletionError`.

## Migration Plan

1. Crear `BudgetSpy 3.xcdatamodel` como nueva versión y marcarla como actual. `BudgetSpy 2` se deja intacta para que la migración ligera pueda inferir el mapeo.
2. Al instalar, Core Data migra el almacenamiento automáticamente y los Tipos de movimiento se siembran al iniciar.
3. El usuario elimina las Cuentas previas (sin Movimientos) borrando la app. No se escribe código de migración ni de limpieza.
4. Reversión: revertir el change en git. Un almacenamiento ya migrado a la versión 3 no es compatible con un build anterior, así que hay que borrar la app del simulador o del dispositivo. Es aceptable porque no hay datos de usuarios en producción.
