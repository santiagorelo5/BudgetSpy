# Tasks

## 1. Preparación

- [ ] 1.1 Borrar la app BudgetSpy del simulador de desarrollo y verificar que ya no aparece en la pantalla de inicio del simulador.
- [ ] 1.2 Crear en Xcode el target `BudgetSpyTests`: File → New → Target → Unit Testing Bundle, framework Swift Testing, en la carpeta `BudgetSpy/BudgetSpyTests/`. No editar el `.pbxproj` a mano. Verificar que ⌘U compila y ejecuta la prueba de ejemplo en verde.

## 2. Persistencia y datos semilla

- [ ] 2.1 Mover `BudgetSpy/BudgetSpy/Persistence.swift` y `BudgetSpy/BudgetSpy/BudgetSpy.xcdatamodeld` a `BudgetSpy/BudgetSpy/Core/Persistence/`. Verificar que el proyecto compila sin referencias rotas.
- [ ] 2.2 En el editor de modelos de Xcode, eliminar `Item` y crear `AccountType` y `Account`. Atributos, opcionalidad, relaciones inversas, reglas de borrado (Deny/Nullify) y la restricción única en `abbreviation` según design §1, con codegen `Class Definition`. Verificar que compila y que las clases `Account` y `AccountType` se generan.
- [ ] 2.3 Crear `Core/Persistence/AccountTypeSeeder.swift` con `AccountTypeCode` y `seedIfNeeded(in:)`. Llamarlo en `PersistenceController.init` tras cargar los stores. Verificar con `AccountTypeSeederTests`:
  - un contexto vacío queda con CA y TC;
  - sembrar dos veces deja exactamente 2;
  - si solo existe CA, se crea solo TC.
- [ ] 2.4 Agregar a `PersistenceController.preview` una Cuenta de Ahorros y una Tarjeta de Crédito de ejemplo. Inyectar `managedObjectContext` en `App/BudgetSpyApp.swift` y en el `#Preview` de `App/ContentView.swift`. Verificar que la app arranca en el simulador sin errores de Core Data.

## 3. Importes monetarios (Core/Shared)

- [ ] 3.1 Crear `Core/Shared/CurrencyFormatter.swift`. Verificar con `CurrencyFormatterTests` que 0 → `$ 0,00`, 1000 → `$ 1.000,00`, -1000 → `$ -1.000,00` y 1234567,5 → `$ 1.234.567,50`.
- [ ] 3.2 Crear `Core/Shared/CurrencyParser.swift`. Verificar con `CurrencyParserTests`:
  - dígitos "12500" → 125,00;
  - "" → 0;
  - extraer dígitos de `$ -1.2a5,0` → "1250";
  - se ignoran los dígitos después del límite de 15.
- [ ] 3.3 Crear `Core/Shared/Views/CurrencyField.swift` con su `#Preview`. Verificar en el preview los escenarios de la spec: escribir 1,2,5,0,0 muestra `$ 125,00`; borrar vuelve dígito a dígito hasta `$ 0,00`; "-" y letras no cambian el valor.

## 4. Dominio y datos de Cuentas

- [ ] 4.1 Crear en `Features/Accounts/Models/`:
  - `AccountDraft.swift`
  - `AccountFormMode.swift`
  - `Account+Convenience.swift`

  Verificar que compila y que `AccountDraft()` por defecto tiene tipo `.savings` e importes en 0.
- [ ] 4.2 Crear `Features/Accounts/Models/AccountValidator.swift`. Verificar con `AccountValidatorTests` todos los casos de la spec:
  - nombre vacío o con solo espacios;
  - nombre de más de 30 caracteres;
  - dígitos incompletos;
  - límite < deuda (inválido);
  - límite = deuda (válido);
  - TC en 0/0 (válido);
  - Ahorros en 0 (válido).
- [ ] 4.3 Crear `Features/Accounts/Models/AccountRepository.swift` (protocolo y `CoreDataAccountRepository`). Verificar con `AccountRepositoryTests` en memoria:
  - crear guarda todos los campos y `createdAt`;
  - crear Ahorros con límite guarda `creditLimit == nil`;
  - `update` no cambia el Tipo de cuenta aunque el borrador traiga otro `typeCode`;
  - eliminar quita la Cuenta;
  - `accountTypes()` devuelve CA y TC.
- [ ] 4.4 Crear `Features/Accounts/Models/AccountCardModel.swift`, con inicializadores desde `AccountDraft` y desde `Account`. Verificar con pruebas:
  - `maskedNumber` devuelve `**** 1234` y `**** ••••`;
  - `balanceLabel` devuelve "Saldo disponible" o "Deuda a la fecha" según el tipo;
  - aparece el texto de ejemplo con nombre vacío.

## 5. Tarjeta gráfica

- [ ] 5.1 Crear `Features/Accounts/Views/AccountCardView.swift` según design §5. Incluir `#Preview` de Ahorros, Tarjeta de Crédito, estado vacío y `.dynamicTypeSize(.accessibility3)`. Verificar en los previews, en modo claro y oscuro, que los textos no se cortan y que la etiqueta de VoiceOver sigue la spec.
- [ ] 5.2 Crear `Features/Accounts/Views/AddAccountCardView.swift` con `#Preview`. Verificar que muestra el "+" y se anuncia como botón "Agregar cuenta".

## 6. Formulario de Cuenta

