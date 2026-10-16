# movements Specification

## Purpose

Permite al usuario registrar, ver, editar y eliminar Movimientos (Gasto, Ingreso y Transferencia) en sus Cuentas, y mantiene el balance de cada Cuenta siempre actualizado y cuadrado con sus Movimientos.

## Requirements

### Requirement: Datos de un Movimiento
El sistema MUST guardar para cada Movimiento: valor, descripción, fecha (solo día, sin hora), Cuenta origen, Cuenta destino (solo en Transferencia), Tipo de movimiento y fecha de creación. El valor MUST estar en pesos colombianos con 2 decimales y MUST ser distinto de 0. La descripción MUST tener máximo 20 caracteres y puede repetirse entre Movimientos. En Gasto e Ingreso la Cuenta destino MUST quedar vacía. En Transferencia la Cuenta destino MUST ser distinta de la Cuenta origen.

#### Scenario: Gasto guardado sin Cuenta destino
- **WHEN** el usuario crea un Gasto de $ 10.000,00 "Compra de café" el 30/09/2026 en la Cuenta de Ahorros "Nómina"
- **THEN** el Movimiento queda guardado con esos datos, Tipo de movimiento Gasto y sin Cuenta destino

#### Scenario: Transferencia guardada con Cuenta destino
- **WHEN** el usuario crea una Transferencia de $ 20.000,00 de "Nómina" a "Ahorros casa"
- **THEN** el Movimiento queda guardado con Cuenta origen "Nómina" y Cuenta destino "Ahorros casa"

#### Scenario: Descripciones repetidas permitidas
- **WHEN** el usuario crea un Movimiento con la misma descripción de un Movimiento existente
- **THEN** el Movimiento se crea sin error

### Requirement: Signo del valor y efecto sobre el balance
El usuario MUST ingresar el valor sin signo. El sistema MUST asignar el signo y aplicar el efecto sobre el balance según esta tabla:

| Tipo de movimiento      | Cuenta de Ahorros                   | Tarjeta de Crédito                       |
|-------------------------|-------------------------------------|------------------------------------------|
| Gasto                   | valor negativo; balance − valor ≥ 0 | valor positivo; balance + valor ≤ Límite |
| Ingreso                 | valor positivo; balance + valor     | valor negativo; balance − valor ≥ 0      |
| Transferencia (origen)  | valor negativo; balance − valor ≥ 0 | no permitido                             |
| Transferencia (destino) | valor positivo; balance + valor     | valor negativo; balance − valor ≥ 0      |

El sistema MUST NOT permitir un Movimiento que deje un balance menor que 0 o una Deuda a la fecha mayor que el Límite.

#### Scenario: Gasto en Cuenta de Ahorros
- **WHEN** la Cuenta de Ahorros "Nómina" tiene $ 100.000,00 y el usuario crea un Gasto de $ 10.000,00
- **THEN** el Movimiento se guarda con valor -$ 10.000,00
- **AND** el saldo de "Nómina" queda en $ 90.000,00

#### Scenario: Gasto en Tarjeta de Crédito
- **WHEN** la Tarjeta de Crédito "Visa" tiene Deuda a la fecha $ 100.000,00 y el usuario crea un Gasto de $ 10.000,00
- **THEN** el Movimiento se guarda con valor $ 10.000,00
- **AND** la deuda de "Visa" queda en $ 110.000,00

#### Scenario: Ingreso en Cuenta de Ahorros
- **WHEN** la Cuenta de Ahorros "Nómina" tiene $ 100.000,00 y el usuario crea un Ingreso de $ 10.000,00
- **THEN** el Movimiento se guarda con valor $ 10.000,00
- **AND** el saldo de "Nómina" queda en $ 110.000,00

#### Scenario: Ingreso en Tarjeta de Crédito
- **WHEN** la Tarjeta de Crédito "Visa" tiene Deuda a la fecha $ 100.000,00 y el usuario crea un Ingreso de $ 10.000,00
- **THEN** el Movimiento se guarda con valor -$ 10.000,00
- **AND** la deuda de "Visa" queda en $ 90.000,00

#### Scenario: Transferencia entre Cuentas de Ahorros
- **WHEN** "Nómina" tiene $ 100.000,00, "Ahorros casa" tiene $ 0,00 y el usuario crea una Transferencia de $ 20.000,00 de "Nómina" a "Ahorros casa"
- **THEN** el saldo de "Nómina" queda en $ 80.000,00 y el de "Ahorros casa" en $ 20.000,00
- **AND** el valor se ve como -$ 20.000,00 en "Nómina" y como $ 20.000,00 en "Ahorros casa"

