# Where do New Yorkers take Uber?

**Clustering Uber pickup locations in New York City (September 2014) and forecasting demand per cluster**

## Questions

1. Where are the main pickup zones in New York City?
2. How does demand in each zone change over the day?
3. How does it change across the days of the week and the month?
4. Which clustering method and how many clusters describe the data best?
5. Can the clusters be used to forecast demand?

## Data

1,028,136 Uber pickups in New York City between 1 and 30 September 2014: date and time, latitude, longitude and the code of the Uber base.

The data is in `data/raw/uber-data.csv`.

## Repository structure

```
R/          analysis scripts, run in numerical order
data/raw/   the raw data (uber-data.csv)
figures/    plots
report/     R Markdown source of the report
```

## Reproducing the analysis

Open `uber-nyc-clusters.Rproj` in RStudio and run the scripts in `R/` in order, starting with `00_setup.R`.

## Status

Work in progress.
