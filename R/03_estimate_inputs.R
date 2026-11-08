# Estimate means, volatilities and correlation from historical returns,
# for the full sample and a recent 50-year window.

library(dplyr)

returns <- read.csv("data/clean/returns_clean.csv")

# Estimate all inputs for a given sample period
estimate_inputs <- function(data, start, end) {
  d <- filter(data, year >= start, year <= end)
  n <- nrow(d)
  data.frame(
    period          = paste0(start, "-", end),
    years           = n,
    stock_mean      = mean(d$stocks),
    stock_sd        = sd(d$stocks),
    bond_mean       = mean(d$bonds),
    bond_sd         = sd(d$bonds),
    correlation     = cor(d$stocks, d$bonds),
    # Volatility drag check: geometric mean vs arithmetic mean - sd^2/2
    stock_geometric = prod(1 + d$stocks)^(1 / n) - 1,
    stock_approx    = mean(d$stocks) - sd(d$stocks)^2 / 2
  )
}

inputs <- bind_rows(
  estimate_inputs(returns, 1928, 2025), # main case 
  estimate_inputs(returns, 1976, 2025) # sensitivity: last 50 years
)

print(inputs, digits = 3)

write.csv(inputs, "output/tables/estimated_inputs.csv", row.names = FALSE)