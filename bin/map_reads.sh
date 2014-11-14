#!/bin/bash

source bin/definitions.sh

function map_reads {
    HITS_FILE=$1
    shift
    READS_FILES=$@

    OUTPUT_DIR=tho.$(get_random_id)
    tophat --library-type fr-unstranded --no-coverage-search -p 8 -o $OUTPUT_DIR ${BOWTIE_INDEX} $@
    mv $OUTPUT_DIR/accepted_hits.bam $HITS_FILE
    rm -rf $OUTPUT_DIR
}

mkdir -p $MAPPED_READS_DIR

for sample in $SINGLE_END_SAMPLES; do
    map_reads ${MAPPED_READS_DIR}/${sample}.bam ${RNA_SEQ_DIR}/${sample}.fastq
done

for sample in $PAIRED_END_SAMPLES; do
    map_reads ${MAPPED_READS_DIR}/${sample}.bam ${RNA_SEQ_DIR}/${sample}.1.fastq ${RNA_SEQ_DIR}/${sample}.2.fastq
done
