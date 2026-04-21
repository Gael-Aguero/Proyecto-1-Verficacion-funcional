FIFO Generic Verification Environment

Integrantes del grupo: Gael Aguero / Kendy Arias

Este proyecto mejora e implementa un entorno de verificación modular y parametrizado en SystemVerilog para validar una FIFO genérica. Utiliza una arquitectura basada en clases, siguiendo principios similares a UVM (Universal Verification Methodology).

📊 Arquitectura del Entorno

El siguiente diagrama muestra la jerarquía de componentes y el flujo de transacciones:

-Link:

🚀 Guía de Uso

El proyecto está diseñado para ejecutarse directamente en simuladores HDL.

Flujo típico:
Compilar todos los archivos .sv
Ejecutar el test_bench
Seleccionar el test deseado en test.sv

⚙️ El entorno se inicializa automáticamente:

Se construye el ambiente
Se configuran agentes y componentes
Se ejecutan transacciones sobre el DUT

Configuración dinámica (Plusargs)

El testbench permite parametrización sin recompilación:

+NUM_TRANS → número de transacciones
+MAX_RETARDO → retardo máximo aleatorio
+SOLO_ESCRITURAS → fuerza modo escritura

Ejemplo:

+NUM_TRANS=50 +MAX_RETARDO=10 +SOLO_ESCRITURAS=1


📂 Documentación Detallada

Para un análisis profundo de cada componente, consulte el reporte técnico:

Link:

🛠️ Requisitos

Simulador compatible con SystemVerilog (Questasim, Vivado, ModelSim).
Soporte para interfaces virtuales
Soporte para estándares de cronometraje 1ns/1ps.

## 📂 Documentación Detallada

Para un análisis profundo de cada componente, consulte el reporte técnico:

🔗 Link: *(insertar aquí enlace al PDF o repositorio)*

---

## 🛠️ Requisitos

- Simulador compatible con SystemVerilog (QuestaSim / ModelSim / Vivado)
- Soporte para interfaces virtuales
- Resolución de tiempo: 1ns / 1ps
