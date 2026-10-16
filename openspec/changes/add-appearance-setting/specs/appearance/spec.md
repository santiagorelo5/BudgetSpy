# Spec Delta

## Purpose

Permite al usuario elegir la apariencia de BudgetSpy (seguir la apariencia del sistema, modo claro o modo oscuro) desde Configuración, y define cómo se aplica y se conserva esa preferencia de apariencia.

## ADDED Requirements

### Requirement: Opciones de la preferencia de apariencia
El sistema MUST mostrar en la pantalla Configuración el ítem "Apariencia" con un selector al final de la misma fila, que ofrece exactamente tres opciones, en este orden: "Sistema", "Claro" y "Oscuro". El selector MUST mostrar seleccionada la preferencia de apariencia actual. Tocar la fila MUST NOT abrir otra pantalla.

#### Scenario: El selector muestra las tres opciones
- **WHEN** el usuario abre el selector de la fila "Apariencia"
- **THEN** ve las opciones "Sistema", "Claro" y "Oscuro", en ese orden
- **AND** la opción de la preferencia de apariencia actual aparece seleccionada

#### Scenario: La fila no abre otra pantalla
- **WHEN** el usuario toca la fila "Apariencia"
- **THEN** se sigue mostrando la pantalla Configuración y no se abre ninguna pantalla nueva

#### Scenario: Estado inicial sin preferencia guardada
- **WHEN** el usuario abre Configuración por primera vez después de instalar la app
- **THEN** el selector de "Apariencia" muestra "Sistema" seleccionado

### Requirement: Valor por defecto: seguir la apariencia del sistema
Mientras no exista una preferencia de apariencia guardada, el sistema MUST mostrar la app con la apariencia del sistema.

#### Scenario: Instalación nueva con el iPhone en oscuro
- **WHEN** el usuario abre la app por primera vez y el iPhone está en modo oscuro
- **THEN** la app se ve en modo oscuro

#### Scenario: Instalación nueva con el iPhone en claro
- **WHEN** el usuario abre la app por primera vez y el iPhone está en modo claro
- **THEN** la app se ve en modo claro

### Requirement: Aplicación inmediata de la preferencia de apariencia
Al elegir una opción del selector, el sistema MUST aplicar la nueva apariencia de inmediato a toda la app (pantallas, barra de navegación inferior, hojas y alertas), sin reiniciar la app, sin salir de Configuración y sin pedir confirmación. El sistema MUST NOT mostrar botones Guardar ni Cancelar para este ajuste.

#### Scenario: Elegir Oscuro estando en claro
- **WHEN** la app se ve en modo claro y el usuario elige "Oscuro"
- **THEN** la pantalla Configuración y la barra de navegación inferior se ven en modo oscuro de inmediato, sin salir de Configuración
- **AND** al ir a Inicio, la pantalla de Inicio se ve en modo oscuro

#### Scenario: Elegir Claro estando en oscuro
- **WHEN** la app se ve en modo oscuro y el usuario elige "Claro"
- **THEN** toda la app se ve en modo claro de inmediato

#### Scenario: Hojas y alertas siguen la preferencia
- **WHEN** la preferencia de apariencia es "Oscuro", el iPhone está en modo claro y se abre una hoja o una alerta de la app
- **THEN** la hoja o la alerta se ve en modo oscuro

#### Scenario: Elegir la opción ya seleccionada
- **WHEN** la preferencia de apariencia es "Claro" y el usuario vuelve a elegir "Claro"
- **THEN** la app sigue en modo claro sin errores

### Requirement: Comportamiento ante cambios de la apariencia del sistema
Con la preferencia de apariencia "Sistema", el sistema MUST cambiar la apariencia de la app cuando cambie la apariencia del sistema, también con la app abierta. Con la preferencia "Claro" u "Oscuro", el sistema MUST mantener esa apariencia aunque cambie la apariencia del sistema.

#### Scenario: Preferencia Sistema y el iPhone cambia a oscuro
- **WHEN** la preferencia de apariencia es "Sistema" y el usuario cambia el iPhone de modo claro a modo oscuro desde el Centro de control
- **THEN** la app pasa a verse en modo oscuro

#### Scenario: Preferencia Claro y el iPhone cambia a oscuro
- **WHEN** la preferencia de apariencia es "Claro" y el iPhone cambia a modo oscuro
- **THEN** la app sigue viéndose en modo claro

#### Scenario: Preferencia Oscuro y el iPhone cambia a claro
- **WHEN** la preferencia de apariencia es "Oscuro" y el iPhone cambia a modo claro
- **THEN** la app sigue viéndose en modo oscuro

#### Scenario: Volver a Sistema
- **WHEN** la preferencia de apariencia es "Claro", el iPhone está en modo oscuro y el usuario elige "Sistema"
- **THEN** la app pasa a verse en modo oscuro de inmediato

### Requirement: Persistencia de la preferencia de apariencia
El sistema MUST conservar la preferencia de apariencia en el dispositivo al cerrar y reabrir la app, y MUST aplicarla desde que la app se abre.

#### Scenario: Reabrir la app con Oscuro
- **WHEN** el usuario elige "Oscuro", cierra la app por completo y la vuelve a abrir con el iPhone en modo claro
- **THEN** la app abre en modo oscuro
- **AND** el selector de "Apariencia" muestra "Oscuro" seleccionado

#### Scenario: Reabrir la app con Sistema
- **WHEN** la preferencia de apariencia es "Sistema", el usuario cierra la app y la vuelve a abrir
- **THEN** la app abre con la apariencia del sistema

### Requirement: Accesibilidad del selector de apariencia
El sistema MUST anunciar con VoiceOver el selector como "Apariencia" junto con su valor actual, y MUST respetar el tamaño de texto dinámico del sistema en la fila "Apariencia".

#### Scenario: VoiceOver anuncia el selector
- **WHEN** VoiceOver está activo y el usuario enfoca la fila "Apariencia" con la preferencia "Sistema"
- **THEN** VoiceOver anuncia "Apariencia" y el valor "Sistema"

#### Scenario: Texto dinámico grande
- **WHEN** el usuario tiene configurado un tamaño de texto de accesibilidad grande
- **THEN** el texto "Apariencia" y el valor seleccionado se muestran completos y legibles
