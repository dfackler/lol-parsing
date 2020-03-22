# group_lists.R

# read all files from a directory
# assumption: all files are named using convention [attribute].txt and contain single column with identities and no header
# input: path to input directory, output file (full path)
# output: grouping file

library(dplyr)
library(readr)
library(stringr)
library(cluster)

# input_dir = "/Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2/prepped"
# output_file = "/Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2/grouping_map.txt"
##############################################
#### Read args and check files ####
##############################################
args = commandArgs(trailingOnly=TRUE)
input_dir = args[1]
output_file = args[2]

if(!dir.exists(input_dir)){
  print(paste0("Input path provided does not exist. Exiting.\nInput path: ", input_dir, "\n"))
  quit(status = 1)
}
files_to_read = list.files(input_dir)
if(length(files_to_read) == 0){
  print("Directory is empty. Exiting\n")
  quit(status = 1)
}

##############################################
#### Read in files ####
##############################################
# read in files to list and track unique identities
lol <- list()
unique_ids <- vector()
for(i in 1:length(files_to_read)){
  fl = read_csv(paste(input_dir, files_to_read[i], sep = "/"), 
                col_names = FALSE, col_types = cols(X1 = col_character())) %>% pull(X1)
  unique_ids <- unique(c(unique_ids, fl))
  lol[[i]] <- fl
}

##############################################
#### Convert to dataframe with binary columns ####
##############################################
# convert to dataframe with binary cols
# TODO: add sampling for when data gets big?
# TODO: keep as sparse matrix for when data gets big?
id_df <- data.frame(t(data.frame(lapply(lol, FUN = function(x){unique_ids %in% x}))))
rownames(id_df) <- str_replace(files_to_read, ".txt", "")
colnames(id_df) <- unique_ids

print(paste0("Total number of identities: ", length(unique_ids)))
print(paste0("Total number of files: ", length(files_to_read)))

##############################################
#### Set groups ####
##############################################
# find good k value
set.seed(123)
# sillhouette method: https://medium.com/codesmart/r-series-k-means-clustering-silhouette-794774b46586
silhouette_score <- function(k, df){
  km <- pam(df, k = k) # more robust kmeans
  ss <- silhouette(km$clustering, dist(df))
  return(mean(ss[, 3]))
}
# don't allow more than 100 iterations but try to get best k guess between 4 and num_obs/2
seq_step <- max(2, floor((nrow(id_df)-4)/100)) 
k_vals <- seq(4, floor(nrow(id_df)/2), seq_step) 
avg_sil <- sapply(k_vals, silhouette_score, id_df)
# plot(k_vals, type='b', avg_sil, xlab='Number of clusters', ylab='Average Silhouette Scores', frame=FALSE)
best_k_guess <- k_vals[which(avg_sil == max(avg_sil))]

# create dataframe of identities and groups of different values
km <- pam(id_df, k = best_k_guess)
clus_info <- data.frame(cluster = 1:best_k_guess, km$clusinfo, stringsAsFactors = FALSE)
clus_info <- clus_info %>% arrange(desc(size))
grouping_df <- data.frame(files = files_to_read,
                          grouping = km$clustering,
                          stringsAsFactors = FALSE)

##############################################
#### Provide outputs ####
##############################################
# print number of groupings predicted
# print groupings for best guess (optional with argument?)

# save file of grouping mappings
# save file of best grouping guess mapping
# save kmeans plot (optional with argument?)
write_csv(grouping_df, output_file)
print(paste0("Grouping file written to: ", output_file))
print(paste0("Best K Guess (using sillhouette method): ", best_k_guess))
print("Grouping counts:")
print(table(pull(grouping_df, grouping)))
print("Cluster metrics:")
print(clus_info)


