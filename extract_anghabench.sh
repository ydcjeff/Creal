#!/usr/bin/env bash

set -e
# set -x

DIRNAME="$(dirname "$0")"
ANGHABENCH_DIR="$DIRNAME/../AnghaBench/"
PROJECTS=$(find "$ANGHABENCH_DIR" -maxdepth 1 -mindepth 1 -type d)

mkdir -p "$DIRNAME/extracted_anghabench"

for project in $PROJECTS; do
  echo "[$0] Building function DB from $project..."

  FNS_DST="$DIRNAME/extracted_anghabench/$(basename "$project")_fns.json"
  FNS_IO_DST="$DIRNAME/extracted_anghabench/$(basename "$project")_fns_io.json"

  "$DIRNAME/databaseconstructor/functionextractor/extractor.py" \
    --src "$project" \
    --dst "$FNS_DST"
  echo "[$0] Extracted functions into $FNS_DST"

  "$DIRNAME/databaseconstructor/generate.py" \
    --src "$FNS_DST" \
    --dst "$FNS_IO_DST"
  echo "[$0] Generated I/O pairs into $FNS_IO_DST"
  echo
done
