FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Inheriting host proxy arguments
ENV HTTP_PROXY=${http_proxy}
ENV http_proxy=${http_proxy}
ENV HTTPS_PROXY=${https_proxy}
ENV https_proxy=${https_proxy}

# Setting proxy everywhere
ARG PROFILE_PROXY_PATH=/etc/profile.d/42-hproxy.sh
RUN echo "export HTTP_PROXY=${http_proxy}" | tee -a ${PROFILE_PROXY_PATH}
RUN echo "export HTTPS_PROXY=${http_proxy}" | tee -a ${PROFILE_PROXY_PATH}
RUN echo "export http_proxy=${http_proxy}" | tee -a ${PROFILE_PROXY_PATH}
RUN echo "export https_proxy=${http_proxy}" | tee -a ${PROFILE_PROXY_PATH}

# Certificates to add ppa
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY --chown=root:root certificates/ /tmp/certificates
RUN for f in $(ls /tmp/certificates/) ; do mv $(readlink -e /tmp/certificates/$f) /usr/local/share/ca-certificates/ ; done \
    && rmdir /tmp/certificates
RUN chmod -f 444 /usr/local/share/ca-certificates/*.crt || true
RUN update-ca-certificates

# Install essential stuff ######################################################
RUN apt-get update && apt-get install -y \
        git \
        build-essential \
        clang \
        libclang-dev \
        llvm \
        llvm-dev \
        maven \
        sudo \
        wget \
        graphviz \
        openjdk-17-jdk \
        openjdk-17-jre

# Install Dat3M ################################################################
RUN cd home && \
    git clone https://github.com/hernanponcedeleon/Dat3M.git && \
    cd Dat3M && git checkout ad4f3568d1342a0618cc4a268c900bc8043e6db1

RUN if [ "${https_proxy}" ]; then \
        export https_host=`echo ${https_proxy} | cut -d: -f 2 | cut -d/ -f3`; \
        export https_port=`echo ${https_proxy} | cut -d: -f 3`; \
    fi && \
    cd home/Dat3M && \
    mvn -Dhttp.proxyHost="${https_host}" \
        -Dhttp.proxyPort="${https_port}" \
        -Dhttps.proxyHost="${https_host}" \
        -Dhttps.proxyPort="${https_port}" \
        clean install -DskipTests

# Prepare environment ##########################################################
ENV DAT3M_HOME=/home/Dat3M
ENV DAT3M_OUTPUT=/workspace/output
ENV CFLAGS="-I$DAT3M_HOME/include"
ENV OPTFLAGS="-mem2reg -sroa -early-cse -indvars -loop-unroll -fix-irreducible -loop-simplify -simplifycfg -gvn"

WORKDIR /workspace
RUN adduser --disabled-password --gecos "" --home /workspace user1
RUN adduser --disabled-password --gecos "" --home /workspace user2
RUN adduser --disabled-password --gecos "" --home /workspace user3
