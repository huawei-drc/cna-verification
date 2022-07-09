# Verification of Linux qspinlock_cna

This repository contains the scripts allowing to run the verification of the
[CNA qspinlock](https://lkml.org/lkml/2021/5/14/821) using two different model
checkers:
- the [GenMC model checker](https://plv.mpi-sws.org/genmc/)
- the [Dartagnan model checker](https://github.com/hernanponcedeleon/Dat3M)

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
(qspinlock, CNA) under the different memory models (LKMM, ARMv8, Power).
The content script is self-explanatory, and can be modified
according to other possible use cases.

Notice that when running Docker containers, the script will mount the current
directory from the host into the containers (to use the Linux source files and
to output result files).

## The verification patch

Notice that after applying the CNA patch files to the original Linux source
files, we apply our own patch `verification.patch`.
This patch file contains the changes detailed in our
[technical note](https://arxiv.org/abs/2111.15240).
