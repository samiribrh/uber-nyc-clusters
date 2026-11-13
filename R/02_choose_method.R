# 02_choose_method.R
# chooses the clustering algorithm and the number of clusters for pickup locations

library(data.table)
library(ggplot2)
library(factoextra)
library(dbscan)

# 1. load ----

uber <- readRDS("data/processed/uber_clean.rds")
dim(uber)

# 2. sample ----

# DBSCAN, the silhouette and the gap statistic need distances between pairs of
# points, which is too much for 1M pickups, so we use a random sample of 10k
# no scaling: Lat and Lon are both in degrees
set.seed(1)
uber_sample <- uber[sample(.N, 10000), .(Lon, Lat)]

# 3. DBSCAN ----

# density-based alternative to k-means: dense areas become clusters, isolated
# pickups become noise (cluster 0)
# minPts = 20; eps at the knee of the distances to the 20th nearest neighbour
# (their 95th percentile, about 1 km)
eps <- quantile(kNNdist(uber_sample, k = 20), 0.95)

png("figures/02_dbscan_knn_distance.png", width = 7, height = 5, units = "in", res = 150)
kNNdistplot(uber_sample, k = 20)
abline(h = eps, col = "red")
dev.off()

db <- dbscan(uber_sample, eps = eps, minPts = 20)
db

p_dbscan <- ggplot(uber_sample, aes(x = Lon, y = Lat, colour = factor(db$cluster))) +
  geom_point(size = 0.1, alpha = 0.3) +
  coord_quickmap() +
  labs(colour = "DBSCAN cluster") +
  guides(colour = guide_legend(override.aes = list(size = 3, alpha = 1)))

ggsave("figures/02_dbscan_map.png", p_dbscan, width = 8.5, height = 7)

# sensitivity: other minPts, each with eps chosen the same way
db_check <- list()

for (m in c(10, 20, 50)) {
  e <- quantile(kNNdist(uber_sample, k = m), 0.95)
  d <- dbscan(uber_sample, eps = e, minPts = m)
  sizes <- table(d$cluster[d$cluster > 0])

  db_check[[as.character(m)]] <- data.table(
    minPts = m,
    eps = round(e, 4),
    clusters = length(sizes),
    noise_share = round(mean(d$cluster == 0), 3),
    largest_share = round(max(sizes) / nrow(uber_sample), 3)
  )
}

db_check <- rbindlist(db_check)
db_check

# 4. k-means: elbow ----

p_elbow <- fviz_nbclust(uber_sample, kmeans, method = "wss", k.max = 10)
ggsave("figures/02_kmeans_elbow_wss.png", p_elbow, width = 7, height = 7)

# 5. k-means: silhouette ----

p_silhouette <- fviz_nbclust(uber_sample, kmeans, method = "silhouette", k.max = 10)
ggsave("figures/02_kmeans_silhouette.png", p_silhouette, width = 7, height = 7)

# 6. k-means: gap statistic ----

# slow: k-means is also run on 100 random reference datasets for every k
# iter.max = 50 gives k-means enough iterations to converge on the random data
p_gap <- fviz_nbclust(uber_sample, kmeans, method = "gap_stat", k.max = 10,
                      iter.max = 50)
ggsave("figures/02_kmeans_gap.png", p_gap, width = 7, height = 7)

# 7. decision ----

# algorithm: k-means
# - DBSCAN puts 89-94% of pickups into one cluster for every setting tried, so
#   it cannot split the city into zones
# - k-means assigns every pickup to one of k zones
# number of clusters: k = 7
# - elbow: no clear bend, flattens only after about 7
# - silhouette: highest at k = 2 (only splits the core from the periphery),
#   best non-trivial value at k = 7
# - gap: picks k = 1, its uniform reference does not suit one dense core with
#   small far-away hotspots
