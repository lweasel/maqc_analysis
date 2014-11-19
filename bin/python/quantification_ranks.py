#!/usr/bin/env python

"""
Usage:
    quantification_ranks
        [--log-level=<log-level>] --ref=<ref-type>
        <taq-file> <synonym-file>
        <quant-file>...

Options:
-h --help
    Show this message.
-v --version
    Show version.
--log-level=<log-level>
    Set logging level (one of {log_level_vals}) [default: info].
--ref-type=<ref-type>
    The RNA-seq reference set (one of {ref_sets}).
<taq-file>
    File containing TaqMan qPCR measurements.
<synonym-file>
    File mapping between old gene names in TaqMan data and up-to-date
    nomenclature.
<quant-file>...
    File(s) containing per-gene TPM abundances estimated by particular
    quantification methods.
"""

import docopt
import maqc
import ordutils.log as log
import ordutils.options as opt
import os.path
import pandas as pd
import schema
import sys

LOG_LEVEL = "--log-level"
LOG_LEVEL_VALS = str(log.LEVELS.keys())
REF_TYPE = "--ref"
TAQMAN_EXPRESSION_FILE = "<taq-file>"
SYNONYM_FILE = "<synonym-file>"
QUANTIFICATION_FILES = "<quant-file>"

GENE_COL = "gene"
TPM_COL = "TPM"

# Suppress false-positive warnings about chained assignment.
pd.options.mode.chained_assignment = None


def validate_command_line_options(options):
    try:
        opt.validate_dict_option(
            options[LOG_LEVEL], log.LEVELS, "Invalid log level")
        opt.validate_file_option(
            options[TAQMAN_EXPRESSION_FILE],
            "Could not open TaqMan expression file.")
        opt.validate_file_option(
            options[SYNONYM_FILE],
            "Could not open synonym file.")

        for quant_file in options[QUANTIFICATION_FILES]:
            opt.validate_file_option(
                quant_file,
                "Could not open quantification file " + quant_file)
    except schema.SchemaError as exc:
        exit(exc.code)


def get_quantification_results(quant_files, logger):
    quant_results = {}

    for quant_file in quant_files:
        logger.info("Reading quantification results from " + quant_file)
        quant_id = os.path.splitext(os.path.basename(quant_file))[0]
        quant_results[quant_id] = pd.read_csv(
            quant_file, delim_whitespace=True, index_col=GENE_COL)

    return quant_results


def calculate_ranks(taqman, quant_results, ref_type, logger):
    ground_truth_rank_col = ref_type + ".rank"
    taqman[ground_truth_rank_col] = \
        maqc.get_ground_truth_abundances(taqman, ref_type).rank(ascending=False)

    for quant_id, results in quant_results.items():
        taqman[quant_id] = taqman[GENE_COL].map(
            lambda x: results.ix[x][TPM_COL] if x in results.index else -1)
        taqman = taqman[taqman[quant_id] >= 0]

        quant_rank_col = quant_id + ".rank"
        taqman[quant_rank_col] = taqman[quant_id].rank(ascending=False)

        rank_diff_col = quant_id + "-taqman.rank_diff"
        taqman[rank_diff_col] = \
            taqman[quant_rank_col] - taqman[ground_truth_rank_col]

        taqman[quant_id + "-taqman.abs_rank_diff"] = abs(taqman[rank_diff_col])

    print(taqman.to_csv())


def main(docstring):
    # Read in command-line options
    docstring = docstring.format(
        log_level_vals=LOG_LEVEL_VALS,
        ref_sets=maqc.REFERENCE_SETS)
    options = docopt.docopt(docstring, version="quantification_ranks v0.1")

    # Validate command-line options
    validate_command_line_options(options)

    # Set up logger
    logger = log.get_logger(sys.stderr, options[LOG_LEVEL])

    # Read in synonym file
    synonyms = maqc.get_synonyms(options[SYNONYM_FILE], logger)

    # Read in TaqMan abundance measurements
    taqman = maqc.get_taqman_abundances(
        options[TAQMAN_EXPRESSION_FILE], synonyms, logger)

    # Read in abundances estimated by quantifiers
    quant_results = get_quantification_results(
        options[QUANTIFICATION_FILES], logger)

    # Calculate ranks of genes ordered by abundance for both ground truth
    # TaqMan qPCR data, and for abundances estimated by quantification tools
    calculate_ranks(taqman, quant_results, options[REF_TYPE], logger)


if __name__ == "__main__":
    main(__doc__)
