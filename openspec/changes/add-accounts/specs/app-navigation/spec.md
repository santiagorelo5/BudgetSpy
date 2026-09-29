# Spec Delta: app-navigation

## ADDED Requirements

### Requirement: Contenido de las pantallas principales
El sistema MUST mostrar la pantalla de Inicio sin título y con el carrusel de Cuentas en su parte superior como único contenido (ver capability `accounts`). El sistema MUST mostrar la pantalla de Configuración con el título "Configuración" y una lista con el único ítem "Datos Maestros" (ver capability `account-types`).

#### Scenario: Pantalla de Inicio
- **WHEN** se muestra la pantalla de Inicio
- **THEN** no se ve ningún título
- **AND** se ve el carrusel de Cuentas en la parte superior como único contenido
- **AND** la barra de navegación inferior sigue visible con la opción "Inicio" seleccionada

#### Scenario: Pantalla de Inicio sin Cuentas
- **WHEN** se muestra la pantalla de Inicio y el usuario no tiene Cuentas
- **THEN** el carrusel muestra solo la tarjeta "+"

#### Scenario: Pantalla de Configuración
- **WHEN** se muestra la pantalla de Configuración
- **THEN** se ve el título "Configuración" y una lista con el único ítem "Datos Maestros"

### Requirement: Visibilidad de la barra de navegación en pantallas internas
El sistema MUST ocultar la barra de navegación inferior mientras el formulario de Cuenta (crear o editar) esté abierto, y MUST volver a mostrarla al salir de él. En Configuración y en todas sus pantallas internas (Datos Maestros, Tipos de cuenta) la barra MUST permanecer visible.

#### Scenario: Formulario para crear
- **WHEN** el usuario toca la tarjeta "+" en Inicio
- **THEN** en el formulario de Cuenta no se ve la barra de navegación inferior

#### Scenario: Formulario para editar
- **WHEN** el usuario elige "Editar" en el menú de una tarjeta
- **THEN** en el formulario de Cuenta no se ve la barra de navegación inferior

#### Scenario: Volver al Inicio
- **WHEN** el usuario sale del formulario de Cuenta, ya sea guardando o regresando
- **THEN** vuelve al Inicio y la barra de navegación inferior se ve de nuevo

#### Scenario: Pantallas internas de Configuración
- **WHEN** el usuario navega a Datos Maestros y luego a Tipos de cuenta
- **THEN** la barra de navegación inferior se ve en todo momento

## REMOVED Requirements

### Requirement: Pantallas principales vacías
**Reason**: Inicio y Configuración dejan de estar vacías: Inicio muestra el carrusel de Cuentas y Configuración muestra "Datos Maestros".
**Migration**: Reemplazado por el requisito "Contenido de las pantallas principales" de esta misma capability.
