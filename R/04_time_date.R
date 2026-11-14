# 04_time_date.R
# analyses pickups in each zone by hour of day, weekday and date

library(data.table)
library(ggplot2)

# 1. load ----

uber <- readRDS("data/processed/uber_clusters.rds")

# 2. by hour ----

by_hour <- uber[, .N, by = .(zone, hour)]

# share of each zone's pickups in each hour, so that big and small zones
# can be compared on the same scale
by_hour[, share := N / sum(N), by = zone]

p_hour <- ggplot(by_hour, aes(x = hour, y = share, colour = zone)) +
  geom_line() +
  facet_wrap(~ zone) +
  theme(legend.position = "none")

ggsave("figures/04_zone_hourly_share.png", p_hour, width = 10, height = 7)

# 3. by weekday ----

# average pickups per day: September 2014 has five Mondays and Tuesdays but
# four of every other weekday, so plain totals would favour Mon and Tue
by_weekday <- uber[, .(avg_pickups = .N / uniqueN(date)), by = .(zone, weekday)]
by_weekday[, share := avg_pickups / sum(avg_pickups), by = zone]

p_weekday <- ggplot(by_weekday,
                    aes(x = weekday, y = share, colour = zone, group = zone)) +
  geom_line() +
  facet_wrap(~ zone) +
  theme(legend.position = "none")

ggsave("figures/04_zone_weekday_share.png", p_weekday, width = 10, height = 7)

# 4. by date ----

# share of each zone's monthly pickups on each day (about 1/30 on a normal day)
by_date <- uber[, .N, by = .(zone, date)]
by_date[, share := N / sum(N), by = zone]

p_date <- ggplot(by_date, aes(x = date, y = share, colour = zone)) +
  geom_line() +
  facet_wrap(~ zone) +
  theme(legend.position = "none")

ggsave("figures/04_zone_date_share.png", p_date, width = 10, height = 7)

# 5. zone centers by hour ----

# mean location of each zone's pickups in each hour
by_hour_centers <- uber[, .(Lon = mean(Lon), Lat = mean(Lat)),
                        by = .(zone, hour)][order(zone, hour)]

# background: a random sample of 100k pickups
set.seed(1)
bg <- uber[sample(.N, 100000), .(Lon, Lat)]

p_centers_hour <- ggplot() +
  geom_point(data = bg, aes(x = Lon, y = Lat),
             colour = "grey80", size = 0.1, alpha = 0.1) +
  geom_point(data = by_hour_centers, aes(x = Lon, y = Lat, colour = hour),
             size = 1.5) +
  coord_quickmap(xlim = c(-74.2, -73.74), ylim = c(40.63, 40.88)) +
  labs(colour = "Hour")

ggsave("figures/04_zone_centers_by_hour.png", p_centers_hour, width = 9, height = 6)
