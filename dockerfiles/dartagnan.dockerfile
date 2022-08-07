FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV http_proxy=${http_proxy}
ENV https_proxy=${https_proxy}

# Install essential stuff ######################################################
RUN apt-get update && apt-get install -y \
    git build-essential cmake maven \
    lsb-release sudo wget \
    software-properties-common

# Install SMACK ################################################################
RUN cd home && \
    git clone -b develop https://github.com/smackers/smack.git && \
    cd smack && \
    git checkout 497740c

ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
RUN cd home && \
    cd smack && \
    sed -i 's/TEST_SMACK:-1/TEST_SMACK:-0/' bin/build.sh && \
    sed -i 's/INSTALL_Z3:-1/INSTALL_Z3:-0/' bin/build.sh && \
    sed -i 's/INSTALL_BOOGIE:-1/INSTALL_BOOGIE:-0/' bin/build.sh && \
    sed -i 's/INSTALL_CORRAL:-1/INSTALL_CORRAL:-0/' bin/build.sh && \
    sed -i 's/sudo /sudo -E /' bin/build.sh && \
    env TEST_SMACK=0 bin/build.sh

# Install Dat3M ################################################################
RUN cd home && \
    git clone --branch cna-verification https://github.com/hernanponcedeleon/Dat3M.git && \
    cd Dat3M && git checkout f9e2b2b85055854f80250e3456042c257f82f03c

RUN if [ "${https_proxy}" ]; then \
        export https_host=`echo ${https_proxy} | cut -d: -f 2 | cut -d/ -f3`; \
        export https_port=`echo ${https_proxy} | cut -d: -f 3`; \
    fi && \
    cd home/Dat3M && \
    chmod 755 Dartagnan-SVCOMP.sh && \
    mvn -Dhttp.proxyHost="${https_host}" \
        -Dhttp.proxyPort="${https_port}" \
        -Dhttps.proxyHost="${https_host}" \
        -Dhttps.proxyPort="${https_port}" \
        clean install -DskipTests

# symlink for clang
RUN ln -s clang-12 /usr/bin/clang

RUN apt-get update && apt-get install -y graphviz

# Prepare environment ##########################################################
ENV DAT3M_HOME=/home/Dat3M
ENV DAT3M_OUTPUT=/workspace/output
ENV SMACK_FLAGS="-q -t --no-memory-splitting"

WORKDIR /workspace
RUN adduser --disabled-password --gecos "" --home /workspace user1
RUN adduser --disabled-password --gecos "" --home /workspace user2
RUN adduser --disabled-password --gecos "" --home /workspace user3
