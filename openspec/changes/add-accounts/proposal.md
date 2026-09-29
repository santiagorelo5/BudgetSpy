# Propuesta: add-accounts

## Why

BudgetSpy ya tiene su estructura de navegación (change `add-app-shell`), pero las pantallas Inicio y Configuración están vacías y la app no guarda ningún dato. Para registrar transacciones más adelante, el usuario primero necesita tener sus Cuentas en la app. Este change le permite crearlas, editarlas y eliminarlas (HU1). También agrega los Tipos de cuenta que las clasifican.

## What Changes

- **Persistencia de datos (primera vez)**: se agregan al modelo de Core Data las entidades Cuenta y Tipo de cuenta. Se elimina la entidad de plantilla `Item`, que no se usa.
- **Datos semilla**: al abrir la app se crean, si no existen, 2 Tipos de cuenta no editables: "Cuenta de Ahorros" (CA) y "Tarjeta de Crédito" (TC).
- **Formulario de Cuenta** (crear y editar):
  - Arriba muestra una tarjeta gráfica que refleja en vivo lo que el usuario escribe.
  - Abajo están los campos: tipo de cuenta, nombre, últimos 4 dígitos, balance y límite.
  - El límite solo se muestra para Tarjeta de Crédito.
  - Al editar, el Tipo de cuenta se muestra en solo lectura y no se puede cambiar.
  - El balance se llama "Saldo en la cuenta" en Cuenta de Ahorros y "Deuda a la fecha" en Tarjeta de Crédito.
  - Tiene un botón "Crear cuenta" o "Guardar cambios", y un botón para regresar que pide confirmación antes de perder cambios.
- **Inicio**: arriba hay un carrusel horizontal de Cuentas con diseño de tarjeta de crédito. Al final siempre aparece una tarjeta "+" que abre el formulario.
  - Mantener presionada una tarjeta abre un menú con "Editar" y "Eliminar". Eliminar pide confirmación.
  - Un toque sencillo no hace nada.
  - **Esto modifica** el requisito de `add-app-shell` que pedía que Inicio estuviera vacío.
- **Configuración**: muestra una lista con "Datos Maestros". Dentro está "Tipos de cuenta", que muestra los 2 Tipos de cuenta en modo solo lectura.
  - **Esto modifica** el requisito de `add-app-shell` que pedía que Configuración estuviera vacía.
- **Entrada de importes**: se crea un campo monetario reutilizable que sigue los principios del proyecto: empieza en 0,00, los dígitos entran por la derecha y no se puede escribir el signo. También se crean `CurrencyFormatter`/`CurrencyParser` para mostrar importes como `$ 1.000,00`.

### Decisiones de negocio

