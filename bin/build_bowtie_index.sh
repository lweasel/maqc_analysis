#!/bin/bash

source bin/definitions.sh

mkdir -p ${BOWTIE_INDEX_DIR}

bowtie-build $(list_files , ${DATA_DIR}/per_contig/*.fa) $BOWTIE_INDEX
bowtie-inspect $BOWTIE_INDEX > ${BOWTIE_INDEX}.fa
