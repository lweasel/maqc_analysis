#!/usr/bin/env python

import itertools
import pandas as pd

UNIVERSAL_HUMAN_REF = "uhr"
AMBION_HUMAN_BRAIN_REF = "hbr"
REFERENCE_SETS = [UNIVERSAL_HUMAN_REF, AMBION_HUMAN_BRAIN_REF]

# A = UHR, B = HBR, C = A:B 75:25, D = A:B 25:75
SAMPLES = ["A", "B", "C", "D"]
REPLICATES = ["1", "2", "3", "4"]

MEAN_UHRR = "mean UHRR"
MEAN_HBRR = "mean HBRR"
GROUND_TRUTH_COL = {
    UNIVERSAL_HUMAN_REF: MEAN_UHRR,
    AMBION_HUMAN_BRAIN_REF: MEAN_HBRR
}

GENE_COL = "gene"

SYNONYMS_ENSEMBL_NAME = "ensembl_name"
SYNONYMS_TAQMAN_NAME_COL = "taq_name"


def get_synonyms(synonym_file, logger):
    logger.info("Reading synonyms from " + synonym_file)
    return pd.read_csv(
        synonym_file, delim_whitespace=True, index_col=SYNONYMS_TAQMAN_NAME_COL)


def get_taqman_abundances(taqman_file, synonyms, logger):
    logger.info("Reading TaqMan abundances from " + taqman_file)
    taqman = pd.read_csv(taqman_file, delim_whitespace=True)

    taqman[MEAN_UHRR] = \
        (taqman["A1"] + taqman["A2"] + taqman["A3"] + taqman["A4"]) / 4
    taqman[MEAN_HBRR] = \
        (taqman["B1"] + taqman["B2"] + taqman["B3"] + taqman["B4"]) / 4

    # Now that we have calculate the mean abundances for the UHR and HBR
    # samples, drop the columns containing raw per-replicate abundances
    taqman.drop(["".join(pair) for pair in
                itertools.product(SAMPLES, REPLICATES)],
                inplace=True, axis=1)

    taqman[GENE_COL] = taqman[GENE_COL].map(
        lambda x: synonyms.ix[x][SYNONYMS_ENSEMBL_NAME]
        if x in synonyms.index else x)

    return taqman


def get_ground_truth_abundances(taqman_data, ref_type):
    return taqman_data[GROUND_TRUTH_COL[ref_type]]
