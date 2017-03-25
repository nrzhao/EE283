#!/usr/bin/env bash

# download script for detecting sequencing adapters
SCRIPT_URL=https://raw.githubusercontent.com/kundajelab/atac_dnase_pipelines/master/utils/detect_adapter.py

[ ! -f detect_adapter.py ] && wget "$SCRIPT_URL"

[ ! -d FASTQ/trimmed ] && mkdir FASTQ/trimmed

##

UNIQUE_SAMPLES=$(find FASTQ/renamed -name '*.fastq.gz' | cut -d '/' -f 3 | cut -d '_' -f 1-2 | sort | uniq)

# a bit primitive at the moment, as it trims only for full adapter matches;
# however, this script does ensure that the trimmed FASTQs maintain 1:1 read pairing

# assumes that each sample has one sequencing adapter and
# that it is the top hit found by `detect_adapter.py`
for SAMPLE in $UNIQUE_SAMPLES; do
    # use process substitution to feed log of `detect_adapter.py` into sed;
    # use sed to get lines after line containing 'Adapter type';
    # pipe to sed to get second line and cut by TAB, take third column
    ADAPTER=$(sed -n '/Adapter type/,$p' <(python detect_adapter.py FASTQ/renamed/"$SAMPLE"_rep1_1.fastq.gz) | sed -n 2p | cut -d $'\t' -f 3)

    # if adapter sequence is present in reads of short fragments,
    # they should be at the end of the read based on how Illumina PE works;
    # in theory, residual adapter sequence in reads should be present in both
    # reads of a pair and at the same location if there is no sequencing error,
    # but the real read data is probably not this perfect
    # --
    # read through each pair of FASTQ files 4 lines at a time;
    # match adapter sequence to 2nd line (read sequence);
    # copy lines 1 and 3 unchanged;
    # only keep beginning to read up to start of adapter if there is a match;
    # trim the same portion of line 4 (quality scores)
    find FASTQ/renamed -name "$SAMPLE*.fastq.gz" | rev | cut -d '_' -f 2- | rev | sort | uniq; while read -r SAMPLE_REP; do
        paste <(zcat $(readlink "$SAMPLE_REP"_1.fastq.gz)) <(zcat $(readlink "$SAMPLE_REP"_2.fastq.gz)) | while IFS="$(printf '\t')" read -r R1_L1 R2_L1; do
            read R1_L2 R2_L2; read R1_L3 R2_L3; read R1_L4 R2_L4

            echo "$R1_L1" >> FASTQ/trimmed/"$SAMPLE_REP"_trimmed_1.fastq
            STOP=$(echo "$R1_L2" | grep -b -o "$ADAPTER" | cut -d ':' -f 1)
            echo "$R1_L2" | cut -c 1-"$STOP" >> FASTQ/trimmed/"$SAMPLE_REP"_trimmed_1.fastq
            echo '+' >> FASTQ/trimmed/"$SAMPLE_REP"_trimmed_1.fastq
            echo "$R1_L4" | cut -c 1-"$STOP" >> FASTQ/trimmed/"$SAMPLE_REP"_trimmed_1.fastq

            echo "$R2_L1" >> FASTQ/trimmed/"$SAMPLE_REP"_trimmed_2.fastq
            STOP=$(echo "$R2_L2" | grep -b -o "$ADAPTER" | cut -d ':' -f 1)
            echo "$R2_L2" | cut -c 1-"$STOP" >> FASTQ/trimmed/"$SAMPLE_REP"_trimmed_2.fastq
            echo '+' >> FASTQ/trimmed/"$SAMPLE_REP"_trimmed_2.fastq
            echo "$R2_L4" | cut -c 1-"$STOP" >> FASTQ/trimmed/"$SAMPLE_REP"_trimmed_2.fastq
        done

        pigz "$SAMPLE_REP"_trimmed_1.fastq
        pigz "$SAMPLE_REP"_trimmed_2.fastq
    done
done
