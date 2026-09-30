---
name: openspec-propose-review
description: Revisa y corrige prompts de propose de OpenSpec (/opsx:propose) antes de ejecutarlos. Úsala cuando el usuario comparta un prompt de propose o pida revisarlo, mejorarlo o corregirlo.
---

# Revisión de prompts de propose (OpenSpec)

Objetivo: que el prompt de propose llegue a la IA sin contradicciones ni huecos, para que no tenga que improvisar decisiones de negocio, de UI ni técnicas.

## Principios

1. **La spec habla como usuario.** Historias, reglas, requisitos y criterios describen el comportamiento observable, no la implementación. Lo técnico va en "Notas técnicas" (que alimenta `design.md`) o en el contexto del proyecto.
2. **Un change es una funcionalidad entregable** (un slice vertical): modelo + persistencia + lógica + UI + tests de una sola capacidad. Agrupa varias HU. No se divide por entidad de base de datos ni por pantalla.
3. **Nunca inventes decisiones de negocio.** Si algo no está definido, márcalo como `[DECIDIR]` y da 2–3 opciones concretas con tu recomendación.
4. **Conserva la redacción del usuario.** Corrige ortografía, claridad, consistencia y numeración, pero no cambies el sentido.
5. **Todo lo que no se escribe, la IA lo decide.** Tu trabajo es encontrar esos huecos.

## Proceso

1. Lee el prompt completo.
2. Evalúa el alcance (sección A del checklist) antes que el detalle.
3. Recorre el checklist completo.
4. Responde con el formato de salida.

## Checklist

### A. Alcance
- ¿El change cubre una sola capacidad funcional? Si mezcla otras (navegación base, otra entidad, configuración general), sugiere sacarlas a un change previo o posterior.
- ¿El identificador está en kebab-case con verbo + sustantivo? (`add-accounts`, `add-transaction-categories`).
- ¿Dice qué ya existe (changes previos, pantallas) para que la IA modifique en vez de recrear?
- ¿La funcionalidad tiene un **punto de entrada** definido? (desde qué pantalla o gesto se llega).
- Tamaño: si previsiblemente genera más de ~20 tareas, sugiere dividir. Si generaría menos de ~3, sugiere unirlo con otro.

### B. Contradicciones (prioridad máxima)
- Rangos numéricos consistentes en todo el documento (`≥ 0` vs "positivo" vs `> 0`).
- Campos "opcionales" en una regla y "ocultos/siempre vacíos" en otra.
- Uso de "o" donde debería ir "y" en condiciones de validación.
- El mismo concepto con varios nombres (balance / saldo / deuda). Exige un glosario.
- Criterios de aceptación que contradicen reglas de negocio o requisitos funcionales.

### C. Datos y reglas de negocio
Para cada campo de cada entidad:
- Obligatoriedad, tipo, formato, rango, longitud exacta o máxima, unicidad, valor por defecto.
- Si es dinero: moneda, decimales, formato de visualización, signo.
- Si depende de otro campo (p. ej. obligatorio solo según el tipo), que esté explícito.
- Cada regla con un **ejemplo comprobable** (valor válido y valor inválido).
- Datos semilla: cuáles son, si son editables y que **no se dupliquen** al abrir la app varias veces.

### D. CRUD completo
- **Crear:** valores por defecto del formulario.
- **Listar/ver:** orden de los elementos y qué información se muestra.
- **Editar:** qué campos se pueden cambiar. Revisa especialmente si se puede cambiar el tipo o la categoría y qué pasa con los campos dependientes.
- **Eliminar:** confirmación, eliminación definitiva o archivado, y qué pasa con los datos relacionados (ahora o en el futuro).

### E. Flujos de UI y estados
- Qué pasa después de guardar (a dónde vuelve y qué se actualiza).
- Cancelar o volver con cambios sin guardar.
- Gestos: toque sencillo, toque sostenido, deslizar. Si un gesto no hace nada, que se diga explícitamente.
- Estado vacío (sin datos).
- Errores de validación: qué mensaje y dónde se muestra.
- Vista previa en vivo, si existe: qué campos se reflejan.

### F. Criterios de aceptación
- Cada requisito funcional tiene al menos un criterio de aceptación. Referéncialo: `CA3 (RF2)`.
- Cada criterio se verifica con sí/no mirando la app, sin leer código.
- Incluye casos negativos (qué **no** se permite), no solo el camino feliz.

