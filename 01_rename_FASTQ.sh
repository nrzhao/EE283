#!/usr/bin/env bash

RAW_FASTQ_DIRECTORY=FASTQ/raw
RENAMED_FASTQ_DIRECTORY=FASTQ/renamed

tail -n +2 README.txt | while read -r line; do
    BARCODE=$(echo "$line" | cut -d $'\t' -f 1)
    GENOTYPE=$(echo "$line" | cut -d $'\t' -f 2)
    TISSUE=$(echo "$line" | cut -d $'\t' -f 3)
    REPLICATE=$(echo "$line" | cut -d $'\t' -f 4)

    for FASTQ in "$RAW_FASTQ_DIRECTORY"/*"$BARCODE"*.fq.gz; do
        READ_NUMBER=$(echo "$FASTQ" | cut -d '/' -f 3 | rev | cut -d '_' -f 1 | rev | cut -d '.' -f 1 | cut -c 2)

        NEW_FASTQ_NAME="$GENOTYPE"_"$TISSUE"_rep"$REPLICATE"_"$READ_NUMBER".fastq.gz

        cp -aiv "$FASTQ" "$RENAMED_FASTQ_DIRECTORY"/"$NEW_FASTQ_NAME"
    done
done
