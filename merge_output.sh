#!/usr/bin/env bash



set -e



if [ "$#" -ne 2 ]; then

  echo "Usage: $0 <input_dir> <output_file>"

  echo "Example: $0 results/chunks results/fgsea_merged.csv"

  exit 1

fi



INPUT_DIR="$1"

OUTPUT_FILE="$2"



FILES=("$INPUT_DIR"/fgsea*.csv)



if [ ! -e "${FILES[0]}" ]; then

  echo "No files found matching $INPUT_DIR/fgsea*.csv"

  exit 1

fi



NUM_FILES=${#FILES[@]}



echo "Found $NUM_FILES files."

echo "Merging into $OUTPUT_FILE"



# Write header from first file

head -n 1 "${FILES[0]}" > "$OUTPUT_FILE"



# Append remaining rows

for f in "${FILES[@]}"; do

  tail -n +2 "$f" >> "$OUTPUT_FILE"

done



echo "Successfully merged $NUM_FILES files."
