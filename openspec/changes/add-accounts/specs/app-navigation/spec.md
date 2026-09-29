# Spec Delta

## REMOVED Requirements

### Requirement: Pantallas principales vacías con título
**Reason**: Inicio y Configuración dejan de estar vacías. Inicio muestra el carrusel de Cuentas y Configuración muestra la lista de Datos Maestros.
**Migration**: Lo reemplaza el requisito "Contenido de las pantallas principales" de esta misma capability.

## ADDED Requirements

### Requirement: Contenido de las pantallas principales
El sistema MUST mostrar la pantalla de Inicio con el título "Inicio" y la pantalla de Configuración con el título "Configuración". Debajo del título, Inicio MUST mostrar únicamente el carrusel de Cuentas (capability `accounts`) y Configuración MUST mostrar únicamente la lista de Datos Maestros (capability `account-types`), sin ningún otro contenido.

#### Scenario: Pantalla de Inicio
- **WHEN** se muestra la pantalla de Inicio
- **THEN** se ve el título "Inicio" y, debajo, el carrusel de Cuentas terminado en la tarjeta "+"
- **AND** no se ve ningún otro contenido

#### Scenario: Pantalla de Inicio sin Cuentas
- **WHEN** se muestra la pantalla de Inicio y el usuario no tiene Cuentas
- **THEN** se ve el título "Inicio" y solo la tarjeta "+"

#### Scenario: Pantalla de Configuración
- **WHEN** se muestra la pantalla de Configuración
- **THEN** se ve el título "Configuración" y una lista con el único ítem "Datos Maestros"
- **AND** no se ve ningún otro contenido
