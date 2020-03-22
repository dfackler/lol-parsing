# group_lists.R

# read all files from a directory
# assumption: all files are named using convention [attribute].txt and contain single column with identities and no header
# input: path to input directory, output dir
# output: grouping file, clustering object

library(dplyr)
library(readr)
library(stringr)
library(cluster)

# input_dir = "/Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2/prepped"
# output_file = "/Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2/grouping_map.txt"
##############################################
#### Read args and check files ####
##############################################
args = commandArgs(trailingOnly=FALSE)

# source helper script in same directory
file_name <- "--file="
script_name <- str_replace(args[grep(file_name, args)], file_name, "")
script_basename <- dirname(script_name)
helper_script <- file.path(script_basename, "helper_functions.R")
print(paste("Sourcing",helper_script,"from",script_name))
source(helper_script)

# increment user passed arguments to get past trailing args
# TODO: define explicit name for arguments
input_dir = args[6]
output_dir = args[7]

if(!dir.exists(input_dir)){
  print(paste0("Input directory provided does not exist. Exiting.\nInput directory: ", input_dir, "\n"))
  quit(status = 1)
}
files_to_read = list.files(input_dir, full.names = TRUE)
if(length(files_to_read) == 0){
  print("Directory is empty. Exiting\n")
  quit(status = 1)
}

if(!dir.exists(output_dir)){
  #TODO: handle dir creation failure, don't want to enable recursive creation
  dir.create(output_dir) 
}

##############################################
#### Read in files ####
##############################################
# read in files to list and track unique identities
lol <- read_in_lol(files_to_read)
unique_ids <- lol[[2]]
lol <- lol[[1]]

##############################################
#### Convert to dataframe with binary columns ####
##############################################
# convert to dataframe with binary cols
# TODO: add sampling for when data gets big?
id_df <- lol_to_table(lol, unique_ids, files_to_read)

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
# TODO: consider adding iterations as argument
# TODO: consider running second round that searches between the one k below max and one k above max when data is big and step is large
seq_step <- max(1, floor((nrow(id_df)-4)/100)) 
k_vals <- seq(4, floor(nrow(id_df)/2), seq_step) 
avg_sil <- sapply(k_vals, silhouette_score, id_df)
best_k_guess <- k_vals[which(avg_sil == max(avg_sil))]

# create dataframe of identities and groups of different values
km <- pam(id_df, k = best_k_guess, metric = "euclidean")
clus_info <- data.frame(cluster = 1:best_k_guess, km$clusinfo, stringsAsFactors = FALSE)
clus_info <- clus_info %>% arrange(desc(size))
grouping_file <- data.frame(files = files_to_read,
                          grouping = km$clustering,
                          stringsAsFactors = FALSE)
# TODO: look into identifying large clusters with high withinss and breaking them up
# TODO: try other clustering types to get beyond strict partitioning
#     ex) heirarchical, overlapping

##############################################
#### Provide outputs ####
##############################################
write_delim(grouping_file, paste(output_dir, "grouping_file.txt", sep = "/"), delim = "\t")
print(paste0("Grouping file written to: ", paste(output_dir, "grouping_file.txt", sep = "/")))
save(km, file = paste(output_dir, "km.RData", sep = "/"))
print(paste0("Clustering object saved to: ", paste(output_dir, "km.RData", sep = "/")))
print(paste0("Best K Guess (using sillhouette method): ", best_k_guess))
print("Grouping counts:")
print(table(pull(grouping_file, grouping)))
print("Cluster metrics:")
print(clus_info)


