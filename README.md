# Proyecto FIFO - Verificación con SystemVerilog

## 1. Introducción

Este proyecto desarrolla un entorno de verificación funcional para una FIFO síncrona, evolucionando desde un testbench básico hacia una arquitectura alineada con metodologías modernas de verificación (Layered Testbench).

El objetivo principal es mejorar la **modularidad, escalabilidad y observabilidad del diseño**, incorporando técnicas como:

- Verificación aleatoria restringida (Constrained Random Verification)
- Arquitectura por capas (Driver, Monitor, Checker, Scoreboard)
- Configuración dinámica mediante plusargs
- Separación clara entre generación, estímulo y verificación

Esto permite pasar de un entorno estático a uno capaz de ejecutar escenarios complejos de estrés, corner cases y validación funcional robusta.

---

## 2. Descripción del DUT (FIFO)

La FIFO (First In - First Out) es un bloque síncrono que almacena datos respetando el orden de llegada.

### Evolución del diseño

La versión inicial basada en flip-flops individuales presentaba limitaciones importantes:

- Baja escalabilidad (crecimiento manual del hardware)
- Latencia elevada por ausencia de bypass
- Complejidad en el control de estados full/empty

### Arquitectura mejorada

El diseño optimizado introduce mejoras estructurales clave:

- Memoria circular con punteros (`rd_ptr`, `wr_ptr`)
- Contador interno de ocupación (`count`)
- Soporte FWFT (First Word Fall Through)
- Operaciones simultáneas de lectura y escritura

Esto reduce latencia, mejora el uso de recursos y facilita la síntesis en FPGA/ASIC.

---

## 3. Arquitectura del Testbench

El entorno de verificación sigue una arquitectura Layered Testbench, separando responsabilidades por bloques funcionales.

---

### 3.1 Test (Control de simulación)

El Test define el comportamiento global de la simulación y los escenarios de verificación.

Sus responsabilidades principales son:

- Configuración dinámica mediante plusargs
- Definición de escenarios (aleatorio, estrés, corner cases)
- Control del ciclo de vida de la simulación

Además, permite modificar parámetros sin recompilación, lo que habilita flujos de regresión más eficientes.

---

### 3.2 Testbench Top (test_bench.sv)

El Testbench conecta el mundo RTL con el entorno de verificación.

Componentes principales:

- DUT (FIFO)
- Interface física (`fifo_if`)
- Clase Test
- Generador de reloj

Su función es:

- Instanciar y conectar el DUT
- Distribuir interfaces virtuales
- Generar clock y reset
- Controlar ejecución global

---

### 3.3 Ambiente (Environment)

El Environment integra todos los componentes del sistema.

Funciona como núcleo de coordinación:

- Instancia Driver, Monitor, Checker, Scoreboard y Agente
- Conecta mailboxes entre bloques
- Ejecuta procesos en paralelo (`fork-join_none`)

La mejora clave es la separación total entre generación, observación y verificación, permitiendo arquitectura desacoplada.

---

### 3.4 Agente (Generador de transacciones)

El Agente crea estímulos de alto nivel para la FIFO.

Funciones principales:

- Generación de transacciones aleatorias
- Uso de constraints para control de tráfico
- Interpretación de instrucciones del Test

Características destacadas:

- Soporte para saturación controlada
- Configuración dinámica por plusargs
- Separación de escenarios por tipo de prueba

---

### 3.5 Driver (Interfaz con el DUT)

El Driver traduce transacciones en señales físicas.

Responsabilidades:

- Control de señales `push`, `pop`, `dato_in`
- Sincronización con `posedge clk`
- Manejo de retardo por transacción

Mejoras importantes:

- Soporte de operación simultánea (`write_read`)
- Limpieza estricta de señales
- Eliminación de lógica de verificación (solo control físico)

---

### 3.6 Monitor (Observador del DUT)

El Monitor captura el comportamiento real del hardware.

Funciones:

- Muestreo síncrono del DUT
- Conversión de señales a transacciones
- Clasificación de operaciones

Mejoras clave:

- Retardo de estabilización para evitar glitches
- Captura consistente de datos combinacionales
- Arquitectura completamente pasiva

---

### 3.7 Checker (Verificador funcional)

El Checker valida el comportamiento del DUT contra un modelo de referencia.

Funciones principales:

- Modelo Golden Model (cola emulada)
- Comparación dato a dato
- Detección de overflow y underflow
- Cálculo de latencia

Mejoras:

- Soporte de operaciones simultáneas
- Manejo de bypass (latencia 0)
- Validación basada en observación (no en estímulo)

---

### 3.8 Scoreboard (Análisis y métricas)

El Scoreboard centraliza la información de verificación.

Funciones:

- Cálculo de latencia promedio
- Registro histórico de transacciones
- Generación de reportes

Mejoras relevantes:

- Ejecución concurrente (no bloqueante)
- Acceso no destructivo a datos
- Mayor precisión numérica

---

## 4. Definiciones globales e interfaces

Este módulo define la base estructural del sistema de verificación.

Incluye:

- Tipos de transacción (`read`, `write`, `reset`, `write_read`)
- Clase `trans_fifo`
- Interface `fifo_if`

Características importantes:

- Tipado estricto de mailboxes
- Inclusión de `dato_out` y timestamps
- Soporte para análisis de latencia

---

## 5. Mejoras generales del proyecto

Las mejoras más importantes del sistema son:

- Arquitectura completamente modular (Layered TB)
- Observabilidad completa mediante Monitor
- Separación entre estímulo y verificación
- Soporte de escenarios de estrés y corner cases
- Configuración dinámica con plusargs

---

## 6. Conclusión

Este proyecto transforma un entorno básico de simulación en una arquitectura de verificación funcional completa.

El sistema final permite:

- Validación funcional robusta
- Escalabilidad para futuros diseños
- Mejor observabilidad del DUT
- Análisis de rendimiento mediante métricas

En conjunto, representa una evolución hacia metodologías reales de verificación usadas en diseño de hardware profesional.
