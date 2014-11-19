#!/usr/bin/env python

"""Usage:
    estimate_read_depth
        [--log-level=<log-level>]
        <quant-method>
        <quant-file>
        <read-length>
        <paired-end>

-h --help
    Show this message.
-v --version
    Show version.
--log-level=<log-level>
    Set logging level (one of {log_level_vals}) [default: info].
<quant-method>
    Method used to quantify transcripts (one of {quant_methods})
<quant-file>
    File containing per-transcript TPM abundances estimated by the particular
    quantification method.
<read-length>
    The length of reads in base-pairs of the RNA-seq data from which transcript
    abundance estimates were calculated.
<paired-end>
    A boolean, True if the RNA-seq reads were paired-end, False if they were
    single-end.
"""

import docopt
import ordutils.log as log
import ordutils.options as opt
import pandas as pd
import schema
import sys

LOG_LEVEL = "--log-level"
LOG_LEVEL_VALS = str(log.LEVELS.keys())

QUANT_METHOD = "<quant-method>"
SAILFISH_METHOD = "sailfish"
EXPRESS_METHOD = "express"
QUANT_METHODS = [SAILFISH_METHOD, EXPRESS_METHOD]

QUANT_FILE = "<quant-file>"
READ_LENGTH = "<read-length>"
PAIRED_END = "<paired-end>"

TRANSCRIPT_COL = {
    SAILFISH_METHOD: "Transcript",
    EXPRESS_METHOD: "target_id"
}

LENGTH_COL = {
    SAILFISH_METHOD: "Length",
    EXPRESS_METHOD: "length"
}

NUM_READS_COL = {
    SAILFISH_METHOD: "EstimatedNumReads",
    EXPRESS_METHOD: "eff_counts"
}


def validate_command_line_options(options):
    try:
        opt.validate_dict_option(
            options[LOG_LEVEL], log.LEVELS, "Invalid log level")
        opt.validate_list_option(
            options[QUANT_METHOD], QUANT_METHODS,
            "Invalid quantification method")
        opt.validate_file_option(
            options[QUANT_FILE],
            "Could not open Sailfish quantification results file.")
        options[READ_LENGTH] = opt.validate_int_option(
            options[READ_LENGTH], "Read length must be a positive integer",
            min_val=0)
        options[PAIRED_END] = opt.check_boolean_value(options[PAIRED_END])
    except schema.SchemaError as exc:
        exit("Exiting. " + exc.code)


def read_quantification_results(quant_method, quant_file, logger):
    results = pd.read_csv(quant_file, delim_whitespace=True)
    results.set_index(TRANSCRIPT_COL[quant_method], inplace=True)

    logger.info("Read quantification results for {n} transcripts.".
                format(n=len(results)))

    # Filter those transcripts with zero estimated reads
    results = results[results[NUM_READS_COL[quant_method]] > 0]

    logger.info("Retained {n} transcripts with non-zero expression".
                format(n=len(results)))

    return results


def calculate_mean_sequencing_depth(
        quant_method, quant_results, read_length,
        paired_end, logger):

    # Output the required number of reads to (approximately) give the specified
    # read depth
    total_transcript_length = quant_results[LENGTH_COL[quant_method]].sum()
    logger.info("Total transcript length {b} bases".
                format(b=total_transcript_length))

    total_reads = quant_results[NUM_READS_COL[quant_method]].sum()
    if quant_method == EXPRESS_METHOD and paired_end:
        # Express 'eff_counts' is the number of *fragments*
        total_reads *= 2

    logger.info("Total reads {r}.".format(r=total_reads))

    depth = total_reads * read_length // total_transcript_length
    logger.info("Read depth {d}.".format(d=depth))

    print(depth)


def main(docstring):
    # Read in command-line options
    docstring = docstring.format(
        log_level_vals=LOG_LEVEL_VALS,
        quant_methods=str(QUANT_METHODS))
    options = docopt.docopt(
        docstring, version="estimate_read_depth v1.0")

    # Validate command-line options
    validate_command_line_options(options)

    # Set up logger
    logger = log.get_logger(sys.stderr, options[LOG_LEVEL])

    # Read in Sailfish quantification results
    results = read_quantification_results(
        options[QUANT_METHOD], options[QUANT_FILE], logger)

    # Calculate mean sequencing depth given a read length and the numbers of
    # reads per transcript indicated by the quantification results
    calculate_mean_sequencing_depth(
        options[QUANT_METHOD], results, options[READ_LENGTH],
        options[PAIRED_END], logger)


if __name__ == "__main__":
    main(__doc__)
