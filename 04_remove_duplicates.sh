#!/usr/bin/env bash

samtools --version
echo $'\n#####################################################################'

##

mkdir BAM_dedup

# remove PCR duplicates
for BAM in bwa-mem_r6/*.bam; do
    SAMPLE_BAM=$(echo "$BAM" | cut -d '/' -f 2)
    samtools rmdup "$BAM" BAM_dedup/"$SAMPLE_BAM"

# index BAM files
for BAM in BAM_dedup/*.bam; do
    samtools index "$BAM" &
done
