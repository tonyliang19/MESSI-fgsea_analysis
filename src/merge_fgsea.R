#!/usr/bin/env Rscript
# merge_fgsea.R
# Merges all per-chunk fgsea CSV files into a single output CSV.
# Run after all array tasks complete (enforced via SLURM --dependency).
#
# Usage:
#   Rscript merge_fgsea.R <results_dir> <final_output_csv>

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  stop("Usage: Rscript merge_fgsea.R <results_dir> <final_output_csv>")
}

results_dir <- args[1]
out_csv     <- args[2]

csv_files <- list.files(results_dir, pattern = "^fgsea_.*\\.csv$", full.names = TRUE)

if (length(csv_files) == 0) {
  stop("No fgsea_*.csv files found in: ", results_dir)
}

message("Merging ", length(csv_files), " CSV files ...")

df_list     <- lapply(csv_files, read.csv, check.names = FALSE)
combined_df <- do.call(rbind, df_list)

message("Total rows in merged dataframe: ", nrow(combined_df))

dir.create(dirname(out_csv), showWarnings = FALSE, recursive = TRUE)
write.csv(combined_df, out_csv, row.names = FALSE)

message("Final merged results written to: ", out_csv)
