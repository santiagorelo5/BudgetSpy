# Proposal: add-accounts

## Why

Hoy BudgetSpy solo tiene la estructura de navegación (change `add-app-shell`): Inicio y Configuración están vacías y el usuario no puede registrar dónde tiene su dinero. Las Cuentas son la base de todo lo que viene después (Transacciones, informes), así que el usuario primero necesita crear, ver, editar y eliminar sus Cuentas, y consultar los Tipos de cuenta disponibles.

## What Changes

- Se agrega la gestión de Cuentas: crear, ver, editar y eliminar.
- Inicio muestra en la parte superior un carrusel horizontal de tarjetas gráficas (una por Cuenta, ordenadas por fecha de creación) y al final siempre una tarjeta "+" que abre el formulario para crear una Cuenta.
- Al mantener presionada una tarjeta aparece un menú con "Editar" y "Eliminar" (con confirmación obligatoria). El toque sencillo no hace nada por ahora.
- Nuevo formulario de Cuenta (crear/editar) con una tarjeta gráfica que refleja en vivo lo que el usuario escribe; los textos del balance y la visibilidad del límite dependen del Tipo de cuenta; validaciones con error debajo del campo; botón principal arriba a la derecha y botón para regresar arriba a la izquierda que pregunta antes de descartar cambios.
- La barra de navegación inferior se oculta mientras el formulario de Cuenta está abierto y reaparece al salir.
- Configuración muestra una lista con "Datos Maestros" → "Tipos de cuenta", donde se consultan (solo lectura) los 2 Tipos de cuenta.
- Se crean los Tipos de cuenta semilla "Cuenta de Ahorros" (CA) y "Tarjeta de Crédito" (TC) una sola vez, sin duplicarlos.
- **BREAKING (spec)**: se reemplaza el requisito "Pantallas principales vacías" de `app-navigation`, porque Inicio y Configuración dejan de estar vacías.

## Decisiones de negocio

| Fecha | Decisión |
|---|---|
| 2026-09-29 | Una Cuenta tiene nombre (obligatorio, máx. 20 caracteres, puede repetirse), últimos 4 dígitos de la tarjeta (exactamente 4 caracteres numéricos), balance (≥ 0), límite (solo Tarjeta de Crédito) y Tipo de cuenta (obligatorio, por defecto Cuenta de Ahorros). |
| 2026-09-29 | Balance: en Cuenta de Ahorros es el saldo disponible; en Tarjeta de Crédito es la deuda a la fecha y se guarda en positivo. |
| 2026-09-29 | Límite: obligatorio en Tarjeta de Crédito, mayor a 0 y mayor o igual a la deuda. En Cuenta de Ahorros siempre queda vacío; al cambiar de Tarjeta de Crédito a Cuenta de Ahorros en el formulario, el valor del límite se descarta. |
| 2026-09-29 | Solo se guardan los últimos 4 dígitos; nunca el número completo de la tarjeta. |
| 2026-09-29 | Tipos de cuenta semilla: "Cuenta de Ahorros" (CA) y "Tarjeta de Crédito" (TC). No son editables por el usuario, se crean una sola vez y no se duplican. |
| 2026-09-29 | El Tipo de cuenta queda bloqueado al editar una Cuenta. |
| 2026-09-29 | La eliminación de una Cuenta es definitiva y siempre pide confirmación. |
| 2026-09-29 | El carrusel se ordena por fecha de creación (la más antigua primero) y siempre termina con la tarjeta "+". |
| 2026-09-29 | Diseño de la tarjeta: tono oscuro (Cuenta de Ahorros azul marino, Tarjeta de Crédito grafito) con sombreado que se oscurece hacia la derecha; ícono por Tipo de cuenta (billete / tarjeta) e ícono de pago sin contacto. El balance lleva el rótulo "Saldo disponible" o "Deuda a la fecha", que también es el título del campo en el formulario. |
| 2026-09-29 | Al regresar del formulario se pregunta solo si hubo cambios respecto a los valores iniciales. |
| 2026-09-29 | El botón principal del formulario está deshabilitado mientras haya campos inválidos. |
| 2026-09-29 | Los importes (balance y límite) se ingresan con el efecto de digitación de la app (desde 0,00, dígitos a la derecha) y sin signo; por eso un balance negativo no se puede digitar, aunque la regla se sigue validando. |

## Capabilities

### New Capabilities
- `accounts`: gestión de Cuentas — reglas de datos, carrusel de tarjetas en Inicio, formulario de crear/editar, menú contextual y eliminación.
- `account-types`: Tipos de cuenta semilla (creación idempotente) y su consulta de solo lectura en Configuración → Datos Maestros → Tipos de cuenta.

### Modified Capabilities
- `app-navigation`: el requisito "Pantallas principales vacías" se reemplaza por uno que describe el contenido de Inicio (carrusel de Cuentas) y Configuración (lista "Datos Maestros"); se agrega un requisito de visibilidad de la barra de navegación (oculta solo durante el formulario de Cuenta).

## Fuera de alcance

- En Inicio solo se implementan las tarjetas de Cuentas; ningún otro contenido (totales, gráficos, etc.).
- En Configuración solo se implementan los Datos Maestros; ninguna otra opción.
- Crear, editar o eliminar Tipos de cuenta (los Datos Maestros solo se consultan).
- Cambios a la barra de navegación en sus opciones, orden o estilo; el único cambio es ocultarla durante el formulario de Cuenta.
- Transacciones, transferencias, detalle de Cuenta al tocar la tarjeta y cálculo del cupo disponible (límite − deuda).
- Reordenar manualmente las tarjetas del carrusel.
- Soporte de iPad y otras monedas distintas a COP.

## Impact

- **Modelo de datos (Core Data)**: nuevas entidades `AccountType` y `Account` con relación Cuenta → Tipo de cuenta; se elimina la entidad plantilla `Item`. `Persistence.swift` y el `.xcdatamodeld` se mueven a `Core/Persistence/` y se inyecta el contexto en el entorno.
- **Código nuevo**: feature `Features/Accounts/` (formulario, tarjeta, carrusel, ViewModels), feature `Features/Settings/` ampliada (Datos Maestros, Tipos de cuenta), utilidades de moneda en `Core/Shared/`.
- **Código modificado**: `HomeView`, `SettingsView`, `BudgetSpyApp`.
- **Pruebas**: se crea el target de pruebas `BudgetSpyTests` (Swift Testing) para validaciones, ViewModels, formateo de moneda y la carga idempotente de Tipos de cuenta.
- **Changes futuros**: `add-transactions` actualizará el balance almacenado en cada Cuenta.
- **Dependencias**: ninguna nueva.
