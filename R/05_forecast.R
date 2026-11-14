# 05_forecast.R
# uses the clusters for forecasting: assigns new pickups to zones and
# forecasts daily demand per zone

library(data.table)
library(flexclust)
library(forecast)
library(ggplot2)

# 1. load ----

uber <- readRDS("data/processed/uber_clusters.rds")
dim(uber)

# 2. assign new pickups to zones ----

# clustering for forecasting: learn the zones on training pickups, then
# predict the zone of pickups the model has not seen

# zone centres from 03_clusters.R, used as starting centres so that kcca
# finds the same seven zones (from random starts it can find others)
cluster_centers <- uber[, .(Lon = mean(Lon), Lat = mean(Lat)),
                        by = cluster][order(cluster)]

# 100k pickups to train on, 20k other pickups to test on
set.seed(1)
idx <- sample(nrow(uber), 120000)
train <- uber[idx[1:100000], .(Lon, Lat)]
test <- uber[idx[100001:120000], .(Lon, Lat, cluster)]

cl <- flexclust::kcca(train,
                      k = as.matrix(cluster_centers[, .(Lon, Lat)]),
                      family = kccaFamily("kmeans"))
pred <- predict(cl, newdata = test[, .(Lon, Lat)])

# share of test pickups assigned to their true zone (0.997)
mean(pred == test$cluster)

# 3. forecast daily demand per zone ----

# daily pickups per zone; for each zone, train on 1-23 September and
# forecast the last 7 days (24-30 September), then compare with the actual days
daily <- uber[, .N, by = .(zone, date)]

results <- list()

for (z in levels(daily$zone)) {
  print(z)

  # weekly seasonality: frequency = 7 (one value per day)
  y <- ts(daily[zone == z][order(date)]$N, frequency = 7)
  train_y <- window(y, start = c(1, 1), end = c(4, 2))
  test_y <- window(y, start = c(4, 3), end = c(5, 2))

  # snaive: repeats the last week (baseline)
  fc_snaive <- snaive(train_y, h = 7)

  # ETS: smoothed level (and trend) with weekday effects
  fit_ets <- ets(train_y)
  fc_ets <- forecast(fit_ets, h = 7)

  # ARIMA: linear model of past days and past errors
  fit_arima <- auto.arima(train_y)
  fc_arima <- forecast(fit_arima, h = 7)

  # test-set errors of each model
  rmse <- c(accuracy(fc_snaive, test_y)["Test set", "RMSE"],
            accuracy(fc_ets, test_y)["Test set", "RMSE"],
            accuracy(fc_arima, test_y)["Test set", "RMSE"])
  mape <- c(accuracy(fc_snaive, test_y)["Test set", "MAPE"],
            accuracy(fc_ets, test_y)["Test set", "MAPE"],
            accuracy(fc_arima, test_y)["Test set", "MAPE"])

  results[[z]] <- data.table(zone = z, model = c("snaive", "ETS", "ARIMA"),
                             RMSE = rmse, MAPE = mape)
}

results <- rbindlist(results)

# 4. forecast accuracy plot ----

p_mape <- ggplot(results, aes(x = zone, y = MAPE, fill = model)) +
  geom_col(position = "dodge") +
  coord_flip() +
  labs(x = NULL, y = "MAPE (%)")

ggsave("figures/05_forecast_mape.png", p_mape, width = 9, height = 6)
