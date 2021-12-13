FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        autoconf \
        automake \
        build-essential \
        ca-certificates \
        clang-8 \
        cmake \
        curl \
        file \
        git \
        libclang-8-dev \
        llvm-8 \
        llvm-8-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace/
RUN git clone --branch v0.6.1 --depth 1 https://github.com/MPI-SWS/genmc.git 2> /dev/null
RUN cd genmc \
    && autoreconf --install \
    && ./configure \
        --with-llvm=/usr/lib/llvm-8 \
        --with-clang=/usr/bin/clang-8 \
        --with-clangxx=/usr/bin/clang++-8 \
    && make CXX=/usr/bin/clang++-8 install

ENV USER_NAME=me
RUN adduser --disabled-password --gecos "" ${USER_NAME}
USER ${USER_NAME}
