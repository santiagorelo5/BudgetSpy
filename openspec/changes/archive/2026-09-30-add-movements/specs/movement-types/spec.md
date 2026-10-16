# Spec Delta: movement-types

## Purpose

Define los Tipos de movimiento que clasifican cada Movimiento (Gasto, Ingreso y Transferencia), cómo se crean como datos semilla y cómo el usuario los consulta desde Configuración → Datos Maestros.

## ADDED Requirements

### Requirement: Tipos de movimiento semilla
El sistema MUST tener exactamente 3 Tipos de movimiento, cada uno con nombre: "Gasto", "Ingreso" y "Transferencia". El sistema MUST crearlos la primera vez que se abre la app y MUST NOT duplicarlos en aperturas posteriores. Si falta alguno, el sistema MUST crear solo el que falta. El usuario MUST NOT poder crear, editar ni eliminar Tipos de movimiento.

#### Scenario: Primera apertura
- **WHEN** el usuario abre la app por primera vez
- **THEN** existen los Tipos de movimiento "Gasto", "Ingreso" y "Transferencia"

#### Scenario: Aperturas repetidas
- **WHEN** el usuario cierra y abre la app varias veces
- **THEN** siguen existiendo exactamente 3 Tipos de movimiento, sin duplicados

#### Scenario: Falta uno de los Tipos de movimiento
- **WHEN** al abrir la app ya existen "Gasto" e "Ingreso" pero no "Transferencia"
- **THEN** el sistema crea solo "Transferencia" y queda con exactamente 3 Tipos de movimiento

### Requirement: Consulta de Tipos de movimiento
Al tocar "Tipos de movimiento" en Datos Maestros, el sistema MUST mostrar la pantalla "Tipos de movimiento" con la lista de los Tipos de movimiento en este orden: "Gasto", "Ingreso", "Transferencia". La pantalla MUST ser de solo lectura: sin opciones para crear, editar ni eliminar. Tocar un Tipo de movimiento MUST NOT abrir nada.

#### Scenario: Ver los Tipos de movimiento
- **WHEN** el usuario entra a Configuración → Datos Maestros → Tipos de movimiento
- **THEN** ve exactamente "Gasto", "Ingreso" y "Transferencia", en ese orden

#### Scenario: Sin acciones de edición
- **WHEN** el usuario está en la pantalla Tipos de movimiento
- **THEN** no hay botón para agregar ni opción de editar o eliminar, y no se puede deslizar un ítem para borrarlo
- **AND** tocar un Tipo de movimiento no abre ninguna pantalla

#### Scenario: VoiceOver en Tipos de movimiento
- **WHEN** VoiceOver enfoca un ítem de la lista de Tipos de movimiento
- **THEN** VoiceOver lee su nombre
