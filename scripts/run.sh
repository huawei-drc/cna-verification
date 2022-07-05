#!/bin/bash

OPTS="-it --rm -v $(pwd):/workspace -u $(id -u):$(id -g) -w /workspace"

exec docker run ${OPTS} cna-verification $@
