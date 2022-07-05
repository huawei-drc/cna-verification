FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

ENV SSL_UNAUTH="false"
ENV HTTP_PROXY=${http_proxy}
ENV http_proxy=${http_proxy}
ENV HTTPS_PROXY=${https_proxy}
ENV https_proxy=${https_proxy}


# Install essential stuff ######################################################
RUN apt-get update && apt-get install -y \
    git build-essential cmake maven \
    lsb-release sudo wget \
    software-properties-common

# Allow untrusted certificates #################################################
RUN if [ "${http_proxy}" == "yes" ]; then \
    echo "check_certificate = off" >> ~/.wgetrc; \
    echo "APT::Get::AllowUnauthenticated \"true\";" > /etc/apt/apt.conf.d/99unauth; \
    touch /etc/apt/apt.conf.d/99verify-peer.conf; \
    echo "Acquire { https::Verify-Peer false }" >> /etc/apt/apt.conf.d/99verify-peer.conf; \
    export GIT_SSL_NO_VERIFY=true; \
    git config --global http.sslVerify false; \
fi

# Or copy local certificates in to the right place
#COPY ca-certificates/* /usr/local/share/ca-certificates/
#RUN update-ca-certificates


# Install SMACK ################################################################
RUN cd home \
    && git clone -b develop https://github.com/smackers/smack.git
    
    #&& cd smack \
    #&& git checkout 497740c

ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
RUN cd home && \
    cd smack && \
    sed -i '397 i dotnet dev-certs https --trust' bin/build.sh && \
    sed -i 's/TEST_SMACK=1/TEST_SMACK=0/' bin/build.sh && \
    sed -i 's/sudo /sudo -E /' bin/build.sh && \
    bash -x bin/build.sh

# Install Dat3M ################################################################
RUN cd home \
    && git clone --branch cna-verification https://github.com/hernanponcedeleon/Dat3M.git \
    && cd Dat3M && git checkout afbb640

ENV MAVEN_CLI_OPTS="-DproxySet=true"
RUN cd home && \
    cd Dat3M && \
    chmod 755 Dartagnan-SVCOMP.sh && \
    mvn -Dhttp.proxyHost=$(echo ${http_proxy} | cut -d: -f 1) \
        -Dhttp.proxyPort=$(echo ${http_proxy} | cut -d: -f 2) \
        -Dhttps.proxyHost=$(echo ${https_proxy} | cut -d: -f 1) \
        -Dhttps.proxyPort=$(echo ${https_proxy} | cut -d: -f 2) \
        clean install -DskipTests

# symlink for clang
RUN ln -s clang-12 /usr/bin/clang

# Install GenMC ################################################################

RUN apt-get update && apt-get install -y --no-install-recommends \
        autoconf \
        automake \
        build-essential \
        ca-certificates \
        clang \
        cmake \
        curl \
        file \
        git \
        libclang-dev \
        llvm \
        llvm-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace/
RUN git clone --branch v0.8 --depth 1 https://github.com/MPI-SWS/genmc.git 2> /dev/null
RUN cd genmc \
    && autoreconf --install \
    && ./configure \
    && make -j$(nproc) CXX=/usr/bin/clang++ install

# Prepare environment ##########################################################
ENV DAT3M_HOME=/home/Dat3M
ENV DAT3M_OUTPUT=/workspace/output
ENV SMACK_FLAGS="-q -t --no-memory-splitting"

WORKDIR /workspace
RUN adduser --disabled-password --gecos "" --home /workspace user1
RUN adduser --disabled-password --gecos "" --home /workspace user2
RUN adduser --disabled-password --gecos "" --home /workspace user3