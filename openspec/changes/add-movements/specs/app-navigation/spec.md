# Spec Delta: app-navigation

## MODIFIED Requirements

### Requirement: Contenido de las pantallas principales
El sistema MUST mostrar la pantalla de Inicio sin título, con el carrusel de Cuentas en su parte superior (ver capability `accounts`) y, debajo, la sección "Movimientos" de la Cuenta enfocada (ver capability `movements`). El carrusel MUST tener una altura fija, con la proporción de una tarjeta de crédito, que MUST NOT cambiar al cambiar de Cuenta ni según el contenido de la sección "Movimientos". El sistema MUST mostrar la pantalla de Configuración con el título "Configuración" y una lista con el único ítem "Datos Maestros" (ver capability `account-types`).

#### Scenario: Pantalla de Inicio
- **WHEN** se muestra la pantalla de Inicio y el carrusel está en una Cuenta
- **THEN** no se ve ningún título
- **AND** se ve el carrusel de Cuentas en la parte superior y la sección "Movimientos" debajo
- **AND** la barra de navegación inferior sigue visible con la opción "Inicio" seleccionada

#### Scenario: Pantalla de Inicio sin Cuentas
- **WHEN** se muestra la pantalla de Inicio y el usuario no tiene Cuentas
- **THEN** el carrusel muestra solo la tarjeta "+" y no se ve la sección "Movimientos"

#### Scenario: El carrusel mantiene su tamaño
- **WHEN** el usuario desliza el carrusel entre una Cuenta con 10 Movimientos, una sin Movimientos y la tarjeta "+"
- **THEN** el carrusel conserva la misma altura y las tarjetas conservan su proporción de tarjeta de crédito

#### Scenario: Pantalla de Configuración
- **WHEN** se muestra la pantalla de Configuración
- **THEN** se ve el título "Configuración" y una lista con el único ítem "Datos Maestros"

### Requirement: Visibilidad de la barra de navegación en pantallas internas
El sistema MUST ocultar la barra de navegación inferior mientras el formulario de Cuenta o el formulario de Movimiento (crear o editar) esté abierto. Al salir de ellos, MUST volver a mostrarla. En Configuración y en todas sus pantallas internas (Datos Maestros, Tipos de cuenta, Tipos de movimiento) la barra MUST permanecer visible.

#### Scenario: Formulario para crear
- **WHEN** el usuario toca la tarjeta "+" en Inicio
- **THEN** en el formulario de Cuenta no se ve la barra de navegación inferior

#### Scenario: Formulario para editar
- **WHEN** el usuario elige "Editar" en el menú de una tarjeta
- **THEN** en el formulario de Cuenta no se ve la barra de navegación inferior

#### Scenario: Formulario de Movimiento para crear
- **WHEN** el usuario toca el botón "+" de la sección "Movimientos" del Inicio
- **THEN** en el formulario de Movimiento no se ve la barra de navegación inferior

#### Scenario: Formulario de Movimiento para editar
- **WHEN** el usuario abre la edición de un Movimiento desde la lista
- **THEN** en el formulario de Movimiento no se ve la barra de navegación inferior

#### Scenario: Volver al Inicio
- **WHEN** el usuario sale del formulario de Cuenta o del formulario de Movimiento, ya sea guardando o regresando
- **THEN** vuelve al Inicio y la barra de navegación inferior se ve de nuevo

#### Scenario: Pantallas internas de Configuración
- **WHEN** el usuario navega a Datos Maestros y luego a Tipos de cuenta o a Tipos de movimiento
- **THEN** la barra de navegación inferior se ve en todo momento
