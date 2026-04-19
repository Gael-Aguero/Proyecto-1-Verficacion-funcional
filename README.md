# Proyecto FIFO - Verificación con SystemVerilog

## 1. Introducción

### Descripción del Proyecto

Este proyecto parte de un entorno de verificación básico y lo evoluciona hacia una arquitectura más cercana a los estándares utilizados en la verificación funcional de hardware de alto nivel. El objetivo principal es mejorar la modularidad, escalabilidad y robustez del testbench, garantizando el correcto funcionamiento sincrónico del diseño bajo prueba (FIFO).

Se implementa una arquitectura basada en Layered Testbench, donde los componentes de verificación se separan en bloques independientes (Agente, Driver, Monitor, Checker y Scoreboard). Esta separación jerárquica permite una mejor organización del código, facilita el mantenimiento y mejora significativamente la reutilización en futuros proyectos.

Además, se incorpora Verificación Aleatoria Restringida (Constrained-Random Verification), lo que permite generar estímulos automáticamente bajo las reglas del protocolo de la FIFO. Esto amplía la cobertura de pruebas al explorar escenarios no determinísticos, incluyendo casos límite (corner cases) y situaciones de error que podrían pasar desapercibidas en pruebas dirigidas tradicionales.

Finalmente, se añade configuración dinámica mediante plusargs, lo que permite parametrizar la simulación en tiempo de ejecución sin necesidad de recompilar el entorno. Esto mejora la flexibilidad de las pruebas y facilita la automatización de regresiones.

En conjunto, estas mejoras permiten transformar un banco de pruebas estático en un sistema de verificación autónomo y resiliente, capaz de validar no solo la funcionalidad básica del diseño, sino también su comportamiento ante condiciones de estrés y casos críticos, elevando así la confianza en la calidad y robustez del hardware final.

## 2. Descripción del DUT (FIFO)

La FIFO (First In - First Out) es un dispositivo de almacenamiento síncrono diseñado para gestionar el flujo de datos respetando estrictamente el orden de llegada.

### Limitaciones de la FIFO original

La implementación basada en flip-flops individuales presentaba una arquitectura rígida y poco escalable. Al estar construida mediante el cableado manual de registros, la modificación de parámetros como la profundidad o el ancho de banda resultaba ineficiente y consumía una gran cantidad de recursos de hardware.

Además, la ausencia de una lógica de bypass incrementaba la latencia del sistema, ya que los datos requerían varios ciclos de reloj para estar disponibles en la salida. Por otro lado, los punteros de control eran propensos a errores de sincronización en las señales full y empty bajo condiciones de alto tráfico.

### Mejoras en la FIFO genérica

La versión mejorada introduce una arquitectura optimizada que incrementa la eficiencia, escalabilidad y robustez del diseño.

Se implementa una arquitectura de memoria circular, en la cual los datos permanecen almacenados en una matriz de memoria estática, mientras que únicamente los punteros de lectura (rd_ptr) y escritura (wr_ptr) se actualizan dinámicamente. Este enfoque reduce el consumo de recursos y facilita la escalabilidad del diseño.

También se incorpora una salida combinacional con comportamiento tipo FWFT (First-Word Fall Through). Esto permite que, cuando la FIFO está vacía, el dato de entrada fluya directamente hacia la salida, eliminando ciclos innecesarios de latencia y mejorando el rendimiento general del sistema.

Adicionalmente, se añade un contador centralizado de ocupación mediante el registro count, el cual monitorea en tiempo real la cantidad de elementos dentro de la FIFO. Esto garantiza la correcta generación de las señales full y empty, evitando condiciones de overflow o underflow.

Finalmente, el diseño soporta operaciones simultáneas de lectura y escritura dentro del mismo ciclo de reloj, manteniendo la coherencia del contador interno y la integridad de los datos incluso bajo condiciones de alta actividad.

## 3. Descripción de módulos

# Módulo: Test (Controlador de la Prueba test.sv)

El Test es el componente de más alto nivel en la lógica de software del entorno de verificación. Define el plan de verificación, configura los estímulos y coordina la ejecución de todos los componentes del ambiente mediante comunicación basada en Mailboxes.

## Funcionalidades Clave

El Test se encarga de definir la estrategia de validación del DUT.

Implementa configuración dinámica mediante plusargs, permitiendo modificar parámetros de la simulación desde la línea de comandos sin necesidad de recompilar el entorno. Esto facilita la ejecución de regresiones y pruebas masivas.

