# Compare funding outcomes after 20 years across equity shares.
# Uses the SAME simulated returns for every strategy, so differences
# come from the strategy, not from random noise.

library(dplyr)
library(ggplot2)

inputs <- read.csv("output/tables/estimated_inputs.csv")
p <- inputs[1, ]

start_funding    <- 0.86
years            <- 20
n_sims           <- 10000
liability_growth <- p$bond_mean
set.seed(2026)

mu <- c(p$stock_mean, p$bond_mean)
cov_sb <- p$correlation * p$stock_sd * p$bond_sd
Sigma <- matrix(c(p$stock_sd^2, cov_sb, cov_sb, p$bond_sd^2), nrow = 2)
draws <- MASS::mvrnorm(n_sims * years, mu = mu, Sigma = Sigma)
stock_ret <- matrix(draws[, 1], nrow = n_sims, ncol = years)
bond_ret  <- matrix(draws[, 2], nrow = n_sims, ncol = years)

# Final-year funding ratio for a given equity share and starting level
final_funding <- function(w, start) {
  port <- w * stock_ret + (1 - w) * bond_ret
  start * apply(1 + port, 1, prod) / (1 + liability_growth)^years
}

summarise_strategy <- function(w, start) {
  f <- final_funding(w, start)
  data.frame(
    start_funding    = start,
    equity_share     = w,
    p5               = unname(quantile(f, 0.05)),
    median           = median(f),
    p95              = unname(quantile(f, 0.95)),
    prob_underfunded = mean(f < 1)
  )
}

shares <- seq(0, 1, by = 0.1)

results <- bind_rows(
  lapply(shares, summarise_strategy, start = start_funding),  # main: 86% funded
  lapply(shares, summarise_strategy, start = 1.25)            # sensitivity: 2025 average
)

print(results, digits = 3)
write.csv(results, "output/tables/strategy_comparison.csv", row.names = FALSE)

# Chart: probability of underfunding by equity share
ggplot(results, aes(x = equity_share, y = prob_underfunded,
                    colour = factor(start_funding))) +
  geom_line(linewidth = 1) +
  geom_point() +
  geom_vline(xintercept = c(0.15, 0.61), linetype = "dashed", colour = "grey50") +
  annotate("text", x = 0.15, y = 0.95, label = "2025 avg", hjust = -0.1, size = 3) +
  annotate("text", x = 0.61, y = 0.95, label = "2006 avg", hjust = -0.1, size = 3) +
  scale_x_continuous(labels = scales::percent) +
  scale_y_continuous(labels = scales::percent) +
  labs(
    title = "Probability of being underfunded after 20 years, by equity share",
    x = "Share of assets in equities", y = "Probability funding ratio < 100%",
    colour = "Starting funding ratio"
  ) +
  theme_minimal()

ggsave("output/figures/strategy_comparison.png", width = 8, height = 5, dpi = 300)

