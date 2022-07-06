# Verification of Linux qspinlock_cna

This repository contains the script allowing to run the verification of the
[CNA qspinlock](https://lkml.org/lkml/2021/5/14/821) using the
[GenMC model checker](https://plv.mpi-sws.org/genmc/).
We use this script to produce the results reported in our
[CNA verification technical note](https://arxiv.org/abs/2111.15240) (available
on arXiv).

## Requirements

The verification script is a Makefile.
It requires an Internet connection to get the different source and patch files
and the following to be installed:
- make
- curl
- Dartagnan
- GenMC v0.8

## Verifying CNA with GenMC installed on the host

To install GenMC, please follow the instructions on its
[GitHub repository](https://github.com/mpi-sws/genmc/).

With GenMC installed, simply run:

    git clone git@github.com:huawei-drc/cna-verification.git
    cd cna-verification/
    make

The Makefile will download the Linux source files and the commits of the CNA
patch.
It will apply the CNA patch on the Linux sources and then apply our own patch
to allow the verification.
Finally, the Makefile will run GenMC to verify MCS spinlock with 3 threads,
MCS qspinlock with 3 threads and, finally, CNA qspinlock with 4 threads (as
reported in Section 4 of
[our technical note](https://arxiv.org/abs/2111.15240)).

## Verifying CNA using our Dockerfile

We provide a Dockerfile to ease the installation of GenMC in a Docker container.
To run the verification within a Docker container, you need
[the Docker engine to be installed](https://docs.docker.com/engine/install/).

First, clone the repository and execute the early steps (i.e. fetching Linux
sources and CNA patch files):

    git clone git@github.com:huawei-drc/cna-verification.git
    cd cna-verification/
    make prepared

The target `prepared` ensures the Linux sources are downloaded into
the repository and the CNA patch is applied on top of these sources.

Then, in the same directory, build the Docker image by executing the following
on the host:

    docker build -t cna-verification .

You can run the rest of the steps (GenMC verification) in a new Docker container
by mounting the git repository in it:

    docker run -it --rm -v $(pwd):/workspace -u $(id -u):$(id -g) -w /workspace cna-verification make

This last command will run GenMC to verify the different locks (as described in
the previous section).

## The verification patch

Notice that after applying the CNA patch files to the original Linux source
files, we apply our own patch `verification.patch`.
This patch file contains the changes detailed in our
[technical note](https://arxiv.org/abs/2111.15240).
