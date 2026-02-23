library(fgsea)

input_rds <- commandArgs(trailingOnly=TRUE)[1]

# Apply the extra jitter to stats for specific methods only, to avoid ties in the ranks for those method
jitter_strings <- c("mogonet")

pathways <- readRDS("data/msigdbr_c2reactome-c6_pathways.rds")
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

combined_df <- do.call(rbind, results)

out_name <- tools::file_path_sans_ext(basename(input_rds))
saveRDS(combined_df, file.path("results/fgsea", paste0(out_name, "_fgsea.rds")))

