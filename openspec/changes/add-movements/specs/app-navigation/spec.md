# Spec Delta: app-navigation

## MODIFIED Requirements

### Requirement: Barra de navegación inferior con secciones principales
El sistema MUST mostrar, en la parte inferior de todas las pantallas principales, una barra de navegación del sistema con estilo Liquid Glass. La barra MUST contener exactamente 3 elementos, en este orden:
1. "Inicio" (ícono de casa).
2. Un botón "+" (ícono de más).
3. "Configuración" (ícono de engranaje).

El botón "+" MUST ser una acción que abre el formulario para crear un Movimiento (ver capability `movements`), no una sección: MUST NOT quedar seleccionado nunca. El sistema MUST NOT mostrar elementos adicionales en la barra.

#### Scenario: La barra muestra las dos opciones en orden
- **WHEN** el usuario abre la app
- **THEN** la barra de navegación inferior es visible
- **AND** muestra "Inicio" con ícono de casa en primera posición, el botón "+" en segunda posición y "Configuración" con ícono de engranaje en tercera posición
- **AND** no muestra ningún otro elemento

#### Scenario: El "+" nunca queda seleccionado
- **WHEN** el usuario toca "+" y luego sale del formulario de Movimiento
- **THEN** la barra muestra seleccionada la opción "Inicio" y el "+" no aparece seleccionado en ningún momento

#### Scenario: La barra se ve correctamente en modo claro y oscuro
- **WHEN** el dispositivo está en modo claro o en modo oscuro
- **THEN** la barra de navegación y sus elementos son legibles y se adaptan a la apariencia del sistema

#### Scenario: El contenido se desplaza por detrás de la barra
- **WHEN** el contenido de una pantalla principal se desplaza hasta la parte inferior
- **THEN** el contenido pasa por detrás de la barra de navegación con el efecto de transparencia de Liquid Glass

#### Scenario: Reducir transparencia activado
- **WHEN** el usuario tiene activada la opción de accesibilidad "Reducir transparencia"
- **THEN** la barra de navegación sigue visible y legible, con la apariencia que el sistema define para ese ajuste

### Requirement: Contenido de las pantallas principales
El sistema MUST mostrar la pantalla de Inicio sin título, con el carrusel de Cuentas en su parte superior (ver capability `accounts`) y, debajo, la sección "Movimientos" de la Cuenta enfocada (ver capability `movements`). El sistema MUST mostrar la pantalla de Configuración con el título "Configuración" y una lista con el único ítem "Datos Maestros" (ver capability `account-types`).

#### Scenario: Pantalla de Inicio
- **WHEN** se muestra la pantalla de Inicio y el carrusel está en una Cuenta
- **THEN** no se ve ningún título
- **AND** se ve el carrusel de Cuentas en la parte superior y la sección "Movimientos" debajo
- **AND** la barra de navegación inferior sigue visible con la opción "Inicio" seleccionada

#### Scenario: Pantalla de Inicio sin Cuentas
- **WHEN** se muestra la pantalla de Inicio y el usuario no tiene Cuentas
- **THEN** el carrusel muestra solo la tarjeta "+" y no se ve la sección "Movimientos"

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
- **WHEN** el usuario toca "+" en la barra de navegación
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

### Requirement: Accesibilidad de la barra de navegación
El sistema MUST anunciar con VoiceOver cada opción de la barra con su nombre y su estado de selección. MUST anunciar el botón "+" como "Agregar movimiento". MUST respetar el tamaño de texto dinámico del sistema en el título de la pantalla de Configuración.

#### Scenario: VoiceOver anuncia las opciones
- **WHEN** VoiceOver está activo y el usuario enfoca una opción de la barra
- **THEN** VoiceOver anuncia "Inicio" o "Configuración" según la opción enfocada
- **AND** indica si la opción está seleccionada

#### Scenario: VoiceOver anuncia el botón "+"
- **WHEN** VoiceOver está activo y el usuario enfoca el botón "+" de la barra
- **THEN** VoiceOver anuncia "Agregar movimiento"

#### Scenario: Texto dinámico grande
- **WHEN** el usuario tiene configurado un tamaño de texto de accesibilidad grande
- **THEN** el título "Configuración" se muestra completo con el tamaño correspondiente
