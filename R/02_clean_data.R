# Load annual US stock and bond returns from the Damodaran workbook
# and Save a clean CSV with three columns: year, stocks, bonds.

library(readxl)
library(dplyr)

# Read starting from row 21
# without column names to rename them.
raw <- read_excel(
  "data/raw/histretSP.xls",
  sheet = "Returns by year",
  range = "A21:H200", 
  col_names = FALSE
)

returns <- raw |> 
  select(year = 1, stocks = 2, bonds = 5) |> # columns A, B, and E
  mutate(across(everything(), ~ suppressWarnings(as.numeric(.x)))) |>
  filter(!is.na(year), year >= 1928, year <= 2100)
  # Blank rows and summary rows become NA 

# Checks: stop with an error if anything looks wrong
stopifnot(
  all(diff(returns$year) == 1),          # no missing or repeated years
  !anyNA(returns),                       # no missing values
  all(abs(returns$stocks) < 1),          # returns are decimals (0.43, not 43)
  all(abs(returns$bonds) < 1)
)

head(returns)
tail(returns)
summary(returns)

write.csv(returns, "data/clean/returns_clean.csv", row.names = FALSE)