#### Scenario: Transferencia hacia una Tarjeta de Crédito
- **WHEN** "Nómina" tiene $ 100.000,00, "Visa" tiene Deuda a la fecha $ 50.000,00 y el usuario crea una Transferencia de $ 30.000,00 de "Nómina" a "Visa"
- **THEN** el saldo de "Nómina" queda en $ 70.000,00 y la deuda de "Visa" en $ 20.000,00
- **AND** el valor se ve como -$ 30.000,00 en "Nómina" y como -$ 30.000,00 en "Visa"

#### Scenario: Saldo insuficiente
- **WHEN** la Cuenta de Ahorros "Nómina" tiene $ 50.000,00 y el usuario ingresa un Gasto de $ 60.000,00
- **THEN** debajo del campo valor se muestra "Saldo insuficiente en Nómina. Disponible: $ 50.000,00"
- **AND** el botón principal está deshabilitado

#### Scenario: Gasto que deja el saldo en cero
- **WHEN** la Cuenta de Ahorros "Nómina" tiene $ 50.000,00 y el usuario crea un Gasto de $ 50.000,00
- **THEN** el Movimiento se guarda y el saldo de "Nómina" queda en $ 0,00

#### Scenario: Supera el límite de la Tarjeta de Crédito
- **WHEN** la Tarjeta de Crédito "Visa" tiene Deuda a la fecha $ 4.800.000,00 y Límite $ 5.000.000,00, y el usuario ingresa un Gasto de $ 300.000,00
- **THEN** debajo del campo valor se muestra "Supera el límite de Visa. Cupo disponible: $ 200.000,00"
- **AND** el botón principal está deshabilitado

#### Scenario: Gasto que llega exacto al límite
- **WHEN** la Tarjeta de Crédito "Visa" tiene Deuda a la fecha $ 4.800.000,00 y Límite $ 5.000.000,00, y el usuario crea un Gasto de $ 200.000,00
- **THEN** el Movimiento se guarda y la deuda de "Visa" queda en $ 5.000.000,00

#### Scenario: Ingreso o Transferencia que supera la deuda
- **WHEN** la Tarjeta de Crédito "Visa" tiene Deuda a la fecha $ 100.000,00 y el usuario ingresa un Ingreso, o una Transferencia hacia "Visa", de $ 150.000,00
- **THEN** debajo del campo valor se muestra "El valor supera la deuda de Visa: $ 100.000,00"
- **AND** el botón principal está deshabilitado

#### Scenario: Pago que salda la deuda
- **WHEN** la Tarjeta de Crédito "Visa" tiene Deuda a la fecha $ 100.000,00 y el usuario crea un Ingreso, o una Transferencia hacia "Visa", de $ 100.000,00
- **THEN** el Movimiento se guarda y la deuda de "Visa" queda en $ 0,00

### Requirement: Botón "+" para crear un Movimiento
El encabezado de la sección "Movimientos" del Inicio MUST mostrar, en la misma línea del título "Movimientos", un botón "+" pegado al borde derecho de la pantalla. Al tocarlo, el sistema MUST abrir el formulario para crear un Movimiento. El botón solo existe cuando la sección se muestra, es decir, cuando el carrusel está en una Cuenta. La barra de navegación MUST NOT tener un botón para crear Movimientos. VoiceOver MUST anunciar el botón como "Agregar movimiento".

#### Scenario: Ubicación del botón
- **WHEN** el carrusel está en una Cuenta
- **THEN** el botón "+" se ve en la misma línea del título "Movimientos", alineado al borde derecho de la pantalla

#### Scenario: Crear desde el Inicio
- **WHEN** el usuario toca el botón "+" de la sección "Movimientos"
- **THEN** se abre el formulario para crear un Movimiento

#### Scenario: Tarjeta "+" enfocada
- **WHEN** el carrusel está en la tarjeta "+"
- **THEN** no se ve la sección "Movimientos" ni su botón "+"

#### Scenario: VoiceOver anuncia el botón
- **WHEN** VoiceOver está activo y el usuario enfoca el botón "+" de la sección "Movimientos"
- **THEN** VoiceOver anuncia "Agregar movimiento"

### Requirement: Campos del formulario de Movimiento
El formulario MUST mostrar en la parte superior un selector segmentado con "Gasto", "Ingreso" y "Transferencia", en ese orden. Debajo MUST mostrar los campos valor, descripción, fecha y Cuenta origen. Solo en Transferencia MUST mostrar además el campo Cuenta destino. El campo Cuenta origen MUST titularse "Cuenta" en Gasto e Ingreso y "Cuenta origen" en Transferencia. Al crear, el tipo MUST ser Gasto, la fecha MUST ser la actual y la Cuenta origen MUST ser la Cuenta enfocada en el carrusel.

