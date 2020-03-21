# group_lists.R

# read all files from a directory
# assumption: all files are named using convention [attribute].txt and contain single column with identities
# input: directory path (optional min_groups) (optional max_groups)
# output: grouping file

library(dplyr)
library(readr)
library(stringr)

# input_dir = "/Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2/prepped"
args = commandArgs(trailingOnly=TRUE)
input_dir = args[1]

if(!dir.exists(input_dir)){
  print(paste0("Input path provided does not exist. Exiting.\nInput path: ", input_dir, "\n"))
  quit(status = 1)
}
files_to_read = list.files(input_dir)
if(length(files_to_read) == 0){
  print("Directory is empty. Exiting\n")
  quit(status = 1)
}

# read in files to list and track unique identities
lol <- list()
unique_ids <- vector()
for(i in 1:length(files_to_read)){
  fl = read_csv(paste(input_dir, files_to_read[i], sep = "/"), col_names = FALSE) %>% pull(X1)
  unique_ids <- unique(c(unique_ids, fl))
  lol[[i]] <- fl
}

# convert to dataframe with binary cols
# TODO: add sampling for when data gets big?
# TODO: keep as sparse matrix for when data gets big?
id_df <- data.frame(t(data.frame(lapply(lol, FUN = function(x){unique_ids %in% x}))))
rownames(id_df) <- str_replace(files_to_read, ".txt", "")
colnames(id_df) <- unique_ids

