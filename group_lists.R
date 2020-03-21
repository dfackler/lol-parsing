# group_lists.R

# read all files from a directory
# assumption: all files are named using convention [attribute].txt and contain single column with identities
# input: directory path (optional min_groups) (optional max_groups)
# output: grouping file

library(dplyr)
library(readr)
library(stringr)

# input_dir = "/Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2/prepped"
##############################################
#### Read args and check files ####
##############################################
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

##############################################
#### Read in files ####
##############################################
# read in files to list and track unique identities
lol <- list()
unique_ids <- vector()
for(i in 1:length(files_to_read)){
  fl = read_csv(paste(input_dir, files_to_read[i], sep = "/"), col_names = FALSE) %>% pull(X1)
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
# id_df <- as_tibble(t(as_tibble(lapply(lol, FUN = function(x){unique_ids %in% x}), .name_repair = "universal")), .name_repair = "universal")
rownames(id_df) <- str_replace(files_to_read, ".txt", "")
colnames(id_df) <- unique_ids

##############################################
#### Set groups ####
##############################################
# find good k value
set.seed(123)
# TODO: choose sequence based on number of files or from argument(s)?
# k_vals <- c(seq(5, 10, 2), seq(11, 31, 5))
k_vals <- 1:50
wss <- vector()
for (i in k_vals) {
  wss[i] <- sum(kmeans(id_df, centers=i, nstart = 5)$withinss)
}
plot(1:length(wss), wss, type="b", xlab="Number of Clusters",
     ylab="Within groups sum of squares")

# TODO: base on elbow calculation or something else
best_k_vals <- c(4, 7, 10, 15)
best_k_guess <- 10

# create dataframe of identities and groups of different values

##############################################
#### Provide outputs ####
##############################################
# print number of groupings predicted
# print groupings for best guess (optional with argument?)

# save file of grouping mappings
# save file of best grouping guess mapping
# save kmeans plot (optional with argument?)

