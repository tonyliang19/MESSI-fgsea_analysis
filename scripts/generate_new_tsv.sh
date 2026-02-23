#!/bin/bash

# Set paths
input_dir="gsea_inputs"
#pathways_file="data/msigdbr_c2reactome-c6_pathways.rds"
pathways_file="data/panglao_db_pathways.rds"
#results/fgsea_part2/diablo_full_GSE38609_fgsea.rds"
output_dir="results/fgsea_part2"
output_tsv="new_fgsea_part2_inputs.tsv"

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Start fresh
> "$output_tsv"

# Verbose messages
echo "Reading .rds input files from: $input_dir"
echo "Pathways file: $pathways_file"
echo "Writing output TSV to: $output_tsv"
echo ""

# Counter
count=0

# Loop through RDS files
for input_file in $(ls "$input_dir"/*.rds | sort -V); do
    base=$(basename "$input_file" .rds)
    output_file="$output_dir/${base}_fgsea.rds"
    echo -e "${input_file}\t${pathways_file}\t${output_file}" >> "$output_tsv"
    echo "Added entry: $input_file -> $output_file"
    ((count++))
done

echo ""
echo "Done. Total entries written: $count"
echo "Output file created: $output_tsv"
