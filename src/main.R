library(fgsea)


args  <- commandArgs(trailingOnly=TRUE)
input_rds <- args[1]
db_rds <- args[2]
#message("\nGSEA input rds: ", input_rds)
#message("\nDB rds: ", db_rds)

# Then here should split the 


fgsea_main <- function(input_rds, db_rds) {


# Apply the extra jitter to stats for specific methods only, to avoid ties in the ranks for those method
jitter_strings <- c("mogonet")

pathways <- readRDS(db_rds)
gsea_input_list <- readRDS(input_rds)

results <- lapply(names(gsea_input_list), function(comb_name) {
    seed <- sum(utf8ToInt(comb_name))
    ranks <- gsea_input_list[[comb_name]]
    if (grepl(paste(jitter_strings, collapse = "|"), comb_name)) {
        ranks <- ranks + rnorm(n = length(ranks), sd = 0.001)
    }
    set.seed(seed)
    result <- fgsea(
        pathways,
        stats = ranks,
        minSize = 5,
        maxSize = 10000,
        eps = 0
    )
    result$group <- comb_name
    return(result)
})
names(results) <- names(gsea_input_list)
combined_df <- do.call(rbind, results)
# Get a basename from the input
batch_name <- tools::file_path_sans_ext(basename(input_rds))
output_name <- paste0("results/", "fgsea_",batch_name, ".csv")
write.csv(combined_df, output_name)
# Verbose message
message("\nWrite out to: ", output_name)
}

#fgsea_main(input_rds, db_rds)
#saveRDS(results, "results/bulk_fgsea_output.rds")

#combined_df <- do.call(rbind, results)

#out_name <- tools::file_path_sans_ext(basename(input_rds))
#saveRDS(combined_df, file.path("results", paste0(out_name, "_fgsea.rds")))

