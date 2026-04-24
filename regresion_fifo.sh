#!/bin/bash
source /mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools2.sh

NUM_TESTS=${1:-50}
MAX_W=256
MAX_D=256

echo "Compilando..."
vcs -sverilog -timescale=1ns/1ps +define+WIDTH=$MAX_W +define+DEPTH=$MAX_D \
    test_bench.sv -o simv -l compile.log || exit 1

PASSED=0
for i in $(seq 1 $NUM_TESTS); do
    
    W=$((2 + RANDOM % 255))
    D=$((4 + RANDOM % 253))
    D=$((D % 2 ? D + 1 : D))
    
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
    
    echo "Test $i: W=$W D=$D S=$S N=$N L=$PL E=$PE S=$PS R=$PR Estado=$ESTADO"
    
    ./simv +WIDTH_ARG=$W +DEPTH_ARG=$D +SEMILLA=$S +NUM_TRANS=$N \
           +RETARDO_MIN=$RMIN +RETARDO_MAX=$RMAX \
           +PESO_L=$PL +PESO_E=$PE +PESO_S=$PS +PESO_R=$PR \
           +PATRON=$PATRON +ESTADO_INI=$ESTADO \
           +vcs+lic+wait > sim_${i}.log 2>&1
    
    if [ $? -eq 0 ]; then
        echo "  ✓ PASS"
        PASSED=$((PASSED + 1))
        rm -f sim_${i}.log
    else
        echo "  ✗ FAIL"
        echo "W=$W D=$D S=$S" >> failed.txt
    fi
done

rm -rf simv simv.daidir csrc compile.log
echo "$PASSED/$NUM_TESTS pasaron"