También genera diferentes escenarios de verificación, incluyendo tráfico aleatorio, casos de esquina y pruebas de estrés sobre la FIFO.

Finalmente, controla el ciclo de vida completo de la simulación, desde la inicialización del ambiente hasta la recolección de resultados finales.

## Análisis de Mejoras (Implementación Original vs. Mejorada)

| Característica | Implementación Original | Implementación Mejorada | Impacto |
|----------------|------------------------|--------------------------|----------|
| Flexibilidad de parámetros | Valores fijos (hardcoded) | Uso de `$value$plusargs` | Permite modificar la simulación sin recompilar |
| Conexión de interfaz | Configuración parcial | Inicialización en `run()` | Asegura propagación correcta de interfaces virtuales |
| Visibilidad de configuración | No reportada | Debug de parámetros en consola | Mejora trazabilidad de pruebas |
| Estructura de prueba | Secuencia rígida | Plan de verificación estructurado | Facilita extensión de casos de prueba |

## Justificación Técnica de la Optimización

La mejora más importante del módulo Test es la introducción de configuración dinámica mediante plusargs.

En la versión original, cualquier cambio en parámetros como el número de transacciones requería recompilar el entorno. Con la versión mejorada, estos valores pueden ser modificados en tiempo de ejecución, lo que resulta esencial en flujos modernos de verificación y entornos de integración continua (CI/CD).

Además, la separación clara entre configuración y ejecución mejora significativamente la legibilidad del código. Primero se capturan los parámetros, luego se configuran los componentes del entorno y finalmente se inicia la simulación. Esta estructura modular facilita la escalabilidad del banco de pruebas y la incorporación de nuevos escenarios sin modificar la arquitectura existente.

# Módulo: Test Bench (Top Level test_bench.sv)

El Test Bench es el nivel más alto de la jerarquía en el entorno de verificación. Su función es integrar el mundo físico (módulos de hardware/Verilog) con el mundo de software (clases de verificación/SystemVerilog). Es el encargado de instanciar el dispositivo bajo prueba (DUT), generar las señales de reloj y orquestar el arranque de la simulación.


## Componentes Integrados

| Componente | Tipo | Función |
|------------|------|----------|
| uut        | Hardware (fifo_generic) | Unidad bajo prueba que se desea validar |
| _if        | Interface (fifo_if)     | Bus de señales entre el testbench y la FIFO |
| t0         | Clase de Software (test) | Contiene la lógica y secuencias de verificación |
| clk        | Señal reg                | Generador de reloj del sistema |

## Funcionalidades del Módulo

El Test Bench es responsable de establecer el entorno de ejecución completo de la simulación.

Genera una señal de reloj estable (100 MHz) que sincroniza todos los bloques del sistema. También instancia el DUT y conecta sus puertos a la interfaz física del entorno.

Adicionalmente, realiza la inyección de interfaces virtuales hacia las clases de verificación, permitiendo que componentes como el Driver, Monitor y Ambiente interactúen directamente con las señales del hardware.

Finalmente, incorpora un mecanismo de watchdog que supervisa el tiempo de ejecución de la simulación y evita bloqueos infinitos en caso de fallos del sistema.

---

## Análisis de Mejoras (Implementación Original vs. Mejorada)

| Característica | Implementación Original | Implementación Mejorada | Impacto |
|----------------|------------------------|--------------------------|----------|
| Organización de código | Inclusión parcial de archivos | Estructura completa integrada | Asegura compilación completa del entorno |
| Conexión de interfaces | Solo Driver conectado | Conexión completa (Driver, Monitor, Ambiente) | Mejora la observabilidad del DUT |
| Documentación | Comentarios mínimos | Documentación técnica detallada | Facilita mantenimiento y escalabilidad |
| Instanciación del DUT | Código mezclado con versiones anteriores | Instancia limpia y parametrizada | Elimina ambigüedad del diseño activo |

---

## Justificación Técnica de la Optimización

La mejora más importante en el Test Bench es la correcta distribución de las interfaces virtuales hacia todos los componentes del entorno de verificación.

En la versión original, únicamente el Driver tenía acceso a la interfaz física, lo que limitaba la observabilidad del sistema. En la versión mejorada, tanto el Monitor como el Ambiente reciben correctamente el puntero a la interfaz (vif), lo que permite una verificación completa basada en observación real del DUT.

