#!/bin/sh

set -e

mkdir -p out

TOIT_EXE=$1
TOIT_FILE=$2

# Replace .toit with .png:
OUTPUT_FILE=${TOIT_FILE%.toit}.png

$TOIT_EXE $TOIT_FILE out/$OUTPUT_FILE

cmp out/$OUTPUT_FILE gold/$OUTPUT_FILE
