#!/bin/bash

if [ ! "${DOCKER}" ]; then
        CFLAGS=""
        CFLAGS="${CFLAGS} -I$DAT3M_HOME/include/smack"
        CFLAGS="${CFLAGS} -I$DAT3M_HOME/include/clang"
        CFLAGS="${CFLAGS} -Iinclude"
        CFLAGS="${CFLAGS} -DALGORITHM=2"
        CFLAGS="${CFLAGS} -DSKIP_PENDING"
        export CFLAGS
        export DAT3M_OUTPUT=$(pwd)/output
        
        OPTS="${OPTS} -eCFLAGS=${CFLAGS} -eDAT3M_OUTPUT=$(pwd)"
        exec java -jar \
                $DAT3M_HOME/dartagnan/target/dartagnan-3.0.0.jar \
                $DAT3M_HOME/cat/aarch64.cat \
                --target=arm8 \
                --bound=1 \
                --program.processing.constantPropagation=false \
                --refinement.baseline=no_oota,uniproc,atomic_rmw \
                --property=reachability,liveness $@
else
        OPTS="-it --rm -v $(pwd):$(pwd) -u $(id -u):$(id -g) -w $(pwd)"
        exec docker run ${OPTS} dartagnan $0 $@
fi