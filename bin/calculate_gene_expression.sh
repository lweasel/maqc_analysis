#!/bin/bash

set -o nounset
set -o errexit

source bin/definitions.sh

function calculate_tpms_for_gene_names {
    local TPMS_FILE=$1
    local OUTPUT_FILE=$2
        
    local TMP_FILE=tpms_tmp.$(get_random_id)

    cat <(echo 'gene_id gene TPM') <(join -j 1 $PROTEIN_CODING_GENE_IDS $TPMS_FILE) |
        cut -d' ' -f 2,3 |
        tr ' ' '\t' > $TMP_FILE

    cat <(echo "gene TPM") <(datamash --header-in -s -g 1 sum 2 < $TMP_FILE) > $OUTPUT_FILE

    rm $TMP_FILE
}

function calculate_sailfish_gene_expression {
    local GTF_FILE=$1
    local TRANSCRIPT_EXPRESSION_FILE=$2
    local GENE_EXPRESSION_FILE=$3
    
    local TMP_FILE=sailfish_genes_tmp.$(get_random_id)

    genesum -g $GTF_FILE -e $TRANSCRIPT_EXPRESSION_FILE -o $TMP_FILE

    grep -v '^# \[' $TMP_FILE |
        sed -e 's/# //' |
        cut -f 1,3 |
        sed -e 's/Transcript/gene/' > $GENE_EXPRESSION_FILE

    rm $TMP_FILE
}

function calculate_rsem_gene_expression {
    local GENE_EXPRESSION_INPUT_FILE=$1
    local GENE_EXPRESSION_OUTPUT_FILE=$2

    local TMP_FILE=rsem_genes_tmp.$(get_random_id)

    cut -f 1,6 $GENE_EXPRESSION_INPUT_FILE |
        sed '1d' |
        sort -k 1 > $TMP_FILE

    calculate_tpms_for_gene_names $TMP_FILE $GENE_EXPRESSION_OUTPUT_FILE

    rm $TMP_FILE
}

function calculate_cufflinks_gene_expression {
    local TRANSCRIPT_EXPRESSION_FILE=$1
    local GENE_EXPRESSION_FILE=$2

    local TMP_FILE=cufflinks_genes_tmp.$(get_random_id)

    ${PYTHON_SCRIPT_DIR}/calculate_cufflinks_tpm.py $TRANSCRIPT_EXPRESSION_FILE |
        cut -f 2,15 |
        sed '1d' |
        sort -k 1 > $TMP_FILE

    calculate_tpms_for_gene_names $TMP_FILE $GENE_EXPRESSION_FILE

    rm $TMP_FILE
}

function calculate_express_gene_expression {
    local GTF_FILE=$1
    local TRANSCRIPT_EXPRESSION_FILE=$2
    local GENE_EXPRESSION_FILE=$3

    local TMP_FILE_1=express_transcripts_tmp.$(get_random_id)
    local TMP_FILE_2=express_genes_tmp.$(get_random_id)
    
    cut -f 2,3,15 $TRANSCRIPT_EXPRESSION_FILE |
        sed -e "s/target_id/# target_id/" > $TMP_FILE_1    

    genesum -g $GTF_FILE -e $TMP_FILE_1 -o $TMP_FILE_2

    sed 's/# //;s/target_id/gene/;s/tpm/TPM/' $TMP_FILE_2 |
        cut -f 1,3 > $GENE_EXPRESSION_FILE

    rm $TMP_FILE_1
    rm $TMP_FILE_2
}

mkdir -p $GENE_EXPRESSION_DIR

for sample in $SINGLE_END_SAMPLES $PAIRED_END_SAMPLES; do
    calculate_express_gene_expression \
        $GTF_FILE \
        ${QUANT_RESULTS_DIR}/${sample}.express_tpm \
        $GENE_EXPRESSION_DIR/${sample}.express_genes.txt
    calculate_sailfish_gene_expression \
        $GTF_FILE \
        ${QUANT_RESULTS_DIR}/${sample}.sailfish_tpm \
        $GENE_EXPRESSION_DIR/${sample}.sailfish_genes.txt
    calculate_rsem_gene_expression \
        ${QUANT_RESULTS_DIR}/${sample}.rsem_tpm \
        $GENE_EXPRESSION_DIR/${sample}.rsem_genes.txt
    calculate_cufflinks_gene_expression 
        ${QUANT_RESULTS_DIR}/${sample}.cufflinks_fpkm \
        $GENE_EXPRESSION_DIR/${sample}.cufflinks_genes.txt
done
