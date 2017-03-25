#!/bin/bash
#$ -N ATACseq_bwa-mem_r6
#$ -q adl,free72i,free88i
#$ -m eas
#$ -pe openmp 64-88
#$ -j y

REFERENCE=~/data/Reference_Genomes/Drosophila/melanogaster/r6.11/dmel_ref_r6.11.fasta

OUTPUT_DIR=bwa-mem_r6

##

samtools --version
echo $'\n#####################################################################'
bwa 2>&1 > /dev/null | head -n 3
echo $'\n#####################################################################\n';
echo $'CORES =' "$CORES"
echo $'\n#####################################################################\n'

##

find FASTQ/trimmed -name '*.fastq.gz' | rev | cut -d '_' -f 3- | rev | sort | uniq | while read -r PREFIX; do
    SAMPLE=$(echo "$PREFIX" | rev | cut -d '/' -f 1 | rev)
    SAMPLE_STRLEN=${#SAMPLE}

    # print '=' (length of $PREFIX) number of times
    printf '=%.0s' $(seq 1 "$SAMPLE_STRLEN")
    echo "$SAMPLE"
    printf '=%.0s' $(seq 1 "$SAMPLE_STRLEN")

    bwa mem -t "$CORES" "$REFERENCE" "$PREFIX"_trimmed_1.fastq.gz "$PREFIX"_trimmed_2.fastq.gz | samtools view -bS - > "$OUTPUT_DIR"/"$SAMPLE".bam

    samtools sort -@ "$CORES" -o "$OUTPUT_DIR"/"$SAMPLE"_sorted.bam "$OUTPUT_DIR"/"$SAMPLE".bam

    rm "$OUTPUT_DIR"/"$SAMPLE".bam

    mv "$OUTPUT_DIR"/"$SAMPLE"_sorted.bam "$OUTPUT_DIR"/"$SAMPLE".bam

    echo $'\n\n'
done

##

for BAM in "$OUTPUT_DIR"/*.bam; do
    samtools index "$BAM" &
done

wait
