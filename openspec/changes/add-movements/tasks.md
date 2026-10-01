# Tasks: add-movements

## 1. Modelo de Core Data y Tipos de movimiento

- [x] 1.1 Agregar la versión `BudgetSpy 3` del modelo (Editor → Add Model Version) y marcarla como actual. Verificar en el inspector que `BudgetSpy 3` es la versión activa.
- [x] 1.2 En `BudgetSpy 3`, crear `MovementType` y `Movement` y agregar a `Account` las relaciones `originMovements` y `destinationMovements`, con los atributos, la opcionalidad, las inversas y las reglas de borrado de design.md §1 (codegen Class Definition). Verificar que compila y que la app abre sobre un almacenamiento de `BudgetSpy 2` sin error de migración.
- [x] 1.3 Crear `Features/Movements/Models/MovementKind.swift`:
  - `rawValue` = "Gasto" / "Ingreso" / "Transferencia", más `systemImage` (se retira en 8.9).
  - Crear `Movement+Display.swift` con `MovementType.kind`, `Movement.amountValue`, `Movement.kind` y `Movement.effect`.
  - Prueba `MovementKindTests`: el nombre y el ícono de cada caso.
- [x] 1.4 Crear `Core/Persistence/MovementTypeSeeder.swift`, que busca por nombre, inserta solo los que faltan y guarda solo si insertó. Llamarlo en `PersistenceController.init` después de `AccountTypeSeeder`, con un `Logger` en caso de fallo. Pruebas `MovementTypeSeederTests`:
  - La primera siembra crea exactamente 3.
  - Sembrar 3 veces sigue dejando 3.
  - Si faltaba "Transferencia", crea solo esa (CA29).

## 2. Formato de moneda y fecha

- [x] 2.1 Cambiar `CurrencyFormatter.negativePrefix` a `"-$ "` y actualizar `CurrencyFormatterTests` para que `-1000` dé `-$ 1.000,00`. Verificar con ⌘U que las pruebas de Cuentas siguen en verde.
- [x] 2.2 Crear `Core/Shared/Formatters/MovementDateFormatter.swift`: formato visible `d MMM yyyy` con las abreviaturas fijas "ene"…"dic", y formato hablado en `es_CO` `.long`. Pruebas `MovementDateFormatterTests`:
  - 30/09/2026 → "30 sep 2026".
  - 30/09/2026 hablado → "30 de septiembre de 2026".
  - 01/01/2026 → "1 ene 2026".

## 3. Componente de dominio: reglas de balance (RF3)

- [x] 3.1 Crear `AccountSnapshot.swift`, `MovementEffect.swift` y `MovementBalanceError.swift` (con `MovementDeletionError` y los mensajes exactos de la spec) en `Features/Movements/Models/`.
- [x] 3.2 Crear `MovementRules.swift` con `signedAmount`, `destinationSignedAmount`, `deltas`, `balanceError(applying:replacing:accounts:)`, `deletionError` y `adjustment` (design.md §2–§3). Pruebas `MovementRulesTests` para cada celda de la tabla de RF3, con signo, delta, límite exacto y límite excedido:
  - Gasto: CA y TC.
  - Ingreso: CA y TC.
  - Transferencia origen: solo CA.
  - Transferencia destino: CA y TC.
  - Escenarios con valores concretos:
    - CA7: $ 50.000 − $ 60.000 → "Saldo insuficiente en Nómina. Disponible: $ 50.000,00"; $ 50.000 − $ 50.000 → válido.
    - CA8: deuda $ 4.800.000 con límite $ 5.000.000 → $ 300.000 da "Supera el límite de Visa. Cupo disponible: $ 200.000,00"; $ 200.000 es válido.
    - CA9: deuda $ 100.000 → $ 150.000 da "El valor supera la deuda de Visa: $ 100.000,00"; $ 100.000 es válido.
- [x] 3.3 Pruebas `MovementRulesTests` de edición y eliminación:
  - Gasto −$ 30.000 → $ 50.000 con saldo $ 20.000 → válido.
  - Ingreso $ 50.000 → Gasto con saldo $ 10.000 → saldo insuficiente.
  - Cambio de Cuenta: revierte en la anterior y aplica en la nueva.
  - Eliminar un Ingreso de $ 50.000 con saldo $ 30.000 → "el saldo de Nómina quedaría en -$ 20.000,00".
  - Mensajes de Tarjeta de Crédito de design.md §7.
  - `adjustment`: CA ↑ = Ingreso, CA ↓ = Gasto, TC ↑ = Gasto, TC ↓ = Ingreso, sin cambio = nil.

