#!/bin/sh
set -ex

# Usage (from root of the git repo): ./scripts/docker-run-usecases.sh
# Notice this script assumes the "make prepared" step has been executed before.

CNA_ALGORITHM=1
QSPINLOCK_ALGORITHM=2

make docker_build

mkdir results
export DOCKER=1

# 01    Verifying cna (original version) under IMM using GenMC.
#       Expect no error detected [duration ~10 seconds].
./scripts/genmc.sh cna-c11.c | tee results/out01-genmc-cna-c11.txt

# 02    Verifying qspinlock under LKMM using Dartagnan,
#       without applying any fix.
#       Expect to find a liveness violation [duration ~1 minute].
./scripts/dartagnan.sh \
    -m lkmm \
    -p liveness \
    -DALGORITHM=${QSPINLOCK_ALGORITHM} \
    -DSKIP_PENDING \
    client-code.c | tee results/out02-dartagnan-lkmm-qspinlock-livenessviolation.txt

# 03    Verifying qspinlock under LKMM using Dartagnan,
#       applying fix 1.
#       Expect to find a safety violation [duration ~2 minutes].
./scripts/dartagnan.sh \
    -m lkmm \
    -p reachability,liveness \
    -DALGORITHM=${QSPINLOCK_ALGORITHM} \
    -DSKIP_PENDING \
    -DFIX1 \
    client-code.c | tee results/out03-dartagnan-lkmm-qspinlock-safetyviolation.txt

# 04    Verifying qspinlock under LKMM using Dartagnan,
#       applying fixes 1 and 2.
#       Expect no violation found and result [duration ~2 minutes].
./scripts/dartagnan.sh \
    -m lkmm \
    -p reachability,liveness \
    -DALGORITHM=${QSPINLOCK_ALGORITHM} \
    -DSKIP_PENDING \
    -DFIX1 -DFIX2 \
    client-code.c | tee results/out04-dartagnan-lkmm-qspinlock-fixes.txt

# 05    Verifying qspinlock under Armv8 using Dartagnan,
#       without applying any fix.
#       Expect no violation found and result UNKNOWN [duration ~3 minutes].
./scripts/dartagnan.sh \
    -m armv8 \
    -p reachability,liveness \
    -DALGORITHM=${QSPINLOCK_ALGORITHM} \
    -DSKIP_PENDING \
    client-code.c | tee results/out05-dartagnan-armv8-qspinlock.txt

# 06    Verifying qspinlock on Power using Dartagnan,
#       without applying any fix.
#       Expect no violation found and result UNKNOWN [duration ~3 minutes].
./scripts/dartagnan.sh \
    -m power \
    -p reachability,liveness \
    -DALGORITHM=${QSPINLOCK_ALGORITHM} \
    -DSKIP_PENDING \
    client-code.c | tee results/out06-dartagnan-power-qspinlock.txt

# 07    Verifying CNA under LKMM using Dartagnan,
#       without applying any fix.
#       Expect to find a liveness violation [duration ~30 minutes].
./scripts/dartagnan.sh \
    -m lkmm \
    -p liveness \
    -DALGORITHM=${CNA_ALGORITHM} \
    -DSKIP_PENDING \
    client-code.c | tee results/out07-dartagnan-lkmm-cna-livenessviolation.txt

# 08    Verifying CNA under LKMM using Dartagnan,
#       applying fixes 1 and 2.
#       Expect no violation found and result UNKNOWN [duration ~16 hours].
./scripts/dartagnan.sh \
    -m lkmm \
    -p reachability,liveness \
    -DALGORITHM=${CNA_ALGORITHM} \
    -DSKIP_PENDING \
    -DFIX1 -DFIX2 \
    client-code.c | tee results/out08-dartagnan-lkmm-cna-fixes.txt

# 09    Verifying CNA on Armv8 using Dartagnan,
#       without applying any fix.
#       Expect no violation found and result UNKNOWN [duration ~12 hours].
./scripts/dartagnan.sh \
    -m armv8 \
    -p reachability,liveness \
    -DALGORITHM=${CNA_ALGORITHM} \
    -DSKIP_PENDING \
    client-code.c | tee results/out09-dartagnan-armv8-cna.txt

# 10    Verifying qspinlock on Power using Dartagnan,
#       without applying any fix.
#       Expect no violation found and result UNKNOWN [duration ~12 hours].
./scripts/dartagnan.sh \
    -m power \
    -p reachability,liveness \
    -DALGORITHM=${CNA_ALGORITHM} \
    -DSKIP_PENDING \
    client-code.c | tee results/out10-dartagnan-power-cna.txt
