# prep training data for lol-parsing
# List of data sets at https://www.ecse.rpi.edu/~cvrl/database/AttributeDataset.htm
# Example chosen https://cvml.ist.ac.at/AwA2/

#   zip file containing classes (animals) and predicates (attributes):
# classes.txt
# predicates.txt
# predicate-matrix.png
# predicate-matrix-continuous.txt
# predicate-matrix-binary.txt
# README-attributes.txt

# from README: 
# ------------------------------------------------------------------
#   Animals with Attributes Dataset, v1.0, May 13th 2009
# ------------------------------------------------------------------
#   
#   Animal/attribute matrix for 50 animal categories and 85 attributes.
# Animals and attributes are in the same order as in the text files
# 'classes.txt' and 'predictes.txt'.

# Output a set of files where filename = attribute and it contains a list of animals that have that attribute

##############################################
### Install and load packages ###
##############################################
list_of_packages <- c("dplyr", "readr", "stringr")

new_packages <- list_of_packages[!(list_of_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) install.packages(new_packages)

lapply(list_of_packages, require, character.only = TRUE)

##############################################
### Set Paths ###
##############################################
# TODO: set path as argument
input_dir <- "/Users/dfackler/Desktop/Animals_with_Attributes2"
output_dir <- "/Users/dfackler/Desktop/Animals_with_Attributes2/prepped"

if(!dir.exists(output_dir)){
  dir.create(output_dir)
}

##############################################
### Read Files ###
##############################################
classes <- read_delim(paste(input_dir, "classes.txt", sep = "/"), 
                      delim = "\t", col_names = FALSE)
classes <- classes %>% rename(row_index = X1, class = X2)

attributes <- read_delim(paste(input_dir, "predicates.txt", sep = "/"), 
                         delim = "\t", col_names = FALSE)
attributes <- attributes %>% rename(col_index = X1, attribute = X2)

binary_matrix <- read_delim(paste(input_dir, "predicate-matrix-binary.txt", sep = "/"), 
                            delim = " ", col_names = FALSE)

##############################################
### Combine and clean ###
##############################################
colnames(binary_matrix) <- attributes %>% pull(attribute)
binary_matrix <- binary_matrix %>% mutate(class = pull(classes, class)) %>% 
  select(class, everything())

# replace '+' in names with '_'
binary_matrix <- binary_matrix %>% mutate(class = str_replace(class, "\\+", "_"))

##############################################
### Write out attribute files ###
##############################################
attributes_to_write <- binary_matrix %>% select(-class) %>% colnames()
files_to_write <- paste0(attributes_to_write, ".txt")

for(i in 1:length(files_to_write)){
  file_to_write <- binary_matrix %>% filter(get(attributes_to_write[i]) == 1) %>%
    pull(class)
  file_to_write <- data.frame(file_to_write)
  colnames(file_to_write) <- attributes_to_write[i]
  write_delim(file_to_write, paste(output_dir, files_to_write[i], sep = "/"), delim = "\t")
}
