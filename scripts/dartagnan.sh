#!/bin/bash
set -e

if [ "${DOCKER}" ]; then
        OPTS="-it --rm -v $(pwd):$(pwd) -u $(id -u):$(id -g) -w $(pwd)"
        exec docker run ${OPTS} cna-dartagnan $0 $@
fi

function usage()
{
        echo "Usage: $0 -m <armv8|power|lkmm> [-DVAR=VALUE] <FILE>"
        exit 1
}

target=""
catfile=""
defines=""

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
        case $1 in
                -m|--memory-model)
                        ARCH="$2"
                        shift # past argument
                        shift # past value
                        case "$ARCH" in
                                armv8)
                                        target=arm8
                                        catfile=aarch64.cat      
                                        ;;
                                power)
                                        target=power
                                        catfile=power.cat      
                                        ;;
                                lkmm)
                                        target=lkmm
                                        catfile=linux-kernel.cat      
                                        ;;
                                *)
                                        usage
                                        ;;
                        esac
                        ;;            
                -s|--solver)
                        method="$2"
                        shift
                        ;;
                -p|--properties)
                        properties="$2"
                        shift
                        ;;
                -D*)
                        defines="${defines} $1"
                        shift # past argument
                        ;;
                -*|--*)
                        echo "Unknown option $1"
                        exit 1
                        ;;
                *)
                        POSITIONAL_ARGS+=("$1") # save positional arg
                        shift # past argument
                        ;;
        esac
done

set -- "${POSITIONAL_ARGS[@]}"

if [ -z "$1" ]; then
        usage
fi

if [ -z ${target} ]; then
        usage
fi

CFLAGS=""
CFLAGS="${CFLAGS} -I$DAT3M_HOME/include/smack"
CFLAGS="${CFLAGS} -I$DAT3M_HOME/include/clang"
CFLAGS="${CFLAGS} -Iinclude"
export CFLAGS="${CFLAGS} ${defines}"
export DAT3M_OUTPUT=$(pwd)/output

[ -z "$properties" ] && properties=reachability,liveness
[ -z "$method"] && method=caat

exec java -jar \
        $DAT3M_HOME/dartagnan/target/dartagnan-3.0.0.jar \
        $DAT3M_HOME/cat/${catfile} \
        --target=${target} \
        --bound=1 \
        --program.processing.constantPropagation=false \
        --refinement.baseline=no_oota,uniproc,atomic_rmw \
        --property=${properties} \
        --method=${method} \
        --witness.graphzviz=true \
        $@
