# explore stuff while in table format

num_matrix <- binary_matrix %>% select(-class)
num_matrixt <- as.data.frame(t(num_matrix))
colnames(num_matrixt) <- binary_matrix %>% pull(class)
##############################################
### Correlation ###
##############################################
cor_matrix <- cor(num_matrix)


##############################################
### Clustering ###
##############################################
# Determine number of clusters
set.seed(123)
wss <- (nrow(num_matrixt)-1)*sum(apply(num_matrixt,2,var))
for (i in 2:30) {
  wss[i] <- sum(kmeans(num_matrixt, centers=i)$withinss)
}
plot(1:30, wss, type="b", xlab="Number of Clusters",
     ylab="Within groups sum of squares")

k_vals <- c(6, 10, 15)
k_groups <- list()
k_objs <- list()
for (i in 1:length(k_vals)){
  k_objs[[i]] <- kmeans(num_matrixt, centers=k_vals[i])
  k_groups[[i]] <- k_objs[[i]]$cluster
}
kmeans_groups <- data.frame(attributes = rownames(num_matrixt),
                            k6 = k_groups[[2]],
                            k10 = k_groups[[3]],
                            k15 = k_groups[[4]],
                            stringsAsFactors = FALSE)
k1$withinss

##############################################
### Read and prep matlab files ###
##############################################
install.packages("rmatio")
library(rmatio)
osr <- read.mat("/Users/dfackler/Desktop/lol_training_data/relative_attributes/osr/data.mat")

class_names <- unlist(osr$class_names)
attribute_names <- unlist(osr$attribute_names)
class_labels <- osr$class_labels
attribute_labels <- apply(osr$relative_att_predictions, 1, which.max)

class_attr <- paste(class_labels, attribute_labels, sep = "_")


pubfig_file <- read.mat("/Users/dfackler/Desktop/lol_training_data/relative_attributes/pubfig/data.mat")

shoes <- read.mat("/Users/dfackler/Desktop/lol_training_data/whittle-search-shoes-dataset-cvpr2012/shoes_attributes.mat")
class_names <- unlist(shoes$class_names)
attribute_names <- unlist(shoes$attribute_names)
class_labels <- shoes$class_labels
attribute_labels <- apply(shoes$relative_att_predictions, 1, which.max)