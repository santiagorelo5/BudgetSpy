# Spec Delta

## Purpose

Define los Tipos de cuenta que clasifican las Cuentas del usuario: los datos semilla no editables que la app crea y su consulta de solo lectura desde Configuración → Datos Maestros.

## ADDED Requirements

### Requirement: Tipos de cuenta semilla
El sistema MUST garantizar que existan exactamente estos 2 Tipos de cuenta, cada uno con su tipo (nombre completo) y su abreviación de 2 letras: "Cuenta de Ahorros" (CA) y "Tarjeta de Crédito" (TC). El sistema MUST crearlos al abrir la app si no existen, y MUST NOT duplicarlos si ya existen.

#### Scenario: Primer arranque sin datos
- **WHEN** el usuario abre la app por primera vez y no hay ningún Tipo de cuenta guardado
- **THEN** existen los Tipos de cuenta "Cuenta de Ahorros" (CA) y "Tarjeta de Crédito" (TC)

#### Scenario: Arranques posteriores
- **WHEN** el usuario cierra y vuelve a abrir la app varias veces
- **THEN** siguen existiendo exactamente 2 Tipos de cuenta, sin duplicados

#### Scenario: Falta uno de los tipos semilla
- **WHEN** al abrir la app existe "Cuenta de Ahorros" pero no existe "Tarjeta de Crédito"
- **THEN** el sistema crea solo "Tarjeta de Crédito" (TC) y conserva el existente

### Requirement: Tipos de cuenta no editables
El sistema MUST NOT ofrecer al usuario ninguna opción para crear, editar o eliminar Tipos de cuenta.

#### Scenario: Sin acciones de edición
- **WHEN** el usuario consulta la lista de Tipos de cuenta
- **THEN** no hay botones, menús ni gestos para crear, editar o eliminar un Tipo de cuenta

### Requirement: Datos Maestros en Configuración
La pantalla de Configuración MUST mostrar una lista con un único ítem, "Datos Maestros". Al tocarlo, el sistema MUST mostrar una lista con el ítem "Tipos de cuenta". Al tocar "Tipos de cuenta", el sistema MUST mostrar los Tipos de cuenta existentes con su tipo y su abreviación.

#### Scenario: Configuración muestra Datos Maestros
- **WHEN** el usuario abre la sección Configuración
- **THEN** ve una lista con un único ítem "Datos Maestros"

#### Scenario: Navegar a Tipos de cuenta
- **WHEN** el usuario toca "Datos Maestros" y luego "Tipos de cuenta"
- **THEN** ve "Cuenta de Ahorros" con la abreviación "CA" y "Tarjeta de Crédito" con la abreviación "TC"

#### Scenario: Volver desde Tipos de cuenta
- **WHEN** el usuario está en "Tipos de cuenta" y usa el botón de regresar del sistema
- **THEN** vuelve a "Datos Maestros", y desde allí a Configuración

#### Scenario: Lista sin Tipos de cuenta
- **WHEN** por un error de datos no existe ningún Tipo de cuenta al mostrar la lista
- **THEN** la pantalla muestra un estado vacío con el texto "No hay tipos de cuenta" en lugar de una lista en blanco
