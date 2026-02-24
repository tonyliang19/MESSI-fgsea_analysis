#!/usr/bin/env Rscript
# split_input.R
# Splits a named list RDS (stat vectors for fgsea) into per-chunk RDS files.
# Each chunk becomes one SLURM array task.
#
# Usage:
#   Rscript split_input.R <input_rds> <chunks_dir> [chunk_size]
#
# Arguments:
#   input_rds   : Path to the input RDS (named list of stat vectors)
#   chunks_dir  : Output directory where per-chunk RDS files will be written
#   chunk_size  : (optional) Number of stat vectors per chunk. Default: 57
#                 Set to 0 to split by the first field of the name (e.g. method).

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Usage: Rscript split_input.R <input_rds> <chunks_dir> [chunk_size]")
}

input_rds  <- args[1]
chunks_dir <- args[2]
chunk_size <- if (length(args) >= 3) as.integer(args[3]) else 57L

message("Reading input RDS: ", input_rds)
gsea_input_list <- readRDS(input_rds)
n <- length(gsea_input_list)
message("Total stat vectors: ", n)

dir.create(chunks_dir, showWarnings = FALSE, recursive = TRUE)

if (chunk_size == 0L) {
  # Split by first field of name (text before first " | ")
  group_keys <- sub(" \\|.*", "", names(gsea_input_list))
  unique_groups <- unique(group_keys)
  message("Splitting by name prefix into ", length(unique_groups), " groups")
  for (grp in unique_groups) {
    idx   <- which(group_keys == grp)
    chunk <- gsea_input_list[idx]
    # Sanitise group name for use as filename
    safe  <- gsub("[^A-Za-z0-9._-]", "_", grp)
    out   <- file.path(chunks_dir, paste0(safe, ".rds"))
    saveRDS(chunk, out)
    message("  Wrote ", length(chunk), " vectors -> ", out)
  }
} else {
  # Split into fixed-size chunks
  n_chunks <- ceiling(n / chunk_size)
  message("Splitting into ", n_chunks, " chunks of up to ", chunk_size, " vectors each")
  for (i in seq_len(n_chunks)) {
    idx   <- seq((i - 1L) * chunk_size + 1L, min(i * chunk_size, n))
    chunk <- gsea_input_list[idx]
    out   <- file.path(chunks_dir, sprintf("chunk_%04d.rds", i))
    saveRDS(chunk, out)
    message("  Wrote chunk ", i, " (", length(chunk), " vectors) -> ", out)
  }
}

message("Done. Chunks written to: ", chunks_dir)