#### Scenario: Valores por defecto al crear
- **WHEN** el usuario tiene las Cuentas "Nómina" (la más antigua) y "Visa", el carrusel está en "Visa" y toca el botón "+" de la sección "Movimientos"
- **THEN** el tipo seleccionado es Gasto, la fecha es la de hoy, la Cuenta es "Visa" y no se ve el campo Cuenta destino
- **AND** el valor muestra $ 0,00 y la descripción está vacía

#### Scenario: Título del campo en Transferencia
- **WHEN** el usuario selecciona Transferencia
- **THEN** el campo Cuenta origen se titula "Cuenta origen" y se ve el campo "Cuenta destino"

### Requirement: Selección de Cuentas en el formulario
En Gasto e Ingreso, la lista de Cuenta origen MUST mostrar todas las Cuentas. En Transferencia, la lista de Cuenta origen MUST mostrar solo Cuentas de Ahorros, y la lista de Cuenta destino MUST mostrar todas las Cuentas (incluidas las Tarjetas de Crédito) excepto la Cuenta origen seleccionada. Todas las listas MUST seguir el orden del carrusel.

Al cambiar a Transferencia:
- Si la Cuenta origen es una Tarjeta de Crédito, el sistema MUST seleccionar la primera Cuenta de Ahorros de la lista.
- El sistema MUST seleccionar como Cuenta destino la primera Cuenta de la lista distinta de la Cuenta origen.

Al cambiar la Cuenta origen en Transferencia, si coincide con la Cuenta destino, la Cuenta destino MUST pasar a la primera Cuenta de la lista distinta de la nueva Cuenta origen.

Al cambiar a Gasto o Ingreso, el campo Cuenta destino MUST ocultarse y su valor MUST descartarse.

Si una lista no tiene Cuentas disponibles, el campo MUST quedar sin selección y MUST mostrar "No hay cuentas disponibles", y el Movimiento MUST NOT poder crearse ni guardarse.

#### Scenario: Listas en Transferencia
- **WHEN** existen las Cuentas de Ahorros "Nómina" y "Ahorros casa" y la Tarjeta de Crédito "Visa", el tipo es Transferencia y la Cuenta origen es "Nómina"
- **THEN** la lista de Cuenta origen muestra "Nómina" y "Ahorros casa", pero no "Visa"
- **AND** la lista de Cuenta destino muestra "Ahorros casa" y "Visa", pero no "Nómina"

#### Scenario: De Gasto con Tarjeta de Crédito a Transferencia
- **WHEN** en el carrusel están, en orden, "Visa" (Tarjeta de Crédito), "Nómina" y "Ahorros casa", el tipo es Gasto con Cuenta "Visa" y el usuario selecciona Transferencia
- **THEN** la Cuenta origen pasa a "Nómina"
- **AND** la Cuenta destino es "Visa"

#### Scenario: Cambiar la Cuenta origen a la misma que el destino
- **WHEN** en Transferencia la Cuenta origen es "Nómina", la Cuenta destino es "Ahorros casa" y el usuario cambia la Cuenta origen a "Ahorros casa"
- **THEN** la Cuenta destino pasa a "Nómina", la primera Cuenta de la lista distinta de "Ahorros casa"

#### Scenario: De Transferencia a Gasto
- **WHEN** el tipo es Transferencia con Cuenta destino "Ahorros casa" y el usuario selecciona Gasto y crea el Movimiento
- **THEN** el campo Cuenta destino desaparece
- **AND** el Movimiento se guarda sin Cuenta destino

#### Scenario: Transferencia sin Cuentas de Ahorros
- **WHEN** el usuario solo tiene Tarjetas de Crédito y selecciona Transferencia
- **THEN** el campo Cuenta origen muestra "No hay cuentas disponibles"
- **AND** el botón principal está deshabilitado

#### Scenario: Transferencia sin otra Cuenta para el destino
- **WHEN** el usuario tiene una sola Cuenta, de Ahorros, y selecciona Transferencia
- **THEN** el campo Cuenta destino muestra "No hay cuentas disponibles"
- **AND** el botón principal está deshabilitado

### Requirement: Ingreso del valor, descripción y fecha
El campo valor MUST iniciar en `$ 0,00`. Cada dígito ingresado MUST agregarse a la derecha y cada borrado MUST quitar el último dígito hasta volver a `$ 0,00`. El usuario MUST NOT poder escribir signos en el campo valor. El campo descripción MUST NOT aceptar más de 20 caracteres. El selector de fecha MUST permitir elegir hoy o una fecha pasada y MUST NOT permitir elegir una fecha futura.

