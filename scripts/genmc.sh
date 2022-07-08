#!/bin/sh
set -e

if [ -z "${DOCKER}" ]; then
        exec genmc -disable-spin-assume -check-liveness -imm $@
else
        OPTS="-it --rm -v $(pwd):$(pwd) -u $(id -u):$(id -g) -w $(pwd)"
        exec docker run ${OPTS} cna-genmc scripts/genmc.sh $@
fi
