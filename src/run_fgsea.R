args <- commandArgs(trailingOnly = TRUE)
dataset_path <- args[1]
pathways_path <- args[2]
output_path <- args[3]

library(fgsea)
# Load input
# Data is always a list with length >= 1
data <- readRDS(dataset_path)
pathways <- readRDS(pathways_path)

print(paste0("Running data: ", dataset_path))

# See https://github.com/alserglab/fgsea/issues/151#issuecomment-2088857387 for fix by adding random noise to each gene

# Define a usable run fgsea
run_fgsea_single <- function(ranks, pathways, seed) {
  # Set a seed before running
  set.seed(seed)
  result <- fgsea(
    pathways = pathways,
    stats = ranks + rnorm(n=length(ranks), sd = 0.001),
    minSize = 5,
    maxSize = 10000,
    eps = 0
  )
  return(result)
}


run_fgsea_lapply <- function(data, pathways) {
  # This is when data is batched
  # Record the names to save for later
  comb_names <- names(data)
  fgsea_result_list <- lapply(comb_names, function(comb_name) {
    seed <- sum(utf8ToInt(comb_name))
    ranks <- data[[comb_name]]
    result <- run_fgsea_single(ranks = ranks, pathways = pathways$gene_pathways, seed = seed)
    # Lastly append the comb name inside the output table
    # Check if result has 0 rows, then skip if true
    #if (nrow(result) == 0) {
    #  message(comb_name, " has 0 rows in fgsea table, skipping")
    #} else {
    #  result$comb_name <- comb_name
    #}
    result$comb_name <- comb_name
    return(result)
  })
  names(fgsea_result_list) <- comb_names
  return(fgsea_result_list)
}


main <- function(data, pathways, output_path) {
  # Now check if data is a list , then use the lapply version (batch them)
  # otherwise just run normal fgsea
  if (length(data) > 1) {
    # Then apply for each comb (method | dataset | view) individually fgsea
    fgsea_result_list <- run_fgsea_lapply(data=data, pathways = pathways)
    # This is the final output to return
    fgsea_res <- do.call(rbind, fgsea_result_list)
  } else {
    print("Not implemented")
    fgsea_res <- NULL
  }

  # Finally save the RDS
  saveRDS(fgsea_res, output_path)

  return(fgsea_res)
}

# And call the main function
main(data = data, pathways = pathways, output_path = output_path)


