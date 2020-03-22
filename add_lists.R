# add_lists.R

# read all specified files and provide their best grouping to existing set of groups
# assumption: all files are named using convention [attribute].txt and contain single column with identities and no header
# assumption: a relevant grouping_file.txt and km.RData exist
# input: path to directory with group_file.txt and km.RData, space separated list of files to add to grouping
# note: will NOT update km.RData with new groups, attributes, or identities

# TODO: make sure to handle new identities being added
# TODO: check for wrong file structure
# TODO: allow for person to enter predicted group and give feedback on whether it is best and quality (new script?)

library(dplyr)
library(readr)
library(stringr)
library(cluster)

source("/Users/dfackler/Desktop/workSpace/lol-parsing/helper_functions.R")

# args = c("/Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2/grouping_train",
# "/Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2/grouping_test",
# "/Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2/prepped_test/active.txt",
# "/Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2/prepped_test/agility.txt",
# "/Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2/prepped_test/arctic.txt",
# "/Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2/prepped_test/big.txt",
# "/Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2/prepped_test/bipedal.txt")
##############################################
#### Read args and check input files ####
##############################################
args = commandArgs(trailingOnly=TRUE)
input_dir = args[1]
output_dir = args[2]
files_to_read <- args[3:length(args)]

# initial.options <- commandArgs(trailingOnly = FALSE)
# file.arg.name <- "--file="
# script.name <- sub(file.arg.name, "", initial.options[grep(file.arg.name, initial.options)])
# script.basename <- dirname(script.name)
# other.name <- file.path(script.basename, "other.R")
# print(paste("Sourcing",other.name,"from",script.name))
# source(other.name)

if(length(files_to_read) == 0){
  print("No files to add provided. Exiting.\n")
  quit(status = 1)
}
if(!dir.exists(input_dir)){
  print(paste0("Input directory provided does not exist. Exiting.\nInput directory: ", input_dir, "\n"))
  quit(status = 1)
}
if(!file.exists(paste(input_dir, "grouping_file.txt", sep = "/")) | !file.exists(paste(input_dir, "km.RData", sep = "/"))){
  print("Required files not found in input directory. Exiting\n")
  quit(status = 1)
}
if(!dir.exists(output_dir)){
  #TODO: handle dir creation failure, don't want to enable recursive creation
  dir.create(output_dir) 
}

# load grouping file and km object
grouping_file <- read_delim(paste(input_dir, "grouping_file.txt", sep = "/"), 
                            delim = "\t", col_types = cols(
                              files = col_character(),
                              grouping = col_integer()
                            ))
load(paste(input_dir, "km.RData", sep = "/"))

##############################################
#### Read in files ####
##############################################
# read in new file(s) to list and track new unique identities
lol <- read_in_lol(files_to_read)
new_unique_ids <- lol[[2]]
lol <- lol[[1]]

##############################################
#### Convert to dataframe with binary columns ####
##############################################
# convert to dataframe with binary cols
id_df <- lol_to_table(lol, new_unique_ids, files_to_read)

##############################################
#### Examine quantity and overlap in identities ####
##############################################
prev_ids <- colnames(km$medoids)
unseen_ids <- new_unique_ids[!(new_unique_ids %in% colnames(km$medoids))]
missing_ids <- prev_ids[!(prev_ids %in% new_unique_ids)]
print(paste0("Total number of new files: ", length(files_to_read)))
print(paste0("Total number of existing identities in groupings: ", length(prev_ids)))
print(paste0("Total number of identities in files to group: ", length(new_unique_ids)))
print(paste0("Total number of new identities: ", length(unseen_ids)))

##############################################
#### Add missing dummy cols ####
##############################################
# can this be skipped?
id_df[,missing_ids] <- rep(FALSE, 5)

##############################################
#### Wipe unseen ids ####
##############################################
# is this needed?

##############################################
#### Calculate best existing group for each new list ####
##############################################
k <- max(km$clustering)
# get distance to each cluster
dist_tbl <- apply(id_df, MARGIN = 1, FUN = function(x){get_cluster_distance(km, x)})
# select best cluster by min distance
best_cluster <- apply(dist_tbl, 2, which.min)

grouping_file <- rbind(grouping_file, data.frame(files = files_to_read,
                          grouping = best_cluster,
                          stringsAsFactors = FALSE))

##############################################
#### Estimate "quality" of new grouping ####
##############################################
# distance to new cluster (min distance could still be very large)

# change in withinss (show whether new point is furthest out)

# percentile/ranking towards center

##############################################
#### Provide outputs ####
##############################################
write_delim(grouping_file, paste(output_dir, "grouping_file.txt", sep = "/"), delim = "\t")
print(paste0("Updated grouping file written to: ", paste(output_dir, "grouping_file.txt", sep = "/")))
print("New groups: ")
print(best_cluster)

