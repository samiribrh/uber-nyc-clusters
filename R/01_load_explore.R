# 01_load_explore.R
# loads the raw pickups, adds time variables and looks at daily demand

library(data.table)
library(lubridate)
library(ggplot2)

# 1. load ----

uber <- fread("data/raw/uber-data.csv")
str(uber)

# 2. time variables ----

# Date/Time is text written month/day/year, e.g. "9/1/2014 0:01:00"
uber[, datetime := mdy_hms(`Date/Time`)]
uber[, `Date/Time` := NULL]    # the text version is no longer needed
uber[, `:=`(
  date    = as_date(datetime),
  hour    = lubridate::hour(datetime),
  weekday = lubridate::wday(datetime, label = TRUE, week_start = 1)  # Mon first
)]

stopifnot(
  !anyNA(uber$datetime),
  uniqueN(uber$date) == 30,
  all(uber$hour %in% 0:23)
)

# 3. daily demand ----

daily <- uber[, .N, by = .(date, weekday)]
daily[order(N)]                          # 1 Sep (Labor Day) is the quietest
daily[, .(mean_pickups = mean(N)), by = weekday][order(weekday)]

# 4. location outliers ----

summary(uber[, .(Lat, Lon)])

# keep pickups inside a New York box (about 0.5% fall outside)
uber[, in_nyc := between(Lat, 40.5, 41.0) & between(Lon, -74.3, -73.65)]
sum(uber$in_nyc)

uber <- uber[in_nyc == TRUE]
uber[, in_nyc := NULL]     # helper column no longer needed
nrow(uber)

# 5. map ----

# a random sample of 200k pickups draws much faster and looks the same
set.seed(1)
p_map <- ggplot(uber[sample(.N, 200000)], aes(x = Lon, y = Lat)) +
  geom_point(size = 0.1, alpha = 0.05) +
  coord_quickmap()

ggsave("figures/01_pickups_map.png", p_map, width = 7, height = 7)

# 6. save ----

saveRDS(uber, "data/processed/uber_clean.rds")
