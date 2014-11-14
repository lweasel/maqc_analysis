#!/bin/bash

source bin/definitions.sh

function quantify_with_cufflinks {
    SAMPLE=$1
    
    OUTPUT_DIR=cufflinks.$(get_random_id)
    cufflinks -o $OUTPUT_DIR -u -b ${BOWTIE_INDEX}.fa -p 8 --library-type fr-unstranded -G ${DATA_DIR}/human_protein_coding.gtf ${MAPPED_READS_DIR}/${SAMPLE}.bam
    mv $OUTPUT_DIR/genes.fpkm_tracking ${QUANT_RESULTS_DIR}/${SAMPLE}.cufflinks_fpkm
    rm -rf $OUTPUT_DIR
}

mkdir -p $QUANT_RESULTS_DIR

for sample in $SINGLE_END_SAMPLES $PAIRED_END_SAMPLES; do
    quantify_with_cufflinks $sample
done