## 4. Componente de dominio: ledger en Core Data (RF15–RF17)

- [x] 4.1 Crear `MovementDraft.swift` y `MovementLedger.swift` con `create`, `update` y `delete`: validan con `MovementRules`, aplican los deltas y no guardan. Pruebas `MovementLedgerTests` con contexto en memoria:
  - Crear, editar y eliminar actualizan los balances de las Cuentas origen y destino (CA15, CA16, CA21, CA23).
  - Si un Movimiento es inválido, lanza error sin mutar nada.
  - Tras cada operación, el balance es igual a la suma de los deltas de sus Movimientos.
- [x] 4.2 Agregar `recordInitialBalance` y `recordAdjustment` (design.md §9). Pruebas `MovementLedgerTests`:
  - CA con $ 500.000 → Ingreso "Saldo inicial" de $ 500.000 con la fecha de creación.
  - TC con deuda $ 1.200.000 → Gasto "Saldo inicial" de $ 1.200.000.
  - Balance $ 0 → sin Movimiento (CA30, CA31).
  - CA de $ 100.000 → $ 80.000 → Gasto "Ajuste de saldo" de −$ 20.000 con fecha de hoy.
  - Sin cambio de balance → sin Movimiento (CA32).
- [x] 4.3 Agregar `prepareDeletion(of:)` (design.md §4). Pruebas `MovementLedgerTests`:
  - Eliminar la Cuenta destino → la Transferencia queda como Gasto de la Cuenta origen, sin destino y con el mismo balance (CA33).
  - Eliminar la Cuenta origen → queda como Ingreso de la Cuenta destino, con el signo correcto para CA y TC y el mismo balance (CA34).
  - Los Gastos e Ingresos de la Cuenta eliminada desaparecen (Cascade).

## 5. Cuentas usan el ledger

- [x] 5.1 Modificar `AccountFormViewModel.save()` para crear o ajustar el balance a través de `MovementLedger`, con un solo `save()`. Actualizar `AccountFormViewModelTests`:
  - Crear con saldo genera "Saldo inicial".
  - Editar el balance genera "Ajuste de saldo".
  - Editar solo el nombre no genera Movimiento.
  - Si el guardado falla, hace rollback sin dejar la Cuenta ni el Movimiento.
- [x] 5.2 Modificar `AccountCarouselViewModel.confirmDeletion` para usar `prepareDeletion` + `delete` + `save`, con rollback completo. Actualizar `AccountCarouselViewModelTests`:
  - Las Transferencias se convierten.
  - Los balances de las otras Cuentas no cambian.
  - Cancelar no cambia nada.

## 6. Formulario de Movimiento

- [x] 6.1 Crear `MovementField.swift`, `MovementValidator.swift` y `MovementFormRoute.swift`. Pruebas `MovementValidatorTests` (CA10):
  - Valor 0 → "Ingresa un valor mayor a 0".
  - Descripción "" o "   " → "Ingresa una descripción".
  - Sin Cuenta origen → "Selecciona una cuenta".
  - Transferencia sin Cuenta destino → "Selecciona la cuenta destino".
  - Un borrador válido no da errores.
- [x] 6.2 Crear `MovementFormViewModel.swift`: valores por defecto, `originOptions` y `destinationOptions`, `select(kind:)`, `selectOrigin`, truncado a 20 caracteres, `editedFields`, `balanceError` con `replacing` al editar, `hasChanges`, `primaryButtonTitle` y `save()`, que devuelve el ID de la Cuenta origen. Pruebas `MovementFormViewModelTests`:
  - CA2: por defecto Gasto, fecha de hoy, primera Cuenta y sin Cuenta destino (se cambia a la Cuenta enfocada en 8.10).
  - CA3: sin Cuentas, no hay selección y no se puede guardar.
  - CA4: en Transferencia, la Cuenta origen solo ofrece CA y la Cuenta destino excluye la Cuenta origen.
  - CA5: de Gasto con TC a Transferencia, la Cuenta origen pasa a la primera CA y la Cuenta destino a la primera Cuenta distinta.
  - Cambiar la Cuenta origen a la misma que la destino reasigna la destino.
  - CA6: de Transferencia a Gasto se descarta la Cuenta destino.
  - Transferencia sin CA o sin otra Cuenta → no se puede guardar.
  - Un formulario nuevo no muestra errores.
  - CA12: "Crear movimiento" al crear y "Guardar cambios" al editar.
  - CA13: `hasChanges` es verdadero con cambios y falso al revertirlos.
  - CA37: una edición inválida no se puede guardar.
  - Si el guardado falla, muestra el aviso correcto al crear y al editar, y no cambia ningún balance.