### G. Fuera de alcance
- Menciona explícitamente las funcionalidades vecinas que la IA podría querer agregar.
- Aclara lo que ya existe y no debe modificarse.
- Si algo es solo consulta, indica que crear o editar está fuera de alcance.

### H. Notas técnicas
- Persistencia, modelo de datos, arquitectura, componentes clave y restricciones (p. ej. "sin dependencias externas").
- Solo lo específico de este change. Si se repite en varios changes, recomienda moverlo al contexto del proyecto (`project.md` o `config.yaml`).
- Impacto futuro: decisiones de este change que afectarán a changes siguientes (p. ej. saldo almacenado vs calculado).

### I. Plataforma iOS (si aplica)
- Modo claro y oscuro.
- VoiceOver: etiquetas en elementos interactivos y gráficos.
- Dynamic Type: los textos escalan sin romper el diseño.
- Orientación soportada y dispositivos (iPhone, iPad).
- Usar componentes nativos cuando existan (`TabView`, `List`, `contextMenu`, `confirmationDialog`) en vez de reconstruirlos.

### J. Limpieza
- Sin líneas de plantilla sin rellenar (`[comportamiento observable]`, `- RF1. El sistema debe...`), porque la IA puede tomarlas como requisitos.
- Numeración continua y sin duplicados.
- Ortografía y redacción claras.

## Formato de salida

Responde en español, en este orden. Omite las secciones que no tengan hallazgos.

1. **Veredicto** en 1–2 líneas: qué está bien y qué tan listo está.
2. **Contradicciones (corregir sí o sí).**
3. **Huecos que la IA va a improvisar**, ordenados por impacto.
4. **Alcance**, si hay algo que sacar o unir.
5. **Detalles menores.**
6. **Prompt corregido completo**, en un bloque ```markdown``` y con la plantilla de abajo. Aplica las correcciones que no requieren decisión y deja `[DECIDIR: opción A / opción B]` donde el usuario debe elegir.
7. **Decisiones pendientes**: lista corta de cada `[DECIDIR]`, con tu recomendación.

Sé directo. No repitas lo que ya está bien salvo en el veredicto.

## Plantilla del prompt de propose

```markdown
/opsx:propose <verbo-sustantivo> — Objetivo del change en una frase.

Contexto: qué existe ya (changes previos, pantallas) y de qué depende este change.

## 1. Historias de usuario
- HU1 - Yo como usuario quiero <acción concreta> para <beneficio>.
(Una HU por acción: crear, ver, editar, eliminar, consultar...)

## 2. Glosario
- <término>: definición única. Usar siempre el mismo término en todo el documento.

## 3. Reglas de negocio (con ejemplos)
- Entidad "<Nombre>", campos:
    <campo>: descripción (obligatorio/opcional; tipo; rango; formato; valor por defecto).
    Ej.: <valor válido> → válido; <valor inválido> → error "<mensaje>".
- Datos semilla: cuáles, si son editables, y que no se dupliquen.

## 4. Requisitos funcionales
- RF1 - <qué hace el sistema, visto por el usuario, sin tecnología>.
(Incluir: punto de entrada, qué pasa al guardar y al cancelar, gestos y acciones.)

## 5. Estados y casos borde
- Estado vacío: ...
- Errores de validación: qué mensaje y dónde.
- Confirmaciones: ...
- Cambios sin guardar: ...

## 6. Criterios de aceptación (verificables sin código)
- CA1 (RF1) - <algo que se mira en la app y se sabe si está bien con un sí/no>.
- CA2 (RF1) - <caso negativo: qué no se permite>.

## 7. Fuera de alcance
- <Funcionalidades vecinas que NO se implementan en este change.>
- <Lo que ya existe y no se modifica.>

## 8. Notas técnicas (para design.md)
- Persistencia / modelo: ...
- Arquitectura / componentes: ...
- Restricciones: ...
- Impacto en changes futuros: ...

## 9. Decisiones abiertas
- [DECIDIR] <pregunta> — opciones: A / B.
```

## Ejemplo de hallazgo bien reportado

> **Contradicción:** CA3 permite límite = 0, pero CA5 exige que sea positivo. Si una tarjeta con límite 0 no tiene sentido, cambia CA3 a "el límite debe ser mayor a 0".