Además, la incorporación de un mecanismo de watchdog robusto mejora la estabilidad de la simulación, evitando bloqueos indefinidos y asegurando que cualquier fallo crítico sea detectado dentro de un tiempo controlado. Esto optimiza el uso de recursos computacionales y mejora la depuración del sistema.

## Módulo: Ambiente (Environment ambiente.sv)

El Ambiente es el componente de nivel superior que actúa como contenedor principal del entorno de verificación. Su función es instanciar, configurar y conectar todos los bloques funcionales (Agente, Driver, Monitor, Checker y Scoreboard), estableciendo los canales de comunicación necesarios para la ejecución coordinada de las pruebas.

### Interfaces y comunicación

El Ambiente gestiona tanto la conexión con el hardware (RTL) como la infraestructura de comunicación entre los distintos componentes del testbench.

La interfaz virtual `_if` conecta el entorno de verificación con las señales físicas del DUT, incluyendo señales como clk, rst, push y pop. Esta conexión permite la interacción directa con el diseño bajo prueba.

Los mailboxes `test_agent_mbx` y `test_sb_mbx` permiten la comunicación entre el Test y los componentes de generación de estímulos y reporte final, respectivamente. Por otro lado, los mailboxes internos `agnt_drv_mbx` y `mon_chkr_mbx` gestionan el flujo de datos entre Agente–Driver y Monitor–Checker.

### Funcionalidades del módulo

El Ambiente se encarga de la instanciación jerárquica de todos los componentes del testbench, asegurando que parámetros como width y depth se propaguen correctamente a través del sistema.

También establece la interconectividad entre los diferentes bloques mediante la configuración de mailboxes, lo que permite un diseño desacoplado y modular donde cada componente cumple una función específica sin dependencias directas.

La ejecución concurrente de todos los procesos se gestiona mediante la instrucción `fork-join_none`, lo que permite que el Driver, Monitor, Checker y Agente operen de manera paralela durante la simulación.

### Comparación: versión original vs mejorada

La arquitectura original se basaba en un flujo de validación Driver-Checker, donde el Checker recibía directamente la información generada por el Driver. Este enfoque limitaba la capacidad de observación del sistema, ya que la verificación dependía de la intención del estímulo y no del comportamiento real del hardware.

En la versión mejorada, se introduce un Monitor independiente que observa directamente las salidas del DUT. El Checker ahora recibe la información a través del Monitor, lo que permite una verificación tipo black-box basada en el comportamiento real del diseño.

En cuanto a la conexión de la interfaz, el diseño original realizaba la asignación en el constructor, mientras que la versión mejorada la traslada a la tarea run, garantizando que la interfaz virtual esté completamente inicializada antes de iniciar la ejecución de los componentes.

Finalmente, los mailboxes del Test pasan de ser creados internamente a ser inyectados desde el exterior, lo que incrementa la flexibilidad del entorno y permite la creación de múltiples configuraciones de prueba sin modificar el ambiente.

### Justificación técnica de la mejora

La mejora más importante en esta arquitectura es la incorporación del Monitor y la redefinición del flujo de verificación. En el diseño original, el Driver enviaba directamente los datos al Checker, lo que no garantizaba que el estímulo hubiese sido correctamente procesado por el DUT.

En la versión mejorada, el Monitor observa pasivamente las señales de salida de la FIFO y envía esta información al Checker. Esto asegura que la verificación se base en el comportamiento real del hardware, permitiendo detectar errores de temporización, fallos internos de lógica y discrepancias entre el estímulo generado y la respuesta del diseño.

Este cambio convierte el sistema en una arquitectura de verificación tipo black-box, que es el enfoque utilizado en entornos de verificación funcional modernos.

## Módulo: Agente (Generator agent.sv)

El Agente actúa como el generador de estímulos de alto nivel dentro del entorno de verificación. Su función principal es la creación de objetos de datos denominados transacciones, los cuales contienen la información necesaria para ejecutar una operación en la FIFO (tipo de operación, dato y retardo).

### Entradas y salidas (interfaces lógicas)

Al ser un componente de software basado en SystemVerilog, la comunicación se realiza mediante mailboxes (buzones sincrónicos).

