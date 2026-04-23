#!/bin/bash
# ============================================================
# run_fifo_regression.sh - Script de Regresión para FIFO
# ============================================================

NUM_TESTS=3
source /mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools2.sh;
echo "=========================================="
echo "  REGRESIÓN FIFO - $NUM_TESTS pruebas"
echo "=========================================="

for i in $(seq 1 $NUM_TESTS); do
  
  # Aleatorizar parámetros
  DEPTH=$((2 + RANDOM % 255))   # 2 a 256
  WIDTH=$((2 + RANDOM % 255))   # 2 a 256
  
  # Aleatorizar plusargs
  MAX_RETARDO=$((1 + RANDOM % 10))       # 1 a 10
  NUM_TRANS=$((4 + RANDOM % 13))         # 4 a 16
  SOLO_ESCRITURAS=$((RANDOM % 2))        # 0 o 1
  
  echo ""
  echo "=========================================="
  echo "Test $i/$NUM_TESTS"
  echo "=========================================="
  echo "  DEPTH = $DEPTH"
  echo "  WIDTH = $WIDTH"
  echo "  MAX_RETARDO = $MAX_RETARDO"
  echo "  NUM_TRANS = $NUM_TRANS"
  echo "  SOLO_ESCRITURAS = $SOLO_ESCRITURAS"
  echo "=========================================="
  

  # Compilar con parámetros
  vcs -sverilog \
      -timescale=1ns/1ps \
      +define+WIDTH=$WIDTH \
      +define+DEPTH=$DEPTH \
      test_bench.sv \
      -o simv \
      -l compile.log
  
  if [ $? -ne 0 ]; then
    echo ""
    echo "❌ ERROR: Falló la compilación"
    echo "Últimas líneas del log de compilación:"
    tail -20 compile.log
    exit 1
  fi
  
  echo "  ✓ Compilación exitosa"
  echo ""
  echo "  Ejecutando simulación..."
  
  # Ejecutar simulación
  ./simv +MAX_RETARDO=$MAX_RETARDO \
         +NUM_TRANS=$NUM_TRANS \
         +SOLO_ESCRITURAS=$SOLO_ESCRITURAS \
         +vcs+lic+wait 2>&1 | tee sim_${i}.log
  
  if [ $? -ne 0 ]; then
    echo ""
    echo "❌ ERROR: Falló la simulación"
    echo "Últimas líneas del log de simulación:"
    tail -20 sim_${i}.log
    exit 1
  fi
  
  echo "  ✓ Simulación exitosa"
  
  # Limpiar archivos de compilación
  rm -rf simv simv.daidir csrc compile.log
  rm -f sim_${i}.log
  
done

echo ""
echo "=========================================="
echo "  ✓ REGRESIÓN COMPLETADA EXITOSAMENTE"
echo "  $NUM_TESTS/$NUM_TESTS pruebas pasaron"
echo "=========================================="