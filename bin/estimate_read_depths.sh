#!/bin/bash

set -o nounset
set -o errexit

source bin/definitions.sh

function estimate_read_depth {
    local QUANT_METHOD=$1
    local GENE_EXPRESSION_FILE=$2
    local READ_LENGTH=$3
    
    local TMP_FILE=transcripts_tmp.$(get_random_id)

    grep -v '^# \[' $GENE_EXPRESSION_FILE |
        sed 's/# //' > $TMP_FILE

    ${PYTHON_SCRIPT_DIR}/estimate_read_depth.py $QUANT_METHOD $TMP_FILE $READ_LENGTH

    rm $TMP_FILE
}

for sample in $SINGLE_END_SAMPLES; do
    for quant_method in sailfish express; do
        echo ${quant_method},$sample,$(estimate_read_depth ${quant_method} ${QUANT_RESULTS_DIR}/${sample}.${quant_method}_tpm "${READ_LENGTHS[$sample]} False")
    done
done

for sample in $PAIRED_END_SAMPLES; do
    for quant_method in sailfish express; do
        echo ${quant_method},$sample,$(estimate_read_depth ${quant_method} ${QUANT_RESULTS_DIR}/${sample}.${quant_method}_tpm "${READ_LENGTHS[$sample]} True")
    done
done