#### Scenario: Digitar un valor
- **WHEN** el campo valor muestra `$ 0,00` y el usuario digita 1, 0, 0, 0, 0, 0, 0
- **THEN** el campo muestra `$ 10.000,00`

#### Scenario: Intentar escribir un signo
- **WHEN** el usuario intenta escribir "-" o "+" en el campo valor
- **THEN** el valor no cambia

#### Scenario: Descripción de más de 20 caracteres
- **WHEN** el usuario intenta escribir una descripción de más de 20 caracteres
- **THEN** el campo no acepta caracteres más allá del carácter 20

#### Scenario: Fecha pasada
- **WHEN** hoy es 30/09/2026 y el usuario elige el 15/08/2026
- **THEN** la fecha del formulario queda en 15/08/2026

#### Scenario: Fecha futura
- **WHEN** hoy es 30/09/2026 y el usuario abre el selector de fecha
- **THEN** el 01/10/2026 y las fechas posteriores no se pueden seleccionar

### Requirement: Color del valor en el formulario
El formulario MUST mostrar el valor en rojo en Gasto, en verde en Ingreso y en color neutro en Transferencia.

#### Scenario: Cambiar de tipo cambia el color
- **WHEN** el usuario ingresa $ 10.000,00 con el tipo Gasto y luego selecciona Ingreso y después Transferencia
- **THEN** el valor se ve en rojo, luego en verde y luego en color neutro

### Requirement: Validación del formulario de Movimiento
El sistema MUST considerar inválido el formulario de Movimiento cuando:
- El valor es $ 0,00.
- La descripción está vacía o solo tiene espacios.
- No hay Cuenta origen seleccionada.
- En Transferencia, no hay Cuenta destino seleccionada.
- El Movimiento incumple la regla de balance.

Mientras el formulario sea inválido, el botón principal MUST estar deshabilitado. Cada campo inválido que el usuario ya haya modificado MUST mostrar su mensaje debajo del campo:
- "Ingresa un valor mayor a 0"
- "Ingresa una descripción"
- "Selecciona una cuenta"
- "Selecciona la cuenta destino"

Los errores de balance MUST mostrarse debajo del campo valor:
- "Saldo insuficiente en <Cuenta>. Disponible: <valor>"
- "Supera el límite de <Cuenta>. Cupo disponible: <valor>"
- "El valor supera la deuda de <Cuenta>: <valor>"

Un formulario recién abierto MUST NOT mostrar errores.

#### Scenario: Formulario nuevo
- **WHEN** el usuario abre el formulario para crear
- **THEN** el botón "Crear movimiento" está deshabilitado
- **AND** no se muestra ningún mensaje de error

#### Scenario: Valor en cero
- **WHEN** el usuario digita un valor y lo borra hasta `$ 0,00`
- **THEN** debajo del campo valor se muestra "Ingresa un valor mayor a 0"
- **AND** el botón principal está deshabilitado

#### Scenario: Descripción solo con espacios
- **WHEN** el usuario escribe "   " en la descripción
- **THEN** debajo del campo se muestra "Ingresa una descripción"
- **AND** el botón principal está deshabilitado

#### Scenario: Transferencia sin Cuenta destino
- **WHEN** el tipo es Transferencia y no hay Cuenta destino seleccionada
- **THEN** el botón principal está deshabilitado
- **AND** si el usuario ya modificó el campo, debajo de él se muestra "Selecciona la cuenta destino"

#### Scenario: Formulario válido
- **WHEN** el valor es mayor a 0, la descripción tiene texto, las Cuentas requeridas están seleccionadas y se cumple la regla de balance
- **THEN** el botón principal está habilitado y no se muestran errores

### Requirement: Botones del formulario de Movimiento
El formulario MUST tener el botón principal en la parte superior derecha, con el texto "Crear movimiento" al crear y "Guardar cambios" al editar. MUST tener un botón para regresar en la parte superior izquierda.

#### Scenario: Botón al crear
- **WHEN** el usuario abre el formulario para crear
- **THEN** en la esquina superior derecha se ve el botón "Crear movimiento"
- **AND** en la esquina superior izquierda se ve el botón para regresar

#### Scenario: Botón al editar
- **WHEN** el usuario abre el formulario para editar un Movimiento
- **THEN** en la esquina superior derecha se ve el botón "Guardar cambios"

### Requirement: Regresar desde el formulario de Movimiento
Al tocar el botón para regresar, si hubo cambios respecto a los valores con los que se abrió el formulario, el sistema MUST preguntar si desea descartarlos, con las opciones "Descartar cambios" y "Seguir editando". Si no hubo cambios, el sistema MUST volver al Inicio sin preguntar.

