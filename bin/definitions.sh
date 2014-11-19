#!/bin/bash

set -o nounset
set -o errexit

DATA_DIR=data
RNA_SEQ_DIR=data/rna_seq
MAPPED_READS_DIR=mapped_reads
GENOME_REF_DIR=genome_reference
QUANT_RESULTS_DIR=quant_results
GENE_EXPRESSION_DIR=gene_expression
ANALYSIS_DIR=analysis

GTF_FILE=${DATA_DIR}/human_protein_coding.gtf 
BOWTIE_INDEX_DIR=hs_bowtie_index
BOWTIE_INDEX=${BOWTIE_INDEX_DIR}/per_contig
SAILFISH_INDEX_DIR=${GENOME_REF_DIR}/sailfish
TRANSCRIPTS_REFERENCE=${GENOME_REF_DIR}/transcripts/ref
PROTEIN_CODING_GENE_IDS=protein_coding_gene_ids.txt
GENE_SYNONYMS=${DATA_DIR}/synonyms.txt

BIN_DIR=bin
PYTHON_SCRIPT_DIR=${BIN_DIR}/python

MAPPED_TO_GENOME_SUFFIX=genome.bam
MAPPED_TO_TRANSCRIPTOME_SUFFIX=transcriptome.bam

SINGLE_END_SAMPLES="bullard_uhr bullard_hbr"
PAIRED_END_SAMPLES="rapaport_uhr_1 rapaport_uhr_2 rapaport_uhr_3 rapaport_uhr_4 rapaport_uhr_5 rapaport_hbr_1 rapaport_hbr_2 rapaport_hbr_3 rapaport_hbr_4 rapaport_hbr_5 au_hbr"

declare -A READ_LENGTHS=(
    ["bullard_uhr"]="35" 
    ["bullard_hbr"]="35" 
    ["rapaport_uhr_1"]="101" 
    ["rapaport_uhr_2"]="101" 
    ["rapaport_uhr_3"]="101" 
    ["rapaport_uhr_4"]="101" 
    ["rapaport_uhr_5"]="101" 
    ["rapaport_hbr_1"]="101" 
    ["rapaport_hbr_2"]="101" 
    ["rapaport_hbr_3"]="101" 
    ["rapaport_hbr_4"]="101" 
    ["rapaport_hbr_5"]="101" 
    ["au_hbr"]="50" )

declare -A REF_TYPES=(
    ["bullard_uhr"]="uhr" 
    ["bullard_hbr"]="hbr" 
    ["rapaport_uhr_1"]="uhr" 
    ["rapaport_uhr_2"]="uhr" 
    ["rapaport_uhr_3"]="uhr" 
    ["rapaport_uhr_4"]="uhr" 
    ["rapaport_uhr_5"]="uhr" 
    ["rapaport_hbr_1"]="hbr" 
    ["rapaport_hbr_2"]="hbr" 
    ["rapaport_hbr_3"]="hbr" 
    ["rapaport_hbr_4"]="hbr" 
    ["rapaport_hbr_5"]="hbr" 
    ["au_hbr"]="hbr" )

function get_random_id {
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1   
}

function list_files {
    local DELIMITER=$1
    shift
    local FILES=$@
    
    OUTPUT=$(ls -1 $FILES | tr '\n' "$DELIMITER")
    echo ${OUTPUT%$DELIMITER}    
}
