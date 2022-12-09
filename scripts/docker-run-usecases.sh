#!/bin/sh
set -ex

# Usage (from root of the git repo): ./scripts/docker-run-usecases.sh
# Notice this script assumes the "make prepared" step has been executed before.

CNA_ALGORITHM=1
QSPINLOCK_ALGORITHM=2

solvers="yices2 mathsat5 z3"

make docker_build

mkdir -p results
export DOCKER=1

# 01    Verifying cna (original version) under IMM using GenMC.
#       Expect no error detected [duration ~10 seconds].
./scripts/genmc.sh cna-c11.c | tee results/out01-genmc-cna-c11.txt

for solver in ${solvers}
do
    # 02    Checking liveness of qspinlock under LKMM v00 using Dartagnan,
    #       without applying any fix.
    #       Expect to find a violation.
    ./scripts/dartagnan.sh \
        -m lkmm-v00 \
        -t ${solver} \
        -p liveness \
        -DALGORITHM=${QSPINLOCK_ALGORITHM} \
        client-code.c | tee results/out02-dartagnan-${solver}-lkmm_v00-qspinlock-liveness-none.txt

    # 03    Checking liveness of qspinlock under LKMM v00 using Dartagnan,
    #       applying fix 1.
    #       Expect to find a violation.
    ./scripts/dartagnan.sh \
        -m lkmm-v00 \
        -t ${solver} \
        -p liveness \
        -DALGORITHM=${QSPINLOCK_ALGORITHM} \
        -DFIX1 \
        client-code.c | tee results/out03-dartagnan-${solver}-lkmm_v00-qspinlock-liveness-1.txt

    # 04    Checking liveness of qspinlock under LKMM v00 using Dartagnan,
    #       applying fix 1 and 2.
    #       Expect no violation found and result UNKNOWN.
    ./scripts/dartagnan.sh \
        -m lkmm-v00 \
        -t ${solver} \
        -p liveness \
        -DALGORITHM=${QSPINLOCK_ALGORITHM} \
        -DFIX1 -DFIX2 \
        client-code.c | tee results/out04-dartagnan-${solver}-lkmm_v00-qspinlock-liveness-12.txt

    # 05    Checking safety of qspinlock under LKMM v00 using Dartagnan,
    #       applying fixes 1 and 2.
    #       Expect to find a violation.
    ./scripts/dartagnan.sh \
        -m lkmm-v00 \
        -t ${solver} \
        -p reachability \
        -DALGORITHM=${QSPINLOCK_ALGORITHM} \
        -DFIX1 -DFIX2 \
        client-code.c | tee results/out05-dartagnan-${solver}-lkmm_v00-qspinlock-safety-12.txt

    # 06    Checking safety of qspinlock under LKMM v00 using Dartagnan,
    #       applying fixes 1, 2 and 3.
    #       Expect to find a violation.
    ./scripts/dartagnan.sh \
        -m lkmm-v00 \
        -t ${solver} \
        -p reachability \
        -DALGORITHM=${QSPINLOCK_ALGORITHM} \
        -DFIX1 -DFIX2 -DFIX3 \
        client-code.c | tee results/out06-dartagnan-${solver}-lkmm_v00-qspinlock-safety-123.txt

    # 07    Checking safety of qspinlock under LKMM v00 using Dartagnan,
    #       applying fixes 1, 2, 3 and 4.
    #       Expect no violation found and result UNKNOWN.
    ./scripts/dartagnan.sh \
        -m lkmm-v00 \
        -t ${solver} \
        -p reachability \
        -DALGORITHM=${QSPINLOCK_ALGORITHM} \
        -DFIX1 -DFIX2 -DFIX3 -DFIX4 \
        client-code.c | tee results/out07-dartagnan-${solver}-lkmm_v00-qspinlock-safety-1234.txt

    # 08    Verifying qspinlock under LKMM v01 using Dartagnan,
    #       without applying any fix.
    #       Expect no violation found and result UNKNOWN.
    ./scripts/dartagnan.sh \
        -m lkmm-v01 \
        -t ${solver} \
        -p reachability,liveness \
        -DALGORITHM=${QSPINLOCK_ALGORITHM} \
        client-code.c | tee results/out08-dartagnan-${solver}-lkmm_v01-qspinlock-both-none.txt

    # 09    Verifying qspinlock under Armv8 using Dartagnan,
    #       without applying any fix.
    #       Expect no violation found and result UNKNOWN.
    ./scripts/dartagnan.sh \
        -m armv8 \
        -t ${solver} \
        -p reachability,liveness \
        -DALGORITHM=${QSPINLOCK_ALGORITHM} \
        client-code.c | tee results/out09-dartagnan-${solver}-armv8-qspinlock-both-none.txt

    # 10    Verifying qspinlock under RISC-V using Dartagnan,
    #       without applying any fix.
    #       Expect no violation found and result UNKNOWN.
    ./scripts/dartagnan.sh \
        -m riscv \
        -t ${solver} \
        -p reachability,liveness \
        -DALGORITHM=${QSPINLOCK_ALGORITHM} \
        client-code.c | tee results/out10-dartagnan-${solver}-riscv-qspinlock-both-none.txt

    # 11    Verifying qspinlock on Power using Dartagnan,
    #       without applying any fix.
    #       Expect no violation found and result UNKNOWN.
    ./scripts/dartagnan.sh \
        -m power \
        -t ${solver} \
        -p reachability,liveness \
        -DALGORITHM=${QSPINLOCK_ALGORITHM} \
        client-code.c | tee results/out11-dartagnan-${solver}-power-qspinlock-both-none.txt

    # 12    Verifying CNA under LKMM v00 using Dartagnan,
    #       applying fixes 1, 2, 3, 4 and 5.
    #       Expect no violation found and result UNKNOWN.
    ./scripts/dartagnan.sh \
        -m lkmm-v00 \
        -t ${solver} \
        -p reachability,liveness \
        -DALGORITHM=${CNA_ALGORITHM} \
        -DFIX1 -DFIX2 -DFIX3 -DFIX4 -DFIX5 \
        client-code.c | tee results/out12-dartagnan-${solver}-lkmm_v00-cna-both-12345.txt

    # 13    Verifying CNA under LKMM v01 using Dartagnan,
    #       without applying any fix.
    #       Expect no violation found and result UNKNOWN.
    ./scripts/dartagnan.sh \
        -m lkmm-v01 \
        -t ${solver} \
        -p reachability,liveness \
        -DALGORITHM=${CNA_ALGORITHM} \
        client-code.c | tee results/out13-dartagnan-${solver}-lkmm_v01-cna-both.txt

    # 14    Verifying CNA on Armv8 using Dartagnan,
    #       without applying any fix.
    #       Expect no violation found and result UNKNOWN.
    ./scripts/dartagnan.sh \
        -m armv8 \
        -t ${solver} \
        -p reachability,liveness \
        -DALGORITHM=${CNA_ALGORITHM} \
        client-code.c | tee results/out14-dartagnan-${solver}-armv8-cna-both-none.txt

    # 15    Verifying CNA on RISC-V using Dartagnan,
    #       without applying any fix.
    #       Expect no violation found and result UNKNOWN.
    ./scripts/dartagnan.sh \
        -m riscv \
        -t ${solver} \
        -p reachability,liveness \
        -DALGORITHM=${CNA_ALGORITHM} \
        client-code.c | tee results/out15-dartagnan-${solver}-riscv-cna-both-none.txt

    # 16    Verifying qspinlock on Power using Dartagnan,
    #       without applying any fix.
    #       Expect no violation found and result UNKNOWN.
    ./scripts/dartagnan.sh \
        -m power \
        -t ${solver} \
        -p reachability,liveness \
        -DALGORITHM=${CNA_ALGORITHM} \
        client-code.c | tee results/out16-dartagnan-${solver}-power-cna-both-none.txt

done