#!/usr/bin/env python

"""
Usage:
    taq_correlation
        [--log-level=<log-level>] --ref=<ref-type>
        <taq-file> <quant-file> <synonym-file>

Options:
-h --help
    Show this message.
-v --version
    Show version.
--log-level=<log-level>
    Set logging level (one of {log_level_vals}) [default: info].
--ref=<ref-type>
    The RNA-seq reference set (one of {ref_sets}).
<taq-file>
    File containing TaqMan qPCR measurements.
<quant-file>
    File containing per-gene TPM abundances estimated by a particular
    quantification method.
<synonym-file>
    File mapping between old gene names in TaqMan data and up-to-date
    nomenclature.
"""

import docopt
import matplotlib.pyplot as plt
import maqc
import numpy as np
import ordutils.log as log
import ordutils.options as opt
import pandas as pd
import schema
import sys

LOG_LEVEL = "--log-level"
LOG_LEVEL_VALS = str(log.LEVELS.keys())
REF_TYPE = "--ref"
TAQMAN_EXPRESSION_FILE = "<taq-file>"
QUANTIFICATION_FILE = "<quant-file>"
SYNONYM_FILE = "<synonym-file>"

GENE_COL = "gene"
TPM_COL = "TPM"


def validate_command_line_options(options):
    try:
        opt.validate_dict_option(
            options[LOG_LEVEL], log.LEVELS, "Invalid log level")
        opt.validate_file_option(
            options[TAQMAN_EXPRESSION_FILE],
            "Could not open TaqMan expression file.")
        opt.validate_file_option(
            options[QUANTIFICATION_FILE],
            "Could not open quantification file.")
        opt.validate_file_option(
            options[SYNONYM_FILE],
            "Could not open synonym file.")

        options[REF_TYPE] = options[REF_TYPE].lower()
        opt.validate_list_option(
            options[REF_TYPE], maqc.REFERENCE_SETS,
            "Invalid reference type")
    except schema.SchemaError as exc:
        exit(exc.code)


def get_quantification_results(quant_file, logger):
    logger.info("Reading quantification results from " + quant_file)
    return pd.read_csv(quant_file, delim_whitespace=True, index_col=GENE_COL)


def calculate_correlation(taqman, quant, ref_type, logger):
    taqman[TPM_COL] = taqman[GENE_COL].map(
        lambda x: quant.ix[x][TPM_COL] if x in quant.index else -1)

    taqman = taqman[taqman[TPM_COL] >= 0]

    num_genes = len(taqman)

    ground_truth = maqc.get_ground_truth_abundances(taqman, ref_type)
    corr = ground_truth.corr(taqman[TPM_COL], method='spearman')

    logger.info("Number of genes: " + str(num_genes))
    logger.info("Spearman correlation (UHRR): " + str(corr))

    print(corr)


def draw_abundance_scatter_plot(taqman, ref_type):
    plt.figure()
    plt.scatter(np.log10(taqman[maqc.GROUND_TRUTH_COL[ref_type]]).values,
                np.log10(taqman[TPM_COL]).values,
                c="lightblue", alpha=0.4)
    plt.savefig("scatter.svg", format="svg")
    plt.close()


def main(docstring):
    # Read in command-line options
    docstring = docstring.format(
        log_level_vals=LOG_LEVEL_VALS,
        ref_sets=maqc.REFERENCE_SETS)
    options = docopt.docopt(docstring, version="taq_correlations v1.0")

    # Validate command-line options
    validate_command_line_options(options)

    # Set up logger
    logger = log.get_logger(sys.stderr, options[LOG_LEVEL])

    # Read in synonym file
    synonyms = maqc.get_synonyms(options[SYNONYM_FILE], logger)

    # Read in TaqMan abundance measurements
    taqman = maqc.get_taqman_abundances(
        options[TAQMAN_EXPRESSION_FILE], synonyms, logger)

    # Read in abundances estimated by quantifier
    quant_results = get_quantification_results(
        options[QUANTIFICATION_FILE], logger)

    # Calculate Spearman rank correlation between gene abundances estimated by
    # a quantification tool and TaqMan qPCR measurements.
    calculate_correlation(taqman, quant_results, options[REF_TYPE], logger)

    # Draw a scatter plot of log transformed abundance estimates from the
    # quantification tool against TaqMan qPCR measurements.
    draw_abundance_scatter_plot(taqman, options[REF_TYPE])


if __name__ == "__main__":
    main(__doc__)
