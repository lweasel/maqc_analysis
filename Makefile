BIN_DIR=bin
DATA_DIR=data
MAPPED_READS_DIR=mapped_reads
QUANT_RESULTS_DIR=quant_results
GENOME_REF_DIR=genome_reference
TRANSCRIPTS_REF=$(GENOME_REF_DIR)/transcripts
SAILFISH_INDEX=$(GENOME_REF_DIR)/sailfish

# Fix to $(GENOME_REF_DIR)/hs_bowtie_index
BOWTIE_INDEX_DIR=hs_bowtie_index

MAP_READS=.map_reads
PREPARE_TRANSCRIPT_REFERENCE=.prepare_transcript_reference
RUN_QUANTIFICATION_TOOLS=.run_quantification_tools

.PHONY: all clean

all: $(BOWTIE_INDEX_DIR)

$(RUN_QUANTIFICATION_TOOLS): $(MAP_READS) $(TRANSCRIPTS_REF) $(SAILFISH_INDEX)
	$(BIN_DIR)/run_quantification_tools.sh
	touch $@

$(SAILFISH_INDEX): $(TRANSCRIPTS_REF)
	mkdir $(SAILFISH_INDEX)
	sailfish index -p 8 -t $(TRANSCRIPTS_REF)/ref.transcripts.fa -k 20 -o $(SAILFISH_INDEX)
	
$(TRANSCRIPTS_REF):
	mkdir $(GENOME_REF_DIR)
	rsem-prepare-reference --gtf data/human_protein_coding.gtf --no-polyA $(DATA_DIR)/per_contig $(TRANSCRIPTS_REF)

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
	rm -rf $(BOWTIE_INDEX_DIR)
	rm -rf $(GENOME_REF_DIR)
	rm -rf $(MAPPED_READS_DIR)
	rm -rf $(QUANT_RESULTS_DIR)
