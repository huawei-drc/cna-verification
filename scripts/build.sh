#!/bin/sh

OPTS="--network host"

if [ -n "${http_proxy}" ]; then
        OPTS="${OPTS} --build-arg http_proxy=${http_proxy}"
fi
if [ -n "${https_proxy}" ]; then
        OPTS="${OPTS} --build-arg https_proxy=${https_proxy}"
fi

exec docker build ${OPTS} $@
