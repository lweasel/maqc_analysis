BIN_DIR=bin
DATA_DIR=data
BOWTIE_INDEX_DIR=hs_bowtie_index
MAPPED_READS_DIR=mapped_reads
QUANT_RESULTS_DIR=quant_results

MAP_READS=.map_reads
RUN_QUANTIFICATION_TOOLS=.run_quantification_tools

.PHONY: all clean

all: $(BOWTIE_INDEX_DIR)

$(RUN_QUANTIFICATION_TOOLS): $(MAP_READS)
	$(BIN_DIR)/run_quantification_tools.sh
	touch $@

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
	rm -rf $(MAPPED_READS_DIR)
	rm -rf $(QUANT_RESULTS_DIR)
