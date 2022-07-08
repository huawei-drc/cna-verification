FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV http_proxy=${http_proxy}
ENV https_proxy=${https_proxy}

# Install essential stuff ######################################################
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

# Build GenMC ##################################################################
RUN git clone --branch v0.8 --depth 1 https://github.com/MPI-SWS/genmc.git 2> /dev/null
RUN cd genmc \
    && autoreconf --install \
    && ./configure \
        --with-llvm=/usr/lib/llvm-8 \
        --with-clang=/usr/bin/clang-8 \
        --with-clangxx=/usr/bin/clang++-8 \
    && make -j$(nproc) CXX=/usr/bin/clang++-8 install

# Prepare environment ##########################################################
WORKDIR /workspace
RUN adduser --disabled-password --gecos "" --home /workspace user1
RUN adduser --disabled-password --gecos "" --home /workspace user2
RUN adduser --disabled-password --gecos "" --home /workspace user3
