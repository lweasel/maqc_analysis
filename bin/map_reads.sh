#!/bin/bash

source bin/definitions.sh

function map_reads_to_genome {
    HITS_FILE=$1
    shift
    READS_FILES=$@

    OUTPUT_DIR=tho.$(get_random_id)
    tophat --library-type fr-unstranded --no-coverage-search -p 8 -o $OUTPUT_DIR ${BOWTIE_INDEX} $@
    mv $OUTPUT_DIR/accepted_hits.bam $HITS_FILE
    rm -rf $OUTPUT_DIR
}

function map_reads_to_transcriptome {
    HITS_FILE=$1
    
    if [ "$#" -eq 2 ]; then
        # Single-end reads
        READS_SPEC="$2"
    elif [ "$#" -eq 3 ]; then
        # Paired-end reads
        READS_SPEC="-1 $2 -2 $3"
    fi

    bowtie \
        -q -e 99999999 -l 25 -I 1 -X 1000 -a -S -m 200 -p 8 \
        $TRANSCRIPTS_REFERENCE \
        $READS_SPEC | \
    samtools view -Sb - > $HITS_FILE
}

mkdir -p $MAPPED_READS_DIR

for sample in $SINGLE_END_SAMPLES; do
    map_reads_to_genome \
        ${MAPPED_READS_DIR}/${sample}.${MAPPED_TO_GENOME_SUFFIX} \
        ${RNA_SEQ_DIR}/${sample}.fastq
    map_reads_to_transcriptome \
        ${MAPPED_READS_DIR}/${sample}.${MAPPED_TO_TRANSCRIPTOME_SUFFIX} \
        ${RNA_SEQ_DIR}/${sample}.fastq
done

for sample in $PAIRED_END_SAMPLES; do
    map_reads_to_genome \
        ${MAPPED_READS_DIR}/${sample}.${MAPPED_TO_GENOME_SUFFIX} \
        ${RNA_SEQ_DIR}/${sample}.1.fastq \
        ${RNA_SEQ_DIR}/${sample}.2.fastq
    map_reads_to_transcriptome \
        ${MAPPED_READS_DIR}/${sample}.${MAPPED_TO_TRANSCRIPTOME_SUFFIX} \
        ${RNA_SEQ_DIR}/${sample}.1.fastq \
        ${RNA_SEQ_DIR}/${sample}.2.fastq
done
