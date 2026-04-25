#!/bin/bash
# ============================================================
# run_fifo_regression.sh - Regresión FIFO
# Uso: ./run_fifo_regression.sh [NUM_TESTS]
# ============================================================

source /mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools2.sh

NUM_TESTS=${1:-50}
MAX_W=256
MAX_D=256

echo "=========================================="
echo "  REGRESIÓN FIFO - $NUM_TESTS pruebas"
echo "=========================================="

# Compilar una sola vez con máximos
echo ""
echo "Compilando con WIDTH=$MAX_W, DEPTH=$MAX_D..."
vcs -sverilog -timescale=1ns/1ps \
    +define+WIDTH=$MAX_W \
    +define+DEPTH=$MAX_D \
    test_bench.sv \
    -o simv \
    -l compile.log

if [ $? -ne 0 ]; then
    echo "ERROR: Falló la compilación"
    tail -20 compile.log
    exit 1
fi
echo "Compilación exitosa"

# Ejecutar pruebas
PASSED=0
FAILED=0

for i in $(seq 1 $NUM_TESTS); do
    
    # Aleatorizar parámetros
    W=$((2 + RANDOM % 255))
    D=$((4 + RANDOM % 253))
    D=$((D % 2 ? D + 1 : D))  # hacer par
    
    S=$((RANDOM * 1000 + i))
    N=$((50 + RANDOM % 450))
    
    RMIN=$((RANDOM % 5))
    RMAX=$((RMIN + RANDOM % 15 + 1))
    
    PL=$((RANDOM % 101))
    PE=$((RANDOM % 101))
    PS=$((RANDOM % 51))
    PR=$((RANDOM % 21))
    
    PATRONES=("RANDOM" "CERO" "UNO" "AA" "55" "SEC")
    PATRON=${PATRONES[$((RANDOM % 6))]}
    
    ESTADOS=("ALEATORIO" "VACIO" "LLENO" "MITAD")
    ESTADO=${ESTADOS[$((RANDOM % 4))]}
    
    echo ""
    echo "=========================================="
    echo "  Test $i/$NUM_TESTS"
    echo "=========================================="
    echo "  WIDTH       = $W"
    echo "  DEPTH       = $D"
    echo "  SEMILLA     = $S"
    echo "  NUM_TRANS   = $N"
    echo "  RETARDO     = [$RMIN : $RMAX]"
    echo "  ESTADO_INI  = $ESTADO"
    echo "  PATRON      = $PATRON"
    echo "  PESOS       = L:$PL E:$PE S:$PS R:$PR"
    echo "=========================================="
    
    ./simv +WIDTH_ARG=$W +DEPTH_ARG=$D +SEMILLA=$S +NUM_TRANS=$N \
           +RETARDO_MIN=$RMIN +RETARDO_MAX=$RMAX \
           +PESO_L=$PL +PESO_E=$PE +PESO_S=$PS +PESO_R=$PR \
           +PATRON=$PATRON +ESTADO_INI=$ESTADO \
           +vcs+lic+wait > sim_${i}.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo "  PASS"
        PASSED=$((PASSED + 1))
        rm -f sim_${i}.log #si quieres ver logs de cada test, quita esto, esto borra los test para que corra limpio
    else
        echo "  FAIL"
        FAILED=$((FAILED + 1))
        echo "W=$W D=$D S=$S N=$N L=$PL E=$PE S=$PS R=$PR PATRON=$PATRON ESTADO=$ESTADO" >> failed.txt
    fi
done

# Limpiar
rm -rf simv simv.daidir csrc compile.log

# Reporte final
echo ""
echo "=========================================="
echo "  REGRESIÓN COMPLETADA"
echo "=========================================="
echo "  Total:  $NUM_TESTS"
echo "  Pass:   $PASSED"
echo "  Fail:   $FAILED"
echo "=========================================="

if [ $FAILED -gt 0 ]; then
    echo ""
    echo "Pruebas fallidas:"
    cat failed.txt
    exit 1
else
    echo ""
    echo "Todas las pruebas pasaron"
    exit 0
fi