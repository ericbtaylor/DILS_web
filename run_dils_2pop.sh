#!/bin/bash

set -eo pipefail

usage () {
    echo "Usage: $(basename "$0") [--debug] [TRIAL_YAML]

  Runs DILS_web in 2pop mode.

  Arguments:

     --debug (optional) Opens a shell into the singularity image
                        before running the program.

     TRIAL_YAML         The trial file (described in the manual)
"
}

set -x

if [[ -L "$0" ]]; then
    HERE=$(cd $(dirname "$(readlink -f "$0")") && pwd)
else
    HERE="$( dirname -- "$BASH_SOURCE"; )";
fi
REPODIR="$HERE" # Root of the DILS_web repository
SIF=$REPODIR/DILS.sif

# make mountpoints of the host available inside the container
BIND_ARGS=(
  --bind "$(readlink -f "$HOME"):$HOME"
  --bind /SciBorg/dolly:/SciBorg/dolly

  # the container's working directory when it starts is in /app
  # we make whatever's available in the current directory at the time
  # the script is run available inside the container at directory
  # /app/
  #
  # this means that if your yaml file is pointing to a fasta
  # (myfile_fa) in the same directory as the yaml file, you should
  # refer to it as /app/myfile_fa
  --bind .:/app
)

# we are modifying scripts from the repo, but we don't want to have to
# rebuild the image each time. We mount local edits to save on turnaround
# time. We can commit those changes to git later when we're satisfied.
BIN_OVERRIDE=(
    bin/RNAseqFGT.sh
    bin/Snakefile_2pop
    bin/priorgen_gof_2pop.py
    bin/submit_simulations_gof_2pop.py
)


DEBUG=0
POSARGS=()
while [[ "$#" -gt 0 ]]; do
    case "$1" in
	"--debug")
	    DEBUG=1
	    shift
	    ;;
	--help|-h)
	    usage
	    exit 0
	    ;;
	-*)
	    echo "invalid flag: $1" >&2
	    usage >&2
	    exit 1
	    ;;
	*)
	    POSARGS+=("$1")
	    shift
	    ;;
    esac
done

if [[ "${#POSARGS[@]}" -lt 1 ]]; then
    echo "missing argument" >&2
    usage >&2
    exit 1
fi

YAML=${POSARGS[0]}

set -x

for o in "${BIN_OVERRIDE[@]}"; do
    if [[ ! -r "$REPODIR/DILS/$o" ]]; then
	echo "missing bin file: $REPODIR/DILS/$o" >&2
	exit 1
    fi
    BIND_ARGS+=(--bind "$REPODIR"/DILS/"$o":/tools/"$o")
done
		
if [[ $DEBUG == 1 ]]; then
    # lets us inspect the contents of the container
    echo "entering debug mode. run `exit` to terminate." >&2
    exec singularity exec "${BIND_DIRS[@]}" dils.sif /bin/bash
fi

if [[ ! -f "$SIF" ]]; then
    echo "Expected to find $SIF singularity image. See instructions in README.md" >&2
    exit 1
fi

singularity run "${BIND_ARGS[@]}" "$SIF" 2pop "$YAML" 2>&1 | tee "$(basename "$YAML" .yaml).log"