#### Scenario: Regresar sin cambios
- **WHEN** el usuario abre el formulario y toca regresar sin modificar nada
- **THEN** vuelve al Inicio sin ninguna pregunta

#### Scenario: Regresar con cambios y descartar
- **WHEN** el usuario modifica algún campo, toca regresar y elige "Descartar cambios"
- **THEN** vuelve al Inicio y no se guarda nada

#### Scenario: Regresar con cambios y seguir editando
- **WHEN** el usuario modifica algún campo, toca regresar y elige "Seguir editando"
- **THEN** permanece en el formulario con los datos que había ingresado

#### Scenario: Cambios revertidos
- **WHEN** el usuario cambia un campo, lo deja igual a su valor inicial y toca regresar
- **THEN** vuelve al Inicio sin ninguna pregunta

### Requirement: Crear y guardar un Movimiento
Al tocar el botón principal con un formulario válido, el sistema MUST guardar el Movimiento y actualizar los balances de las Cuentas afectadas en una sola operación. Luego MUST volver al Inicio con el carrusel enfocado en la Cuenta origen del Movimiento, y el carrusel y la lista MUST mostrar los datos actualizados. Si el guardado falla, el sistema MUST NOT cambiar ningún balance, MUST mostrar un aviso y MUST mantener al usuario en el formulario con sus datos.

#### Scenario: Crear un Gasto con el carrusel en otra Cuenta
- **WHEN** el carrusel está en "Visa" y el usuario crea un Gasto de $ 10.000,00 en la Cuenta de Ahorros "Nómina", que tiene $ 100.000,00
- **THEN** vuelve al Inicio con el carrusel enfocado en "Nómina"
- **AND** la tarjeta de "Nómina" muestra $ 90.000,00
- **AND** el Movimiento aparece en la lista

#### Scenario: Crear una Transferencia
- **WHEN** el usuario crea una Transferencia de $ 20.000,00 de "Nómina" a "Ahorros casa"
- **THEN** el saldo de "Nómina" baja $ 20.000,00, el de "Ahorros casa" sube $ 20.000,00 y el Movimiento aparece en la lista de ambas

#### Scenario: Falla al crear
- **WHEN** el usuario toca "Crear movimiento" y el guardado falla
- **THEN** se muestra el aviso "No se pudo crear el movimiento. Intenta de nuevo."
- **AND** el usuario sigue en el formulario con sus datos y ningún balance cambia

#### Scenario: Falla al guardar cambios
- **WHEN** el usuario toca "Guardar cambios" y el guardado falla
- **THEN** se muestra el aviso "No se pudieron guardar los cambios. Intenta de nuevo."
- **AND** el usuario sigue en el formulario con sus datos y ningún balance cambia

### Requirement: Editar un Movimiento
El sistema MUST permitir cambiar todos los campos de un Movimiento, incluidos el Tipo de movimiento y las Cuentas. Al validar y al guardar, el sistema MUST revertir primero el efecto original del Movimiento sobre los balances y después aplicar el nuevo. Las reglas de balance MUST validarse sobre ese resultado. Si alguna no se cumple, el Movimiento MUST NOT poder guardarse. Los Movimientos "Saldo inicial" y "Ajuste de saldo" MUST poder editarse como cualquier otro.

#### Scenario: Aumentar un Gasto hasta dejar el saldo en cero
- **WHEN** la Cuenta de Ahorros tiene $ 20.000,00 y el usuario edita un Gasto existente de -$ 30.000,00 a $ 50.000,00
- **THEN** el cambio es válido y, al guardar, el saldo queda en $ 0,00

#### Scenario: Cambiar un Ingreso a Gasto que deja el saldo negativo
- **WHEN** la Cuenta de Ahorros tiene $ 10.000,00 y el usuario cambia un Ingreso existente de $ 50.000,00 a Gasto
- **THEN** debajo del campo valor se muestra el error de saldo insuficiente
- **AND** el botón "Guardar cambios" está deshabilitado

#### Scenario: Cambiar un Gasto a Ingreso
- **WHEN** el usuario cambia un Gasto de -$ 10.000,00 en una Cuenta de Ahorros a Ingreso de $ 10.000,00 y guarda
- **THEN** el saldo de la Cuenta aumenta $ 20.000,00

#### Scenario: Cambiar la Cuenta de un Movimiento
- **WHEN** el usuario cambia la Cuenta de un Gasto de $ 10.000,00 de "Nómina" a "Ahorros casa" y guarda
- **THEN** el saldo de "Nómina" sube $ 10.000,00 y el de "Ahorros casa" baja $ 10.000,00
- **AND** el Movimiento aparece en la lista de "Ahorros casa" y ya no en la de "Nómina"

