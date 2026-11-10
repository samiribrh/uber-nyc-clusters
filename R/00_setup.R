# 00_setup.R
# installs the packages used in the project (run once)

packages <- c(
  "data.table",  # fast reading and data manipulation
  "lubridate",   # dates and times
  "ggplot2",     # plots
  "cluster",     # silhouette()
  "factoextra",  # fviz_nbclust(): elbow, silhouette and gap statistic
  "dbscan",      # dbscan(), kNNdistplot()
  "flexclust",   # kcca() and predict() for assigning new pickups to zones
  "forecast",    # snaive(), ets(), auto.arima(), accuracy()
  "rmarkdown",   # the report
  "knitr"
)

missing <- packages[!packages %in% rownames(installed.packages())]
if (length(missing) > 0) install.packages(missing)

# check that everything loads
invisible(lapply(packages, library, character.only = TRUE))
cat("All packages loaded.\n")
