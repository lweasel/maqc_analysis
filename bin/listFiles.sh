#!/bin/bash

DELIMITER=$1
shift
FILES=$@

OUTPUT=`ls -1 $FILES | tr '\n' "$DELIMITER"`
echo ${OUTPUT%$DELIMITER}