| Fecha | Decisión |
|---|---|
| 2026-09-29 | Una Cuenta guarda: nombre (obligatorio), últimos 4 dígitos de la tarjeta (obligatorio, exactamente 4 dígitos numéricos), balance (obligatorio, ≥ 0), límite (obligatorio en Tarjeta de Crédito, vacío en Cuenta de Ahorros) y Tipo de cuenta (obligatorio). |
| 2026-09-29 | Un Tipo de cuenta guarda: tipo (nombre, obligatorio) y abreviación de 2 letras. |
| 2026-09-29 | Existen 2 Tipos de cuenta semilla, no editables: "Cuenta de Ahorros" (CA) y "Tarjeta de Crédito" (TC). |
| 2026-09-29 | El formulario abre por defecto con el Tipo de cuenta "Cuenta de Ahorros". |
| 2026-09-29 | En Cuenta de Ahorros, el balance se pide como "Saldo en la cuenta". En Tarjeta de Crédito se pide como "Deuda a la fecha" y siempre se guarda en positivo. |
| 2026-09-29 | En Tarjeta de Crédito, el límite debe ser ≥ 0 y ≥ al balance (deuda). Se aceptan balance y límite en 0. |
| 2026-09-29 | En Cuenta de Ahorros, el campo límite se oculta y el límite siempre se guarda vacío. |
| 2026-09-29 | La tarjeta gráfica muestra: nombre completo del Tipo de cuenta, nombre de la Cuenta, `**** ` + últimos 4 dígitos, y "Saldo disponible" (Ahorros) o "Deuda a la fecha" (Tarjeta de Crédito, siempre positiva). |
| 2026-09-29 | Al crear o guardar una Cuenta, el usuario vuelve a Inicio y ve los datos actualizados. |
| 2026-09-29 | Eliminar una Cuenta siempre pide confirmación. Un toque sencillo sobre una tarjeta no hace nada por ahora. |
| 2026-09-29 | *(Supuesto)* El botón de regresar del formulario solo pide confirmación si hay cambios sin guardar. Si no hay cambios, regresa directo a Inicio. |
| 2026-09-29 | *(Supuesto)* Mientras el formulario está abierto, la barra de navegación inferior se oculta para que no se pueda salir sin confirmar. La barra en sí no se modifica. |
| 2026-09-29 | Al editar una Cuenta, el Tipo de cuenta se muestra pero no se puede cambiar. Si el usuario se equivocó de tipo, debe crear otra Cuenta (y eliminar la incorrecta). |
| 2026-09-29 | *(Supuesto)* El nombre de la Cuenta tiene máximo 30 caracteres para que quepa en la tarjeta. No se exige que sea único. |
| 2026-09-29 | *(Supuesto)* Las tarjetas de Inicio se ordenan por fecha de creación, de la más antigua a la más reciente. |
| 2026-09-29 | *(Supuesto)* Sin Cuentas, Inicio muestra solo la tarjeta "+". |

### Fuera de alcance

- En Inicio: cualquier cosa distinta del carrusel de tarjetas. No hay saldo total, transacciones ni resúmenes, y el toque sencillo sobre una tarjeta no tiene acción.
- En Configuración: cualquier cosa distinta de Datos Maestros → Tipos de cuenta.
- Crear, editar o eliminar Tipos de cuenta. Los Datos Maestros solo se consultan.
- Transacciones y su relación con las Cuentas (y, por tanto, qué pasa al eliminar una Cuenta con transacciones).
- Modificar la barra de navegación inferior.
- Cambios de configuración del target (familia de dispositivos, orientación), que siguen pendientes de `add-app-shell`.

## Capabilities

### New Capabilities
- `accounts`: gestión de Cuentas. Cubre el modelo y las reglas de validación, el formulario de crear/editar con tarjeta gráfica en vivo, el carrusel de tarjetas en Inicio, el menú contextual Editar/Eliminar y la entrada de importes monetarios.
- `account-types`: Tipos de cuenta. Cubre los datos semilla no editables (CA, TC) y su consulta en Configuración → Datos Maestros → Tipos de cuenta.

### Modified Capabilities
- `app-navigation`: el requisito "Pantallas principales vacías con título" se reemplaza por "Contenido de las pantallas principales". Inicio pasa a mostrar el carrusel de Cuentas y Configuración pasa a mostrar la lista de Datos Maestros.

## Impact

- **Código nuevo** en `BudgetSpy/BudgetSpy/Features/Accounts/`, `Features/Settings/`, `Core/Shared/` y `Core/Persistence/`.
- **Código modificado**:
  - `Features/Home/Views/HomeView.swift` y `Features/Settings/Views/SettingsView.swift`.
  - `App/BudgetSpyApp.swift`, que inyecta el contexto de Core Data.
  - `Persistence.swift` y `BudgetSpy.xcdatamodeld`, que se mueven a `Core/Persistence/`, como ya estaba previsto.
- **Modelo de Core Data**: 2 entidades nuevas y se elimina `Item`. La migración se explica en design.md.
- **Pruebas**: se agrega un target de pruebas con Swift Testing (hoy no existe).
- **Dependencias**: ninguna nueva.
