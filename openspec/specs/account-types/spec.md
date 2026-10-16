# account-types Specification

## Purpose

Define los Tipos de cuenta que clasifican cada Cuenta (Cuenta de Ahorros y Tarjeta de Crédito), cómo se crean como datos semilla y cómo el usuario los consulta desde Configuración → Datos Maestros.

## Requirements

### Requirement: Tipos de cuenta semilla
El sistema MUST tener exactamente 2 Tipos de cuenta, cada uno con nombre y abreviación de 2 letras: "Cuenta de Ahorros" (CA) y "Tarjeta de Crédito" (TC). El sistema MUST crearlos la primera vez que se abre la app y MUST NOT duplicarlos en aperturas posteriores. El usuario MUST NOT poder crear, editar ni eliminar Tipos de cuenta.

#### Scenario: Primera apertura
- **WHEN** el usuario abre la app por primera vez
- **THEN** existen los Tipos de cuenta "Cuenta de Ahorros" (CA) y "Tarjeta de Crédito" (TC)

#### Scenario: Aperturas repetidas
- **WHEN** el usuario cierra y abre la app varias veces
- **THEN** siguen existiendo exactamente 2 Tipos de cuenta, sin duplicados

#### Scenario: Falta uno de los Tipos de cuenta
- **WHEN** al abrir la app ya existe "Cuenta de Ahorros" (CA) pero no "Tarjeta de Crédito" (TC)
- **THEN** el sistema crea solo "Tarjeta de Crédito" (TC) y queda con exactamente 2 Tipos de cuenta

### Requirement: Datos Maestros en Configuración
La pantalla de Configuración MUST mostrar una lista con un único ítem, "Datos Maestros". Al tocarlo, el sistema MUST mostrar la pantalla "Datos Maestros" con una lista que tiene exactamente 2 ítems, en este orden: "Tipos de cuenta" y "Tipos de movimiento" (ver capability `movement-types`).

#### Scenario: Entrar a Datos Maestros
- **WHEN** el usuario está en Configuración y toca "Datos Maestros"
- **THEN** se muestra la pantalla "Datos Maestros" con los ítems "Tipos de cuenta" y "Tipos de movimiento", en ese orden

#### Scenario: Configuración solo tiene Datos Maestros
- **WHEN** se muestra la pantalla de Configuración
- **THEN** la lista tiene exactamente un ítem, "Datos Maestros"

#### Scenario: Entrar a Tipos de movimiento
- **WHEN** el usuario está en Datos Maestros y toca "Tipos de movimiento"
- **THEN** se muestra la pantalla "Tipos de movimiento"

### Requirement: Consulta de Tipos de cuenta
Al tocar "Tipos de cuenta", el sistema MUST mostrar la pantalla "Tipos de cuenta" con la lista de los Tipos de cuenta, cada uno con su nombre y su abreviación, ordenados por nombre. La pantalla MUST ser de solo lectura: sin opciones para crear, editar ni eliminar, y tocar un Tipo de cuenta MUST NOT abrir nada.

#### Scenario: Ver los Tipos de cuenta
- **WHEN** el usuario entra a Configuración → Datos Maestros → Tipos de cuenta
- **THEN** ve exactamente "Cuenta de Ahorros" (CA) y "Tarjeta de Crédito" (TC), en ese orden

#### Scenario: Sin acciones de edición
- **WHEN** el usuario está en la pantalla Tipos de cuenta
- **THEN** no hay botón para agregar, ni opción de editar o eliminar, ni se puede deslizar un ítem para borrarlo
- **AND** tocar un Tipo de cuenta no abre ninguna pantalla

#### Scenario: VoiceOver en Tipos de cuenta
- **WHEN** VoiceOver enfoca un ítem de la lista de Tipos de cuenta
- **THEN** VoiceOver lee su nombre y su abreviación
