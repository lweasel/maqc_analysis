BIN_DIR=bin
DATA_DIR=data
BOWTIE_INDEX_DIR=hs_bowtie_index
MAPPED_READS_DIR=mapped_reads

MAP_READS=.map_reads

.PHONY: all clean

all: $(BOWTIE_INDEX_DIR)

$(MAP_READS): $(BOWTIE_INDEX_DIR)
	$(BIN_DIR)/map_reads.sh
	touch $@

$(BOWTIE_INDEX_DIR):
	mkdir $(BOWTIE_INDEX_DIR)
	bowtie-build $$($(BIN_DIR)/listFiles.sh , $(DATA_DIR)/per_contig/*.fa) $(BOWTIE_INDEX_DIR)/per_contig
	bowtie-inspect $(BOWTIE_INDEX_DIR)/per_contig > $(BOWTIE_INDEX)/per_contig.fa

clean:
	rm -f $(MAP_READS)
	rm -rf $(BOWTIE_INDEX_DIR)
	rm -rf $(MAPPED_READS_DIR)
