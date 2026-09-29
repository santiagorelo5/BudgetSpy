# Spec Delta

## Purpose

Permite al usuario gestionar sus Cuentas financieras dentro de la app: crearlas, editarlas y eliminarlas, verlas como tarjetas en Inicio y capturar sus importes monetarios de forma consistente.

## ADDED Requirements

### Requirement: Datos de una Cuenta
Cada Cuenta MUST guardar:
- nombre: obligatorio, de 1 a 30 caracteres después de quitar espacios al inicio y al final.
- últimos 4 dígitos de la tarjeta: obligatorio, exactamente 4 caracteres numéricos.
- balance: obligatorio, importe en COP ≥ 0 con 2 decimales.
- límite: importe en COP.
- Tipo de cuenta: obligatorio.

Si el Tipo de cuenta es "Tarjeta de Crédito", el límite MUST ser obligatorio, ≥ 0 y ≥ al balance. Si el Tipo de cuenta es "Cuenta de Ahorros", el límite MUST guardarse siempre vacío. El sistema MUST NOT guardar una Cuenta que incumpla alguna de estas reglas. El Tipo de cuenta de una Cuenta MUST NOT cambiar después de creada.

#### Scenario: Crear Cuenta de Ahorros válida
- **WHEN** el usuario crea una Cuenta de tipo "Cuenta de Ahorros" con nombre "Nómina", dígitos "1234" y saldo $ 0,00
- **THEN** la Cuenta se guarda con balance $ 0,00 y límite vacío

#### Scenario: Crear Tarjeta de Crédito válida con ceros
- **WHEN** el usuario crea una Cuenta de tipo "Tarjeta de Crédito" con nombre "Visa", dígitos "9876", deuda $ 0,00 y límite $ 0,00
- **THEN** la Cuenta se guarda

#### Scenario: Nombre vacío
- **WHEN** el nombre está vacío o solo tiene espacios
- **THEN** el sistema no permite crear ni guardar la Cuenta e indica que el nombre es obligatorio

#### Scenario: Dígitos incompletos
- **WHEN** el campo de dígitos tiene menos de 4 dígitos
- **THEN** el sistema no permite crear ni guardar la Cuenta e indica que se requieren los últimos 4 dígitos

#### Scenario: Límite menor que la deuda
- **WHEN** el tipo es "Tarjeta de Crédito", la deuda es $ 500.000,00 y el límite es $ 300.000,00
- **THEN** el sistema no permite crear ni guardar la Cuenta e indica que el límite debe ser mayor o igual a la deuda

#### Scenario: Límite igual a la deuda
- **WHEN** el tipo es "Tarjeta de Crédito", la deuda es $ 300.000,00 y el límite es $ 300.000,00
- **THEN** la Cuenta se guarda

### Requirement: Entrada de importes monetarios
Los campos monetarios del formulario (balance y límite) MUST mostrar siempre un importe con formato `$ 0,00`. Cada dígito que escribe el usuario MUST entrar por la derecha y desplazar los demás hacia la izquierda. Cada borrado MUST quitar el dígito más a la derecha, hasta volver a `$ 0,00`. El usuario MUST NOT poder escribir signos ni caracteres no numéricos, ni cambiar el signo del importe. Todos los importes MUST mostrarse con el formato `$ 1.000,00`.

#### Scenario: Escribir un importe
- **WHEN** el campo muestra `$ 0,00` y el usuario escribe 1, 2, 5, 0 y 0
- **THEN** el campo muestra sucesivamente `$ 0,01`, `$ 0,12`, `$ 1,25`, `$ 12,50` y `$ 125,00`

#### Scenario: Borrar dígitos
- **WHEN** el campo muestra `$ 125,00` y el usuario borra tres veces
- **THEN** el campo muestra sucesivamente `$ 12,50`, `$ 1,25` y `$ 0,12`

#### Scenario: Borrar con el campo en cero
- **WHEN** el campo muestra `$ 0,00` y el usuario borra
- **THEN** el campo sigue mostrando `$ 0,00`

#### Scenario: Intentar escribir un signo
- **WHEN** el usuario intenta escribir "-", "+", "," o una letra en un campo monetario
- **THEN** el importe no cambia

### Requirement: Formulario de Cuenta
El sistema MUST ofrecer un formulario para crear y para editar una Cuenta, organizado así:
- Arriba: una tarjeta gráfica con diseño de tarjeta de crédito.
- Abajo: los campos Tipo de cuenta, nombre, últimos 4 dígitos, balance y, solo para "Tarjeta de Crédito", límite.

Al crear, el formulario MUST abrir con el Tipo de cuenta "Cuenta de Ahorros" seleccionado y los importes en `$ 0,00`. Al editar, el formulario MUST abrir con los datos guardados de la Cuenta, y el Tipo de cuenta MUST mostrarse en solo lectura, sin ningún control que permita cambiarlo. Si el usuario se equivocó de Tipo de cuenta, debe crear otra Cuenta. El campo balance MUST llamarse "Saldo en la cuenta" en "Cuenta de Ahorros" y "Deuda a la fecha" en "Tarjeta de Crédito". El campo de dígitos MUST aceptar solo dígitos y como máximo 4.