El mailbox `test_agent_mbx` funciona como entrada y recibe instrucciones desde el Test, tales como llenado aleatorio o transacciones específicas. Por otro lado, el mailbox `agnt_drv_mbx` actúa como salida y envía objetos de tipo `trans_fifo` hacia el Driver para su ejecución en el diseño.

### Funcionalidades del módulo

El Agente implementa aleatorización restringida mediante el uso de `.randomize()`, generando datos y retardos dentro de los límites definidos por constraints. Esto asegura que las transacciones respeten las reglas del protocolo de la FIFO.

También incorpora una estructura de control basada en `case`, la cual interpreta las instrucciones provenientes del Test y permite alternar entre distintos modos de operación, como ráfagas aleatorias o pruebas dirigidas.

Adicionalmente, el módulo permite configuración en tiempo de ejecución, ajustando dinámicamente parámetros como el número de transacciones y el nivel de estrés del tráfico.

### Comparación: versión original vs mejorada

El control de escenarios en la versión original se basaba en una secuencia fija de escritura y lectura. En la versión mejorada, este comportamiento es configurable mediante la variable `solo_escrituras`, lo que permite deshabilitar las lecturas y generar condiciones de saturación controlada.

En términos de depuración, el sistema original utilizaba mensajes genéricos de consola. En la versión mejorada, los reportes discriminan explícitamente el tipo de transacción (WRITE o READ), lo que facilita el análisis del log y el rastreo de eventos.

Respecto al manejo de parámetros, se reemplazó la asignación simple por el uso de `this`, evitando ambigüedad entre variables locales y atributos de clase y asegurando una configuración más robusta.

Finalmente, en cuanto a flexibilidad de tráfico, el diseño evolucionó desde un flujo balanceado hacia un modelo que permite saturación controlada, separando explícitamente fases de llenado y vaciado para pruebas de estrés.

### Justificación técnica de la mejora

La incorporación de la variable `solo_escrituras` es la mejora más significativa del módulo. En el diseño original, una fase de escritura siempre era seguida automáticamente por una fase de lectura, limitando la capacidad de generar escenarios de estrés real.

En la versión mejorada, este comportamiento puede modificarse mediante plusargs, permitiendo deshabilitar las lecturas y forzar la FIFO a alcanzar su estado de ocupación máxima. Esto es fundamental para validar el comportamiento del diseño bajo condiciones de full, verificando que el sistema maneje correctamente el overflow y mantenga estables sus señales de estado.

## Módulo: Driver (Controlador de Protocolo driver.sv)

El Driver es el componente encargado de la interfaz física del entorno de verificación. Su función principal es la serialización de transacciones: traduce los objetos abstractos enviados por el Agente en cambios de niveles lógicos (0 y 1) sincronizados con el reloj, permitiendo que la FIFO procese los estímulos como si vinieran de un hardware real.

### Entradas y salidas

El Driver actúa como puente entre la capa de software y los pines del hardware.

El virtual interface (`vif`) representa la conexión directa con el DUT, controlando señales físicas como push, pop, dato_in y reset. Por otro lado, el mailbox `agnt_drv_mbx` recibe las transacciones generadas por el Agente, que contienen la información necesaria para ejecutar cada operación.

### Funcionalidades del módulo

El Driver garantiza la correcta sincronización del protocolo, asegurando que todas las señales cambien en el flanco de subida del reloj (posedge clk), respetando los tiempos de setup y hold del diseño.

También implementa manejo de latencia inyectada, utilizando el parámetro `retardo` de cada transacción para simular tráfico real, ya sea en ráfagas o de forma espaciada.

El módulo gestiona correctamente el estado de reset, ejecutando secuencias de inicialización que garantizan que la FIFO inicie desde un estado conocido.

Finalmente, controla la ejecución de operaciones de lectura, escritura y escritura_lectura, activando y desactivando las señales del protocolo de forma precisa en cada ciclo.

### Comparación: versión original vs mejorada

En la versión original, el Driver tenía una responsabilidad mixta, ya que además de controlar los pines del DUT, también participaba en la comunicación con el Checker. Esto rompía el principio de responsabilidad única y generaba dependencia innecesaria entre componentes.

En la versión mejorada, el Driver se limita exclusivamente al control del hardware, mientras que la verificación se delega completamente al Monitor y al Checker. Esto mejora la modularidad y la claridad del flujo de datos.

