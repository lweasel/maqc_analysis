#!/bin/bash

set -o nounset
set -o errexit

source bin/definitions.sh

for sample in $SINGLE_END_SAMPLES $PAIRED_END_SAMPLES; do
    ${PYTHON_SCRIPT_DIR}/quantification_ranks.py \
        --ref="${REF_TYPES[$sample]}" \
        ${TAQMAN_GENE_ABUNDANCES} \
        $GENE_SYNONYMS \
        ${GENE_EXPRESSION_DIR}/${sample}.*_genes* \
        > ${ANALYSIS_DIR}/${sample}_ranks.csv
done
