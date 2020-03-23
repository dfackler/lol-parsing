# lol-parsing
Scripts for reading and grouping lists of lists. Also provides ability to classify one or more new lists among existing groups and provide feeback on estimated quality of fit within the group.

## Scripts
`prep_training_data.R` - Script to organize Animal test data. Takes an input directory with unzipped contents of https://cvml.ist.ac.at/AwA2/AwA2-base.zip (this link will download a 32KB zip file which expands to 80KB). See https://cvml.ist.ac.at/AwA2/ for a description of the dataset. This data set has 85 attributes and 50 identities (animals).

*notes: I am working on finding a larger data set. https://www.ecse.rpi.edu/~cvrl/database/AttributeDataset.htm has a list of attribute data sets but many of the data sets with a larger number of identities contain only a handful of attributes. 85 attributes for 50 identities is not ideal.*

example call) `Rscript prep_training_data.R /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/prepped` 

Input Directory:
```
(lolparse) penny:Animals_with_Attributes2_test dfackler$ ls -ltr
total 160
-rw-r--r--@ 1 dfackler  staff    755 Oct  2  2008 classes.txt
-rw-r--r--@ 1 dfackler  staff   1205 Oct  2  2008 predicates.txt
-rw-r--r--@ 1 dfackler  staff  21379 Oct  2  2008 predicate-matrix.png
-rw-r--r--@ 1 dfackler  staff  29800 Dec 19  2008 predicate-matrix-continuous.txt
-rw-r--r--@ 1 dfackler  staff   8500 Dec 19  2008 predicate-matrix-binary.txt
-rw-r--r--@ 1 dfackler  staff   1143 May 13  2009 README-attributes.txt
```

Output Directory:
```
(lolparse) penny:prepped dfackler$ ls -ltr | head -n 5
total 680
-rw-r--r--  1 dfackler  staff  250 Mar 23 10:47 black.txt
-rw-r--r--  1 dfackler  staff  169 Mar 23 10:47 white.txt
-rw-r--r--  1 dfackler  staff   46 Mar 23 10:47 blue.txt
-rw-r--r--  1 dfackler  staff  239 Mar 23 10:47 brown.txt
(lolparse) penny:prepped dfackler$ head -n 5 black.txt
grizzly_bear
killer_whale
dalmatian
horse
german_shepherd
```

`group_lists.R` - Script to group attribute lists. **Will pull all files from input directory. Assumes directory contains only files that are lists of identities.** Initial implementation uses the [sillhoutte method and k-medoids](https://en.wikipedia.org/wiki/K-medoids) to automatically identify the best guess for number of groups and clusters them with strict partitioning (each file is in one and only group). 

*notes: It currently does not handle passing in a manual mapping file of groups. Nor does it give recommendations for possible alternative groupings beyond the optimal k-medoids guess. These would both be helpful to add in the future.*

example call) `Rscript group_lists.R /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/prepped /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/grouping`

Output:
```
[1] "Total number of identities: 50"
[1] "Total number of files: 85"
[1] "Grouping file written to: /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/grouping/grouping_file.txt"
[1] "Clustering object saved to: /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/grouping/km.RData"
[1] "Best K Guess (using sillhouette method): 18"
[1] "Grouping counts:"

 1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 
 6  9  5 24  1  3  7  4  2  7  5  3  1  3  2  1  1  1 
[1] "Cluster metrics:"
   cluster size max_diss  av_diss diameter separation
1        4   24 3.605551 2.255276 4.898979   1.732051
2        2    9 3.000000 1.604700 4.000000   1.732051
3        7    7 3.741657 2.214241 4.123106   3.162278
4       10    7 3.741657 2.701399 4.582576   2.645751
5        1    6 3.741657 2.627517 4.472136   3.162278
6        3    5 3.605551 2.524469 4.472136   3.464102
7       11    5 3.162278 2.037166 3.605551   2.828427
8        8    4 3.162278 2.202007 3.872983   3.000000
9        6    3 3.162278 1.936010 3.316625   3.872983
10      12    3 3.162278 2.108185 4.000000   3.162278
11      14    3 3.464102 2.097510 3.741657   3.000000
12       9    2 3.316625 1.658312 3.316625   3.605551
13      15    2 3.000000 1.500000 3.000000   3.162278
14       5    1 0.000000 0.000000 0.000000   4.000000
15      13    1 0.000000 0.000000 0.000000   4.123106
16      16    1 0.000000 0.000000 0.000000   3.605551
17      17    1 0.000000 0.000000 0.000000   4.242641
18      18    1 0.000000 0.000000 0.000000   4.000000
```

Output Grouping File:
```
(lolparse) penny:grouping dfackler$ head -n 5 grouping_file.txt 
files	grouping
/Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/prepped/active.txt	1
/Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/prepped/agility.txt	1
/Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/prepped/arctic.txt	2
/Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/prepped/big.txt	3
```

`add_lists.R` - Script to classify one or more lists to an existing set of groups. Takes an input directory with a grouping file and km object and writes out a new grouping file to an output directory with the additional lists appended. Trailing arguments are file names to be added. Will output a coarse estimate of how well the lists fit into their respective groups. This is based on their distance to the medoid compared to the mean, min, and max distances within that medoid.

*notes: Km object will NOT be uptated to consider new lists and new lists will NOT be evaluated as a potential new medoid. Regroup full set of lists using group_lists.R to updated Km object. Have not yet allowed for manual selection and evaluation of list group, but this would be helpful to add in the future. Opted for specific file names rather than directory approach but could be good to swap to reading full directory depending on use case.*

*example call note: reran group_lists.R for 80 of the 85 files. The files used in this call were the 5 not included in the original grouping.*
example call) `Rscript add_lists.R /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/grouping_80 /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/grouping_5 /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/prepped_5/flippers.txt /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/prepped_5/big.txt /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/prepped_5/solitary.txt /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/prepped_5/meatteeth.txt /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/prepped_5/forest.txt`

Output: 
```
[1] "Total number of new files: 5"
[1] "Total number of existing identities in groupings: 50"
[1] "Total number of identities in files to group: 49"
[1] "Total number of new identities: 0"
[1] "Updated grouping file written to: /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/grouping_5/grouping_file.txt"
[1] "New groups: "
                                                                                            files
1  /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/prepped_5/flippers.txt
2       /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/prepped_5/big.txt
3  /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/prepped_5/solitary.txt
4 /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/prepped_5/meatteeth.txt
5    /Users/dfackler/Desktop/lol_training_data/Animals_with_Attributes2_test/prepped_5/forest.txt
  grouping dist_to_best avg_dist_to_meds dist_to_worst mean_dist_in_group
1        3     2.828427         4.780598      6.164414           2.196569
2        1     2.449490         4.858997      6.403124           2.627517
3        6     4.472136         4.984323      5.656854           1.936010
4       12     4.358899         4.981935      5.567764           0.000000
5        6     4.000000         4.975492      5.916080           1.936010
  max_dist_in_group fit_quality
1          3.464102        okay
2          3.741657        good
3          3.162278         bad
4          0.000000   undefined
5          3.162278         bad
```

`helper_functions.R` - Script with functions to load and organize data in addition to calculate distance measurements. Loaded at the start of `group_lists.R` and `add_lists.R` under the assumption that `helper_scripts.R` will be in the same directory as the script that is called directly.