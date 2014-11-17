#!/bin/bash

set -o nounset
set -o errexit

source bin/definitions.sh

function estimate_sailfish_read_depth {
    GENE_EXPRESSION_FILE=$1
    READ_LENGTH=$2
    
    local TMP_FILE=sailfish_transcripts_tmp.$(get_random_id)

    grep -v '^# \[' $GENE_EXPRESSION_FILE |
        sed 's/# //' > $TMP_FILE

    ${PYTHON_SCRIPT_DIR}/estimate_sailfish_read_depth.py $TMP_FILE $READ_LENGTH

    rm $TMP_FILE
}

for sample in $SINGLE_END_SAMPLES $PAIRED_END_SAMPLES; do
    echo Sailfish,$sample,$(estimate_sailfish_read_depth ${QUANT_RESULTS_DIR}/${sample}.sailfish_tpm "${READ_LENGTHS[$sample]}")
done