#### Scenario: Abrir formulario de creación
- **WHEN** el usuario abre el formulario para crear una Cuenta
- **THEN** el Tipo de cuenta seleccionado es "Cuenta de Ahorros"
- **AND** el campo balance se llama "Saldo en la cuenta" y muestra `$ 0,00`
- **AND** el campo límite no se muestra

#### Scenario: Cambiar a Tarjeta de Crédito
- **WHEN** el usuario está creando una Cuenta y selecciona el tipo "Tarjeta de Crédito"
- **THEN** el campo balance pasa a llamarse "Deuda a la fecha"
- **AND** aparece el campo límite con `$ 0,00`

#### Scenario: Volver a Cuenta de Ahorros
- **WHEN** el usuario está creando una Cuenta, tenía seleccionado "Tarjeta de Crédito" con un límite escrito y selecciona "Cuenta de Ahorros"
- **THEN** el campo límite se oculta
- **AND** al guardar, el límite queda vacío

#### Scenario: Escribir más de 4 dígitos o letras
- **WHEN** el usuario intenta escribir "12a345" en el campo de dígitos
- **THEN** el campo muestra "1234"

#### Scenario: Abrir formulario de edición
- **WHEN** el usuario elige "Editar" sobre una Tarjeta de Crédito "Visa" con dígitos "9876", deuda $ 200.000,00 y límite $ 1.000.000,00
- **THEN** el formulario muestra esos datos en sus campos y en la tarjeta gráfica

#### Scenario: Tipo de cuenta bloqueado al editar
- **WHEN** el usuario edita una Cuenta de tipo "Tarjeta de Crédito"
- **THEN** el formulario muestra el Tipo de cuenta "Tarjeta de Crédito" como texto de solo lectura
- **AND** no hay ningún control para cambiarlo a "Cuenta de Ahorros"
- **AND** el campo balance sigue llamándose "Deuda a la fecha" y el campo límite sigue visible

### Requirement: Tarjeta gráfica en vivo
La tarjeta gráfica del formulario MUST reflejar los datos del formulario a medida que el usuario los escribe. Tanto la tarjeta del formulario como las tarjetas de Inicio MUST mostrar:
- el nombre completo del Tipo de cuenta;
- el nombre de la Cuenta;
- el número de tarjeta como `**** ` seguido de los últimos 4 dígitos;
- el importe del balance con su etiqueta: "Saldo disponible" en "Cuenta de Ahorros" y "Deuda a la fecha" en "Tarjeta de Crédito", siempre en positivo.

#### Scenario: Escribir el nombre
- **WHEN** el usuario escribe "Nómina" en el campo nombre
- **THEN** la tarjeta gráfica muestra "Nómina" mientras escribe

#### Scenario: Datos aún vacíos
- **WHEN** el formulario de creación acaba de abrirse
- **THEN** la tarjeta muestra "Cuenta de Ahorros", un texto de ejemplo en lugar del nombre, `**** ••••` como número y "Saldo disponible" con `$ 0,00`

#### Scenario: Tarjeta de Crédito en la tarjeta gráfica
- **WHEN** el tipo es "Tarjeta de Crédito", los dígitos son "9876" y la deuda es $ 200.000,00
- **THEN** la tarjeta muestra "Tarjeta de Crédito", `**** 9876` y "Deuda a la fecha" con `$ 200.000,00`

### Requirement: Guardar y regresar desde el formulario
El formulario MUST mostrar el botón "Crear cuenta" al crear y "Guardar cambios" al editar. Ese botón MUST estar deshabilitado mientras los datos no cumplan las reglas de la Cuenta. Al crear o guardar con éxito, el sistema MUST volver a Inicio, donde se ven los datos actualizados.

El formulario MUST tener un botón para regresar a Inicio:
- Si hay cambios sin guardar, MUST preguntar si el usuario desea perder los cambios antes de regresar.
- Si no hay cambios, MUST regresar sin preguntar.

Mientras el formulario está abierto, el sistema MUST ocultar la barra de navegación inferior, para que no se pueda salir del formulario sin pasar por la confirmación. Al volver a Inicio, la barra MUST mostrarse de nuevo sin cambios.

#### Scenario: Barra inferior oculta en el formulario
- **WHEN** el usuario abre el formulario de crear o editar una Cuenta
- **THEN** la barra de navegación inferior no se muestra
- **AND** al volver a Inicio, la barra se muestra de nuevo con "Inicio" seleccionado

#### Scenario: Crear cuenta
- **WHEN** el usuario completa datos válidos y toca "Crear cuenta"
- **THEN** vuelve a Inicio y la nueva Cuenta aparece en el carrusel

#### Scenario: Guardar cambios
- **WHEN** el usuario cambia el nombre de una Cuenta de "Visa" a "Visa Oro" y toca "Guardar cambios"
- **THEN** vuelve a Inicio y la tarjeta muestra "Visa Oro"

