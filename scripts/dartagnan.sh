#!/bin/bash
set -e

if [ "${DOCKER}" ]; then
        OPTS="-it --rm -v $(pwd):$(pwd) -u $(id -u):$(id -g) -w $(pwd)"
        exec docker run ${OPTS} cna-dartagnan $0 $@
fi

function usage()
{
        echo "Usage: $0 -m <armv8|power|riscv|lkmm-v00|lkmm-v01> [-DVAR=VALUE] <FILE>"
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
                                riscv)
                                        target=riscv
                                        catfile=riscv.cat
                                        ;;
                                lkmm-v00)
                                        target=lkmm
                                        catfile=lkmm/lkmm-v00.cat      
                                        ;;
                                lkmm-v01)
                                        target=lkmm
                                        catfile=lkmm/lkmm-v01.cat      
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
                -t|--smt-solver)
                        smtsolver="$2"
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
CFLAGS="${CFLAGS} -I$DAT3M_HOME/include"
CFLAGS="${CFLAGS} -Iinclude"
export CFLAGS="${CFLAGS} ${defines}"
export DAT3M_OUTPUT=$(pwd)/output

[ -z "$properties" ] && properties=program_spec,liveness
[ -z "$method" ] && method=caat
[ -z "$smtsolver" ] && smtsolver=Z3

exec java -jar \
        $DAT3M_HOME/dartagnan/target/dartagnan-3.1.1.jar \
        $DAT3M_HOME/cat/${catfile} \
        --target=${target} \
        --bound=1 \
        --refinement.baseline=no_oota \
        --encoding.symmetry.breakOn=_cf \
        --encoding.wmm.idl2sat=true \
        --modeling.threadCreateAlwaysSucceeds=true \
        --modeling.precision=64 \
        --property=${properties} \
        --method=${method} \
        --solver=${smtsolver} \
        --witness.graphzviz=true \
        $@
