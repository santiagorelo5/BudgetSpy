# Spec Delta: accounts

## Purpose

Permite al usuario gestionar sus Cuentas (crear, ver, editar y eliminar) para separar su dinero dentro de BudgetSpy, y verlas como tarjetas gráficas en el Inicio.

## ADDED Requirements

### Requirement: Datos de una Cuenta
El sistema MUST guardar para cada Cuenta: nombre, últimos 4 dígitos de la tarjeta, balance, límite (solo para Tarjeta de Crédito), Tipo de cuenta y fecha de creación. El sistema MUST NOT guardar el número completo de la tarjeta. Los importes MUST estar en pesos colombianos con 2 decimales y mostrarse con el formato `$ 1.000,00`.

#### Scenario: Cuenta de Ahorros guardada sin límite
- **WHEN** el usuario crea una Cuenta de Ahorros "Nómina Bancolombia", número "4821" y saldo $ 1.250.000,00
- **THEN** la Cuenta queda guardada con esos datos y sin límite

#### Scenario: Tarjeta de Crédito guardada con deuda en positivo
- **WHEN** el usuario crea una Tarjeta de Crédito con deuda a la fecha $ 1.200.000,00 y límite $ 5.000.000,00
- **THEN** la Cuenta queda guardada con balance $ 1.200.000,00 (positivo) y límite $ 5.000.000,00

#### Scenario: Nombres repetidos permitidos
- **WHEN** el usuario crea una Cuenta con el mismo nombre de una Cuenta existente
- **THEN** la Cuenta se crea sin error y ambas aparecen en el carrusel

### Requirement: Validación del formulario de Cuenta
El sistema MUST considerar inválido el formulario de Cuenta cuando: el nombre está vacío o solo tiene espacios; el nombre supera 20 caracteres; el número de tarjeta no tiene exactamente 4 caracteres numéricos; el balance es menor que 0; o, en Tarjeta de Crédito, el límite es 0 o es menor que la deuda a la fecha. Mientras el formulario sea inválido, el botón principal MUST estar deshabilitado. Cada campo inválido que el usuario ya haya modificado MUST mostrar su mensaje de error debajo del campo.

#### Scenario: Nombre vacío
- **WHEN** el usuario escribe un nombre y luego lo borra por completo
- **THEN** debajo del campo nombre se muestra el error "Ingresa un nombre"
- **AND** el botón principal está deshabilitado

#### Scenario: Nombre con más de 20 caracteres
- **WHEN** el usuario intenta escribir un nombre de más de 20 caracteres
- **THEN** el campo no acepta caracteres más allá del carácter 20

#### Scenario: Número de tarjeta incompleto
- **WHEN** el usuario escribe "482" en el número de tarjeta
- **THEN** debajo del campo se muestra el error "Ingresa los últimos 4 dígitos"
- **AND** el botón principal está deshabilitado

#### Scenario: Número de tarjeta con caracteres no numéricos
- **WHEN** el usuario intenta ingresar "48A1" en el número de tarjeta
- **THEN** el campo solo acepta los caracteres numéricos y no acepta más de 4

#### Scenario: Límite menor que la deuda
- **WHEN** el Tipo de cuenta es Tarjeta de Crédito, la deuda a la fecha es $ 1.200.000,00 y el límite es $ 1.000.000,00
- **THEN** debajo del campo límite se muestra el error "El límite debe ser mayor o igual a la deuda"
- **AND** el botón principal está deshabilitado

#### Scenario: Límite faltante en Tarjeta de Crédito
- **WHEN** el Tipo de cuenta es Tarjeta de Crédito y el límite queda en $ 0,00 después de que el usuario lo modificó
- **THEN** debajo del campo límite se muestra el error "Ingresa un límite mayor a 0"
- **AND** el botón principal está deshabilitado

#### Scenario: Formulario nuevo sin datos
- **WHEN** el usuario abre el formulario para crear y aún no ha escrito nada
- **THEN** el botón principal está deshabilitado
- **AND** no se muestra ningún mensaje de error

#### Scenario: Formulario válido
- **WHEN** el nombre, el número de tarjeta, el balance y, si aplica, el límite cumplen las reglas
- **THEN** el botón principal está habilitado y no se muestran errores

