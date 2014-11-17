#!/usr/bin/env python

"""Usage:
    calculate_cufflinks_tpm [--log-level=<log-level>] <quant-file>

-h --help
    Show this message.
-v --version
    Show version.
--log-level=<log-level>
    Set logging level (one of {log_level_vals}) [default: info].
<quant-file>
    File containing per-transcript FPKM abundances estimated by Cufflinks.
"""

import docopt
import ordutils.log as log
import ordutils.options as opt
import pandas as pd
import schema
import sys

LOG_LEVEL = "--log-level"
LOG_LEVEL_VALS = str(log.LEVELS.keys())
QUANT_FILE = "<quant-file>"

FPKM_COL = "FPKM"
TPM_COL = "TPM"


def validate_command_line_options(options):
    try:
        opt.validate_dict_option(
            options[LOG_LEVEL], log.LEVELS, "Invalid log level")
        opt.validate_file_option(
            options[QUANT_FILE],
            "Could not open Sailfish quantification results file.")
    except schema.SchemaError as exc:
        exit("Exiting. " + exc.code)


def write_tpms_to_csv(fpkm_file, logger):
    # Read in Cufflinks quantification results
    logger.info("Reading FPKM values from " + fpkm_file)
    results = pd.read_csv(fpkm_file, delim_whitespace=True)

    norm_constant = 1000000.0 / results[FPKM_COL].sum()
    results[TPM_COL] = results[FPKM_COL] * norm_constant

    results.to_csv(sys.stdout, sep='\t')


def main(docstring):
    # Read in command-line options
    docstring = docstring.format(log_level_vals=LOG_LEVEL_VALS)
    options = docopt.docopt(docstring, version="calculate_cufflinks_tpm v1.0")

    # Set up logger
    logger = log.get_logger(sys.stderr, options[LOG_LEVEL])

    write_tpms_to_csv(options[QUANT_FILE], logger)

if __name__ == "__main__":
    main(__doc__)
