#!/usr/bin/env Rscript
# run_fgsea.R
# Runs fgsea on a single chunk RDS file (named list of stat vectors).
# Called once per SLURM array task.
#
# Usage:
#   Rscript run_fgsea.R <chunk_rds> <db_rds> <out_dir>
#
# Output:
#   <out_dir>/fgsea_<chunk_basename>.csv

library(fgsea)

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 3) {
  stop("Usage: Rscript run_fgsea.R <chunk_rds> <db_rds> <out_dir>")
}

chunk_rds <- args[1]
db_rds    <- args[2]
out_dir   <- args[3]

message("chunk_rds : ", chunk_rds)
message("db_rds    : ", db_rds)
message("out_dir   : ", out_dir)

# Apply jitter for methods that produce tied ranks
jitter_strings <- c("mogonet")

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

pathways        <- readRDS(db_rds)
gsea_input_list <- readRDS(chunk_rds)

message("Running fgsea on ", length(gsea_input_list), " stat vectors ...")

results <- lapply(names(gsea_input_list), function(comb_name) {
  seed  <- sum(utf8ToInt(comb_name))
  ranks <- gsea_input_list[[comb_name]]

  if (grepl(paste(jitter_strings, collapse = "|"), comb_name)) {
    ranks <- ranks + rnorm(n = length(ranks), sd = 0.001)
  }

  set.seed(seed)
  result_df        <- fgsea(pathways, stats = ranks, minSize = 10, maxSize = 10000, eps = 1e-10)
  # Drop the leadingEdge column
  result_df        <- result_df[, -c("leadingEdge")]
  # Append group info
  result_df$group  <- comb_name
  # And return this
  return(result_df)
})

combined_df <- do.call(rbind, results)

chunk_name <- tools::file_path_sans_ext(basename(chunk_rds))
out_file   <- file.path(out_dir, paste0("fgsea_", chunk_name, ".csv"))
write.csv(combined_df, out_file, row.names = FALSE)

message("Written: ", out_file)
