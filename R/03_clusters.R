# 03_clusters.R
# fits k-means with k = 7 on all pickups and describes the clusters

library(data.table)
library(ggplot2)
library(cluster)

# 1. load ----

uber <- readRDS("data/processed/uber_clean.rds")
dim(uber)

# 2. k-means ----

# k = 7 chosen in 02_choose_method.R
# nstart = 25 tries 25 random starts and keeps the best one
set.seed(1)
km <- kmeans(uber[, .(Lon, Lat)], centers = 7, nstart = 25, iter.max = 50)
round(km$centers, 3)

# cluster of each pickup
uber[, cluster := km$cluster]
table(uber$cluster)    # should match km$size

# zone names, read from the cluster centres above (they hold with set.seed(1))
uber[, zone := factor(cluster, levels = 1:7,
                      labels = c("Brooklyn", "Midtown & Upper Manhattan", "JFK",
                                 "Newark & NJ", "Bronx & Upper Manhattan",
                                 "Lower Manhattan", "LaGuardia & Queens"))]
table(uber$zone)

# 3. quality ----

# share of total variance explained by the clusters (0.836)
km$betweenss / km$totss

# average silhouette width on a 10k sample (distances for 1M pickups are too many)
set.seed(1)
sil_sample <- uber[sample(.N, 10000), .(Lon, Lat, cluster)]
sil <- silhouette(sil_sample$cluster, dist(sil_sample[, .(Lon, Lat)]))
mean(sil[, 3])

# 4. cluster map ----

# a random sample of 200k pickups, as in 01_load_explore.R
set.seed(1)
p_clusters <- ggplot(uber[sample(.N, 200000)],
                     aes(x = Lon, y = Lat, colour = zone)) +
  geom_point(size = 0.1, alpha = 0.3) +
  coord_quickmap() +
  labs(colour = "Zone") +
  guides(colour = guide_legend(override.aes = list(size = 3, alpha = 1)))

ggsave("figures/03_kmeans_clusters_map.png", p_clusters, width = 9.5, height = 7)

# 5. save ----

saveRDS(uber, "data/processed/uber_clusters.rds")