Otra mejora importante es el soporte para operaciones simultáneas mediante `escritura_lectura`, lo que permite activar push y pop en el mismo ciclo de reloj. Esto incrementa el nivel de estrés aplicado al DUT y permite validar casos complejos de concurrencia interna.

También se introduce un protocolo estricto de limpieza de señales, asegurando que después de cada operación las señales push y pop regresen inmediatamente a cero, evitando activaciones accidentales.

Finalmente, el manejo del bus de datos se vuelve más robusto, manteniendo el valor de `dato_in` estable durante los ciclos de retardo, lo que emula de forma más realista el comportamiento de un bus físico.

### Justificación técnica de la mejora

La mejora más importante en el Driver es el desacoplamiento total del flujo de verificación. En la arquitectura original, el Driver enviaba información directamente al Checker, lo que podía ocultar errores en la capa física del sistema.

En la versión mejorada, el Driver únicamente controla los pines del DUT, eliminando cualquier dependencia con la lógica de verificación.

La incorporación de la operación simultánea `escritura_lectura` permite forzar condiciones de alta concurrencia dentro de la FIFO. Esto es fundamental para validar el comportamiento del contador interno, la coherencia de los punteros y la ausencia de condiciones de carrera.

De esta forma, el Driver se convierte en un generador de estímulos a nivel físico completamente puro, alineado con arquitecturas modernas de verificación funcional.

## Módulo: Monitor (Observador Pasivo monitor.sv)

El Monitor es el componente encargado de la observabilidad dentro del entorno de verificación. Su función es puramente pasiva: no altera las señales de la interfaz, sino que observa el tráfico en los pines del DUT (`fifo_if`) y traduce esos niveles lógicos en objetos de transacción (`trans_fifo`) para su posterior validación en el Checker.

### Entradas y salidas

El Monitor se conecta directamente al hardware a través de la interfaz virtual y envía la información capturada al Checker mediante un mailbox.

- `vif` (entrada física): conexión virtual a la interface `fifo_if`, que incluye señales de reloj, reset, habilitadores y buses de datos.
- `mon_chkr_mbx` (salida lógica): mailbox que transporta las transacciones capturadas hacia el Checker.

### Evolución del componente

En versiones iniciales, el entorno de verificación no contaba con un Monitor completamente independiente, lo que limitaba la capacidad de observación directa del DUT.

En la versión mejorada, se introduce un Monitor modular separado, encargado exclusivamente de la captura de señales, lo que mejora la fidelidad del modelo de verificación y permite una arquitectura tipo black-box más precisa.

### Funcionalidades del módulo

El Monitor realiza captura síncrona del estado del DUT en cada flanco de subida del reloj (posedge clk), garantizando consistencia temporal en la observación.

También identifica el tipo de operación ejecutada analizando las señales de control, clasificando cada evento como escritura, lectura, reset o escritura_lectura.

Los valores de los buses de entrada y salida son encapsulados en objetos de transacción junto con su marca de tiempo, permitiendo análisis posterior de latencia y comportamiento.

Adicionalmente, se implementa una estabilización del muestreo para asegurar la validez de los datos en señales combinacionales antes de ser enviados al Checker.

### Análisis de mejoras (implementación inicial vs optimizada)

