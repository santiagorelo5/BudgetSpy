# Tasks: add-accounts

## 1. Preparación del proyecto (interfaz de Xcode)

- [x] 1.1 Mover `Persistence.swift` y `BudgetSpy.xcdatamodeld` a `BudgetSpy/BudgetSpy/Core/Persistence/` desde el navegador de Xcode; verificar que el proyecto compila (⌘B) y la app abre en el simulador
- [x] 1.2 Crear el target `BudgetSpyTests` (Unit Testing Bundle, Swift Testing, target a probar: BudgetSpy) usando la carpeta existente `BudgetSpy/BudgetSpyTests/`; verificar que una prueba vacía con `@testable import BudgetSpy` corre con ⌘U
- [x] 1.3 Inyectar `.environment(\.managedObjectContext, …viewContext)` en `App/BudgetSpyApp.swift`; verificar que compila y el `#Preview` de `ContentView` sigue funcionando

## 2. Modelo de Core Data

- [x] 2.1 Agregar la versión `BudgetSpy 2` del modelo (Editor → Add Model Version) y marcarla como actual; verificar en el inspector que es la versión activa
- [x] 2.2 En `BudgetSpy 2`, eliminar `Item` y crear `AccountType` y `Account` con los atributos, opcionalidad, relaciones y reglas de borrado de design.md §1 (codegen Class Definition); verificar que compila y que la app abre sobre un store de la versión anterior sin error de migración
- [x] 2.3 Crear `Features/Accounts/Models/AccountKind.swift` (`displayName`, `balanceTitle`, `requiresCreditLimit`) y `Account+Display.swift` (`AccountType.kind`, `Account.balanceValue`, `Account.creditLimitValue`); pruebas `AccountKindTests`: CA → "Cuenta de Ahorros"/"Saldo disponible"/sin límite, TC → "Tarjeta de Crédito"/"Deuda a la fecha"/con límite

## 3. Tipos de cuenta semilla

- [x] 3.1 Crear `Core/Persistence/AccountTypeSeeder.swift` (verifica por abreviación, inserta solo los faltantes, guarda solo si insertó) y llamarlo en `PersistenceController.init`; limpiar los comentarios de plantilla y registrar fallos con `Logger`
- [x] 3.2 Pruebas `AccountTypeSeederTests` con contenedor en memoria: primera siembra crea exactamente CA y TC; sembrar 3 veces sigue dejando 2; con solo CA existente, crea solo TC; verificar con ⌘U
- [x] 3.3 Ampliar `PersistenceController.preview` con 2 Cuentas de ejemplo (una CA y una TC); verificar que se ven en los `#Preview` de las tareas siguientes

## 4. Utilidades de moneda

- [x] 4.1 Crear `Core/Shared/Formatters/CurrencyFormatter.swift`; pruebas `CurrencyFormatterTests`: `0` → `$ 0,00`, `1000` → `$ 1.000,00`, `1250000` → `$ 1.250.000,00`, `-1000` → `$ -1.000,00`
- [x] 4.2 Crear `Core/Shared/Formatters/CurrencyParser.swift`; pruebas `CurrencyParserTests`: `""` → 0, `"125000"` → 1250.00, `"$ 1.250,0"` → 125.00 (borrado), `"-5"` → 0.05 (ignora signo), más de 13 dígitos se trunca
- [x] 4.3 Crear `Core/Shared/Components/CurrencyField.swift` (`TextField` con `.numberPad` y `Binding` formateado) con `#Preview`; verificar en el preview que digitar 1,2,5,0,0,0 muestra `$ 1.250,00` y borrar 6 veces vuelve a `$ 0,00`

## 5. Borrador y validación de Cuenta

- [x] 5.1 Crear `AccountDraft.swift`, `AccountField.swift` (con `AccountValidationError` y sus mensajes en español del spec) y `AccountValidator.swift`
- [x] 5.2 Pruebas `AccountValidatorTests` con los ejemplos del pedido: "Nómina Bancolombia" válido, `""` y `"   "` inválidos; "4821" válido, "482" y "48A1" inválidos; balance 0 y 1.250.000 válidos, -1 inválido; TC con límite 5.000.000/deuda 1.200.000 válido, 1.000.000/1.200.000 inválido, límite 0 inválido; CA ignora el límite; verificar con ⌘U

## 6. Tarjeta gráfica