#### Scenario: Editar el Saldo inicial
- **WHEN** el usuario edita el Movimiento "Saldo inicial" de $ 500.000,00 a $ 400.000,00 en una Cuenta de Ahorros y guarda
- **THEN** el saldo de la Cuenta baja $ 100.000,00

### Requirement: Sección Movimientos en el Inicio
Debajo del carrusel, el Inicio MUST mostrar una sección titulada "Movimientos" con todos los Movimientos de la Cuenta enfocada en el carrusel. Una Transferencia MUST aparecer en la lista de la Cuenta origen y en la de la Cuenta destino. El área de la lista MUST tener una altura fija equivalente a 6 filas, que MUST NOT cambiar según la cantidad de Movimientos ni al cambiar de Cuenta. Si hay más de 6, el usuario MUST poder deslizar dentro de la lista para ver los demás. Si el carrusel está en la tarjeta "+", la sección MUST NOT mostrarse. Si la Cuenta no tiene Movimientos, la sección MUST mostrar "Sin movimientos" dentro de esa misma área.

#### Scenario: Más de 6 Movimientos
- **WHEN** la Cuenta enfocada tiene 10 Movimientos
- **THEN** se ven 6 filas
- **AND** al deslizar dentro de la lista se ven las otras 4

#### Scenario: Menos de 6 Movimientos
- **WHEN** la Cuenta enfocada tiene 2 Movimientos
- **THEN** el área de la lista conserva la altura de 6 filas y las 2 filas se ven en la parte superior

#### Scenario: La sección mantiene su tamaño al cambiar de Cuenta
- **WHEN** el usuario desliza el carrusel de una Cuenta con 10 Movimientos a una sin Movimientos
- **THEN** la sección "Movimientos" conserva la misma altura y muestra "Sin movimientos" dentro de ella

#### Scenario: Cambiar de Cuenta en el carrusel
- **WHEN** el usuario desliza el carrusel de "Nómina" a "Visa"
- **THEN** la lista muestra solo los Movimientos de "Visa"

#### Scenario: Tarjeta "+" enfocada
- **WHEN** el carrusel está en la tarjeta "+"
- **THEN** no se ve la sección "Movimientos"

#### Scenario: Cuenta sin Movimientos
- **WHEN** la Cuenta enfocada no tiene Movimientos
- **THEN** la sección muestra "Sin movimientos"

#### Scenario: Sin Cuentas
- **WHEN** el usuario no tiene Cuentas
- **THEN** el carrusel muestra solo la tarjeta "+" y no se ve la sección "Movimientos"

### Requirement: Orden de la lista de Movimientos
La lista MUST mostrar arriba el Movimiento más reciente: MUST ordenarse por fecha, del más reciente al más antiguo. A igual fecha, MUST desempatarse por la fecha y hora de creación, del creado más recientemente al más antiguo.

#### Scenario: Orden por fecha
- **WHEN** la Cuenta tiene un Movimiento del 29/09/2026 y otro del 30/09/2026
- **THEN** el del 30/09/2026 aparece primero

#### Scenario: Misma fecha
- **WHEN** la Cuenta tiene dos Movimientos del 30/09/2026, un Ingreso de $ 50.000,00 creado a las 9:00 y un Gasto de -$ 10.000,00 creado a las 18:30
- **THEN** el Gasto creado a las 18:30 aparece primero

#### Scenario: Movimiento registrado con fecha pasada
- **WHEN** el 30/09/2026 la Cuenta tiene un Movimiento del 30/09/2026 y el usuario crea otro con fecha 29/09/2026
- **THEN** el del 30/09/2026 sigue apareciendo primero

### Requirement: Contenido y color de una fila
Cada fila MUST mostrar:
- Un ícono que indica el efecto sobre el balance de la Cuenta enfocada: en Gasto e Ingreso, una flecha diagonal hacia arriba si el Movimiento sube el balance y una flecha diagonal hacia abajo si lo baja; en Transferencia, un ícono de flechas opuestas.
- La fecha con el formato "30 sep 2026".
- El valor con su signo.
- La descripción en una línea.

El valor MUST mostrarse como "$ 10.000,00" si es positivo y "-$ 10.000,00" si es negativo, con el signo de la tabla de signo y efecto según la Cuenta enfocada. Un Gasto MUST verse en rojo y un Ingreso en verde. Una Transferencia MUST verse en rojo en la lista de la Cuenta origen y en verde en la de la Cuenta destino. El ícono MUST tomar el mismo color que el valor. Por tanto, en Cuenta de Ahorros un Ingreso MUST llevar la flecha hacia arriba en verde y un Gasto la flecha hacia abajo en rojo; en Tarjeta de Crédito, donde el balance es la deuda, un Gasto MUST llevar la flecha hacia arriba en rojo y un Ingreso la flecha hacia abajo en verde. La fila MUST respetar el tamaño de texto dinámico y verse legible en modo claro y oscuro.

