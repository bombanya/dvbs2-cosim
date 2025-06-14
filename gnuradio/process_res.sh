#!/bin/bash

# Usage: process_res.sh input.file output.file reference.file

infile="$1"
outfile="$2"
reffile="$3"
nldpc=8100

# Safety checks
if [[ ! -f "$infile" ]]; then
  echo "Error: Input file '$infile' not found." >&2
  exit 1
fi

if [[ ! -f "$reffile" ]]; then
  echo "Error: Reference file '$reffile' not found." >&2
  exit 1
fi

# Get input size and compute trimmed size
orig_size=$(stat -c%s "$infile")
new_size=$((orig_size - 1))
aligned_size=$(( (new_size / nldpc) * nldpc ))

# Process the file
head -c "$aligned_size" "$infile" > "$outfile"

# Compare with reference
if cmp -s "$outfile" "$reffile"; then
  echo "Success: Output matches the reference file '$reffile'."
else
  echo "Warning: Output does NOT match the reference file '$reffile'."
fi