- [ ] 6.1 Crear `Features/Accounts/ViewModels/AccountFormViewModel.swift`. Verificar con `AccountFormViewModelTests` (repositorio en memoria):
  - modo crear arranca con `.savings`, `showsCreditLimit == false`, `balanceLabel == "Saldo en la cuenta"` y `saveButtonTitle == "Crear cuenta"`;
  - en modo crear, `canChangeType == true`, y cambiar a `.creditCard` da "Deuda a la fecha" y muestra el límite;
  - modo editar carga los datos, con `saveButtonTitle == "Guardar cambios"` y `canChangeType == false`;
  - `hasChanges` es falso al abrir y verdadero tras editar;
  - `canSave` es falso con datos inválidos;
  - `save()` crea o actualiza en el repositorio;
  - si el repositorio lanza un error, `save()` lo propaga y el borrador no cambia.
- [ ] 6.2 Crear `Features/Accounts/Views/AccountFormView.swift` según design §7 y §8:
  - tarjeta en vivo;
  - `Picker` segmentado solo al crear; al editar, `LabeledContent` de solo lectura con el Tipo de cuenta;
  - campo de dígitos filtrado (solo dígitos, máximo 4);
  - `CurrencyField`;
  - límite condicional;
  - errores en los footers;
  - botón principal deshabilitado con `!canSave`;
  - botón de regresar con confirmación solo si hay cambios;
  - alerta de error al guardar;
  - `.toolbar(.hidden, for: .tabBar)`.

  Incluir `#Preview` de crear y editar. Verificar en los previews que escribir el nombre y los dígitos se refleja en la tarjeta, y que "12a345" queda "1234".

## 7. Inicio: carrusel de Cuentas

- [ ] 7.1 Crear `Features/Accounts/ViewModels/AccountCarouselViewModel.swift`. Verificar con `AccountCarouselViewModelTests`:
  - `requestDeletion` fija la Cuenta pendiente;
  - `cancelDeletion` la limpia sin borrar;
  - `confirmDeletion` elimina la Cuenta en el repositorio y limpia el estado.
- [ ] 7.2 Crear `Features/Accounts/Views/AccountCarouselView.swift` según design §6:
  - `@FetchRequest` por `createdAt` ascendente;
  - tarjeta "+" al final;
  - `contextMenu` Editar/Eliminar solo en Cuentas;
  - sin acción de toque sencillo;
  - `confirmationDialog` para eliminar.

  Incluir `#Preview` con datos y sin Cuentas. Verificar que sin Cuentas solo se ve "+".
- [ ] 7.3 Modificar `Features/Home/Views/HomeView.swift`: el carrusel va arriba, con `@State formMode` y `.navigationDestination(item:)` hacia `AccountFormView` (la tarjeta "+" asigna `.create` y "Editar" asigna `.edit`). Actualizar su `#Preview` con el contexto de preview. Verificar en el preview que se ven las 2 Cuentas de ejemplo y "+".

## 8. Configuración: Datos Maestros

- [ ] 8.1 Crear `Features/Settings/Views/AccountTypeListView.swift` (`@FetchRequest` ordenado por `name`, `LabeledContent`, `ContentUnavailableView` si está vacío) y `Features/Settings/Views/MasterDataView.swift`, cada una con su `#Preview`. Verificar en los previews que aparecen "Cuenta de Ahorros – CA" y "Tarjeta de Crédito – TC", y el estado vacío con un contexto sin datos.
- [ ] 8.2 Modificar `Features/Settings/Views/SettingsView.swift` a `List` con el único ítem "Datos Maestros" y actualizar su `#Preview`. Verificar que no hay acciones de crear, editar o eliminar en ninguna de las tres pantallas.

## 9. Verificación de integración en simulador

- [ ] 9.1 Primer arranque:
  - Inicio muestra solo "+" y Configuración → Datos Maestros → Tipos de cuenta muestra CA y TC.
  - Tras cerrar y reabrir la app, siguen siendo exactamente 2 Tipos de cuenta.
- [ ] 9.2 CA1, CA2, CA4, CA6 y RF6:
  - Crear una Cuenta de Ahorros con saldo $ 0,00. El formulario abre en Ahorros, el límite está oculto y la etiqueta es "Saldo en la cuenta".
  - Al crear, vuelve a Inicio y la tarjeta muestra "Cuenta de Ahorros", el nombre, `**** dddd` y "Saldo disponible".
- [ ] 9.3 CA3, CA4, CA5 y CA8:
  - Crear una Tarjeta de Crédito: con límite < deuda el botón está deshabilitado; con límite = deuda se puede crear.
  - La tarjeta muestra "Deuda a la fecha" en positivo.
- [ ] 9.4 CA7: con 3 o más Cuentas, deslizar horizontalmente para verlas todas en orden de creación, terminando en "+". Un toque sencillo sobre una Cuenta no hace nada.
- [ ] 9.5 RF3: mantener presionada una Cuenta y verificar:
  - "Editar" abre el formulario con sus datos y con el Tipo de cuenta visible pero sin forma de cambiarlo; cambiar el nombre y guardar actualiza la tarjeta en Inicio.
  - "Eliminar" → Cancelar la conserva; "Eliminar" → confirmar la quita.
  - Mantener presionada "+" no muestra el menú.
- [ ] 9.6 RF1: en el formulario, la barra inferior está oculta.
  - Regresar sin cambios vuelve directo a Inicio.
  - Con cambios, pregunta: "Seguir editando" conserva los datos y "Descartar cambios" vuelve a Inicio sin guardar.
  - Deslizar desde el borde no cierra el formulario.
- [ ] 9.7 Accesibilidad:
  - VoiceOver anuncia cada tarjeta según la spec y ofrece las acciones Editar/Eliminar; "+" se anuncia como "Agregar cuenta".
  - Con tamaño de texto de accesibilidad grande y en modo claro/oscuro, las tarjetas y el formulario se leen completos.
- [ ] 9.8 Ejecutar ⌘U y verificar que toda la suite de `BudgetSpyTests` pasa. Ejecutar `openspec validate add-accounts --strict` y verificar que no reporta errores.