### Requirement: Ingreso de importes en el formulario
El sistema MUST mostrar los campos de balance y límite iniciando en `$ 0,00`. Cada dígito ingresado MUST agregarse a la derecha (desplazando los decimales) y cada borrado MUST quitar el último dígito hasta volver a `$ 0,00`. El usuario MUST NOT poder ingresar signos ni cambiar el signo del importe.

#### Scenario: Digitar un importe
- **WHEN** el campo muestra `$ 0,00` y el usuario digita 1, 2, 5, 0, 0, 0
- **THEN** el campo muestra `$ 1.250,00`

#### Scenario: Borrar un importe
- **WHEN** el campo muestra `$ 1.250,00` y el usuario borra 6 veces
- **THEN** el campo muestra `$ 0,00`

#### Scenario: Intentar ingresar un signo
- **WHEN** el usuario intenta escribir "-" en el campo de balance
- **THEN** el importe no cambia y sigue siendo mayor o igual a 0

### Requirement: Formulario de Cuenta con tarjeta gráfica en vivo
El formulario de Cuenta MUST mostrar una tarjeta gráfica en la parte superior y debajo todos los campos. Cada cambio en el nombre, el número de tarjeta, el balance o el Tipo de cuenta MUST reflejarse de inmediato en la tarjeta gráfica del formulario.

#### Scenario: La tarjeta refleja lo que se escribe
- **WHEN** el usuario escribe el nombre "Nómina", el número "4821" y el saldo $ 500.000,00
- **THEN** la tarjeta gráfica del formulario muestra "Nómina", "**** 4821" y "$ 500.000,00" mientras el usuario escribe

#### Scenario: Tarjeta gráfica sin datos
- **WHEN** el usuario abre el formulario para crear
- **THEN** la tarjeta gráfica muestra el Tipo de cuenta "Cuenta de Ahorros", un nombre de ejemplo atenuado, "**** ----" y "$ 0,00"

### Requirement: Campos según el Tipo de cuenta
Al crear una Cuenta, el formulario MUST traer seleccionado el Tipo de cuenta "Cuenta de Ahorros". Con Cuenta de Ahorros, el campo balance MUST titularse "Saldo en la cuenta" y el campo límite MUST NOT mostrarse. Con Tarjeta de Crédito, el campo balance MUST titularse "Deuda a la fecha" y el campo límite MUST mostrarse. Al pasar de Tarjeta de Crédito a Cuenta de Ahorros, el valor del límite MUST descartarse.

#### Scenario: Tipo por defecto al crear
- **WHEN** el usuario abre el formulario para crear una Cuenta
- **THEN** el Tipo de cuenta seleccionado es "Cuenta de Ahorros"
- **AND** el balance se titula "Saldo en la cuenta" y el campo límite no se ve

#### Scenario: Seleccionar Tarjeta de Crédito
- **WHEN** el usuario selecciona "Tarjeta de Crédito"
- **THEN** el balance se titula "Deuda a la fecha" y el campo límite se ve

#### Scenario: Volver a Cuenta de Ahorros descarta el límite
- **WHEN** el usuario selecciona Tarjeta de Crédito, escribe un límite de $ 3.000.000,00 y vuelve a seleccionar Cuenta de Ahorros
- **THEN** el campo límite deja de verse
- **AND** si vuelve a seleccionar Tarjeta de Crédito, el límite muestra $ 0,00
- **AND** si guarda como Cuenta de Ahorros, la Cuenta se guarda sin límite

#### Scenario: Tipo bloqueado al editar
- **WHEN** el usuario abre el formulario para editar una Cuenta existente
- **THEN** el Tipo de cuenta se muestra con el valor de la Cuenta y no se puede cambiar

### Requirement: Botones del formulario de Cuenta
El formulario MUST tener el botón principal en la parte superior derecha, con el texto "Crear cuenta" al crear y "Guardar cambios" al editar, y MUST tener un botón para regresar en la parte superior izquierda.

#### Scenario: Botón al crear
- **WHEN** el usuario abre el formulario para crear
- **THEN** en la esquina superior derecha se ve el botón "Crear cuenta"
- **AND** en la esquina superior izquierda se ve el botón para regresar

