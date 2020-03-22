# helper_functions.R

# files to read must be vector of full file paths
read_in_lol <- function(files_to_read){
  require(readr)
  lol <- list()
  unique_ids <- vector()
  for(i in 1:length(files_to_read)){
    if(!file.exists(files_to_read[i])){
      print(paste0("File to add not found. Exiting\nFile to add: ", files_to_read[i]))
      quit(status = 1)
    }
    fl = read_csv(files_to_read[i], 
                  col_names = FALSE, col_types = cols(X1 = col_character())) %>% pull(X1)
    unique_ids <- unique(c(unique_ids, fl))
    lol[[i]] <- fl
  }
  return(list(lol, unique_ids))
}

# lol must be list of identities in files (output from read_in_lol)
# TODO: add sampling for when data gets big?
# TODO: keep as sparse matrix for when data gets big?
lol_to_table <- function(lol, unique_ids, files_to_read){
  require(stringr)
  id_df <- data.frame(t(data.frame(lapply(lol, FUN = function(x){unique_ids %in% x}))))
  # set rows to attributes
  rownames(id_df) <- str_replace(unlist(lapply(files_to_read, FUN = function(x){tail(unlist(str_split(x, "/")), n = 1)})), ".txt", "")
  # set columns to ids
  colnames(id_df) <- unique_ids
  return(id_df)
}

# calculate euclidean distance
euclidean_func <- function(x, y){
  sqrt(sum((x-y)^2))
}

# choose best cluster based on min distance
get_cluster_distance <- function(km, new_data){
  return(sapply(1:k, FUN = function(i) euclidean_func(km$medoids[i,], new_data)))
}
