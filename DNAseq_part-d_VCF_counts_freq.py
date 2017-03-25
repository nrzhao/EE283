#!/usr/bin/env python

from sys import argv


def main(VCFFILEPATH, OUTFILEPATH):
    with open(VCFFILEPATH) as f:
        VCF = f.read().splitlines()

    while VCF[0].startswith('##'):
        VCF.pop(0)

    sample_names = VCF[0].split('\t')[9:]

    # assumes same format for all sample rows!!
    format = VCF[1].split('\t')[8].split(':')
    geno_index = format.index('GT')
    cov_index = format.index('DP')

    # {Chr_Coord: {sample1: (alt count, depth), ..., total: (alt count, depth)}}
    counts = {}

    # {Chr_Coord: {sample1: 0|0.5|1, ..., total: number in [0,1]}}
    freqs = {}

    for line in VCF[1:]:
        line = line.split('\t')
        pos = '_'.join(line[:2])

        line_counts = {}
        line_freqs = {}

        total_alt = 0
        total_depth = 0

        for sample, name in zip(*(line[9:], sample_names)):
            sample_data = sample.split(':')

            coverage = int(sample_data[cov_index])

            # assumes 50/50 split for samples called as het
            alt_count = sum(map(int, sample_data[geno_index].split('/'))) * coverage / 2.

            line_counts[name] = (alt_count, coverage)
            line_freqs[name] = alt_count / coverage

            total_alt += alt_count
            total_depth += coverage

        line_counts['total'] = (total_alt, total_depth)
        line_freqs['total'] = total_alt / total_depth

        counts[pos] = line_counts
        freqs[pos] = line_freqs

    ALL_POSITIONS = counts.keys()
    ALL_SAMPLES = counts[ALL_POSITIONS[0]].keys()

    with open(OUTFILEPATH, 'w') as f:
        f.write('\t'.join(['POSITION', 'SAMPLE', 'COUNT', 'DEPTH', 'FREQUENCY']) + '\n')

        for POSITION in ALL_POSITIONS:
            pos_counts = counts[POSITION]
            pos_freqs = freqs[POSITION]

            for SAMPLE in ALL_SAMPLES:
                f.write(POSITION + '\t' + SAMPLE + '\t')
                f.write('\t'.join(map(str, pos_counts[SAMPLE])) + '\t')
                f.write(str(pos_freqs[SAMPLE]) + '\n')


if __name__ == '__main__':
    main(argv[1], argv[2])

