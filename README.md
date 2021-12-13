# Verification of Linux qspinlock_cna

This repository contains the script allowing to run the verification of the CNA
qspinlock using the GenMC model checker.
We use this script to produce the results reported in our
[CNA verification technical note](https://arxiv.org/abs/2111.15240) (available
on arXiv).

## Requirements

The verification script is a Makefile (GNU make needs to be installed) requiring
the GenMC model checker to be installed and an Internet connection to get the
Linux source files and the CNA patch files.

## Verifying CNA with GenMC installed on the host

To install GenMC, please follow the instructions on its
[GitHub repository](https://github.com/mpi-sws/genmc/).

With GenMC installed, simply run:

    $ git clone git@github.com:huawei-drc/cna-verification.git
    $ cd cna-verification/
    $ make

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

    $ git clone git@github.com:huawei-drc/cna-verification.git
    $ cd cna-verification/
    $ make verification_ready

The target `verification_ready` ensures the Linux sources are downloaded into
the repository and the CNA patch is applied on top of these sources.

Then, in the same directory, build the Docker image by executing the following
on the host:

    $ docker build -t genmc-cna .

You can run the rest of the steps (GenMC verification) in a new Docker container
by mounting the git repository in it:

    $ docker run -it --rm -v $(pwd):/workspace -eNUID=$(id -u) -w /workspace genmc-cna make

This last command will run GenMC to verify MCS spinlock with 3 threads,
MCS qspinlock with 3 threads and, finally, CNA qspinlock with 4 threads
(as reported in Section 4 of
[our technical note](https://arxiv.org/abs/2111.15240)).

## The verification patch

Notice that after applying the CNA patch files to the original Linux source
files, we apply our own patch `verification.patch`.
This patch file contains the changes detailed in our
[technical note](https://arxiv.org/abs/2111.15240).
We marked our changes in the source code with "NOTE:".
