# Simulate funding ratios for a pension scheme using estimated inputs,
# then summarise with percentiles and a fan chart

library(dplyr)
library(ggplot2)

inputs <- read.csv("output/tables/estimated_inputs.csv")
p <- inputs[1, ]  # main case: 1928-2025

# ---- Scenario choices (justify each in the README) ----
start_funding <- 0.86
years <- 20
n_sims <- 10000
equity_share <- 0.61
liability_growth <- p$bond_mean
set.seed(2026)

# Correlated random returns 
mu <- c(p$stock_mean, p$bond_mean)
cov_sb <- p$correlation * p$stock_sd * p$bond_sd
Sigma <- matrix(c(p$stock_sd^2, cov_sb,
                  cov_sb, p$bond_sd^2), nrow = 2)

draws <- MASS::mvrnorm(n_sims * years, mu = mu, Sigma = Sigma)
stock_ret <- matrix(draws[, 1], nrow = n_sims, ncol = years)
bond_ret  <- matrix(draws[, 2], nrow = n_sims, ncol = years)

# Checks (making sure simulated values match estimated inputs)
check_sim <- c(
  stock_mean = mean(stock_ret), stock_sd = sd(stock_ret),
  bond_mean  = mean(bond_ret),  bond_sd  = sd(bond_ret),
  correlation = cor(as.vector(stock_ret), as.vector(bond_ret))
)
print(round(check_sim, 4))

# portfolio returns 
port_ret <- equity_share * stock_ret + (1 - equity_share) * bond_ret

port_mean_theory <- equity_share * p$stock_mean + (1 - equity_share) * p$bond_mean
port_sd_theory <- sqrt(equity_share^2 * p$stock_sd^2 +
                         (1 - equity_share)^2 * p$bond_sd^2 +
                         2 * equity_share * (1 - equity_share) * cov_sb)
print(c(sim_mean = mean(port_ret), theory_mean = port_mean_theory,
        sim_sd = sd(port_ret), theory_sd = port_sd_theory))

# assets, liabilities, and funding ratio
asset_growth <- t(apply(1 + port_ret, 1, cumprod))   # compounding, row by row
assets       <- start_funding * asset_growth
liabilities  <- (1 + liability_growth)^(1:years)
funding      <- sweep(assets, 2, liabilities, "/")
funding      <- cbind(start_funding, funding)           # add year 0

# Volatility drag check (comparing predictions with simulated mean)
naive    <- start_funding * ((1 + port_mean_theory) / (1 + liability_growth))^years
adjusted <- start_funding * ((1 + port_mean_theory - port_sd_theory^2 / 2) /
                               (1 + liability_growth))^years
print(c(naive = naive, adjusted = adjusted,
        simulated_median = median(funding[, years + 1])))

# Percentiles and probability of under-funding 
pct <- apply(funding, 2, quantile, probs = c(0.05, 0.5, 0.95))
fan <- data.frame(year = 0:years, p5 = pct[1, ], p50 = pct[2, ], p95 = pct[3, ])

prob_underfunded <- mean(funding[, years + 1] < 1)
print(fan[nrow(fan), ])
print(c(prob_underfunded = prob_underfunded))

write.csv(fan, "output/tables/fan_chart_data.csv", row.names = FALSE)

# Fan Chart
ggplot(fan, aes(x = year)) +
  geom_ribbon(aes(ymin = p5, ymax = p95), fill = "steelblue", alpha = 0.3) +
  geom_line(aes(y = p50), colour = "steelblue4", linewidth = 1) +
  geom_hline(yintercept = 1, linetype = "dashed") +
  labs(
    title = "Simulated funding ratio: median and 5th-95th percentile range",
    subtitle = paste0(equity_share * 100, "% equities, ", n_sims,
                      " simulations, inputs estimated from 1928-2025 US data"),
    x = "Year", y = "Funding ratio (assets / liabilities)"
  ) +
  theme_minimal()

ggsave("output/figures/fan_chart.png", width = 8, height = 5, dpi = 300)