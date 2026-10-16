# Spec Delta: accounts

## ADDED Requirements

### Requirement: Movimiento inicial al crear una Cuenta
Al crear una Cuenta con balance mayor a $ 0,00, el sistema MUST crear, en la misma operación de guardado, un Movimiento con descripción "Saldo inicial" y la fecha de creación de la Cuenta (ver capability `movements`):
- En Cuenta de Ahorros, MUST ser un Ingreso con el valor del Saldo disponible.
- En Tarjeta de Crédito, MUST ser un Gasto con el valor de la Deuda a la fecha.

El balance de la Cuenta MUST quedar igual al ingresado en el formulario. Si el balance es $ 0,00, el sistema MUST NOT crear ningún Movimiento. Si el guardado falla, MUST NOT quedar guardada ni la Cuenta ni el Movimiento.

#### Scenario: Cuenta de Ahorros con saldo
- **WHEN** el usuario crea una Cuenta de Ahorros con Saldo disponible $ 500.000,00
- **THEN** la tarjeta de la Cuenta muestra $ 500.000,00
- **AND** su lista de Movimientos muestra un Ingreso "Saldo inicial" de $ 500.000,00 con la fecha de hoy

#### Scenario: Cuenta de Ahorros sin saldo
- **WHEN** el usuario crea una Cuenta de Ahorros con Saldo disponible $ 0,00
- **THEN** su lista de Movimientos muestra "Sin movimientos"

#### Scenario: Tarjeta de Crédito con deuda
- **WHEN** el usuario crea una Tarjeta de Crédito con Deuda a la fecha $ 1.200.000,00
- **THEN** su lista de Movimientos muestra un Gasto "Saldo inicial" de $ 1.200.000,00

#### Scenario: Tarjeta de Crédito sin deuda
- **WHEN** el usuario crea una Tarjeta de Crédito con Deuda a la fecha $ 0,00
- **THEN** no se crea ningún Movimiento y su lista muestra "Sin movimientos"

### Requirement: Ajuste de saldo al editar el balance
El balance de una Cuenta MUST seguir pudiendo editarse en el formulario de Cuenta. Al guardar un balance distinto al anterior, el sistema MUST crear, en la misma operación de guardado, un Movimiento con descripción "Ajuste de saldo", la fecha actual y el valor de la diferencia:
- En Cuenta de Ahorros, MUST ser un Ingreso si el saldo sube y un Gasto si baja.
- En Tarjeta de Crédito, MUST ser un Gasto si la deuda sube y un Ingreso si baja.

Si el balance no cambia, el sistema MUST NOT crear ningún Movimiento.

#### Scenario: Bajar el saldo de una Cuenta de Ahorros
- **WHEN** el usuario edita una Cuenta de Ahorros de $ 100.000,00 a $ 80.000,00 y guarda
- **THEN** la tarjeta muestra $ 80.000,00
- **AND** su lista muestra un Gasto "Ajuste de saldo" de -$ 20.000,00

#### Scenario: Subir el saldo de una Cuenta de Ahorros
- **WHEN** el usuario edita una Cuenta de Ahorros de $ 100.000,00 a $ 130.000,00 y guarda
- **THEN** su lista muestra un Ingreso "Ajuste de saldo" de $ 30.000,00

#### Scenario: Subir la deuda de una Tarjeta de Crédito
- **WHEN** el usuario edita una Tarjeta de Crédito de Deuda a la fecha $ 100.000,00 a $ 150.000,00 y guarda
- **THEN** su lista muestra un Gasto "Ajuste de saldo" de $ 50.000,00

#### Scenario: Bajar la deuda de una Tarjeta de Crédito
- **WHEN** el usuario edita una Tarjeta de Crédito de Deuda a la fecha $ 100.000,00 a $ 40.000,00 y guarda
- **THEN** su lista muestra un Ingreso "Ajuste de saldo" de -$ 60.000,00

#### Scenario: Guardar sin cambiar el balance
- **WHEN** el usuario cambia solo el nombre de una Cuenta y guarda
- **THEN** no se crea ningún Movimiento

## MODIFIED Requirements

### Requirement: Eliminar una Cuenta
Al elegir "Eliminar", el sistema MUST pedir confirmación antes de eliminar. Si el usuario cancela, nada cambia. Si el usuario confirma, en una sola operación de guardado:
- La Cuenta MUST eliminarse de forma definitiva y su tarjeta MUST desaparecer del carrusel.
- Los Gastos e Ingresos de la Cuenta MUST eliminarse.
- Cada Transferencia en la que la Cuenta eliminada es Cuenta destino MUST convertirse en Gasto de su Cuenta origen, con Cuenta destino vacía.
- Cada Transferencia en la que la Cuenta eliminada es Cuenta origen MUST convertirse en Ingreso de su Cuenta destino: esa Cuenta pasa a ser la Cuenta origen del Movimiento y la Cuenta destino queda vacía.
- El balance de las demás Cuentas MUST NOT cambiar.

#### Scenario: Confirmar eliminación
- **WHEN** el usuario elige "Eliminar" y confirma "Eliminar cuenta"
- **THEN** la tarjeta de esa Cuenta desaparece del carrusel
- **AND** la Cuenta no vuelve a aparecer al cerrar y abrir la app

#### Scenario: Cancelar eliminación
- **WHEN** el usuario elige "Eliminar" y luego "Cancelar"
- **THEN** la tarjeta sigue en el carrusel sin cambios y sus Movimientos no cambian

#### Scenario: Eliminar la única Cuenta
- **WHEN** el usuario elimina su única Cuenta
- **THEN** el carrusel muestra solo la tarjeta "+"

#### Scenario: Eliminar la Cuenta destino de una Transferencia
- **WHEN** existe una Transferencia de $ 20.000,00 de "Nómina" a "Ahorros casa" y el usuario elimina "Ahorros casa"
- **THEN** el Movimiento se ve en la lista de "Nómina" como Gasto de -$ 20.000,00, sin Cuenta destino
- **AND** el saldo de "Nómina" no cambia

#### Scenario: Eliminar la Cuenta origen de una Transferencia
- **WHEN** existe una Transferencia de $ 20.000,00 de "Nómina" a "Ahorros casa" y el usuario elimina "Nómina"
- **THEN** el Movimiento se ve en la lista de "Ahorros casa" como Ingreso de $ 20.000,00, sin Cuenta destino
- **AND** el saldo de "Ahorros casa" no cambia
- **AND** los demás Movimientos de "Nómina" desaparecen

#### Scenario: Eliminar la Cuenta origen de una Transferencia hacia una Tarjeta de Crédito
- **WHEN** existe una Transferencia de $ 30.000,00 de "Nómina" a "Visa" y el usuario elimina "Nómina"
- **THEN** el Movimiento se ve en la lista de "Visa" como Ingreso de -$ 30.000,00, sin Cuenta destino
- **AND** la deuda de "Visa" no cambia

#### Scenario: Falla al eliminar
- **WHEN** el usuario confirma la eliminación y esta falla
- **THEN** se muestra el aviso "No se pudo eliminar la cuenta. Intenta de nuevo."
- **AND** la tarjeta sigue en el carrusel y ningún Movimiento ni balance cambia
