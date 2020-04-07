# add_lists.py

# read all specified files and provide their best grouping to existing set of groups
# assumption: all files are named using convention [attribute].txt and contain single column with identities and no header
# assumption: a relevant grouping_file.txt and km.RData exist
# input: path to directory with group_file.txt and km.RData, space separated list of files to add to grouping
# note: will NOT update km.RData with new groups, attributes, or identities

# TODO: check for wrong file structure
# TODO: allow for person to enter predicted group and give feedback on whether it is best and quality (optional named arg?)
# TODO: update km with new lists (maybe?)

from pathlib import Path
import sys
import os
import pandas as pd
import numpy as np
from sklearn.cluster import KMeans
from scipy.spatial.distance import cdist
from joblib import load

##############################################
#### Read args and check input files ####
##############################################
# TODO: handle args with argparse
input_dir = Path(str(sys.argv[1]))
output_dir = Path(str(sys.argv[2]))
files_to_read = sys.argv[3:]

print("Files to read: " + str(files_to_read))

# lambda to set elements in list to Path objects


#def to_path(x): return Path(x)


#files_to_read = list(map(to_path, files_to_read))

if len(files_to_read) == 0:
    print("No files to read.")
    exit(1)
if not input_dir.exists:
    print("Input directory does not exist.")
    exit(1)
for fl in files_to_read:
    if not Path(fl).exists:
        print(fl + " does not exist.")
        exit(1)
if not (input_dir / "grouping_file.txt").exists or not (input_dir / "km.joblib").exists or not (input_dir / "unique_ids.txt").exists:
    print("Required files not found in input directory.")
    exit(1)
if not output_dir.exists:
    output_dir.mkdir()

##############################################
#### Load input files ####
##############################################
grouping_df = pd.read_csv(input_dir / "grouping_file.txt", sep="\t")
with open(input_dir / "unique_ids.txt") as f:
    prev_ids = f.readlines()
prev_ids = [item.rstrip() for item in prev_ids]
kmeans = load(input_dir / "km.joblib")

print(grouping_df.head(5))

##############################################
#### Check to see if files have already been grouped in grouping_file.txt ####
##############################################

##############################################
#### Read in files ####
##############################################
# read files into list


def read_in_lol(files_to_read):
    lol = []
    headers = ["ids"]
    dtypes = {"ids": "str"}
    for fl in files_to_read:
        tmp = pd.read_csv(fl, sep="\t",
                          header=None, names=headers, dtype=dtypes).ids.to_numpy()
        lol.append(tmp)
    unique_ids = list(set([item for sublist in lol for item in sublist]))
    return lol, unique_ids


lol, unique_ids = read_in_lol(files_to_read)
##############################################
#### Convert to dataframe with binary columns ####
##############################################
# TODO: add sampling for when data gets big?
# TODO: move to sparse matrix for when data gets big?


def lol_to_table(lol, unique_ids, files_to_read):
    # get boolean column for each entry in lol for which indices of unique_ids match to it
    def bool_cols(x): return np.isin(unique_ids, x)
    bools = [bool_cols(item) for item in lol]
    bool_df = pd.DataFrame(bools, columns=unique_ids)
    # set index to be file names
    bool_df["files"] = files_to_read
    bool_df.set_index("files", inplace=True)
    return bool_df


id_df = lol_to_table(lol, unique_ids, files_to_read)
print(id_df)

##############################################
#### Examine quantity and overlap in identities ####
##############################################
unseen_ids = list(set(unique_ids).difference(set(prev_ids)))
missing_ids = list(set(prev_ids).difference(set(unique_ids)))
print("Total number of new files: " + str(len(files_to_read)))
print("Total number of existing identities in groupings: " + str(len(prev_ids)))
print("Total number of identities in files in group: " + str(len(unique_ids)))
print("Total number of new identities: " + str(len(unseen_ids)))
print("Total number of existing identities not found in new files: " +
      str(len(missing_ids)))

##############################################
#### Add missing dummy cols ####
##############################################
missing_bools = pd.DataFrame([[False for i in range(len(missing_ids))] for i in range(id_df.shape[0])],
                             columns=missing_ids, index=files_to_read)
id_df = pd.concat([id_df, missing_bools], axis=1)

##############################################
#### Wipe unseen ids ####
##############################################
if len(unseen_ids) > 0:
    id_df.drop(unseen_ids, axis=1, inplace=True)

##############################################
#### Calculate best existing group for each new list ####
##############################################
new_groups = kmeans.predict(id_df)
dist_to_centers = cdist(id_df, kmeans.cluster_centers_)

grouping_df.append(pd.DataFrame(
    [files_to_read, new_groups]).T, inplace=True)


'''
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


'''