#### Scenario: Botón al editar
- **WHEN** el usuario abre el formulario para editar
- **THEN** en la esquina superior derecha se ve el botón "Guardar cambios"

### Requirement: Crear y guardar una Cuenta
Al tocar el botón principal con un formulario válido, el sistema MUST guardar la Cuenta (nueva o editada), volver al Inicio y mostrar las tarjetas con los datos actualizados. Si el guardado falla, el sistema MUST mostrar un aviso y MUST mantener al usuario en el formulario con sus datos.

#### Scenario: Crear una Cuenta de Ahorros
- **WHEN** el usuario llena nombre "Nómina", número "4821", saldo $ 1.000.000,00 y toca "Crear cuenta"
- **THEN** vuelve al Inicio y aparece la tarjeta de la nueva Cuenta antes de la tarjeta "+"

#### Scenario: Crear una Tarjeta de Crédito
- **WHEN** el usuario selecciona Tarjeta de Crédito, llena nombre "Visa", número "1234", deuda $ 1.200.000,00, límite $ 5.000.000,00 y toca "Crear cuenta"
- **THEN** vuelve al Inicio y aparece la tarjeta "Visa" con deuda $ 1.200.000,00

#### Scenario: Guardar cambios de una Cuenta
- **WHEN** el usuario edita el nombre de una Cuenta a "Ahorros casa" y toca "Guardar cambios"
- **THEN** vuelve al Inicio y la tarjeta de esa Cuenta muestra "Ahorros casa" en la misma posición del carrusel

#### Scenario: Falla al guardar
- **WHEN** el usuario toca el botón principal y el guardado falla
- **THEN** se muestra el aviso "No se pudo guardar la cuenta. Intenta de nuevo."
- **AND** el usuario sigue en el formulario con los datos que había ingresado

### Requirement: Regresar desde el formulario de Cuenta
Al tocar el botón para regresar, si hubo cambios respecto a los valores con los que se abrió el formulario, el sistema MUST preguntar si desea descartarlos. Si no hubo cambios, el sistema MUST volver al Inicio sin preguntar. El sistema MUST NOT permitir salir del formulario con cambios sin pasar por esta pregunta.

#### Scenario: Regresar sin cambios
- **WHEN** el usuario abre el formulario y toca regresar sin modificar nada
- **THEN** vuelve al Inicio sin ninguna pregunta

#### Scenario: Regresar con cambios y descartar
- **WHEN** el usuario modifica algún campo, toca regresar y confirma "Descartar cambios"
- **THEN** vuelve al Inicio y no se guarda nada

#### Scenario: Regresar con cambios y seguir editando
- **WHEN** el usuario modifica algún campo, toca regresar y elige "Seguir editando"
- **THEN** permanece en el formulario con los datos que había ingresado

#### Scenario: Cambios revertidos a los valores iniciales
- **WHEN** el usuario cambia un campo y luego lo deja igual a su valor inicial, y toca regresar
- **THEN** vuelve al Inicio sin ninguna pregunta

### Requirement: Carrusel de Cuentas en Inicio
El Inicio MUST mostrar en su parte superior las Cuentas como tarjetas gráficas en un carrusel horizontal que se desliza, ordenadas por fecha de creación (la más antigua primero). Al final del carrusel MUST aparecer siempre una tarjeta vacía con el signo "+" que abre el formulario para crear una Cuenta.

#### Scenario: Sin Cuentas
- **WHEN** el usuario no tiene Cuentas y abre el Inicio
- **THEN** el carrusel muestra solo la tarjeta "+"

#### Scenario: Varias Cuentas
- **WHEN** el usuario tiene 3 Cuentas
- **THEN** puede deslizar horizontalmente entre las 3 tarjetas en el orden en que las creó
- **AND** la última tarjeta del carrusel es la tarjeta "+"

#### Scenario: Tocar la tarjeta "+"
- **WHEN** el usuario toca la tarjeta "+"
- **THEN** se abre el formulario para crear una Cuenta

### Requirement: Contenido de la tarjeta gráfica
Cada tarjeta gráfica MUST mostrar el nombre completo del Tipo de cuenta, el nombre de la Cuenta, "**** " seguido de los últimos 4 dígitos y el balance. En Cuenta de Ahorros el balance es el saldo disponible; en Tarjeta de Crédito es la deuda a la fecha, siempre como valor positivo. Las tarjetas MUST verse legibles en modo claro y oscuro, y el texto MUST respetar el tamaño de texto dinámico.

