#!/bin/bash

DATA_DIR=data
FASTA_DIR=data/fasta
MAPPED_READS_DIR=mapped_reads
QUANT_RESULTS_DIR=quant_results

BOWTIE_INDEX=hs_bowtie_index/per_contig

SINGLE_END_SAMPLES="bullard_uhr bullard_hbr"
PAIRED_END_SAMPLES="rapaport_uhr_1 rapaport_uhr_2 rapaport_uhr_3 rapaport_uhr_4 rapaport_uhr_5 rapaport_hbr_1 rapaport_hbr_2 rapaport_hbr_3 rapaport_hbr_4 rapaport_hbr_5 au_hbr"

function get_random_id {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1   
}
