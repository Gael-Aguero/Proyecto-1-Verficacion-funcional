# Entorno de Verificación para FIFO Genérico

> Entorno de verificación modular, parametrizado y automatizado en SystemVerilog para la validación de una FIFO genérica, basado en una arquitectura de componentes inspirada en UVM.

---

## 📋 Descripción General

Este proyecto implementa un entorno de verificación completo en SystemVerilog para validar el comportamiento funcional de una FIFO genérica bajo múltiples escenarios operativos.

A diferencia de un testbench tradicional basado en casos fijos, este entorno utiliza técnicas de **Verificación Basada en Restricciones (CRV)** y configuración dinámica mediante *plusargs*, permitiendo generar estímulos aleatorios controlados y explorar condiciones de borde (*corner cases*) del diseño.

El sistema fue diseñado con un enfoque modular y desacoplado, incorporando componentes como **Driver, Monitor, Checker y Scoreboard**, lo que permite una verificación robusta, reutilizable y escalable.

---

## 📊 Arquitectura

El siguiente diagrama ilustra la jerarquía de componentes y el flujo de transacciones dentro del entorno de verificación:

![Diagrama de Flujo](https://github.com/Gael-Aguero/Proyecto-1-Verficacion-funcional/blob/main/Imagenes/DiagramaFlujo%20de%20Modulo.png)

El flujo de verificación sigue el modelo:

**Agente → Driver → DUT → Monitor → Checker → Scoreboard**

Esto permite una validación tipo *black-box*, basada en el comportamiento real del hardware.

---

## 🚀 Guía de Uso

El proyecto está diseñado para ejecutarse en un entorno con soporte para SystemVerilog, utilizando un script de regresión automatizada.

### Flujo de Ejecución

1. Acceder al servidor o entorno de simulación
2. Ubicarse en la carpeta del proyecto
3. Ejecutar el script de regresión:

```bash
./fifo_regresion.sh
```
Por defecto, el script ejecuta 50 pruebas automatizadas. Es posible especificar la cantidad de iteraciones como argumento de entrada:
```bash
./fifo_regresion.sh 100
```

---
## 🛠️ Requisitos

- Simulador compatible con SystemVerilog (QuestaSim / ModelSim / Vivado / VCS)
- Soporte para interfaces virtuales
- Entorno Linux recomendado
- Resolución de tiempo: `1ns / 1ps`
---

## 📂 Documentación

Para un análisis detallado de cada componente, consulte el reporte técnico completo:

🔗 **Reporte:** [Ver documento](./Documentacion/Documentación%20Proyecto%201%20Verificación-%20AgueroG.AriasK..pdf)

---

## 👥 Estudiantes

| Nombre        | Rol                                 |
|---------------|-------------------------------------|
| Gael Agüero   | Estudiante de Ingeniería Electrónica |
| Kendy Arias   | Estudiante de Ingeniería Electrónica |
