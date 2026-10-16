# Spec Delta

## Purpose

Permite al usuario elegir desde Configuración si BudgetSpy se ve en modo claro o en modo oscuro, mediante el interruptor de la fila "Apariencia". Mientras el usuario no elija, la app sigue la apariencia del sistema. Define cómo se aplica y se conserva esa preferencia de apariencia.

## ADDED Requirements

### Requirement: Interruptor de apariencia
El sistema MUST mostrar en la pantalla Configuración el ítem "Apariencia" con, al final de la misma fila, un ícono de sol, un interruptor y un ícono de luna, en ese orden. El interruptor MUST estar encendido (hacia la luna) cuando la app se ve en modo oscuro y apagado (hacia el sol) cuando se ve en modo claro. Tocar la fila MUST NOT abrir otra pantalla.

#### Scenario: Sol a la izquierda y luna a la derecha
- **WHEN** el usuario abre Configuración
- **THEN** la fila "Apariencia" muestra el ícono de sol a la izquierda del interruptor y el ícono de luna a su derecha

#### Scenario: Interruptor encendido en modo oscuro
- **WHEN** la app se ve en modo oscuro y el usuario abre Configuración
- **THEN** el interruptor de "Apariencia" se ve encendido, del lado de la luna

#### Scenario: Interruptor apagado en modo claro
- **WHEN** la app se ve en modo claro y el usuario abre Configuración
- **THEN** el interruptor de "Apariencia" se ve apagado, del lado del sol

#### Scenario: La fila no abre otra pantalla
- **WHEN** el usuario toca la fila "Apariencia"
- **THEN** se sigue mostrando la pantalla Configuración y no se abre ninguna pantalla nueva

### Requirement: Sin decisión guardada se sigue la apariencia del sistema
Mientras el usuario no haya tocado el interruptor de "Apariencia", el sistema MUST mostrar la app con la apariencia del sistema, también cuando esta cambia con la app abierta, y el interruptor MUST reflejar esa apariencia.

#### Scenario: Instalación nueva con el iPhone en oscuro
- **WHEN** el usuario abre la app por primera vez y el iPhone está en modo oscuro
- **THEN** la app se ve en modo oscuro
- **AND** en Configuración el interruptor de "Apariencia" se ve encendido

#### Scenario: Instalación nueva con el iPhone en claro
- **WHEN** el usuario abre la app por primera vez y el iPhone está en modo claro
- **THEN** la app se ve en modo claro
- **AND** en Configuración el interruptor de "Apariencia" se ve apagado

#### Scenario: El iPhone cambia de apariencia sin decisión guardada
- **WHEN** el usuario no ha tocado el interruptor y cambia el iPhone de modo claro a modo oscuro desde el Centro de control
- **THEN** la app pasa a verse en modo oscuro
- **AND** el interruptor de "Apariencia" se ve encendido

### Requirement: Aplicación inmediata de la preferencia de apariencia
Al tocar el interruptor de "Apariencia", el sistema MUST aplicar la nueva apariencia de inmediato a toda la app (pantallas, barra de navegación inferior, hojas y alertas), sin reiniciar la app, sin salir de Configuración y sin pedir confirmación. El sistema MUST NOT mostrar botones Guardar ni Cancelar para este ajuste.

#### Scenario: Encender el interruptor estando en claro
- **WHEN** la app se ve en modo claro y el usuario enciende el interruptor de "Apariencia"
- **THEN** la pantalla Configuración y la barra de navegación inferior se ven en modo oscuro de inmediato, sin salir de Configuración
- **AND** al ir a Inicio, la pantalla de Inicio se ve en modo oscuro

#### Scenario: Apagar el interruptor estando en oscuro
- **WHEN** la app se ve en modo oscuro y el usuario apaga el interruptor de "Apariencia"
- **THEN** toda la app se ve en modo claro de inmediato

#### Scenario: Hojas y alertas siguen la preferencia
- **WHEN** el usuario encendió el interruptor de "Apariencia", el iPhone está en modo claro y se abre una hoja o una alerta de la app
- **THEN** la hoja o la alerta se ve en modo oscuro

### Requirement: Con decisión guardada no se sigue la apariencia del sistema
Una vez el usuario tocó el interruptor de "Apariencia", el sistema MUST mantener la apariencia elegida aunque cambie la apariencia del sistema. El sistema MUST NOT ofrecer una opción para volver a seguir la apariencia del sistema.

#### Scenario: Eligió claro y el iPhone cambia a oscuro
- **WHEN** el usuario apagó el interruptor de "Apariencia" y el iPhone cambia a modo oscuro
- **THEN** la app sigue viéndose en modo claro
- **AND** el interruptor de "Apariencia" sigue apagado

#### Scenario: Eligió oscuro y el iPhone cambia a claro
- **WHEN** el usuario encendió el interruptor de "Apariencia" y el iPhone cambia a modo claro
- **THEN** la app sigue viéndose en modo oscuro
- **AND** el interruptor de "Apariencia" sigue encendido

### Requirement: Persistencia de la preferencia de apariencia
El sistema MUST conservar en el dispositivo la decisión tomada con el interruptor al cerrar y reabrir la app, y MUST aplicarla desde que la app se abre.

#### Scenario: Reabrir la app con el interruptor encendido
- **WHEN** el usuario enciende el interruptor de "Apariencia", cierra la app por completo y la vuelve a abrir con el iPhone en modo claro
- **THEN** la app abre en modo oscuro
- **AND** el interruptor de "Apariencia" se ve encendido

#### Scenario: Reabrir la app sin decisión guardada
- **WHEN** el usuario nunca ha tocado el interruptor, cierra la app y la vuelve a abrir
- **THEN** la app abre con la apariencia del sistema

### Requirement: Accesibilidad del interruptor de apariencia
El sistema MUST anunciar con VoiceOver el interruptor como "Apariencia, modo oscuro" junto con su estado (activado o desactivado), y MUST NOT anunciar los íconos de sol y luna por separado. El sistema MUST respetar el tamaño de texto dinámico del sistema en la fila "Apariencia"; si el texto, los íconos y el interruptor no caben en una línea, MUST mostrarlos completos en más de una línea.

#### Scenario: VoiceOver anuncia el interruptor
- **WHEN** VoiceOver está activo, la app se ve en modo claro y el usuario enfoca el interruptor de "Apariencia"
- **THEN** VoiceOver anuncia "Apariencia, modo oscuro" y el estado desactivado
- **AND** no anuncia los íconos de sol y luna

#### Scenario: Texto dinámico grande
- **WHEN** el usuario tiene configurado un tamaño de texto de accesibilidad grande
- **THEN** el texto "Apariencia" se muestra completo y legible, y los íconos de sol y luna y el interruptor siguen visibles
