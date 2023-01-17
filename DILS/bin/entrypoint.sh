#!/usr/bin/env bash

#
# Entrypoint to container
#

set -eo pipefail

usage () {
    echo "Usage: $(basename "$0") 1pop|2pop YAMLFILE [SNAKEMAKE_ARG]*"
}


if [[ "$#" -lt 2 ]]; then
    usage
fi

mode="$1"

case "$mode" in
    1pop)
	:
	;;
    *)
	echo "invalid mode: $mode. expected 1pop or 2pop" >&2
	exit 1
	;;
esac
shift

yamlfile=$1
shift

if [[ ! -f "$yamlfile" ]]; then
    echo "Could not find yaml file: $yamlfile" >&2
    echo "(current directory inside container is $(pwd))" >&2
    exit 1
fi

fastafile=$(cat "$yamlfile" | python -c '
import yaml
import sys
obj = yaml.safe_load(sys.stdin)
print(obj["infile"])
')

if [[ ! -f "$fastafile" ]]; then
    echo "Could not find fasta file: $fastafile" >&2
    echo "(current directory inside container is $(pwd))" >&2
    exit 1
fi

# make a temp yaml file with the path to itself.
# override keys with absolute pathnames by appending new values.

snakemake_cfg=`mktemp snakemake.config.XXXXX.yaml`

cat "$yamlfile" >> "${snakemake_cfg}"

{
    echo "config_yaml: \"${snakemake_cfg}\""
    echo "infile: \"$(readlink -f "${fastafile}")\""
} >> "${snakemake_cfg}"

binpath='/tools/bin'

# in local executions -j default is set to the number of CPUs
exec snakemake --snakefile ${binpath}/Snakefile_${mode} \
     -p \
     `: -j 8` \
     --configfile "${snakemake_cfg}" \
     --cluster-config ${binpath}/cluster_1pop.json "$@"
