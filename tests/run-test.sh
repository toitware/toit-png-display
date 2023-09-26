#!/bin/sh

set -e

mkdir -p tests/out

TOIT_EXE=$1
TOIT_FILE=$2

# Replace .toit with .png:
OUTPUT_FILE=${TOIT_FILE%.toit}.png

$TOIT_EXE tests/$TOIT_FILE tests/out/$OUTPUT_FILE

cmp tests/out/$OUTPUT_FILE tests/gold/$OUTPUT_FILE
