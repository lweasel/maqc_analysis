SHELL := /bin/bash

BIN_DIR=bin
DATA_DIR=data
MAPPED_READS_DIR=mapped_reads
QUANT_RESULTS_DIR=quant_results
GENE_EXPRESSION_DIR=gene_expression
GENOME_REF_DIR=genome_reference
ANALYSIS_DIR=analysis
TRANSCRIPTS_REF=$(GENOME_REF_DIR)/transcripts
SAILFISH_INDEX=$(GENOME_REF_DIR)/sailfish
GTF_FILE=data/human_protein_coding.gtf
TAQ_DATA=$(DATA_DIR)/taq.txt

# Fix to $(GENOME_REF_DIR)/hs_bowtie_index
BOWTIE_INDEX_DIR=hs_bowtie_index

MAP_READS=.map_reads
PREPARE_TRANSCRIPT_REFERENCE=.prepare_transcript_reference
RUN_QUANTIFICATION_TOOLS=.run_quantification_tools
CALCULATE_GENE_EXPRESSION=.calculate_gene_expression
PROTEIN_CODING_GENE_IDS=protein_coding_gene_ids.txt
TAQMAN_GENE_ABUNDANCES=taq_genes.txt
ESTIMATED_READ_DEPTHS=$(ANALYSIS_DIR)/estimated_read_depths.csv

.PHONY: all clean

all: $(ESTIMATED_READ_DEPTHS)

$(ESTIMATED_READ_DEPTHS): $(RUN_QUANTIFICATION_TOOLS)
	mkdir -p $(ANALYSIS_DIR)
	$(BIN_DIR)/estimate_read_depths.sh > $@

$(TAQMAN_GENE_ABUNDANCES):
	grep -v -f <(cut -f 1 $(TAQ_DATA) | sort | uniq -d) $(TAQ_DATA) > $@

$(CALCULATE_GENE_EXPRESSION): $(RUN_QUANTIFICATION_TOOLS) $(PROTEIN_CODING_GENE_IDS)
	$(BIN_DIR)/calculate_gene_expression.sh
	touch $@

$(PROTEIN_CODING_GENE_IDS):
	cut -f 9 $(GTF_FILE) | cut -d ';' -f 1,4 | sed 's/"//g' | sed 's/gene_id //' | sed 's/; gene_name / /' | uniq | sort | uniq > $@

$(RUN_QUANTIFICATION_TOOLS): $(MAP_READS) $(TRANSCRIPTS_REF) $(SAILFISH_INDEX)
	$(BIN_DIR)/run_quantification_tools.sh
	touch $@

$(SAILFISH_INDEX): $(TRANSCRIPTS_REF)
	mkdir $(SAILFISH_INDEX)
	sailfish index -p 8 -t $(TRANSCRIPTS_REF)/ref.transcripts.fa -k 20 -o $(SAILFISH_INDEX)
	
$(TRANSCRIPTS_REF):
	mkdir $(GENOME_REF_DIR)
	rsem-prepare-reference --gtf $(GTF_FILE) --no-polyA $(DATA_DIR)/per_contig $(TRANSCRIPTS_REF)

$(MAP_READS): $(BOWTIE_INDEX_DIR)
	$(BIN_DIR)/map_reads.sh
	touch $@

$(BOWTIE_INDEX_DIR):
	mkdir $(BOWTIE_INDEX_DIR)
	bowtie-build $$($(BIN_DIR)/listFiles.sh , $(DATA_DIR)/per_contig/*.fa) $(BOWTIE_INDEX_DIR)/per_contig
	bowtie-inspect $(BOWTIE_INDEX_DIR)/per_contig > $(BOWTIE_INDEX)/per_contig.fa

clean:
	rm -f $(MAP_READS)
	rm -f $(RUN_QUANTIFICATION_TOOLS)
	rm -f $(CALCULATE_GENE_EXPRESSION)
	rm -f $(PROTEIN_CODING_GENE_IDS)
	rm -f $(TAQMAN_GENE_ABUNDANCES)
	rm -f $(ESTIMATED_READ_DEPTHS)
	rm -rf $(BOWTIE_INDEX_DIR)
	rm -rf $(GENOME_REF_DIR)
	rm -rf $(MAPPED_READS_DIR)
	rm -rf $(QUANT_RESULTS_DIR)
	rm -rf $(GENE_EXPRESSION_DIR)
	rm -rf $(ANALYSIS_DIR)
