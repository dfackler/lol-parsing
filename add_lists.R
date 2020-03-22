# add_lists.R

# read all specified files and provide their best grouping to existing set of groups
# assumption: all files are named using convention [attribute].txt and contain single column with identities and no header
# assumption: a relevant grouping_file.txt and km.RData exist
# input: path to directory with group_file.txt and km.RData, space separated list of files to add to grouping
# note: will NOT update km.RData with new groups, attributes, or identities

# TODO: check for wrong file structure
# TODO: allow for person to enter predicted group and give feedback on whether it is best and quality (optional named arg?)
# TODO: update km with new lists (not sure if want to do this)

library(dplyr)
library(readr)
library(stringr)
library(cluster)

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
files_to_read <- args[8:length(args)]

# initial.options <- commandArgs(trailingOnly = FALSE)


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
#### Check to see if files have already been grouped in grouping_file.txt ####
##############################################
if(sum(files_to_read %in% pull(grouping_file, files)) > 0){
  print("Some files set to be added already exist in grouping file. Exiting.")
  print("Already grouped files:")
  print(files_to_read[files_to_read %in% pull(grouping_file, files)])
  quit(status = 1)
}

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
id_df[,missing_ids] <- rep(FALSE, nrow(id_df))

##############################################
#### Wipe unseen ids ####
##############################################
# is this the best way? should a list with unseen ids be punished in distance metric?
id_df <- id_df %>% select(-one_of(unseen_ids))

##############################################
#### Calculate best existing group for each new list ####
##############################################
k <- max(km$clustering)
# get distance to each cluster
dist_tbl <- apply(id_df, MARGIN = 1, FUN = function(x){get_cluster_distance(km, x)})
# select best cluster by min distance
best_cluster <- apply(dist_tbl, 2, which.min)

new_group_df <- data.frame(files = files_to_read,
                           grouping = best_cluster,
                           stringsAsFactors = FALSE)

grouping_file <- rbind(grouping_file, new_group_df)

##############################################
#### Estimate quality of new grouping ####
##############################################
# note: NOT estimating quality of the group, just how well new list fits into group

# gather medoid distance metrics (note: medoids NOT updated to consider new points)
dist_to_best <- apply(dist_tbl, 2, min)
avg_dist_to_meds <- apply(dist_tbl, 2, mean)
dist_to_worst <- apply(dist_tbl, 2, max)
mean_dist_in_group <- sapply(best_cluster, FUN = function(x){km$clusinfo[x,3]})
max_dist_in_group <- sapply(best_cluster, FUN = function(x){km$clusinfo[x,2]})

new_group_df <- new_group_df %>% mutate(dist_to_best = dist_to_best,
                                        avg_dist_to_meds = avg_dist_to_meds,
                                        dist_to_worst = dist_to_worst,
                                        mean_dist_in_group = mean_dist_in_group,
                                        max_dist_in_group = max_dist_in_group
                                        )

# classify new list quality-in-group based on comparisons to avg and max dist
# equal to 0 (perfect), less than avg list in group (good fit), more than average but less than max (okay fit), 
# more than max (bad fit), or if mean distance equal to 0 due to single point cluster (undefined)
# TODO: make this more granular - score between 0 and 1?
#       could require a lot more processing time and memory if compare to individual points instead of group aggregate metrics
new_group_df <- new_group_df %>% mutate(
  fit_quality = case_when(
    dist_to_best == 0 ~ "perfect",
    mean_dist_in_group == 0 ~ "undefined",
    dist_to_best > max_dist_in_group ~ "bad",
    dist_to_best > mean_dist_in_group ~ "okay",
    dist_to_best < mean_dist_in_group ~ "good"
  )
)

##############################################
#### Provide outputs ####
##############################################
write_delim(grouping_file, paste(output_dir, "grouping_file.txt", sep = "/"), delim = "\t")
print(paste0("Updated grouping file written to: ", paste(output_dir, "grouping_file.txt", sep = "/")))
print("New groups: ")
print(new_group_df)

