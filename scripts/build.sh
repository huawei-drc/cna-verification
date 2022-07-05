#!/bin/bash

OPTS="--network host"

if [ ! -z "${http_proxy}" ]; then
        OPTS="${OPTS} --build-arg http_proxy=${http_proxy}"
fi
if [ ! -z "${https_proxy}" ]; then
        OPTS="${OPTS} --build-arg https_proxy=${https_proxy}"
fi

exec docker build ${OPTS} $@