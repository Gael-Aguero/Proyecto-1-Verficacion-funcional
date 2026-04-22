# Entorno de Verificación para FIFO Genérico

> Entorno de verificación modular y parametrizado en SystemVerilog para validar una FIFO genérica — construido siguiendo una arquitectura basada en clases inspirada en UVM.

---

## 📋 Descripción General

Este proyecto mejora e implementa un entorno de verificación completamente parametrizado en SystemVerilog para validar un diseño de FIFO genérica. La arquitectura sigue una metodología basada en clases y componentes inspirada en UVM (Universal Verification Methodology), permitiendo una construcción de testbench escalable y reutilizable.

---

## 📊 Arquitectura

El siguiente diagrama ilustra la jerarquía de componentes y el flujo de transacciones a lo largo del entorno:

![Diagrama de Flujo](https://github.com/Gael-Aguero/Proyecto-1-Verficacion-funcional/blob/main/Imagenes/DiagramaFlujo%20de%20Modulo.png)

---

## 🚀 Guía de Uso

El proyecto está diseñado para ejecutarse directamente en cualquier simulador HDL con soporte para SystemVerilog.

### Flujo Típico

1. **Compilar** todos los archivos `.sv`
2. **Ejecutar** el módulo top `test_bench`
3. **Seleccionar** el caso de prueba deseado dentro de `test.sv`

Una vez iniciado, el entorno se inicializa automáticamente:

- Construye y conecta el entorno de verificación
- Configura agentes y sub-componentes
- Genera transacciones sobre el DUT (Device Under Test)

---

## ⚙️ Configuración Dinámica (Plusargs)

El testbench soporta parametrización en tiempo de ejecución sin necesidad de recompilar, mediante plusargs del simulador:

| Plusarg              | Descripción                                  |
|----------------------|----------------------------------------------|
| `+NUM_TRANS`         | Número de transacciones a generar            |
| `+MAX_RETARDO`       | Retardo aleatorio máximo entre operaciones   |
| `+SOLO_ESCRITURAS`   | Fuerza el modo solo escritura (valor `1`)    |

**Ejemplo de invocación:**

```bash
+NUM_TRANS=50 +MAX_RETARDO=10 +SOLO_ESCRITURAS=1
```

---

## 📂 Documentación

Para un análisis detallado de cada componente, consulte el reporte técnico completo:

🔗 **Reporte:** *(insertar aquí el enlace al PDF o repositorio)*

---

## 🛠️ Requisitos

- Simulador compatible con SystemVerilog (QuestaSim / ModelSim / Vivado)
- Soporte para interfaces virtuales
- Resolución de tiempo: `1ns / 1ps`

---

## 👥 Estudiantes

| Nombre        | Rol                        |
|---------------|----------------------------|
| Gael Agüero   | Estudiante de Ingeniería Electrónica  |
| Kendy Arias   | Estudiante de Ingeniería Electrónica  |