#### Scenario: Botón deshabilitado con datos inválidos
- **WHEN** falta el nombre o los dígitos, o el límite es menor que la deuda
- **THEN** el botón "Crear cuenta" o "Guardar cambios" está deshabilitado

#### Scenario: Regresar con cambios y confirmar
- **WHEN** el usuario modificó algún campo y toca el botón de regresar
- **THEN** el sistema pregunta si desea perder los cambios
- **AND** si confirma, vuelve a Inicio sin guardar

#### Scenario: Regresar con cambios y cancelar
- **WHEN** el sistema pregunta si desea perder los cambios y el usuario cancela
- **THEN** permanece en el formulario con sus datos intactos

#### Scenario: Regresar sin cambios
- **WHEN** el usuario no modificó ningún campo y toca el botón de regresar
- **THEN** vuelve a Inicio sin que se le pregunte nada

#### Scenario: Error al guardar
- **WHEN** el guardado de la Cuenta falla
- **THEN** el sistema muestra un mensaje de error, permanece en el formulario y conserva los datos escritos

### Requirement: Carrusel de Cuentas en Inicio
La parte superior de Inicio MUST mostrar todas las Cuentas como tarjetas con diseño de tarjeta de crédito, en una fila horizontal que el usuario puede deslizar. Las tarjetas MUST estar ordenadas por fecha de creación, de la más antigua a la más reciente. Al final MUST aparecer siempre una tarjeta vacía con el signo "+", que abre el formulario para crear una Cuenta. Un toque sencillo sobre una tarjeta de Cuenta MUST NOT tener efecto.

#### Scenario: Ver todas las Cuentas
- **WHEN** el usuario tiene 3 Cuentas
- **THEN** Inicio muestra 3 tarjetas seguidas de la tarjeta "+"
- **AND** el usuario puede deslizar horizontalmente para verlas todas

#### Scenario: Sin Cuentas
- **WHEN** el usuario no tiene Cuentas
- **THEN** Inicio muestra solo la tarjeta "+"

#### Scenario: Tocar la tarjeta "+"
- **WHEN** el usuario toca la tarjeta "+"
- **THEN** se abre el formulario para crear una Cuenta

#### Scenario: Toque sencillo sobre una Cuenta
- **WHEN** el usuario toca una vez una tarjeta de Cuenta
- **THEN** no sucede nada

### Requirement: Menú de acciones sobre una Cuenta
Al mantener presionada una tarjeta de Cuenta en Inicio, el sistema MUST mostrar un menú con las opciones "Editar" y "Eliminar":
- "Editar" MUST abrir el formulario de edición de esa Cuenta.
- "Eliminar" MUST pedir confirmación antes de eliminar la Cuenta. Si el usuario confirma, la Cuenta desaparece del carrusel. Si cancela, no cambia nada.

La tarjeta "+" MUST NOT mostrar este menú.

#### Scenario: Abrir el menú
- **WHEN** el usuario mantiene presionada una tarjeta de Cuenta
- **THEN** aparece un menú con "Editar" y "Eliminar"

#### Scenario: Editar desde el menú
- **WHEN** el usuario elige "Editar"
- **THEN** se abre el formulario de edición con los datos de esa Cuenta

#### Scenario: Eliminar confirmado
- **WHEN** el usuario elige "Eliminar" y confirma
- **THEN** la Cuenta se elimina y deja de aparecer en el carrusel

#### Scenario: Eliminar cancelado
- **WHEN** el usuario elige "Eliminar" y cancela la confirmación
- **THEN** la Cuenta sigue existiendo sin cambios

#### Scenario: Eliminar la única Cuenta
- **WHEN** el usuario elimina su única Cuenta
- **THEN** Inicio muestra solo la tarjeta "+"

#### Scenario: Mantener presionada la tarjeta "+"
- **WHEN** el usuario mantiene presionada la tarjeta "+"
- **THEN** no aparece el menú de Editar/Eliminar

### Requirement: Accesibilidad de las tarjetas
Cada tarjeta de Cuenta MUST ser un único elemento para VoiceOver. VoiceOver MUST anunciar el Tipo de cuenta, el nombre, los últimos 4 dígitos y el importe con su etiqueta, y MUST ofrecer las acciones "Editar" y "Eliminar". La tarjeta "+" MUST anunciarse como "Agregar cuenta". Los textos de las tarjetas y del formulario MUST respetar Dynamic Type y el modo claro/oscuro.

#### Scenario: VoiceOver sobre una tarjeta
- **WHEN** VoiceOver enfoca la tarjeta de Ahorros "Nómina" con dígitos "1234" y saldo $ 50.000,00
- **THEN** anuncia "Cuenta de Ahorros, Nómina, terminada en 1234, Saldo disponible $ 50.000,00"

#### Scenario: VoiceOver sobre la tarjeta "+"
- **WHEN** VoiceOver enfoca la tarjeta "+"
- **THEN** anuncia "Agregar cuenta" como botón
