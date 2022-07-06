#!/bin/sh
set -ex

CNA_ALGORITHM=1
QSPINLOCK_ALGORITHM=2

make prepared
make docker_build

mkdir results
export DOCKER=1

# 01 verifying cna (original version) under IMM using GenMC, expect no error detected [duration ~10 seconds]
./scripts/genmc.sh cna-c11.c | tee results/out01-genmc-cna-c11.txt

# 02 verifying qspinlock under LKMM using dartagnan, without applying any fix, expect to find a liveness violation [duration ~2 minutes]
./scripts/dartagnan.sh \
    -m lkmm \
    -p liveness \
    -DALGORITHM=${QSPINLOCK_ALGORITHM} \
    -DSKIP_PENDING \
    client-code.c | tee results/out02-dartagnan-lkmm-qspinlock-livenessviolation.txt

# 03 verifying qspinlock under LKMM using dartagnan, applying first fix, expect to find a safety violation [duration ~2 minutes]
./scripts/dartagnan.sh \
    -m lkmm \
    -p reachability,liveness \
    -DALGORITHM=${QSPINLOCK_ALGORITHM} \
    -DSKIP_PENDING \
    -DFIX1 \
    client-code.c | tee results/out03-dartagnan-lkmm-qspinlock-safetyviolation.txt

# 04 verifying qspinlock under LKMM using dartagnan, applying both fixes, expect no violation found and result UNKNOWN TODO [duration ~2 minutes]
./scripts/dartagnan.sh \
    -m lkmm \
    -p reachability,liveness \
    -DALGORITHM=${QSPINLOCK_ALGORITHM} \
    -DSKIP_PENDING \
    -DFIX1 -DFIX2 \
    client-code.c | tee results/out04-dartagnan-lkmm-qspinlock-fixes.txt

# 05 verifying qspinlock on Armv8, without fix, expect no violation found and result UNKNOWN TODO [duration ~XX minutes]
./scripts/dartagnan.sh \
    -m arm \
    -p reachability,liveness \
    -DALGORITHM=${QSPINLOCK_ALGORITHM} \
    -DSKIP_PENDING \
    client-code.c | tee results/out05-dartagnan-armv8-qspinlock.txt

# 06 verifying qspinlock on Power, without fix, expect no violation found and result UNKNOWN TODO [duration ~XX minutes]
./scripts/dartagnan.sh \
    -m power \
    -p reachability,liveness \
    -DALGORITHM=${QSPINLOCK_ALGORITHM} \
    -DSKIP_PENDING \
    client-code.c | tee results/out06-dartagnan-power-qspinlock.txt

# 07 verifying CNA under LKMM using dartagnan, without applying any fix, expect to find a liveness violation [duration ~2 minutes]
./scripts/dartagnan.sh \
    -m lkmm \
    -p liveness \
    -DALGORITHM=${CNA_ALGORITHM} \
    -DSKIP_PENDING \
    client-code.c | tee results/out07-dartagnan-lkmm-cna-livenessviolation.txt

# 08 verifying CNA under LKMM using dartagnan, applying both fixes, expect no violation found and result UNKNOWN TODO [duration ~2 minutes]
./scripts/dartagnan.sh \
    -m lkmm \
    -p reachability,liveness \
    -DALGORITHM=${CNA_ALGORITHM} \
    -DSKIP_PENDING \
    -DFIX1 -DFIX2 \
    client-code.c | tee results/out08-dartagnan-lkmm-cna-fixes.txt

# 09 verifying CNA on Armv8, without fix, expect no violation found and result UNKNOWN TODO [duration ~XX minutes]
./scripts/dartagnan.sh \
    -m arm \
    -p reachability,liveness \
    -DALGORITHM=${CNA_ALGORITHM} \
    -DSKIP_PENDING \
    client-code.c | tee results/out09-dartagnan-armv8-cna.txt

# 41 verifying qspinlock on Power, without fix, expect no violation found and result UNKNOWN TODO [duration ~XX minutes]
./scripts/dartagnan.sh \
    -m power \
    -p reachability,liveness \
    -DALGORITHM=${CNA_ALGORITHM} \
    -DSKIP_PENDING \
    client-code.c | tee results/out10-dartagnan-power-cna.txt
