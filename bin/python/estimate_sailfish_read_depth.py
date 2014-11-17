#!/usr/bin/env python

"""Usage:
    calculate_sailfish_read_depth
        [--log-level=<log-level>]
        <quant-file>
        <read-length>

-h --help
    Show this message.
-v --version
    Show version.
--log-level=<log-level>
    Set logging level (one of {log_level_vals}) [default: info].
<quant-file>
    File containing per-transcript TPM abundances estimated by Sailfish.
"""

import docopt
import ordutils.log as log
import ordutils.options as opt
import pandas as pd
import schema
import sys

LOG_LEVEL = "--log-level"
LOG_LEVEL_VALS = str(log.LEVELS.keys())
READ_LENGTH = "<read-length>"
QUANT_FILE = "<quant-file>"

TRANSCRIPT_COL = "Transcript"
LENGTH_COL = "Length"
NUM_READS_COL = "EstimatedNumReads"


def validate_command_line_options(options):
    try:
        opt.validate_dict_option(
            options[LOG_LEVEL], log.LEVELS, "Invalid log level")
        opt.validate_file_option(
            options[QUANT_FILE],
            "Could not open Sailfish quantification results file.")
        options[READ_LENGTH] = opt.validate_int_option(
            options[READ_LENGTH], "Read length must be a positive integer",
            min_val=0)
    except schema.SchemaError as exc:
        exit("Exiting. " + exc.code)


def read_quantification_results(quant_file, logger):
    results = pd.read_csv(quant_file, delim_whitespace=True)
    results.set_index(TRANSCRIPT_COL, inplace=True)

    logger.info("Read quantification results for {n} transcripts.".
                format(n=len(results)))

    # Filter those transcripts with zero estimated reads
    results = results[results[NUM_READS_COL] > 0]

    logger.info("Retained {n} transcripts with non-zero expression".
                format(n=len(results)))

    return results


def calculate_mean_sequencing_depth(quant_results, read_length, logger):
    # Output the required number of reads to (approximately) give the specified
    # read depth
    total_transcript_length = quant_results[LENGTH_COL].sum()
    logger.info("Total transcript length {b} bases".
                format(b=total_transcript_length))

    total_reads = quant_results[NUM_READS_COL].sum()
    logger.info("Total reads {r}.".format(r=total_reads))

    depth = total_reads * read_length // total_transcript_length
    logger.info("Read depth {d}.".format(d=depth))

    print(depth)


def main(docstring):
    # Read in command-line options
    docstring = docstring.format(log_level_vals=LOG_LEVEL_VALS)
    options = docopt.docopt(
        docstring, version="calculate_sailfish_read_depth v1.0")

    # Validate command-line options
    validate_command_line_options(options)

    # Set up logger
    logger = log.get_logger(sys.stderr, options[LOG_LEVEL])

    # Read in Sailfish quantification results
    results = read_quantification_results(options[QUANT_FILE], logger)

    # Calculate mean sequencing depth given a read length and the numbers of
    # reads per transcript indicated by the quantification results
    calculate_mean_sequencing_depth(results, options[READ_LENGTH], logger)


if __name__ == "__main__":
    main(__doc__)