#### Scenario: Tarjeta de Cuenta de Ahorros
- **WHEN** existe la Cuenta de Ahorros "Nómina" con número "4821" y saldo $ 1.250.000,00
- **THEN** su tarjeta muestra "Cuenta de Ahorros", "Nómina", "**** 4821" y "$ 1.250.000,00"

#### Scenario: Tarjeta de Tarjeta de Crédito
- **WHEN** existe la Tarjeta de Crédito "Visa" con número "1234" y deuda $ 1.200.000,00
- **THEN** su tarjeta muestra "Tarjeta de Crédito", "Visa", "**** 1234" y "$ 1.200.000,00" sin signo negativo

#### Scenario: Balance en cero
- **WHEN** una Cuenta tiene balance $ 0,00
- **THEN** su tarjeta muestra "$ 0,00"

#### Scenario: Modo oscuro
- **WHEN** el dispositivo está en modo oscuro
- **THEN** las tarjetas y el formulario de Cuenta se ven legibles

### Requirement: Accesibilidad de las tarjetas
VoiceOver MUST leer cada tarjeta de Cuenta como un solo elemento que incluye el Tipo de cuenta, el nombre, los últimos 4 dígitos y el balance, y MUST leer la tarjeta "+" como "Agregar cuenta".

#### Scenario: VoiceOver en una tarjeta de Cuenta
- **WHEN** VoiceOver enfoca la tarjeta de la Cuenta de Ahorros "Nómina", número "4821", saldo $ 1.250.000,00
- **THEN** VoiceOver lee el Tipo de cuenta, "Nómina", "terminada en 4821" y el saldo $ 1.250.000,00

#### Scenario: VoiceOver en la tarjeta "+"
- **WHEN** VoiceOver enfoca la tarjeta "+"
- **THEN** VoiceOver lee "Agregar cuenta" como botón

### Requirement: Menú de acciones de una tarjeta
Al mantener presionada la tarjeta de una Cuenta, el sistema MUST mostrar un menú con las opciones "Editar" y "Eliminar". Un toque sencillo sobre la tarjeta de una Cuenta MUST NOT abrir nada. La tarjeta "+" MUST NOT mostrar este menú.

#### Scenario: Mantener presionada una tarjeta
- **WHEN** el usuario mantiene presionada la tarjeta de una Cuenta
- **THEN** aparece un menú con "Editar" y "Eliminar"

#### Scenario: Toque sencillo
- **WHEN** el usuario toca una vez la tarjeta de una Cuenta
- **THEN** no se abre ninguna pantalla ni menú

#### Scenario: Editar desde el menú
- **WHEN** el usuario elige "Editar" en el menú de una Cuenta
- **THEN** se abre el formulario con todos los datos de esa Cuenta cargados y el botón "Guardar cambios"

### Requirement: Eliminar una Cuenta
Al elegir "Eliminar", el sistema MUST pedir confirmación antes de eliminar. Si el usuario confirma, la Cuenta MUST eliminarse de forma definitiva y su tarjeta MUST desaparecer del carrusel. Si cancela, nada cambia.

#### Scenario: Confirmar eliminación
- **WHEN** el usuario elige "Eliminar" y confirma "Eliminar cuenta"
- **THEN** la tarjeta de esa Cuenta desaparece del carrusel
- **AND** la Cuenta no vuelve a aparecer al cerrar y abrir la app

#### Scenario: Cancelar eliminación
- **WHEN** el usuario elige "Eliminar" y luego "Cancelar"
- **THEN** la tarjeta sigue en el carrusel sin cambios

#### Scenario: Eliminar la única Cuenta
- **WHEN** el usuario elimina su única Cuenta
- **THEN** el carrusel muestra solo la tarjeta "+"

#### Scenario: Falla al eliminar
- **WHEN** el usuario confirma la eliminación y esta falla
- **THEN** se muestra el aviso "No se pudo eliminar la cuenta. Intenta de nuevo."
- **AND** la tarjeta sigue en el carrusel
