#!/bin/bash

source bin/definitions.sh

function map_reads {
    HITS_FILE=$1
    shift
    READS_FILES=$@

    OUTPUT_DIR=tho.$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
    tophat --library-type fr-unstranded --no-coverage-search -p 8 -o $OUTPUT_DIR hs_bowtie_index/per_contig $@
    mv $OUTPUT_DIR/accepted_hits.bam $HITS_FILE
    rm -rf $OUTPUT_DIR
}

mkdir -p $MAPPED_READS_DIR

echo "Single-end samples"
for sample in $SINGLE_END_SAMPLES; do
    map_reads ${MAPPED_READS_DIR}/${sample}.bam ${DATA_DIR}/${sample}.fastq &
done

echo "Paired-end samples"
for sample in $PAIRED_END_SAMPLES; do
    map_reads ${MAPPED_READS_DIR}/${sample}.bam ${DATA_DIR}/${sample}.1.fastq ${DATA_DIR}/${sample}.2.fastq &
done