| Característica      | Implementación inicial        | Versión optimizada        | Impacto en la verificación |
|--------------------|------------------------------|---------------------------|-----------------------------|
| Muestreo temporal  | Captura en flanco directo    | Retardo crítico (#2)      | Evita condiciones de carrera y captura valores estables del DUT |
| Arquitectura       | Máquina de estados explícita | Lógica directa condicional | Reduce complejidad y mejora mantenibilidad |
| Detección de reset | Reporte básico               | Prioridad estricta        | Garantiza limpieza inmediata del modelo |
| Precisión de datos | Captura manual de buses      | Asignación estructurada   | Diferenciación precisa entre entrada y salida |

### Justificación técnica de la optimización

La mejora más importante en el Monitor es la introducción de un retardo crítico (#2) después del flanco de reloj.

En la implementación inicial, el muestreo se realizaba directamente en el evento `@(posedge vif.clk)`. Sin embargo, debido al comportamiento del scheduler de SystemVerilog, esto puede provocar la captura de valores transitorios o no estabilizados, especialmente en señales combinacionales como `dato_out`.

En la versión optimizada, se introduce un pequeño retardo que permite que las señales del DUT se estabilicen antes de la captura. Esto evita condiciones de carrera entre la actualización del hardware y el muestreo del Monitor.

Este ajuste es esencial para garantizar que el Checker valide datos consistentes con el comportamiento real del hardware, evitando falsos errores de verificación.

## Módulo: Checker (Validador checker.sv)

El Checker es el componente encargado de verificar la integridad de los datos y el cumplimiento del protocolo de la FIFO. Actúa como un juez dentro del entorno de verificación, comparando la salida real del hardware (DUT) contra un modelo de referencia (Golden Model) emulado en software mediante una cola de SystemVerilog.

### Entradas y salidas

El Checker recibe información proveniente del Monitor y envía resultados al Scoreboard.

El mailbox `mon_chkr_mbx` actúa como entrada y transporta las transacciones capturadas directamente desde los pines del DUT. Por otro lado, el mailbox `chkr_sb_mbx` funciona como salida, enviando al Scoreboard los resultados de verificación, incluyendo transacciones completadas, errores y métricas de latencia.

### Funcionalidades del módulo

El Checker implementa un modelo de referencia (Golden Model) mediante una cola interna (`emul_fifo`) que reproduce el comportamiento ideal de la FIFO. Este modelo permite predecir qué datos deberían salir y en qué orden.

También realiza la validación de datos comparando el valor recibido del hardware con el valor almacenado en la cola emulada. Cualquier discrepancia se considera un error de verificación y puede detener la simulación.

Adicionalmente, el módulo detecta condiciones críticas como overflow y underflow, reportando situaciones donde se intenta escribir en una FIFO llena o leer de una FIFO vacía.

El Checker también calcula la latencia de cada transacción, determinando el tiempo que un dato permanece dentro de la FIFO como la diferencia entre el tiempo de entrada y el tiempo de salida.

### Comparación: versión original vs mejorada

En la versión original, el Checker recibía datos directamente del Driver, lo que implicaba validar la intención del estímulo en lugar del comportamiento real del hardware. En la versión mejorada, los datos provienen del Monitor, asegurando una verificación basada en observación directa del DUT.

La versión original no contemplaba explícitamente operaciones simultáneas, mientras que la versión mejorada incorpora lógica para manejar correctamente escenarios de escritura y lectura en el mismo ciclo de reloj.

En cuanto al manejo de bypass, el diseño original asumía una latencia fija, mientras que la versión mejorada detecta casos donde la FIFO está vacía y el dato se propaga inmediatamente, asignando latencia cero en estos escenarios.

Finalmente, la precisión en el cálculo de latencia mejora al basarse en tiempos reales capturados por el Monitor en lugar de estimaciones provenientes del Driver.

### Justificación técnica de la mejora

La mejora más importante en el Checker es el manejo de operaciones simultáneas (`escritura_lectura`). En el diseño original, estos eventos se procesaban de forma secuencial, lo que podía generar desincronización en el modelo de referencia.

En la versión mejorada, el Checker distingue tres escenarios principales.

En el caso de bypass, cuando la FIFO está vacía, el dato entra y sale en el mismo instante, resultando en latencia cero.

En el caso de colisión con FIFO llena, se valida que la lectura pueda ocurrir mientras se bloquea la escritura, preservando la integridad del sistema.

En el caso de operación simultánea normal, el Checker extrae el dato antiguo para validación y almacena el nuevo en la cola emulada.

Esta lógica de manejo de escenarios convierte al Checker en un validador robusto capaz de soportar condiciones de tráfico extremo y validar correctamente el comportamiento del diseño bajo cualquier situación.

# Módulo: Scoreboard (Centro de Análisis y Reportes score_board.sv)

El Scoreboard es el componente de análisis crítico del entorno de verificación. Su función es recolectar los resultados procesados por el Checker para generar estadísticas de rendimiento, medir latencias y emitir reportes detallados sobre el comportamiento de la FIFO durante la simulación.

## Entradas y Canales de Comunicación

| Mailbox       | Origen   | Tipo de Dato | Descripción |
|--------------|----------|--------------|-------------|
| chkr_sb_mbx  | Checker  | trans_sb     | Recibe resultados de comparación y timestamps de transacciones. |
| test_sb_mbx  | Test     | solicitud_sb | Recibe comandos de control para generación de reportes. |

## Funcionalidades del Módulo

El Scoreboard realiza la recolección histórica de transacciones, permitiendo análisis posteriores del comportamiento del DUT. Además, calcula métricas de rendimiento como latencia promedio, y clasifica eventos como operaciones exitosas, overflow y underflow.

También es responsable de generar reportes bajo demanda, proporcionando una visión global del estado de la simulación.

## Análisis de Mejoras (Original vs. Mejorado)

| Característica | Implementación Original | Implementación Mejorada | Impacto |
|----------------|------------------------|--------------------------|----------|
| Flujo de Ejecución | Bloqueante | Concurrente | Permite procesar datos y solicitudes simultáneamente |
| Gestión de Memoria | pop_front destructivo | Acceso indexado | Mantiene historial completo de transacciones |
| Precisión Matemática | División entera | Conversión a real ($itor) | Mejora precisión de métricas |
| Robustez | Sin validaciones | Protección contra división por cero | Evita fallos en simulación |

## Justificación Técnica de la Optimización

La principal mejora del Scoreboard es la eliminación del consumo destructivo de la cola de transacciones, reemplazándolo por acceso indexado. Esto permite mantener un historial completo de la simulación sin afectar la integridad de los datos.

Adicionalmente, la separación de lógica mediante condiciones independientes mejora la concurrencia, permitiendo que el Scoreboard procese simultáneamente datos provenientes del Checker y solicitudes del Test sin bloquear el flujo de verificación.

Finalmente, el uso de conversiones a tipo real mejora la precisión del cálculo de latencia promedio, lo que resulta esencial para análisis de rendimiento en sistemas de alta velocidad.

## Módulo: Definiciones Globales, Transacciones e Interface (interface_transactions.sv)

Este conjunto de definiciones constituye el lenguaje común y la infraestructura de conexión del entorno de verificación. Define qué es una operación (transacción), por dónde viaja (interface) y cómo se comunican los componentes mediante mailboxes.

### 1. Definiciones de tipos

Se estandarizan los tipos de datos para garantizar seguridad de tipos (type safety) y facilitar el control desde el Test.

- `tipo_trans`: lectura, escritura, reset, escritura_lectura. Define las operaciones posibles en el DUT.
- `solicitud_sb`: retardo_promedio, reporte. Comandos de control para el Scoreboard.
- `instrucciones_agente`: llenado_aleatorio, trans_aleatoria, entre otros. Escenarios de prueba definidos por el Test.
- Mailboxes: `trans_fifo_mbx`, `trans_sb_mbx`, entre otros. Canales de comunicación especializados por tipo de objeto.

### 2. Clase de transacción (trans_fifo)

La transacción es el objeto central del entorno de verificación. Encapsula toda la información necesaria para representar un evento dentro de la FIFO.

Incluye los siguientes campos:

- `retardo` (rand): número de ciclos de espera antes de la operación, utilizado para generar tráfico realista.
- `dato` (rand): valor que será escrito en la FIFO.
- `dato_out`: valor capturado por el Monitor durante una lectura.
- `tiempo`: marca temporal utilizada para el cálculo de latencia.

### 3. Interface de la FIFO (fifo_if)

La interface agrupa las señales físicas del DUT y actúa como punto de conexión entre el entorno de verificación y el diseño en Verilog.

Se organiza en tres grupos principales:

- Control: `rst`, `push`, `pop`.
- Estado: `full`, `pndng`.
- Datos: `dato_in` y `dato_out` con ancho parametrizable.

### Análisis de mejoras (original vs mejorado)

| Característica        | Versión original          | Versión mejorada              | Impacto en la verificación |
|----------------------|---------------------------|-------------------------------|----------------------------|
| Tipos de operación   | 3 operaciones básicas     | Incluye escritura_lectura     | Permite validar colisiones y bypass (FWFT) |
| Estructura de datos  | Transacción simplificada  | Incluye dato_out y max_retardo | Mejora trazabilidad y análisis de latencia |
| Seguridad de tipos   | Mailboxes genéricos       | Mailboxes tipados             | Reduce errores de conexión entre módulos |
| Reportes del SB      | Básico                    | Cálculo automático de latencia | Automatiza análisis de rendimiento |

### Justificación técnica de la mejora

La mejora más importante es la inclusión de la operación `escritura_lectura` y la tipificación estricta de los mailboxes.

En la versión original, una operación simultánea requería enviar múltiples transacciones separadas, lo que podía provocar desalineación temporal en el simulador y resultados inconsistentes. En la versión mejorada, esta operación se encapsula en un único tipo de transacción, garantizando que el Driver ejecute push y pop en el mismo flanco de reloj. Esto es esencial para validar correctamente la lógica de bypass del DUT.

Además, el uso de mailboxes tipados mediante `typedef mailbox #(trans_fifo)` mejora la robustez del entorno. Cualquier conexión incorrecta entre componentes es detectada en tiempo de compilación, evitando errores difíciles de depurar en simulación.

## Módulo: FIFO Genérica (DUT fifo.sv)

La FIFO (First-In, First-Out) es el componente bajo prueba (Device Under Test). Su propósito es el almacenamiento temporal de datos, garantizando que el primer dato en entrar sea el primero en salir. Esta implementación es síncrona y parametrizable, lo que permite ajustar el ancho de palabra y la profundidad según los requisitos del diseño.

### Interfaces de hardware

El módulo FIFO se comunica mediante las siguientes señales de entrada y salida:

- `writeData` (entrada): bus de datos de ancho DataWidth utilizado para almacenar información en la FIFO.
- `writeEn` (entrada): señal de habilitación de escritura (push).
- `readEn` (entrada): señal de habilitación de lectura (pop).
- `clk` (entrada): reloj global síncrono.
- `rst` (entrada): reset asíncrono activo en alto.
- `readData` (salida): bus de salida con el dato más antiguo almacenado.
- `full` (salida): indica que la FIFO ha alcanzado su capacidad máxima.
- `pndng` (salida): indica que la FIFO contiene datos disponibles o en condición de bypass.

### Funcionalidades del módulo

El diseño utiliza una memoria interna parametrizable cuya profundidad (Depth) y ancho de palabra (DataWidth) se definen mediante parámetros de Verilog, permitiendo su reutilización en diferentes configuraciones.

La FIFO implementa punteros circulares de lectura y escritura, los cuales se reinician al alcanzar el límite de la memoria. Esto permite un uso eficiente del espacio disponible sin necesidad de mover físicamente los datos.

También incorpora modo FWFT (First-Word Fall Through), donde el dato en la cabeza de la FIFO está disponible en la salida sin necesidad de un ciclo adicional tras la operación de lectura.

Adicionalmente, se implementa lógica de bypass, permitiendo que un dato pase directamente de la entrada a la salida cuando la FIFO está vacía y se presenta una condición de lectura y escritura simultánea.

### Comparación: versión original vs mejorada

En la versión original, la FIFO estaba implementada mediante instancias individuales de flip-flops, lo que generaba una arquitectura rígida y poco escalable. Incrementar la profundidad implicaba aumentar manualmente la cantidad de registros y conexiones.

En la versión mejorada, se utiliza una matriz de memoria indexada, donde los datos permanecen almacenados de forma estática y únicamente los punteros de lectura y escritura se actualizan dinámicamente. Esto reduce significativamente la complejidad del diseño y mejora la síntesis en FPGA y ASIC.

El control de salida también evoluciona desde una red de multiplexores a una asignación combinacional directa, optimizando los caminos críticos y reduciendo el consumo de área.

Los punteros dejan de representar movimiento físico de datos y pasan a ser direcciones lógicas dentro de la memoria, eliminando transferencias innecesarias entre registros.

Finalmente, las banderas full y pndng se basan en un contador de ocupación robusto, lo que mejora la precisión del estado interno de la FIFO y reduce la posibilidad de inconsistencias bajo condiciones de alta actividad.

### Justificación técnica de la mejora

La principal mejora en esta implementación es el cambio de una arquitectura basada en registros individuales hacia una memoria indexada con punteros.

En el diseño original, la escalabilidad era limitada, ya que cada incremento en la profundidad implicaba replicar hardware. En contraste, la versión mejorada desacopla la estructura física del tamaño de la FIFO, permitiendo su crecimiento sin cambios estructurales significativos.

Además, la incorporación de lógica de bypass reduce la latencia en escenarios donde la FIFO está vacía, permitiendo que los datos fluyan directamente de entrada a salida sin ciclos adicionales de espera.

Esto convierte a la FIFO en un diseño más eficiente, escalable y adecuado para sistemas de alta velocidad.

## 4. Plan de pruebas

## 5. Casos de esquina

## 6. Mejoras implementadas

## 7. Resultados

## 8. Conclusiones
