#!/bin/bash

set -o nounset
set -o errexit

source bin/definitions.sh

for sample in $SINGLE_END_SAMPLES $PAIRED_END_SAMPLES; do
    for quant_method in "cufflinks" "express" "rsem" "sailfish"; do
        quant_file=${GENE_EXPRESSION_DIR}/${sample}.${quant_method}_genes.txt
        correlation=$($PYTHON_SCRIPT_DIR/taq_correlations.py --ref="${REF_TYPES[$sample]}" taq_genes.txt $quant_file $GENE_SYNONYMS)
        
        echo ${quant_method},${sample},${correlation}
        mv scatter.svg ${ANALYSIS_DIR}/${sample}.${quant_method}_scatter.svg
    done
done