#### Scenario: Gasto en Cuenta de Ahorros
- **WHEN** la lista muestra un Gasto de $ 10.000,00 de una Cuenta de Ahorros
- **THEN** el valor se ve en rojo como "-$ 10.000,00"
- **AND** el ícono es una flecha diagonal hacia abajo en rojo

#### Scenario: Gasto en Tarjeta de Crédito
- **WHEN** la lista muestra un Gasto de $ 10.000,00 de una Tarjeta de Crédito
- **THEN** el valor se ve en rojo como "$ 10.000,00"
- **AND** el ícono es una flecha diagonal hacia arriba en rojo

#### Scenario: Ingreso en Cuenta de Ahorros
- **WHEN** la lista muestra un Ingreso de $ 10.000,00 de una Cuenta de Ahorros
- **THEN** el valor se ve en verde como "$ 10.000,00"
- **AND** el ícono es una flecha diagonal hacia arriba en verde

#### Scenario: Ingreso en Tarjeta de Crédito
- **WHEN** la lista muestra un Ingreso de $ 10.000,00 de una Tarjeta de Crédito
- **THEN** el valor se ve en verde como "-$ 10.000,00"
- **AND** el ícono es una flecha diagonal hacia abajo en verde

#### Scenario: Transferencia en cada Cuenta
- **WHEN** existe una Transferencia de $ 20.000,00 de "Nómina" a "Ahorros casa"
- **THEN** en la lista de "Nómina" se ve en rojo como "-$ 20.000,00"
- **AND** en la lista de "Ahorros casa" se ve en verde como "$ 20.000,00"
- **AND** en ambas listas el ícono es el de flechas opuestas, con el color del valor

#### Scenario: Descripción y fecha
- **WHEN** la lista muestra un Movimiento "Compra de café" del 30/09/2026
- **THEN** la fila muestra "30 sep 2026" y "Compra de café" en una línea

### Requirement: Eliminar un Movimiento desde la lista
Al deslizar una fila a la izquierda, el sistema MUST mostrar un botón rojo con ícono de basura. Un deslizamiento largo MUST accionarlo directamente. En ambos casos el sistema MUST pedir confirmación con las opciones "Eliminar movimiento" y "Cancelar". Si el usuario confirma, el Movimiento MUST eliminarse de forma definitiva y los balances de las Cuentas afectadas MUST recalcularse en una sola operación. Si al revertir su efecto algún balance quedaría menor que 0 o una Deuda a la fecha quedaría mayor que el Límite, el sistema MUST NOT eliminarlo y MUST mostrar el aviso "No se puede eliminar el movimiento: <justificación>". Si la eliminación falla, el sistema MUST mostrar el aviso "No se pudo eliminar el movimiento. Intenta de nuevo." y nada cambia.

#### Scenario: Deslizar poco a la izquierda
- **WHEN** el usuario desliza una fila un poco a la izquierda
- **THEN** aparece el botón rojo con ícono de basura

#### Scenario: Deslizamiento largo a la izquierda
- **WHEN** el usuario desliza una fila completamente a la izquierda
- **THEN** se pide la confirmación "Eliminar movimiento" / "Cancelar"

#### Scenario: Cancelar la eliminación
- **WHEN** el usuario elige "Cancelar" en la confirmación
- **THEN** el Movimiento sigue en la lista y los balances no cambian

#### Scenario: Eliminar un Gasto
- **WHEN** el usuario elimina un Gasto de -$ 10.000,00 de una Cuenta de Ahorros
- **THEN** el Movimiento desaparece de la lista y el saldo de la Cuenta aumenta $ 10.000,00

#### Scenario: Eliminación bloqueada por saldo negativo
- **WHEN** la Cuenta de Ahorros "Nómina" tiene $ 30.000,00 y el usuario confirma eliminar un Ingreso de $ 50.000,00
- **THEN** se muestra el aviso "No se puede eliminar el movimiento: el saldo de Nómina quedaría en -$ 20.000,00"
- **AND** el Movimiento sigue en la lista y los balances no cambian

#### Scenario: Eliminar el Saldo inicial
- **WHEN** una Cuenta de Ahorros tiene solo el Movimiento "Saldo inicial" de $ 500.000,00 y saldo $ 500.000,00, y el usuario lo elimina
- **THEN** el Movimiento desaparece y el saldo queda en $ 0,00

