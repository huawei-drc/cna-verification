#!/bin/sh
set -ex

# Usage (from root of the git repo): ./scripts/docker-run-usecases.sh
# Notice this script assumes the "make prepared" step has been executed before.

CNA_ALGORITHM=1
QSPINLOCK_ALGORITHM=2

solvers="yices2 mathsat5 Z3"

make docker_build

mkdir results
export DOCKER=1

# 01    Verifying cna (original version) under IMM using GenMC.
#       Expect no error detected [duration ~10 seconds].
./scripts/genmc.sh cna-c11.c | tee results/out01-genmc-cna-c11.txt

for solver in ${solvers}
do
    # 02    Verifying qspinlock under LKMM using Dartagnan,
    #       without applying any fix.
    #       Expect to find a liveness violation [duration ~1 minute].
    ./scripts/dartagnan.sh \
        -m lkmm \
        -t ${solver} \
        -p liveness \
        -DALGORITHM=${QSPINLOCK_ALGORITHM} \
        -DSKIP_PENDING \
        client-code.c | tee results/out02-dartagnan-${solver}-lkmm-qspinlock-livenessviolation.txt

    # 03    Verifying qspinlock under LKMM using Dartagnan,
    #       applying fix 1.
    #       Expect to find a safety violation [duration ~2 minutes].
    ./scripts/dartagnan.sh \
        -m lkmm \
        -t ${solver} \
        -p reachability,liveness \
        -DALGORITHM=${QSPINLOCK_ALGORITHM} \
        -DSKIP_PENDING \
        -DFIX1 \
        client-code.c | tee results/out03-dartagnan-${solver}-lkmm-qspinlock-safetyviolation.txt

    # 04    Verifying qspinlock under LKMM using Dartagnan,
    #       applying fixes 1 and 2.
    #       Expect no violation found and result [duration ~2 minutes].
    ./scripts/dartagnan.sh \
        -m lkmm \
        -t ${solver} \
        -p reachability,liveness \
        -DALGORITHM=${QSPINLOCK_ALGORITHM} \
        -DSKIP_PENDING \
        -DFIX1 -DFIX2 \
        client-code.c | tee results/out04-dartagnan-${solver}-lkmm-qspinlock-fixes.txt

    # 05    Verifying qspinlock under Armv8 using Dartagnan,
    #       without applying any fix.
    #       Expect no violation found and result UNKNOWN [duration ~3 minutes].
    ./scripts/dartagnan.sh \
        -m armv8 \
        -t ${solver} \
        -p reachability,liveness \
        -DALGORITHM=${QSPINLOCK_ALGORITHM} \
        -DSKIP_PENDING \
        client-code.c | tee results/out05-dartagnan-${solver}-armv8-qspinlock.txt

    # 06    Verifying qspinlock under RISC-V using Dartagnan,
    #       without applying any fix.
    #       Expect no violation found and result UNKNOWN [duration ~3 minutes].
    ./scripts/dartagnan.sh \
        -m riscv \
        -t ${solver} \
        -p reachability,liveness \
        -DALGORITHM=${QSPINLOCK_ALGORITHM} \
        -DSKIP_PENDING \
        client-code.c | tee results/out06-dartagnan-${solver}-riscv-qspinlock.txt

    # 07    Verifying qspinlock on Power using Dartagnan,
    #       without applying any fix.
    #       Expect no violation found and result UNKNOWN [duration ~3 minutes].
    ./scripts/dartagnan.sh \
        -m power \
        -t ${solver} \
        -p reachability,liveness \
        -DALGORITHM=${QSPINLOCK_ALGORITHM} \
        -DSKIP_PENDING \
        client-code.c | tee results/out07-dartagnan-${solver}-power-qspinlock.txt

    # 08    Verifying CNA under LKMM using Dartagnan,
    #       without applying any fix.
    #       Expect to find a liveness violation [duration ~30 minutes].
    ./scripts/dartagnan.sh \
        -m lkmm \
        -t ${solver} \
        -p liveness \
        -DALGORITHM=${CNA_ALGORITHM} \
        -DSKIP_PENDING \
        client-code.c | tee results/out08-dartagnan-${solver}-lkmm-cna-livenessviolation.txt

    # 09    Verifying CNA under LKMM using Dartagnan,
    #       applying fixes 1 and 2.
    #       Expect no violation found and result UNKNOWN [duration ~16 hours].
    ./scripts/dartagnan.sh \
        -m lkmm \
        -t ${solver} \
        -p reachability,liveness \
        -DALGORITHM=${CNA_ALGORITHM} \
        -DSKIP_PENDING \
        -DFIX1 -DFIX2 \
        client-code.c | tee results/out09-dartagnan-${solver}-lkmm-cna-fixes.txt

    # 10    Verifying CNA on Armv8 using Dartagnan,
    #       without applying any fix.
    #       Expect no violation found and result UNKNOWN [duration ~12 hours].
    ./scripts/dartagnan.sh \
        -m armv8 \
        -t ${solver} \
        -p reachability,liveness \
        -DALGORITHM=${CNA_ALGORITHM} \
        -DSKIP_PENDING \
        client-code.c | tee results/out10-dartagnan-${solver}-armv8-cna.txt

    # 11    Verifying CNA on RISC-V using Dartagnan,
    #       without applying any fix.
    #       Expect no violation found and result UNKNOWN [duration ~12 hours].
    ./scripts/dartagnan.sh \
        -m riscv \
        -t ${solver} \
        -p reachability,liveness \
        -DALGORITHM=${CNA_ALGORITHM} \
        -DSKIP_PENDING \
        client-code.c | tee results/out11-dartagnan-${solver}-riscv-cna.txt

    # 12    Verifying qspinlock on Power using Dartagnan,
    #       without applying any fix.
    #       Expect no violation found and result UNKNOWN [duration ~12 hours].
    ./scripts/dartagnan.sh \
        -m power \
        -t ${solver} \
        -p reachability,liveness \
        -DALGORITHM=${CNA_ALGORITHM} \
        -DSKIP_PENDING \
        client-code.c | tee results/out12-dartagnan-${solver}-power-cna.txt

done
