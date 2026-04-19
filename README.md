# 📌 Entorno de Verificación FIFO (SystemVerilog)

## Descripción General

Este proyecto implementa un entorno de verificación funcional para una FIFO síncrona utilizando SystemVerilog, basado en una arquitectura tipo **Layered Testbench** con enfoque modular.

El objetivo es validar el comportamiento del DUT bajo escenarios funcionales, aleatorios y de estrés, utilizando técnicas de verificación modernas como:

- Generación de estímulos constrained-random 
- Modelo de referencia (Golden Model) 
- Comunicación basada en mailboxes 
- Observación tipo black-box 
- Configuración dinámica mediante plusargs 

## 🔁 Flujo de Verificación
Agregar imagen

Este flujo separa claramente la generación de estímulos, la interacción con el DUT y la verificación, permitiendo mayor escalabilidad y mantenibilidad.

## ⚙️ DUT: FIFO

La FIFO es un bloque síncrono parametrizable que implementa política **First-In First-Out**, optimizado para entornos de alta concurrencia.

### Características principales:
- Memoria circular indexada (escalable)
- Punteros de lectura/escritura
- Contador de ocupación (count)
- Soporte FWFT (First Word Fall Through)
- Operaciones simultáneas de lectura/escritura

### Mejoras respecto a implementación base:
- Eliminación de arquitectura basada en flip-flops individuales
- Reducción de latencia mediante lógica de bypass
- Flags full/empty más robustas basadas en ocupación real
- Mejor comportamiento bajo condiciones de estrés

## 🧩 Arquitectura del Testbench

### 🔹 Test
Define la estrategia de verificación y configuración del entorno:
- Selección de escenarios mediante plusargs
- Control de tráfico (random, estrés, dirigido)
- Orquestación del entorno completo

### 🔹 Agent
Generador de estímulos de alto nivel:
- Transacciones aleatorias restringidas
- Escenarios configurables
- Independiente del timing del DUT

### 🔹 Driver
Interfaz física con el DUT:
- Traducción de transacciones a señales RTL
- Control sincronizado por reloj
- Soporte de operaciones concurrentes

### 🔹 Monitor
Observador pasivo del DUT:
- Captura señales directamente del hardware
- Genera transacciones de salida
- Permite verificación tipo black-box

### 🔹 Checker
Motor de verificación funcional:
- Modelo de referencia (Golden Model)
- Comparación entre esperado vs real
- Cálculo de latencia por transacción
- Detección de overflow y underflow

### 🔹 Scoreboard
Módulo de análisis y métricas:
- Historial de transacciones
- Cálculo de latencia promedio
- Reportes de rendimiento
- Estadísticas de simulación

## 🚀 Características del entorno

- Arquitectura modular y escalable 
- Separación estricta de responsabilidades 
- Verificación basada en observación (black-box) 
- Generación constrained-random de estímulos 
- Configuración en tiempo de ejecución (plusargs) 
- Soporte de tráfico concurrente y estrés 

## 📊 Mejoras respecto a la versión original

- Se introduce Monitor independiente (observación real del DUT)
- Checker basado en Golden Model en lugar de comparación directa con Driver
- Desacoplamiento completo entre generación y verificación
- Scoreboard con análisis estadístico real
- Soporte de operaciones simultáneas (read/write en mismo ciclo)
- Mayor robustez en escenarios de estrés

## 🎯 Objetivos de verificación

- Validar funcionalidad correcta de la FIFO
- Verificar comportamiento en condiciones de saturación (full/empty)
- Medir latencia real de transacciones
- Detectar errores de sincronización y concurrencia
- Aumentar cobertura mediante estímulos aleatorios

## 📌 Conclusión

Este entorno implementa una metodología de verificación funcional moderna para FIFO, combinando arquitectura modular, modelo de referencia y observación directa del DUT.

El resultado es un sistema de verificación robusto, escalable y alineado con prácticas utilizadas en entornos industriales de diseño digital.
