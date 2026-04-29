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

## 🚀 Ejecución Rápida

El entorno está diseñado para ejecutarse mediante un script de regresión automatizada.

### Ejecutar regresión:

```bash
./run_fifo_regression.sh