- [x] 6.1 Crear `AccountCardContent.swift` (desde `Account` y desde `AccountDraft`, con nombre de ejemplo y relleno `-` en dígitos) y pruebas `AccountCardContentTests` (nombre vacío → ejemplo, "48" → "**** 48--", etiqueta de accesibilidad con tipo, nombre, "terminada en" y balance)
- [x] 6.2 Crear `Features/Accounts/Views/AccountCardView.swift` según design.md §9 (fondo oscuro por tipo —CA azul marino, TC grafito— con sombreado hacia la derecha, ícono del tipo `banknote`/`creditcard`, ícono sin contacto `wave.3.right` decorativos, rótulo `balanceTitle` sobre el balance) con `#Preview` de CA, TC y vacía en modo claro y oscuro; verificar legibilidad en ambos modos y con texto dinámico de accesibilidad, y que VoiceOver no lee los íconos
- [x] 6.3 Crear `Features/Accounts/Views/AddAccountCardView.swift` con `#Preview`; verificar que VoiceOver (Accessibility Inspector) lee "Agregar cuenta, botón"

## 7. Formulario de Cuenta

- [x] 7.1 Crear `AccountFormRoute.swift` y `ViewModels/AccountFormViewModel.swift` según design.md §6 (draft/initialDraft, `editedFields`, `select(kind:)`, saneo de nombre y dígitos, `canSave`, `hasChanges`, `primaryButtonTitle`, `save()` con rollback y aviso)
- [x] 7.2 Pruebas `AccountFormViewModelTests` (contenedor en memoria): crear arranca en CA con botón deshabilitado y sin errores visibles; `select(.creditCard)` y volver a `.savings` deja límite en 0; `hasChanges` falso al abrir y al revertir a valores iniciales; nombre truncado a 20 y dígitos a 4 numéricos; `save()` crea CA sin límite y TC con límite y `createdAt`; en edición el tipo está bloqueado, el título es "Guardar cambios" y `save()` actualiza la misma Cuenta; verificar con ⌘U
- [x] 7.3 Crear `Views/AccountFormView.swift` (secciones de design.md §8, errores debajo de cada campo, botón principal en `.confirmationAction`, botón regresar en `.cancellationAction`, `.navigationBarBackButtonHidden(true)`, `.toolbar(.hidden, for: .tabBar)`, diálogo "¿Descartar los cambios?", alerta de error de guardado) con `#Preview` de crear y de editar; verificar en el preview que la tarjeta se actualiza al escribir y que el campo límite aparece solo con Tarjeta de Crédito

## 8. Carrusel en Inicio

- [x] 8.1 Crear `ViewModels/AccountCarouselViewModel.swift` (solicitar, confirmar y cancelar eliminación; aviso de error) y pruebas `AccountCarouselViewModelTests`: confirmar borra la Cuenta y no borra su Tipo de cuenta; cancelar no borra nada; verificar con ⌘U
- [x] 8.2 Crear `Views/AccountCarouselView.swift` (`@FetchRequest` por `createdAt`, scroll horizontal con `.viewAligned`, tarjeta "+" al final, `contextMenu` Editar/Eliminar sin gesto de toque, `confirmationDialog` de eliminar) con `#Preview` con Cuentas y sin Cuentas
- [x] 8.3 Modificar `Features/Home/Views/HomeView.swift` para mostrar el carrusel arriba (sin título) y abrir el formulario con `.navigationDestination(item:)`; actualizar su `#Preview` con el contexto de preview

## 9. Configuración → Datos Maestros → Tipos de cuenta

- [x] 9.1 Crear `Features/Settings/Views/AccountTypeListView.swift` (`@FetchRequest` por nombre, `LabeledContent(nombre, abreviación)`, sin acciones) con `#Preview`; verificar que muestra "Cuenta de Ahorros CA" y "Tarjeta de Crédito TC" en ese orden
- [x] 9.2 Crear `Features/Settings/Views/MasterDataView.swift` (lista con "Tipos de cuenta") con `#Preview`
- [x] 9.3 Modificar `Features/Settings/Views/SettingsView.swift` para mostrar la lista con "Datos Maestros"; actualizar su `#Preview`; verificar la navegación Configuración → Datos Maestros → Tipos de cuenta en el preview de `ContentView`

## 10. Verificación integral en simulador

- [x] 10.1 Recorrer CA1–CA17 en el simulador (crear CA y TC, validaciones, descartar cambios, editar, eliminar confirmando y cancelando, toque sencillo sin efecto, carrusel vacío solo con "+") y anotar cualquier desviación
- [x] 10.2 Verificar CA10–CA11: la barra de navegación se oculta en el formulario (crear y editar), reaparece al volver, y siempre se ve en Configuración, Datos Maestros y Tipos de cuenta
- [x] 10.3 Verificar CA18–CA19: cerrar y abrir la app 3 veces y comprobar que Tipos de cuenta sigue mostrando exactamente 2 ítems sin opciones de edición
- [x] 10.4 Verificar CA20: modo claro/oscuro en tarjetas y formulario, "Reducir transparencia", texto dinámico grande y VoiceOver leyendo tipo, nombre, últimos 4 dígitos y balance de cada tarjeta
- [x] 10.5 Correr toda la suite (⌘U) y `openspec validate add-accounts --strict`; ambos deben pasar
