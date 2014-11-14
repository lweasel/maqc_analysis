#!/bin/bash

DATA_DIR=data
RNA_SEQ_DIR=data/rna_seq
MAPPED_READS_DIR=mapped_reads
GENOME_REF_DIR=genome_reference
QUANT_RESULTS_DIR=quant_results

BOWTIE_INDEX=hs_bowtie_index/per_contig
SAILFISH_INDEX_DIR=${GENOME_REF_DIR}/sailfish
TRANSCRIPTS_REFERENCE=${GENOME_REF_DIR}/transcripts/ref

MAPPED_TO_GENOME_SUFFIX=genome.bam
MAPPED_TO_TRANSCRIPTOME_SUFFIX=transcriptome.bam

SINGLE_END_SAMPLES="bullard_uhr bullard_hbr"
PAIRED_END_SAMPLES="rapaport_uhr_1 rapaport_uhr_2 rapaport_uhr_3 rapaport_uhr_4 rapaport_uhr_5 rapaport_hbr_1 rapaport_hbr_2 rapaport_hbr_3 rapaport_hbr_4 rapaport_hbr_5 au_hbr"

function get_random_id {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1   
}