- [x] 6.3 Crear `MovementFormView.swift` (design.md §8):
  - Segmentado Gasto / Ingreso / Transferencia.
  - `CurrencyField` coloreado por tipo.
  - Descripción y `DatePicker(in: ...Date.now)`.
  - Pickers de Cuenta con "No hay cuentas disponibles".
  - Errores debajo de cada campo.
  - Toolbar con "Regresar" y el botón principal, diálogo "Descartar cambios" / "Seguir editando" y `.toolbar(.hidden, for: .tabBar)`.

  Agregar `#Preview` "Crear", "Editar" y "Sin cuentas". Verificar en el preview:
  - CA11: no se puede escribir un signo.
  - CA35: no se pueden elegir fechas futuras.
  - RF13: el valor es rojo, verde o neutro según el tipo.

## 7. Barra de navegación sin "+"

- [x] 7.1 Revertir el `Tab` "+" de la barra (design.md §5):
  - Quitar `.newMovement` de `AppTab`.
  - En `ContentView`, quitar el `Tab` "+", el `Binding` que intercepta la selección y `@State movementFormRoute`. `HomeView` deja de recibirlo como `Binding`.
  - Actualizar el `#Preview`.

  Verificar en el simulador:
  - CA1: la barra muestra solo Inicio y Configuración, como en main.
  - Cambiar de sección sigue funcionando y conserva la navegación de Configuración.

## 8. Inicio: foco del carrusel y lista de Movimientos

- [x] 8.1 Modificar `AccountCarouselView` (design.md §6):
  - Recibir `Binding<UUID?>` del foco y usar `.scrollPosition(id:)`, con `nil` para la tarjeta "+".
  - Fijar la altura del carrusel con la proporción 1,586 sobre el ancho de la tarjeta (85 %).
  - En `AccountCardView` y `AddAccountCardView`, usar la proporción como tamaño exacto y adaptar el contenido en lugar de estirar la tarjeta.

  Actualizar sus `#Preview`. Verificar en el preview que deslizar cambia el foco, que la tarjeta "+" da `nil` y que la tarjeta conserva su proporción con texto dinámico grande.
- [x] 8.2 Crear `MovementRowContent.swift` (design.md §7). Pruebas `MovementRowContentTests`:
  - CA26: Gasto en CA → rojo "-$ 10.000,00". Gasto en TC → rojo "$ 10.000,00". Ingreso en CA → verde "$ 10.000,00".
  - CA27: una Transferencia es roja en la Cuenta origen y verde en la destino.
  - La etiqueta de accesibilidad dice "Gasto, Compra de café, 30 de septiembre de 2026, menos 10.000 pesos".
- [x] 8.3 Crear `MovementListViewModel.swift`: Movimiento pendiente de eliminar, `confirmDeletion` con ledger + save + rollback, aviso de bloqueo con justificación, aviso de falla y cancelar. Pruebas `MovementListViewModelTests`:
  - CA21: eliminar un Gasto de −$ 10.000 sube el saldo $ 10.000.
  - CA36: eliminación bloqueada con el texto exacto.
  - Cancelar no cambia nada.
  - Si el guardado falla, muestra "No se pudo eliminar el movimiento. Intenta de nuevo." y hace rollback.
- [x] 8.4 Crear `MovementRowView.swift` (ícono, fecha, valor con color y descripción en una línea, elemento de accesibilidad único) y `MovementDetailView.swift` (todos los campos, sin acciones), cada uno con `#Preview` en modo claro y oscuro y con texto dinámico grande. Verificar en el preview que el contenido no se superpone.
- [x] 8.5 Crear `MovementListView.swift`:
  - `@FetchRequest` por Cuenta con `sortDescriptors` `date` desc y `createdAt` desc.
  - Encabezado `HStack`: título "Movimientos" y botón "+" (`plus.circle.fill`) pegado a la derecha, con etiqueta de accesibilidad "Agregar movimiento" y cierre `onCreate`.
  - Área de altura fija `rowHeight * 6`, tanto con filas como con "Sin movimientos" (centrado).
  - `swipeActions` en los dos bordes con `allowsFullSwipe` (izquierda roja sin `.destructive`, derecha azul).
  - `contextMenu` con vista previa del detalle.
  - `confirmationDialog` y avisos.

  Agregar `#Preview` con 10 Movimientos y otro sin Movimientos. Verificar si `contextMenu` sin ítems muestra la vista previa; si no, aplicar el fallback de design.md (Riesgos).
