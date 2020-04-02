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

# python3 prep_training_data.py /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2/ /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2/prepped_python

from pathlib import Path
import sys
import os
import pandas as pd
import numpy as np

##############################################
#### Set Paths ####
##############################################
input_dir = Path(str(sys.argv[1]))
output_dir = Path(str(sys.argv[2]))

if not os.path.isdir(input_dir):
    print("Input path provided does not exist. Exiting.\n" +
          "Input path: " + input_dir)
    exit(1)
files_to_read = os.listdir(input_dir)
if len(files_to_read) == 0:
    print("Directory is empty. Exiting.")
    exit(1)

if not os.path.isdir(output_dir):
    os.mkdir(output_dir)

##############################################
#### Read Files ####
##############################################
headers = ["row_index", "classes"]
dtypes = {"row_index": "int", "classes": "str"}
classes = pd.read_csv(input_dir / "classes.txt", sep="\t",
                      header=None, names=headers, dtype=dtypes)

headers = ["col_index", "attributes"]
dtypes = {"col_index": "int", "attributes": "str"}
attributes = pd.read_csv(input_dir / "predicates.txt", sep="\t",
                         header=None, names=headers, dtype=dtypes)

binary_matrix = pd.read_csv(input_dir / "predicate-matrix-binary.txt", sep=" ",
                            header=None, names=attributes.attributes)
##############################################
#### Combine and clean ####
##############################################
binary_matrix.insert(0, "classes", classes.classes.str.replace("+", "_"))

##############################################
#### Write out attribute files ####
##############################################
for i in range(1, len(binary_matrix.columns)):
    nzrows = binary_matrix.iloc[:, i].to_numpy().nonzero()
    binary_matrix.classes.iloc[nzrows].to_csv(output_dir / (binary_matrix.columns[i] + ".txt"),
                                              header=False, index=False)
print("Output Directory: " + str(output_dir))
print("Files Created: " + str(len(binary_matrix.columns)-1))
