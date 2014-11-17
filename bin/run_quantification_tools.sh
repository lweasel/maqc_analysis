#!/bin/bash

set -o nounset
set -o errexit

source bin/definitions.sh

function quantify_with_cufflinks {
    SAMPLE=$1
    MAPPED_READS=$2
    
    OUTPUT_DIR=cufflinks.$(get_random_id)

    cufflinks \
        -p 8 \
        -u -b ${BOWTIE_INDEX}.fa  \
        --library-type fr-unstranded \
        -G $GTF_FILE \
        -o $OUTPUT_DIR \
        $MAPPED_READS

    mv $OUTPUT_DIR/genes.fpkm_tracking ${QUANT_RESULTS_DIR}/${SAMPLE}.cufflinks_fpkm
    rm -rf $OUTPUT_DIR
}

function quantify_with_sailfish {
    SAMPLE=$1

    OUTPUT_DIR=sailfish.$(get_random_id)

    if [ "$#" -eq 2 ]; then
        # Single-end reads
        READS_SPEC="-l T=SE:S=U -r $2"
    elif [ "$#" -eq 3 ]; then
        # Paired-end reads
        READS_SPEC="-l T=PE:O=><:S=U -1 $2 -2 $3"
    fi

    sailfish quant \
        -p 8 \
        -i $SAILFISH_INDEX_DIR \
        $READS_SPEC \
        -o $OUTPUT_DIR

    mv $OUTPUT_DIR/quant_bias_corrected.sf ${QUANT_RESULTS_DIR}/${SAMPLE}.sailfish_tpm
    rm -rf $OUTPUT_DIR
}

function quantify_with_rsem {
    SAMPLE=$1
    
    OUTPUT_DIR=rsem.$(get_random_id)
    mkdir -p $OUTPUT_DIR
    
    if [ "$#" -eq 2 ]; then
        # Single-end reads
        READS_SPEC=$2
    elif [ "$#" -eq 3 ]; then
        # Paired-end reads
        READS_SPEC="--paired-end $2 $3"
    fi

    rsem-calculate-expression \
        --p 8 \
        $READS_SPEC \
        $TRANSCRIPTS_REFERENCE \
        $OUTPUT_DIR/quant

    mv $OUTPUT_DIR/quant.genes.results ${QUANT_RESULTS_DIR}/${SAMPLE}.rsem_tpm
    rm -rf $OUTPUT_DIR
}

function quantify_with_express {
    SAMPLE=$1
    MAPPED_READS=$2
    
    OUTPUT_DIR=express.$(get_random_id)

    express ${TRANSCRIPTS_REFERENCE}.transcripts.fa $MAPPED_READS -o $OUTPUT_DIR

    mv $OUTPUT_DIR/results.xprs ${QUANT_RESULTS_DIR}/${SAMPLE}.express_tpm
    rm -rf $OUTPUT_DIR
}

mkdir -p $QUANT_RESULTS_DIR

#for sample in $SINGLE_END_SAMPLES; do
    #quantify_with_cufflinks $sample ${MAPPED_READS_DIR}/${sample}.${MAPPED_TO_GENOME_SUFFIX}
    #quantify_with_sailfish $sample ${RNA_SEQ_DIR}/${sample}.fastq
    #quantify_with_rsem $sample ${RNA_SEQ_DIR}/${sample}.fastq &
    #quantify_with_express $sample ${MAPPED_READS_DIR}/${sample}.${MAPPED_TO_TRANSCRIPTOME_SUFFIX}
#done

for sample in $PAIRED_END_SAMPLES; do
    quantify_with_cufflinks $sample ${MAPPED_READS_DIR}/${sample}.${MAPPED_TO_GENOME_SUFFIX} &
    #quantify_with_sailfish $sample ${RNA_SEQ_DIR}/${sample}.1.fastq ${RNA_SEQ_DIR}/${sample}.2.fastq
    #quantify_with_rsem $sample ${RNA_SEQ_DIR}/${sample}.1.fastq ${RNA_SEQ_DIR}/${sample}.2.fastq &
    #quantify_with_express $sample ${MAPPED_READS_DIR}/${sample}.${MAPPED_TO_TRANSCRIPTOME_SUFFIX}
done