#### Scenario: Falla al eliminar
- **WHEN** el usuario confirma la eliminación y esta falla
- **THEN** se muestra el aviso "No se pudo eliminar el movimiento. Intenta de nuevo."
- **AND** el Movimiento sigue en la lista y los balances no cambian

### Requirement: Editar un Movimiento desde la lista
Al deslizar una fila a la derecha, el sistema MUST mostrar un botón azul con ícono de editar. Tocarlo o hacer un deslizamiento largo MUST abrir el formulario de edición con los datos del Movimiento. En una Transferencia vista desde la Cuenta destino, el formulario MUST abrirse con los mismos datos que desde la Cuenta origen.

#### Scenario: Deslizar poco a la derecha
- **WHEN** el usuario desliza una fila un poco a la derecha
- **THEN** aparece el botón azul con ícono de editar

#### Scenario: Deslizamiento largo a la derecha
- **WHEN** el usuario desliza una fila completamente a la derecha
- **THEN** se abre el formulario con los datos del Movimiento y el botón "Guardar cambios"

### Requirement: Detalle de un Movimiento
Al mantener presionada una fila, el sistema MUST mostrar un recuadro superpuesto de solo lectura con:
- El Tipo de movimiento, con el mismo ícono y color que su fila.
- El valor con signo según la Cuenta enfocada en el carrusel, con el mismo signo y color que su fila.
- La descripción.
- La fecha.
- La Cuenta origen.
- Si es Transferencia, la Cuenta destino.

El recuadro MUST NOT tener acciones. Un toque sencillo sobre una fila MUST NOT abrir nada.

#### Scenario: Ver el detalle de un Gasto
- **WHEN** el usuario mantiene presionada la fila de un Gasto "Compra de café" de -$ 10.000,00 del 30/09/2026 en "Nómina"
- **THEN** se ve un recuadro con "Gasto", "-$ 10.000,00", "Compra de café", "30 sep 2026" y "Nómina"
- **AND** no hay campo Cuenta destino ni botones de acción

#### Scenario: Ver el detalle de una Transferencia
- **WHEN** el usuario mantiene presionada la fila de una Transferencia de "Nómina" a "Ahorros casa"
- **THEN** el recuadro muestra también la Cuenta destino "Ahorros casa"

#### Scenario: Detalle de una Transferencia vista desde la Cuenta origen
- **WHEN** existe una Transferencia de $ 10.000,00 de "Cuenta1" (Cuenta de Ahorros) a "Tarjeta1" (Tarjeta de Crédito), el carrusel está en "Cuenta1" y el usuario mantiene presionada su fila
- **THEN** el recuadro muestra "Transferencia" y "-$ 10.000,00" en rojo, igual que la fila

#### Scenario: Detalle de una Transferencia vista desde una Tarjeta de Crédito destino
- **WHEN** existe una Transferencia de $ 10.000,00 de "Cuenta1" a "Tarjeta1", el carrusel está en "Tarjeta1" y el usuario mantiene presionada su fila
- **THEN** el recuadro muestra "Transferencia" y "-$ 10.000,00" en verde, igual que la fila

#### Scenario: Detalle de una Transferencia vista desde una Cuenta de Ahorros destino
- **WHEN** existe una Transferencia de $ 20.000,00 de "Nómina" a "Ahorros casa", el carrusel está en "Ahorros casa" y el usuario mantiene presionada su fila
- **THEN** el recuadro muestra "Transferencia" y "$ 20.000,00" en verde, igual que la fila

#### Scenario: Toque sencillo
- **WHEN** el usuario toca una vez una fila
- **THEN** no se abre ninguna pantalla, menú ni recuadro

### Requirement: Accesibilidad de los Movimientos
VoiceOver MUST leer cada fila como un solo elemento con el Tipo de movimiento, la descripción, la fecha completa y el valor con su signo en palabras. Las acciones de editar y eliminar MUST estar disponibles como acciones de accesibilidad de la fila. El formulario y el detalle MUST respetar el tamaño de texto dinámico sin romper el diseño.

#### Scenario: VoiceOver en una fila
- **WHEN** VoiceOver enfoca la fila de un Gasto "Compra de café" de -$ 10.000,00 del 30/09/2026
- **THEN** VoiceOver lee "Gasto, Compra de café, 30 de septiembre de 2026, menos 10.000 pesos"

#### Scenario: Acciones con VoiceOver
- **WHEN** VoiceOver enfoca una fila y el usuario abre las acciones
- **THEN** están disponibles las acciones para editar y para eliminar el Movimiento

#### Scenario: Texto dinámico grande
- **WHEN** el usuario tiene un tamaño de texto de accesibilidad grande
- **THEN** las filas, el formulario y el detalle muestran su contenido completo sin superponerse
