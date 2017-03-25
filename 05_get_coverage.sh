#!/usr/bin/env bash

samtools --version
echo $'\n#####################################################################'

##

BAM_DIR=BAM_dedup
COVERAGE_DIR=coverage

REFERENCE=~/data/Reference_Genomes/Drosophila/melanogaster/r6.11/dmel_ref_r6.11.fasta

##

for BAM in "$BAM_DIR"/*.bam; do
    SAMPLE=$(echo "$BAM" | rev | cut -d '/' -f 1 | cut -d '.' -f 2- | rev)

    NUM_READS=$(samtools view -c -F 4 "$BAM")
    SCALE=$(echo "1.0 / ($NUM_READS / 1000000)" | bc -l)

    samtools view -b "$BAM" | genomeCoverageBed -ibam - -g "$REFERENCE" -bg -scale "$SCALE" > "$COVERAGE_DIR"/"$SAMPLE".coverage
done
