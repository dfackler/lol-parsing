# group_lists.py

# read all files from a directory
# assumption: all files are named using convention [attribute].txt and contain single column with identities and no header
# input: path to input directory, output dir
# output: grouping file, clustering object

# TODO: provide optional mapping file as input which defines manual groups to create but still generate distance metrics
#       for the scenario where lists might be grouped by common labels (new script?)

from pathlib import Path
import sys
import os
import pandas as pd
import numpy as np
from sklearn.cluster import KMeans
from scipy.spatial.distance import cdist
from joblib import dump, load

# input_dir = "/Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2/prepped_python"
# output_file = "/Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2/grouped_python"
##############################################
#### Read args and check files ####
##############################################
# TODO: source helper script

input_dir = Path(str(sys.argv[1]))
output_dir = Path(str(sys.argv[2]))

if not input_dir.exists():
    print("Input path provided does not exist. Exiting.\n" +
          "Input path: " + input_dir)
    exit(1)
files_to_read = os.listdir(input_dir)
if len(files_to_read) == 0:
    print("Directory is empty. Exiting.")
    exit(1)
if not output_dir.exists():
    output_dir.mkdir()

##############################################
#### Read in files ####
##############################################
# read in files to list and track unique identities


# read files into dictionary
def read_in_lol(files_to_read, input_dir):
    files_to_read = os.listdir(input_dir)
    lol = []
    headers = ["ids"]
    dtypes = {"ids": "str"}
    for file in files_to_read:
        tmp = pd.read_csv(input_dir / file, sep="\t",
                          header=None, names=headers, dtype=dtypes).ids.to_numpy()
        lol.append(tmp)
    unique_ids = list(set([item for sublist in lol for item in sublist]))
    return lol, unique_ids


lol, unique_ids = read_in_lol(files_to_read, input_dir)

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

print("Total number of identities: " + str(id_df.shape[0]))
print("Total number of files: " + str(id_df.shape[1]))

##############################################
#### Set groups ####
##############################################
# check diff k values
inertia = []
# TODO: make min and max cluster options optional parameters
min_k = 5
max_k = 20
K = range(min(1, min_k-1), max_k+3)
for k in K:
    kmeanModel = KMeans(n_clusters=k).fit(id_df)
    kmeanModel.fit(id_df)
    inertia.append(kmeanModel.inertia_)

# https://www.datasciencecentral.com/profiles/blogs/how-to-automatically-determine-the-number-of-clusters-in-your-dat
# find optimal k based on highest strength elbow
# compute first and second degree delta between k and k+1
# consider strength of elbow by difference between d2 and d1 at point after elbow
# select highest strength elbow as best k guess
# TODO: improve this by handling large clusters and making sure cluster groups balance specificity with strength
diff1 = np.diff(inertia, 1)
diff2 = np.diff(diff1, 1)
d2_elbow_inds = np.reshape(np.nonzero(diff2 < 0), -1)
# don't allow max K value as elbow because unable to compute diff
d2_elbow_inds = d2_elbow_inds[d2_elbow_inds < (max_k-min_k)]
strength = []
for i in d2_elbow_inds:
    strength.append(diff2[i+1] - diff1[i+2])
strength = np.asarray(strength)
relative_strength = strength/len(inertia)
# to get from d2_elbow_ind to related k value add min_k+3
best_k_guess = int(d2_elbow_inds[np.argmax(strength)]+min_k+3)

print("Elbow Points Between Min and Max K:")
print(d2_elbow_inds + min_k + 3)
print("Relative Strengths:")
print(relative_strength)
print("Best K Guess: " + str(best_k_guess))

# create dataframe of identities and groups of different values
kmeans = KMeans(n_clusters=best_k_guess, random_state=123).fit(id_df)
file_groups = kmeans.predict(id_df)
grouping_df = pd.DataFrame({"file": id_df.index.values, "group": file_groups})

##############################################
#### Provide outputs ####
##############################################
grouping_df.to_csv(output_dir / "grouping_file.txt", sep='\t',
                   index=None)
print("Grouping file written to: " + str(output_dir / "grouping_file.txt"))
dump(kmeans, output_dir / "km.joblib")
print("Kmeans object written to: " + str(output_dir / "km.joblib"))
print("Best K guess: " + str(best_k_guess))
print("Grouping counts:")
print(grouping_df.groupby('group').count())
