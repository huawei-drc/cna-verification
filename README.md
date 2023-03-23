# Verification of Linux qspinlock_cna

This repository contains the scripts allowing to run the verification of the
[CNA qspinlock](https://lkml.org/lkml/2021/5/14/821) using two different model
checkers:
- [GenMC](https://plv.mpi-sws.org/genmc/)
- [Dartagnan](https://github.com/hernanponcedeleon/Dat3M)

We use these scripts to produce the results reported in our
[CNA verification technical note](https://arxiv.org/abs/2111.15240) (available
on arXiv).

## Requirements

The Makefile allows to download the Linux source files, apply the CNA patch,
and apply our own patch (required for the verification).
It also builds two Docker images: one to build each model checker.

To get the different sources, patches and Docker images, an Internet connection
is required, and the following dependencies must be installed on the host
system:
- make
- curl
- Docker

## Proxy

If your organization requires the usage of ca certificates, create a
"certificates" directory in the root of the git repository and fill it with
the certificates files (`*.crt`) before building any docker image.
The images will be built using these certificates.

## Verifying CNA using our Dockerfile

We provide dockerfiles to ease the installation of GenMC and Dartagnan in a
Docker container.
To run the verification within a Docker container, you need
[the Docker engine to be installed](https://docs.docker.com/engine/install/).

First, clone the repository and execute the early steps (i.e. fetching Linux
sources and CNA patch files):

    git clone git@github.com:huawei-drc/cna-verification.git
    cd cna-verification/
    make prepared

The make target `prepared` ensures the following steps:
- the Linux sources are downloaded into the repository,
- the CNA patch is applied on top of these sources,
- and the patch to allow the verification is applied on top of the CNA patch.

Then, in the same directory, build the Docker images by executing the following
make target on the host:

    make docker_build

This will build one Docker image for GenMC and one Docker image for Dartagnan.

A helper script is provided to run all the actual verification steps as
reported in [our technical note](https://arxiv.org/abs/2111.15240):

    ./scripts/docker-run-usecases.sh

This last command will run GenMC and Dartagnan to verify the different locks
(qspinlock, CNA) under the different memory models (IMM, LKMM, ARMv8, Power, RISCV).
The content script is self-explanatory, and can be modified
according to other possible use cases.

Notice that when running Docker containers, the script will mount the current
directory from the host into the containers (to use the Linux source files and
to output result files).

## The verification patch

Notice that after applying the CNA patch files to the original Linux source
files, we apply our own patch `verification.patch`.
This patch file contains the changes detailed in  **CNA and qspinlock changes** 
of our [technical note](https://arxiv.org/abs/2111.15240).

## The LKMM fixes patch

As described in **Correctness violations in qspinlock** of the 
[technical report](https://arxiv.org/abs/2111.15240), we found some correctness 
issues (safety, liveness, and data-races) in qspinlock according to LKMM up-to v6.1.3 (refered as LKMM v00 below)).
File `lkmm-fixes.patch` proposes solutions to those problems. Each solution can 
be enabled using the flag `-DFIXN` where `N` in `{1,2,3,4,5}`. Once all flags are 
enabled, the code is correct according to LKMM v00. We also run the verification using
the most up-to-date LKMM version (referred as LKMM v01 below) which includes 
[this patch](https://lkml.org/lkml/2022/11/16/1555).

## Verification results

Herebelow we show our verification results for different lock algorithms and with different Dartagnan parameters.

| Memory model   | SMT solver   | Lock algorithm            | Properties       | Verif. time   | Verified?          |
|:---------------|:-------------|:--------------------------|:-----------------|:--------------|:-------------------|
| LKMM v00       | mathsat5     | qspinlock, unmodified     | Liveness         | 2 min         | :x:                |
| LKMM v00       | yices2       | qspinlock, unmodified     | Liveness         | 22 s          | :x:                |
| LKMM v00       | z3           | qspinlock, unmodified     | Liveness         | 2 min         | :x:                |
| LKMM v00       | mathsat5     | qspinlock, with fix 1     | Liveness         | 58 s          | :x:                |
| LKMM v00       | yices2       | qspinlock, with fix 1     | Liveness         | 21 s          | :x:                |
| LKMM v00       | z3           | qspinlock, with fix 1     | Liveness         | 2 min         | :x:                |
| LKMM v00       | mathsat5     | qspinlock, with fixes 1-2 | Liveness         | 3 min         | :heavy_check_mark: |
| LKMM v00       | yices2       | qspinlock, with fixes 1-2 | Liveness         | 39 s          | :heavy_check_mark: |
| LKMM v00       | z3           | qspinlock, with fixes 1-2 | Liveness         | 5 min         | :heavy_check_mark: |
| LKMM v00       | mathsat5     | qspinlock, with fixes 1-2 | Safety           | 51 s          | :x:                |
| LKMM v00       | yices2       | qspinlock, with fixes 1-2 | Safety           | 13 s          | :x:                |
| LKMM v00       | z3           | qspinlock, with fixes 1-2 | Safety           | 42 s          | :x:                |
| LKMM v00       | mathsat5     | qspinlock, with fixes 1-3 | Safety           | 2 min         | :x:                |
| LKMM v00       | yices2       | qspinlock, with fixes 1-3 | Safety           | 26 s          | :x:                |
| LKMM v00       | z3           | qspinlock, with fixes 1-3 | Safety           | 3 min         | :x:                |
| LKMM v00       | mathsat5     | qspinlock, with fixes 1-4 | Safety           | 30 min        | :heavy_check_mark: |
| LKMM v00       | yices2       | qspinlock, with fixes 1-4 | Safety           | 5 min         | :heavy_check_mark: |
| LKMM v00       | z3           | qspinlock, with fixes 1-4 | Safety           | 21 min        | :heavy_check_mark: |
| LKMM v01       | mathsat5     | qspinlock, unmodified     | Liveness, Safety | 44 min        | :heavy_check_mark: |
| LKMM v01       | yices2       | qspinlock, unmodified     | Liveness, Safety | 6 min         | :heavy_check_mark: |
| LKMM v01       | z3           | qspinlock, unmodified     | Liveness, Safety | 26 min        | :heavy_check_mark: |
| ARMv8          | mathsat5     | qspinlock, unmodified     | Liveness, Safety | 2h 9 min      | :heavy_check_mark: |
| ARMv8          | yices2       | qspinlock, unmodified     | Liveness, Safety | 12 min        | :heavy_check_mark: |
| ARMv8          | z3           | qspinlock, unmodified     | Liveness, Safety | 1h 34 min     | :heavy_check_mark: |
| RISC-V         | mathsat5     | qspinlock, unmodified     | Liveness, Safety | 2h 22 min     | :heavy_check_mark: |
| RISC-V         | yices2       | qspinlock, unmodified     | Liveness, Safety | 15 min        | :heavy_check_mark: |
| RISC-V         | z3           | qspinlock, unmodified     | Liveness, Safety | 1h 28 min     | :heavy_check_mark: |
| Power          | mathsat5     | qspinlock, unmodified     | Liveness, Safety | 2h 45 min     | :heavy_check_mark: |
| Power          | yices2       | qspinlock, unmodified     | Liveness, Safety | 15 min        | :heavy_check_mark: |
| Power          | z3           | qspinlock, unmodified     | Liveness, Safety | 1h 51 min     | :heavy_check_mark: |
| LKMM v00       | mathsat5     | CNA, with fixes 1-5       | Liveness, Safety | 1h 32 min     | :heavy_check_mark: |
| LKMM v00       | yices2       | CNA, with fixes 1-5       | Liveness, Safety | 16 min        | :heavy_check_mark: |
| LKMM v00       | z3           | CNA, with fixes 1-5       | Liveness, Safety | 1h 41 min     | :heavy_check_mark: |
| LKMM v01       | mathsat5     | CNA, unmodified           | Liveness, Safety | 1h 27 min     | :heavy_check_mark: |
| LKMM v01       | yices2       | CNA, unmodified           | Liveness, Safety | 25 min        | :heavy_check_mark: |
| LKMM v01       | z3           | CNA, unmodified           | Liveness, Safety | 1h 38 min     | :heavy_check_mark: |
| ARMv8          | mathsat5     | CNA, unmodified           | Liveness, Safety | 5h 2 min      | :heavy_check_mark: |
| ARMv8          | yices2       | CNA, unmodified           | Liveness, Safety | 54 min        | :heavy_check_mark: |
| ARMv8          | z3           | CNA, unmodified           | Liveness, Safety | 4h 26 min     | :heavy_check_mark: |
| RISC-V         | mathsat5     | CNA, unmodified           | Liveness, Safety | 5h 5 min      | :heavy_check_mark: |
| RISC-V         | yices2       | CNA, unmodified           | Liveness, Safety | 1h 2 min      | :heavy_check_mark: |
| RISC-V         | z3           | CNA, unmodified           | Liveness, Safety | 5h 46 min     | :heavy_check_mark: |
| Power          | mathsat5     | CNA, unmodified           | Liveness, Safety | 7h 29 min     | :heavy_check_mark: |
| Power          | yices2       | CNA, unmodified           | Liveness, Safety | 40 min        | :heavy_check_mark: |
| Power          | z3           | CNA, unmodified           | Liveness, Safety | 5h 50 min     | :heavy_check_mark: |

## Verification of an alternative version of qpsinlock

We also allow to verify an old version of qspinlock which contains an actual bug (i.e. reproducible in hardware) introduced by [this commit](https://github.com/torvalds/linux/commit/64d816cba06c67eeee455b8c78ebcda349d49c24).
This version can be verified following the steps below inside the Dartagnan container
- `make prepared LINUX_VERSION_TYPE=commit-old`
- `./scripts/dartagnan.sh -m armv8 -p liveness -DALGORITHM=3 -DCFLAGS="${CFLAGS} -I./include" client-code.c`

**Expected result:** "Liveness violation found"