- [x] 8.6 Modificar `HomeView`:
  - Quitar el `ScrollView` externo.
  - Agregar el `VStack` con el carrusel de altura fija y la sección "Movimientos" de altura fija (6 filas, `@ScaledMetric`).
  - Ocultar la sección, y con ella el "+", cuando el foco es `nil`.
  - `@State movementFormRoute`: el "+" de la sección abre `.create(originAccountID: focusedAccountID)`.
  - Agregar `navigationDestination` para `movementFormRoute`, con `onSaved` que enfoca la Cuenta origen.
  - Editar desde el deslizamiento abre `.edit`.

  Actualizar el `#Preview`. Verificar en el simulador CA15, CA17, CA18, CA19, CA20, CA22, CA24 y CA25, que no hay conflicto de scroll entre el carrusel y la lista, y que el carrusel y la sección no cambian de altura al pasar entre Cuentas con 0, 2 y 10 Movimientos. Revisar con texto de accesibilidad grande que el Inicio cabe en pantalla (design.md, Riesgos).
- [x] 8.7 Agregar Movimientos de ejemplo a `PersistenceController.preview` usando `MovementLedger`: un Gasto, un Ingreso y una Transferencia entre las Cuentas de ejemplo. Verificar que los `#Preview` de Inicio y de la lista los muestran con balances cuadrados.
- [x] 8.8 Cambiar el orden de la lista (design.md §6): eliminar `MovementOrdering.swift` y `MovementOrderingTests.swift` y ordenar en el `@FetchRequest` de `MovementListView`. Verificar en el preview:
  - El Movimiento de fecha más reciente va arriba.
  - A igual fecha, el creado más recientemente va arriba, sin importar su valor.
- [x] 8.9 Cambiar los íconos de la fila (design.md §7): mover el cálculo a `MovementRowContent.systemImage` según el valor con signo en la Cuenta vista y quitar `MovementKind.systemImage`. Actualizar `MovementKindTests` (solo nombre) y `MovementRowContentTests`:
  - Ingreso en CA → `arrow.up.right.circle.fill`; Gasto en CA → `arrow.down.right.circle.fill`.
  - Gasto en TC → `arrow.up.right.circle.fill`; Ingreso en TC → `arrow.down.right.circle.fill`.
  - Transferencia en origen y en destino → `arrow.left.arrow.right.circle.fill`.
- [x] 8.10 Cuenta origen por defecto = Cuenta enfocada: cambiar `MovementFormRoute.create` a `.create(originAccountID:)` y usarla en `MovementFormViewModel`. Actualizar `MovementFormViewModelTests`:
  - CA2: con "Nómina" y "Visa", abrir desde "Visa" deja "Visa" como Cuenta.
  - CA5 sigue pasando: de Gasto con TC a Transferencia, la Cuenta origen pasa a la primera CA.
- [x] 8.11 Colores del detalle (design.md §7): `MovementDetailView` recibe la Cuenta enfocada (`perspective`) desde `MovementListView` y construye su `MovementRowContent` con ella en lugar de la Cuenta origen. Actualizar sus `#Preview`. Verificar en el simulador que el detalle coincide con su fila:
  - Transferencia de Cuenta de Ahorros a Tarjeta de Crédito vista desde la Cuenta de Ahorros → rojo "-$ 10.000,00".
  - La misma vista desde la Tarjeta de Crédito → verde "-$ 10.000,00".
  - Transferencia entre dos Cuentas de Ahorros vista desde la destino → verde "$ 20.000,00".

## 9. Configuración: Tipos de movimiento

- [x] 9.1 Crear `Features/Settings/Views/MovementTypeListView.swift` (`@FetchRequest` por nombre, solo lectura, título "Tipos de movimiento") con `#Preview`. Agregar su `NavigationLink` debajo de "Tipos de cuenta" en `MasterDataView` y actualizar su `#Preview`. Verificar:
  - CA28: se ven exactamente Gasto, Ingreso y Transferencia, en ese orden y sin acciones.
  - CA14: la barra sigue visible en esa pantalla.

## 10. Verificación integral

- [x] 10.1 Correr todas las pruebas (⌘U) y verificar que pasan en verde (repetir tras 8.8–8.10).
- [x] 10.2 Recorrer en el simulador CA1–CA37 en modo claro y oscuro, con VoiceOver (filas, acciones de deslizar y "+" de la sección Movimientos) y con tamaño de texto de accesibilidad grande. Anotar cualquier desviación.
- [x] 10.3 Borrar la app del simulador, reinstalarla, y verificar que se crean los 3 Tipos de movimiento, que no hay Cuentas y que al abrir la app varias veces siguen siendo 3 (CA29).
