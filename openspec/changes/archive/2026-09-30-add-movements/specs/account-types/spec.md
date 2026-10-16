# Spec Delta: account-types

## MODIFIED Requirements

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
