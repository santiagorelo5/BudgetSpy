# Spec Delta

## MODIFIED Requirements

### Requirement: Barra de navegación inferior con secciones principales
El sistema MUST mostrar, en la parte inferior de todas las pantallas principales, una barra de navegación del sistema con estilo Liquid Glass que contiene exactamente 2 opciones, en este orden: "Inicio" (ícono de casa) y "Configuración" (ícono de engranaje). El sistema MUST NOT mostrar opciones adicionales en la barra. La barra MUST verse siempre con la misma apariencia que el resto de la app, según la preferencia de apariencia (ver capability `appearance`).

#### Scenario: La barra muestra las dos opciones en orden
- **WHEN** el usuario abre la app
- **THEN** la barra de navegación inferior es visible
- **AND** muestra la opción "Inicio" con ícono de casa en primera posición
- **AND** muestra la opción "Configuración" con ícono de engranaje en segunda posición
- **AND** no muestra ninguna otra opción

#### Scenario: La barra se ve correctamente en modo claro y oscuro
- **WHEN** la app se ve en modo claro o en modo oscuro
- **THEN** la barra de navegación y sus opciones son legibles y se ven con la misma apariencia que el resto de la app

#### Scenario: La barra sigue la preferencia de apariencia y no la del sistema
- **WHEN** la preferencia de apariencia es "Claro" y el iPhone está en modo oscuro
- **THEN** la barra de navegación se ve en modo claro, igual que las pantallas de la app

#### Scenario: El contenido se desplaza por detrás de la barra
- **WHEN** el contenido de una pantalla principal se desplaza hasta la parte inferior
- **THEN** el contenido pasa por detrás de la barra de navegación con el efecto de transparencia de Liquid Glass

#### Scenario: Reducir transparencia activado
- **WHEN** el usuario tiene activada la opción de accesibilidad "Reducir transparencia"
- **THEN** la barra de navegación sigue visible y legible, con la apariencia que el sistema define para ese ajuste

### Requirement: Contenido de las pantallas principales
El sistema MUST mostrar la pantalla de Inicio sin título, con el carrusel de Cuentas en su parte superior (ver capability `accounts`) y, debajo, la sección "Movimientos" de la Cuenta enfocada (ver capability `movements`). El carrusel MUST tener una altura fija, con la proporción de una tarjeta de crédito, que MUST NOT cambiar al cambiar de Cuenta ni según el contenido de la sección "Movimientos". El sistema MUST mostrar la pantalla de Configuración con el título "Configuración" y una lista con exactamente dos ítems, en este orden: "Datos Maestros" (ver capability `account-types`) y "Apariencia" (ver capability `appearance`).

#### Scenario: Pantalla de Inicio
- **WHEN** se muestra la pantalla de Inicio y el carrusel está en una Cuenta
- **THEN** no se ve ningún título
- **AND** se ve el carrusel de Cuentas en la parte superior y la sección "Movimientos" debajo
- **AND** la barra de navegación inferior sigue visible con la opción "Inicio" seleccionada

#### Scenario: Pantalla de Inicio sin Cuentas
- **WHEN** se muestra la pantalla de Inicio y el usuario no tiene Cuentas
- **THEN** el carrusel muestra solo la tarjeta "+" y no se ve la sección "Movimientos"

#### Scenario: El carrusel mantiene su tamaño
- **WHEN** el usuario desliza el carrusel entre una Cuenta con 10 Movimientos, una sin Movimientos y la tarjeta "+"
- **THEN** el carrusel conserva la misma altura y las tarjetas conservan su proporción de tarjeta de crédito

#### Scenario: Pantalla de Configuración
- **WHEN** se muestra la pantalla de Configuración
- **THEN** se ve el título "Configuración" y una lista con los ítems "Datos Maestros" y "Apariencia", en ese orden
- **AND** no se ve ningún otro ítem

#### Scenario: Fila Apariencia con su selector
- **WHEN** se muestra la pantalla de Configuración
- **THEN** la fila "Apariencia" muestra al final de la fila el selector con la preferencia de apariencia actual
