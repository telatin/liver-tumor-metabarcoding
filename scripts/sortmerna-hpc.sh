#!/bin/bash
set -exuo pipefail
if [[ -z ${2+x} ]]; then
  echo "USAGE: $0 R1_file R2_file [12] [outdir]"
  exit 1
fi
IMG=/qib/platforms/Informatics/transfer/outgoing/singularity/sortmerna/sortmerna.4.2.0.sif
CMD="singularity exec $IMG sortmerna"
THREADS=${3:-12}
OUTDIR=${4:-./}
# Check deps
seqfu version
sortmerna --version 2>&1 | grep -i version


R1="$1"
R2="$2"
echo "Forward: $R1"
echo "Reverse: $R2"

BASE=$(basename "$R1" | cut -f 1 -d _ | cut -f 1 -d .)
if [[ -e "${OUTDIR}/sortmerna_${BASE}.log" ]]; then
  echo "[ERROR:$BASE] Logfile found at ${OUTDIR}/sortmerna_${BASE}.log" #sortmerna_45-12-N1.log
  exit 1
fi
mkdir -p "${OUTDIR}"
TMPDIR=$(mktemp -d ${OUTDIR}/srtmrnatmp_${BASE}_XXXXXXXX)
echo "[INFO:$BASE] Sorting to $OUTDIR with $THREADS threads (temp: $TMPDIR)"

DBDIR="/qib/platforms/Informatics/transfer/outgoing/databases/SortMeRNA/rRNA_databases/"
REF=$(echo "/rRNA_databases/silva-bac-16s-id90.fasta --ref /rRNA_databases/silva-bac-16s-id90:./rRNA_databases/silva-bac-23s-id98.fasta --ref /rRNA_databases/silva-bac-23s-id98:./rRNA_databases/silva-arc-16s-id95.fasta --ref /rRNA_databases/silva-arc-16s-id95:./rRNA_databases/silva-arc-23s-id98.fasta --ref /rRNA_databases/silva-arc-23s-id98:./rRNA_databases/silva-euk-18s-id95.fasta --ref /rRNA_databases/silva-euk-18s-id95:./rRNA_databases/silva-euk-28s-id98.fasta --ref /rRNA_databases/silva-euk-28s-id98:./rRNA_databases/rfam-5s-database-id98.fasta --ref /rRNA_databases/rfam-5s-database-id98:./rRNA_databases/rfam-5.8s-database-id98.fasta --ref /rRNA_databases/rfam-5.8s-database-id98" | sed 's/\n//g' | sed "s|/rRNA_databases|$DBDIR|g")

mkdir -p $TMPDIR
$CMD --workdir $TMPDIR --threads $THREADS  --reads "$R1" --reads "${R2}" --paired_in \
  --ref /qib/platforms/Informatics/transfer/outgoing/databases/SortMeRNA/rRNA_databases/rfam-5.8s-database-id98.fasta --ref /qib/platforms/Informatics/transfer/outgoing/databases/SortMeRNA/rRNA_databases/rfam-5s-database-id98.fasta \
  --ref /qib/platforms/Informatics/transfer/outgoing/databases/SortMeRNA/rRNA_databases/silva-arc-16s-id95.fasta --ref /qib/platforms/Informatics/transfer/outgoing/databases/SortMeRNA/rRNA_databases/silva-arc-23s-id98.fasta \
  --ref /qib/platforms/Informatics/transfer/outgoing/databases/SortMeRNA/rRNA_databases/silva-bac-16s-id90.fasta --ref /qib/platforms/Informatics/transfer/outgoing/databases/SortMeRNA/rRNA_databases/silva-bac-23s-id98.fasta \
  --ref /qib/platforms/Informatics/transfer/outgoing/databases/SortMeRNA/rRNA_databases/silva-euk-18s-id95.fasta --ref /qib/platforms/Informatics/transfer/outgoing/databases/SortMeRNA/rRNA_databases/silva-euk-28s-id98.fasta  \
  --aligned "$TMPDIR/${BASE}.aligned" --other "$TMPDIR/${BASE}.other_merged" --fastx  --num_alignments 1 -v

echo "[INFO:$BASE] Sortmerna finished"
seqfu dei -o "$OUTDIR/${BASE}" "$TMPDIR"/${BASE}.other_merged.*
echo "[INFO:$BASE] Reads deinterleaved to $OUTDIR/${BASE}..."

cp "$TMPDIR"/*log $OUTDIR/sortmerna_${BASE}.log
#rm -rf "$TMPDIR"
echo "[INFO:$BASE] Done"
