# app-navigation Specification

## Purpose

Define la estructura base de navegación de BudgetSpy: una barra de navegación inferior que permite al usuario moverse entre las secciones principales de la app (Inicio y Configuración), conservando la navegación propia de cada sección.

## Requirements

### Requirement: Barra de navegación inferior con secciones principales
El sistema MUST mostrar, en la parte inferior de todas las pantallas principales, una barra de navegación del sistema con estilo Liquid Glass que contiene exactamente 2 opciones, en este orden: "Inicio" (ícono de casa) y "Configuración" (ícono de engranaje). El sistema MUST NOT mostrar opciones adicionales en la barra.

#### Scenario: La barra muestra las dos opciones en orden
- **WHEN** el usuario abre la app
- **THEN** la barra de navegación inferior es visible
- **AND** muestra la opción "Inicio" con ícono de casa en primera posición
- **AND** muestra la opción "Configuración" con ícono de engranaje en segunda posición
- **AND** no muestra ninguna otra opción

#### Scenario: La barra se ve correctamente en modo claro y oscuro
- **WHEN** el dispositivo está en modo claro o en modo oscuro
- **THEN** la barra de navegación y sus opciones son legibles y se adaptan a la apariencia del sistema

#### Scenario: El contenido se desplaza por detrás de la barra
- **WHEN** el contenido de una pantalla principal se desplaza hasta la parte inferior
- **THEN** el contenido pasa por detrás de la barra de navegación con el efecto de transparencia de Liquid Glass

#### Scenario: Reducir transparencia activado
- **WHEN** el usuario tiene activada la opción de accesibilidad "Reducir transparencia"
- **THEN** la barra de navegación sigue visible y legible, con la apariencia que el sistema define para ese ajuste

### Requirement: Sección por defecto al abrir la app
El sistema MUST mostrar la sección "Inicio" y marcar su opción como seleccionada cada vez que la app se abre.

#### Scenario: Abrir la app muestra Inicio
- **WHEN** el usuario abre la app
- **THEN** se muestra la pantalla de Inicio
- **AND** la opción "Inicio" aparece seleccionada en la barra de navegación

### Requirement: Cambio de sección desde la barra
El sistema MUST mostrar la sección correspondiente cuando el usuario toca una opción de la barra, y MUST distinguir visualmente la opción seleccionada de la no seleccionada.

#### Scenario: Ir a Configuración
- **WHEN** el usuario está en Inicio y toca la opción "Configuración"
- **THEN** se muestra la pantalla de Configuración
- **AND** la opción "Configuración" aparece seleccionada y la opción "Inicio" aparece no seleccionada

#### Scenario: Volver a Inicio
- **WHEN** el usuario está en Configuración y toca la opción "Inicio"
- **THEN** se muestra la pantalla de Inicio
- **AND** la opción "Inicio" aparece seleccionada

#### Scenario: Tocar la opción ya seleccionada
- **WHEN** el usuario está en Inicio y toca de nuevo la opción "Inicio"
- **THEN** se sigue mostrando la pantalla de Inicio sin errores

### Requirement: Navegación independiente por sección
El sistema MUST conservar la navegación de cada sección de forma independiente: al cambiar de sección y volver, el usuario MUST encontrar la sección en la misma pantalla en la que la dejó.

#### Scenario: Se conserva la pantalla interna al cambiar de sección
- **WHEN** el usuario entra a una pantalla interna de Configuración, cambia a Inicio y vuelve a Configuración
- **THEN** se muestra la misma pantalla interna de Configuración donde estaba

#### Scenario: Sección sin pantallas internas
- **WHEN** el usuario cambia de Configuración a Inicio y vuelve, sin haber entrado a ninguna pantalla interna
- **THEN** se muestra la pantalla principal de Configuración

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

### Requirement: Accesibilidad de la barra de navegación
El sistema MUST anunciar con VoiceOver cada opción de la barra con su nombre y su estado de selección, y MUST respetar el tamaño de texto dinámico del sistema en el título de la pantalla de Configuración.

#### Scenario: VoiceOver anuncia las opciones
- **WHEN** VoiceOver está activo y el usuario enfoca una opción de la barra
- **THEN** VoiceOver anuncia "Inicio" o "Configuración" según la opción enfocada
- **AND** indica si la opción está seleccionada

#### Scenario: Texto dinámico grande
- **WHEN** el usuario tiene configurado un tamaño de texto de accesibilidad grande
- **THEN** el título "Configuración" se muestra completo con el tamaño correspondiente

### Requirement: Solo orientación vertical
El sistema MUST funcionar únicamente en orientación vertical en iPhone.

#### Scenario: Girar el dispositivo
- **WHEN** el usuario gira el iPhone a orientación horizontal
- **THEN** la app permanece en orientación vertical
