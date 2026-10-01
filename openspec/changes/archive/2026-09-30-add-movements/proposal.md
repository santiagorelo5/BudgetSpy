# Proposal: add-movements

## Why

Hoy el usuario puede crear Cuentas con un balance, pero no puede registrar el dinero que entra, sale o se mueve entre ellas. El balance queda desactualizado y no hay forma de saber por qué cambió. Este change agrega los Movimientos (Gasto, Ingreso y Transferencia). El balance de cada Cuenta se mantiene siempre actualizado y cuadrado con sus Movimientos, y el usuario tiene trazabilidad desde el Inicio.

## What Changes

- **Movimientos**: el usuario puede crear, ver, editar y eliminar Gastos, Ingresos y Transferencias. Un Gasto o un Ingreso afecta una Cuenta; una Transferencia afecta dos (Cuenta origen y Cuenta destino).
- **Botón "+" en la sección Movimientos**: aparece en la misma línea del título "Movimientos" del Inicio, pegado al borde derecho, y abre el formulario para crear un Movimiento con la Cuenta enfocada como Cuenta origen. La barra de navegación no cambia.
- **Formulario de Movimiento**: tiene un selector segmentado Gasto / Ingreso / Transferencia y los campos valor, descripción, fecha, Cuenta origen y, solo en Transferencia, Cuenta destino. Los valores por defecto y los cambios de tipo siguen reglas fijas. El valor se ingresa sin signo y el sistema le pone el signo. Los errores de validación y de balance aparecen debajo del campo. Al regresar con cambios, se pregunta si se descartan.
- **Reglas de balance**: un Movimiento nunca puede dejar un balance menor que 0 ni una Deuda a la fecha mayor que el Límite. Esto se valida al crear, al editar (primero se revierte el efecto original y después se aplica el nuevo) y al eliminar.
- **Inicio**: el carrusel tiene una altura fija, con la proporción de una tarjeta de crédito, para que el diseño de la tarjeta no se deforme. Debajo aparece la sección "Movimientos", con los Movimientos de la Cuenta enfocada. El área tiene una altura fija de 6 filas, sin importar cuántos Movimientos haya, y se desliza dentro de ella. Cada fila tiene ícono, fecha, valor con signo y color, y descripción. Al deslizar a la izquierda se elimina y al deslizar a la derecha se edita (con deslizamiento largo). Al mantener presionada una fila se ve el detalle de solo lectura. Al crear o guardar un Movimiento, el carrusel se enfoca en su Cuenta origen.
- **Tipos de movimiento**: se crean como datos semilla ("Gasto", "Ingreso", "Transferencia") sin duplicarse. Se consultan en solo lectura en Configuración → Datos Maestros → Tipos de movimiento.
- **Cuentas**: al crear una Cuenta con balance mayor a 0, se crea un Movimiento "Saldo inicial". Al cambiar el balance de una Cuenta, se crea un Movimiento "Ajuste de saldo". Al eliminar una Cuenta, sus Gastos e Ingresos se eliminan y sus Transferencias se convierten sin cambiar el balance de la otra Cuenta.
- **Formato de valores negativos**: pasa de `$ -1.000,00` a `-$ 1.000,00` en toda la app. Hoy ninguna pantalla muestra negativos, así que el cambio solo es visible en los Movimientos.
- **BREAKING (spec)**:
  - El carrusel deja de ser el único contenido del Inicio.
  - Datos Maestros pasa de 1 a 2 ítems.

## Decisiones de negocio

