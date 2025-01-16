#!/bin/bash

# Remove 16S primers using the NBI Cluster
# Requires Singularity image of cutadapt 3.3 and NBI::Slurm
#


#set -euo pipefail
IMG=/nbi/software/testing/GMH-Tools/images/cutadapt~3.3
fwd_primer=""
rev_primer=""
input_R1=""
input_R2=""
outdir=""
# Function to display usage instructions
usage() {
    echo "Usage: $0 -f FWD_PRIMER -r REV_PRIMER -1 input_R1 -2 input_R2 -o outdir"
    echo "  -f: Forward primer sequence"
    echo "  -r: Reverse primer sequence"
    echo "  -1: Path to forward reads file"
    echo "  -2: Path to reverse reads file"
    echo "  -o: Output directory"
    exit 1
}

# Parse command-line options
while getopts ":f:r:1:2:o:" opt; do
    case "${opt}" in
        f)
            fwd_primer=${OPTARG}
            ;;
        r)
            rev_primer=${OPTARG}
            ;;
        1)
            input_R1=${OPTARG}
            ;;
        2)
            input_R2=${OPTARG}
            ;;
        o)
            outdir=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

# Check if all required parameters are provided
if [[ -z $fwd_primer || -z $rev_primer || -z $input_R1 || -z $input_R2 || -z $outdir ]]; then
    usage
fi

# Source package
#source package 91905514-21c8-45f3-bc78-98a73cea34be
source package gmhtools-last
source package seqfu-1.20.0

mkdir -p "$outdir"

SAMPLE_NAME=$(basename "$input_R1" | cut -f 1 -d . | sed 's/_R1//' )

fwd_rc=$(seqfu rc "$fwd_primer")
rev_rc=$(seqfu rc "$rev_primer")

echo -e "Sample: $SAMPLE_NAME\tFrom: $input_R1 $input_R2\tTo: $outdir"
echo Primers: $fwd_primer:$rev_primer

# Parameters:
# -f FWD_PRIMER -r REV_PRIMER -1 input_R1 -2 input_R2 -o outdir
runjob -w logs -run -c 8 -m 12 -t 32h -n cutadapt-$SAMPLE_NAME \
 "singularity exec $IMG cutadapt -j 8 -a ${fwd_primer}...${rev_rc} -A ${rev_primer}...${fwd_rc} --discard-untrimmed \
   -o $outdir/$(basename $input_R1) -p $outdir/$(basename $input_R2) \
    $input_R1 $input_R2 2> $outdir/$(basename $SAMPLE_NAME).log > $outdir/$(basename $SAMPLE_NAME).txt"

echo "## $SAMPLE_NAME  | $input_R1"
echo "## $SAMPLE_NAME  | $input_R2"
echo "--------------------"
echo  "singularity exec $IMG cutadapt -j 8 -a ${fwd_primer}...${rev_rc} -A ${rev_primer}...${fwd_rc} --discard-untrimmed \
   -o $outdir/$(basename $input_R1) -p $outdir/$(basename $input_R2) \
    $input_R1 $input_R2"