| Fecha | Decisión |
|---|---|
| 2026-09-30 | Un Movimiento tiene valor (≠ 0, COP con 2 decimales, sin signo al ingresarlo), descripción (obligatoria, máx. 20 caracteres, sin solo espacios, repetible), fecha (solo día, por defecto hoy, sin fechas futuras), Cuenta origen (obligatoria), Cuenta destino (solo y obligatoria en Transferencia, distinta de la origen) y Tipo de movimiento. |
| 2026-09-30 | Signo del valor y efecto según Tipo de movimiento y Tipo de cuenta (RF3). En Cuenta de Ahorros: Gasto −, Ingreso +, Transferencia origen −, Transferencia destino +. En Tarjeta de Crédito: Gasto +, Ingreso −, Transferencia destino −. La Tarjeta de Crédito no puede ser origen de una Transferencia. |
| 2026-09-30 | Un Movimiento nunca deja un balance < 0 ni una Deuda a la fecha > Límite. Si al editar o eliminar la regla no se cumple, la acción se bloquea con su justificación. |
| 2026-09-30 | El balance sigue almacenado en la Cuenta, no se calcula. Cada operación que lo toque se guarda de forma atómica (todo o nada). |
| 2026-09-30 | Al crear un Movimiento, la Cuenta origen por defecto es la Cuenta enfocada en el carrusel. En Transferencia, la Cuenta origen solo puede ser una Cuenta de Ahorros y la Cuenta destino puede ser cualquier Cuenta distinta de la origen. |
| 2026-09-30 | El botón "+" para crear un Movimiento está en el encabezado de la sección "Movimientos", a la derecha del título, y no en la barra de navegación. La barra conserva sus 2 opciones, se oculta en el formulario de Movimiento y sigue visible en todo Configuración. |
| 2026-09-30 | Lista de Movimientos en el Inicio: todos los de la Cuenta enfocada, en un área de altura fija para 6 filas. El más reciente va arriba: se ordena por fecha descendente y, a igual fecha, por fecha y hora de creación descendente. Una Transferencia aparece en ambas Cuentas. |
| 2026-09-30 | El carrusel y la sección "Movimientos" tienen altura fija, para que el diseño de la tarjeta no se deforme al cambiar de Cuenta ni según la cantidad de Movimientos. |
| 2026-09-30 | Color: Gasto en rojo e Ingreso en verde. Una Transferencia es roja en la Cuenta origen y verde en la destino; en el formulario es neutra. Cada fila lleva un ícono para que el color no sea la única señal: en Gasto e Ingreso, una flecha diagonal hacia arriba si el Movimiento sube el balance de la Cuenta y hacia abajo si lo baja (Cuenta de Ahorros: Ingreso ↗, Gasto ↘; Tarjeta de Crédito: Gasto ↗, Ingreso ↘). La Transferencia lleva un ícono de flechas opuestas. El detalle usa el mismo signo, ícono y color que la fila de la Cuenta enfocada. |
| 2026-09-30 | Formato de negativos `-$ 10.000,00` (antes `$ -10.000,00`). Reemplaza el formato de negativos del principio de moneda de `openspec/config.yaml`. |
| 2026-09-30 | Tipos de movimiento semilla: "Gasto", "Ingreso", "Transferencia". No son editables por el usuario, se crean una sola vez y no se duplican. |
| 2026-09-30 | Crear una Cuenta con balance > 0 genera un Movimiento "Saldo inicial" con la fecha de creación: Ingreso en Cuenta de Ahorros y Gasto en Tarjeta de Crédito. Con balance 0 no se genera ninguno. |
| 2026-09-30 | Editar el balance de una Cuenta genera un Movimiento "Ajuste de saldo" con la fecha actual. Si el saldo sube o la deuda baja, es un Ingreso; si el saldo baja o la deuda sube, es un Gasto. Sin cambio de balance no se genera ninguno. |
| 2026-09-30 | Eliminar una Cuenta elimina sus Gastos e Ingresos. Una Transferencia hacia la Cuenta eliminada queda como Gasto de su Cuenta origen. Una Transferencia desde la Cuenta eliminada queda como Ingreso de su Cuenta destino. El balance de las otras Cuentas no cambia. |
| 2026-09-30 | "Saldo inicial" y "Ajuste de saldo" se editan y eliminan como cualquier otro Movimiento. |
| 2026-09-30 | Las Cuentas creadas antes de este change se eliminan a mano borrando la app. No hay código de migración ni de limpieza de datos. |

## Capabilities

### New Capabilities
- `movements`: Movimientos. Cubre reglas de datos, signo y efecto sobre el balance (RF3), formulario de crear y editar, lista en el Inicio con acciones de deslizar, detalle, eliminación y accesibilidad.
- `movement-types`: Tipos de movimiento semilla (creación idempotente) y su consulta de solo lectura en Configuración → Datos Maestros → Tipos de movimiento.

### Modified Capabilities
- `app-navigation`:
  - El Inicio muestra el carrusel, con altura fija, y la sección "Movimientos".
  - La barra se oculta también en el formulario de Movimiento y sigue visible en Tipos de movimiento.
- `account-types`: Datos Maestros tiene 2 ítems, "Tipos de cuenta" y "Tipos de movimiento".
- `accounts`:
  - Se agrega el Movimiento "Saldo inicial" al crear una Cuenta.
  - Se agrega el Movimiento "Ajuste de saldo" al editar el balance.
  - Se agrega el manejo de Movimientos al eliminar una Cuenta.

## Fuera de alcance

- En el Inicio solo se agrega la sección de Movimientos. No hay buscador, filtros, totales ni pantalla "Ver todos".
- En Configuración solo se agrega "Tipos de movimiento" en Datos Maestros. No se pueden crear, editar ni eliminar Tipos de movimiento.
- Categorías, Movimientos recurrentes o programados, adjuntos, informes y gráficos.
- Cambios en la barra de navegación: conserva sus 2 opciones, su orden, su estilo y su comportamiento. El único cambio es ocultarla durante el formulario de Movimiento.
- Reimplementar las Cuentas. De las Cuentas solo cambia el manejo de Movimientos al crear, editar el balance y eliminar, y la actualización del balance.
- Migración o limpieza de Cuentas creadas antes de este change.
- iPad, orientación horizontal y otras monedas distintas a COP.

## Impact

- **Modelo de datos (Core Data)**:
  - Nueva versión del modelo con las entidades `MovementType` y `Movement`.
  - `Account` tiene nuevas relaciones inversas.
  - Se usa migración ligera.
- **Código nuevo**:
  - Feature `Features/Movements/`: componente de dominio de balance, formulario, lista, fila, detalle y ViewModels.
  - Seeder de Tipos de movimiento.
  - Pantalla "Tipos de movimiento" en Configuración.
- **Código modificado**:
  - `HomeView`: sección "Movimientos" con su botón "+" y foco del carrusel.
  - `AccountCarouselView`: foco y altura fija.
  - `AccountFormViewModel` y `AccountCarouselViewModel`, que pasan por el componente de dominio.
  - `MasterDataView`, `Persistence` y `CurrencyFormatter`.
- **Pruebas**: Swift Testing para el componente de dominio (todas las celdas de RF3, edición, eliminación bloqueada y RF15–RF17), los ViewModels nuevos y modificados, el seeder y el formato de negativos.
- **Configuración del proyecto**: el principio 5 de `openspec/config.yaml` debe actualizarse a `-$ 1.000,00`. Queda como tarea explícita del usuario.
- **Changes futuros**: cualquier change que toque Movimientos o balances debe usar el mismo componente de dominio. Las categorías se relacionarán con `Movement`.
- **Dependencias**: ninguna nueva.
