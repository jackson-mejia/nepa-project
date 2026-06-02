# Compute the steady-state aggregate $ and % gains from a one-year reduction in
# NEPA review delay (dL = 1). Produces the headline Table 1 for the memo.
#
# Mechanism (analytical steady-state limit of the time-to-build model):
#   d ln Y_sector  / dL = -alpha * r / (1 - alpha)   per year of dL reduction
#   d ln K_sector  / dL = -r       / (1 - alpha)     per year of dL reduction
#   Aggregate (Domar-weighted): multiply by Phi.
#   Wages: under inelastic labor supply, % wage gain equals % output gain.
#
# Capital level gains use a denominator-matched K base:
#   - Upper-bound Phi (structures-only denominator) -> structures-only K stock
#   - Lower-bound Phi (struct + equip denominator)   -> struct + equip K stock
#   - Central row uses the midpoint of the two bases.
#
# Inputs:
#   output/phi_domar_headline.csv             — Phi central/lower/upper
#   data/bea/t115.csv                         — 2024 nominal GDP (line 1)
#   data/bea/detailnonres_stk2.xlsx           — private nonres net stock (rows 8/48)
#   data/bea/fa71.csv                         — government nonres net stock (lines 2/3/4)
#
# Outputs:
#   output/aggregate_gains.csv  — Table 1 (one row per scenario)
#   stdout: formatted table + the bases/constants used

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(readxl); library(purrr); library(tibble); library(here)
})

# ============================================================
# Model parameters (keep in sync with nepa_transition.R)
# ============================================================
alpha <- 0.4
r     <- 0.08
dlogY_per_dL_per_phi <- alpha * r / (1 - alpha)   # ~0.0533
dlogK_per_dL_per_phi <- r       / (1 - alpha)     # ~0.1333

# Census ACS 2024 mean household income (used to scale the household_income_gain
# column — under inelastic labor supply the percent change in household income
# equals the percent change in output, but the absolute dollar gain reported
# here aggregates wages, capital income, and other income, not just wages).
MEAN_HH_INCOME_2024 <- 109160

# ============================================================
# 1. Phi (from compute_domar.R headline output)
# ============================================================
phi <- read_csv(here("output", "phi_domar_headline.csv"), show_col_types = FALSE)
phi_lo <- phi$phi_domar_lower[1]
phi_md <- phi$phi_domar_headline[1]
phi_up <- phi$phi_domar_upper[1]

# ============================================================
# 2. 2024 nominal GDP (BEA t115.csv line 1)
# ============================================================
gdp_raw <- suppressWarnings(read_csv(here("data", "bea", "t115.csv"), skip = 3,
                    show_col_types = FALSE,
                    col_names = c("line", "label", as.character(1929:2025))))
gdp_raw$line <- suppressWarnings(as.integer(gdp_raw$line))
gdp_2024 <- as.numeric(gdp_raw$`2024`[which(gdp_raw$line == 1L)])   # $B nominal

# ============================================================
# 3. Private nonresidential net stock 2024 (detailnonres_stk2.xlsx)
#    Row 48 = TOTAL STRUCTURES, Row 8 = TOTAL EQUIPMENT (per-sheet),
#    summed across all industry sheets.
# ============================================================
priv_stk_file <- here("data", "bea", "detailnonres_stk2.xlsx")
priv_sheets <- setdiff(excel_sheets(priv_stk_file),
                       c("readme", "Datasets", "CreateCTQI"))

read_priv_stock_2024 <- function(sh) {
  d <- suppressMessages(read_excel(priv_stk_file, sheet = sh,
                                    col_names = FALSE, .name_repair = "minimal"))
  if (nrow(d) < 48) return(NULL)
  yr <- suppressWarnings(as.integer(unlist(d[6, ])))
  struct <- suppressWarnings(as.numeric(unlist(d[48, ])))
  equip  <- suppressWarnings(as.numeric(unlist(d[8,  ])))
  # Safety: verify row labels — fail loudly rather than silently dropping/zeroing.
  if (!isTRUE(grepl("TOTAL STRUCTURES", d[[2]][48], ignore.case = TRUE)))
    stop("Sheet '", sh, "' lacks 'TOTAL STRUCTURES' at row 48 in ",
         basename(priv_stk_file), " — verify BEA workbook layout has not changed.")
  if (!isTRUE(grepl("TOTAL EQUIPMENT",  d[[2]][8],  ignore.case = TRUE)))
    stop("Sheet '", sh, "' lacks 'TOTAL EQUIPMENT' at row 8 in ",
         basename(priv_stk_file), " — verify BEA workbook layout has not changed.")
  tibble(sheet = sh, year = yr, struct = struct, equip = equip) |>
    filter(!is.na(year), !is.na(struct), year == 2024)
}

priv <- map_dfr(priv_sheets, read_priv_stock_2024)
# detailnonres_stk2.xlsx values are $M nominal; convert to $B for consistency
# with fa71.csv (gov) and t115.csv (GDP), both of which are already $B.
priv_struct <- sum(priv$struct, na.rm = TRUE) / 1000
priv_equip  <- sum(priv$equip,  na.rm = TRUE) / 1000

# ============================================================
# 4. Government nonresidential net stock 2024 (fa71.csv)
#    BEA Table 7.1: line 2 = Equipment, line 3 = Structures (all),
#                   line 4 = Residential structures.
#    Nonres structures = line 3 − line 4.
# ============================================================
gov_raw <- suppressWarnings(read_csv(here("data", "bea", "fa71.csv"), skip = 3,
                    show_col_types = FALSE,
                    col_names = c("line", "label", as.character(2017:2024))))
gov_raw$line <- suppressWarnings(as.integer(gov_raw$line))
get_gov <- function(l) as.numeric(gov_raw$`2024`[which(gov_raw$line == l)])
gov_equip       <- get_gov(2)
gov_struct_all  <- get_gov(3)
gov_struct_res  <- get_gov(4)
gov_struct      <- gov_struct_all - gov_struct_res
gov_struct_eq   <- gov_struct + gov_equip

# ============================================================
# 5. Combined K bases
# ============================================================
K_struct_only <- priv_struct + gov_struct                       # upper-Phi base
K_struct_eq   <- (priv_struct + priv_equip) + gov_struct_eq     # lower-Phi base
K_mid         <- (K_struct_only + K_struct_eq) / 2

# ============================================================
# 6. Scenario table
# ============================================================
scenarios <- tibble(
  scenario = c("Lower", "Central", "Upper"),
  phi      = c(phi_lo, phi_md, phi_up),
  K_base_b = c(K_struct_eq, K_mid, K_struct_only),
  K_base_basis = c("structures + equipment (ex-IPP)",
                   "midpoint",
                   "structures only")
) |>
  mutate(
    output_pct_gain         = 100 * dlogY_per_dL_per_phi * phi,
    capital_pct_gain        = 100 * dlogK_per_dL_per_phi * phi,
    gdp_b_gain              = (output_pct_gain  / 100) * gdp_2024,
    capital_b_gain          = (capital_pct_gain / 100) * K_base_b,
    household_income_gain   = (output_pct_gain  / 100) * MEAN_HH_INCOME_2024
  )

# ============================================================
# 7. Write and report
# ============================================================
out_dir <- here("output")
dir.create(out_dir, showWarnings = FALSE)
write_csv(scenarios, file.path(out_dir, "aggregate_gains.csv"))

cat("=== Table 1: Long-Run Aggregate Gains per Year of NEPA Delay Reduction (dL = 1) ===\n\n")
print(
  scenarios |>
    mutate(
      phi              = round(phi, 4),
      output_pct_gain  = round(output_pct_gain,  2),
      capital_pct_gain = round(capital_pct_gain, 2),
      gdp_b_gain            = round(gdp_b_gain,            0),
      capital_b_gain        = round(capital_b_gain,        0),
      household_income_gain = round(household_income_gain, 0),
      K_base_T              = round(K_base_b / 1000,       1)
    ) |>
    select(scenario, phi, output_pct_gain, capital_pct_gain,
           gdp_b_gain, capital_b_gain, household_income_gain, K_base_T, K_base_basis),
  width = 200
)

cat("\n--- Bases & constants ---\n")
cat(sprintf("  alpha=%.2f, r=%.2f, semi-elasticity dlnY/dL/Phi = %.4f, dlnK/dL/Phi = %.4f\n",
            alpha, r, dlogY_per_dL_per_phi, dlogK_per_dL_per_phi))
cat(sprintf("  GDP (2024 nominal):                 $%.0fB         [BEA t115.csv line 1]\n", gdp_2024))
cat(sprintf("  Mean household income (2024):       $%s        [Census ACS]\n",
            format(MEAN_HH_INCOME_2024, big.mark = ",")))
cat(sprintf("  Private nonres struct (2024):       $%.1fT         [detailnonres_stk2.xlsx]\n",
            priv_struct / 1000))
cat(sprintf("  Private nonres equip  (2024):       $%.1fT         [detailnonres_stk2.xlsx]\n",
            priv_equip / 1000))
cat(sprintf("  Gov     nonres struct (2024):       $%.1fT         [fa71.csv line 3 - line 4]\n",
            gov_struct / 1000))
cat(sprintf("  Gov     nonres equip  (2024):       $%.1fT         [fa71.csv line 2]\n",
            gov_equip / 1000))
cat(sprintf("  K base, structures only:            $%.1fT\n", K_struct_only / 1000))
cat(sprintf("  K base, struct + equip ex-IPP:      $%.1fT\n", K_struct_eq / 1000))
cat(sprintf("  K base, midpoint (central row):     $%.1fT\n", K_mid / 1000))

cat(sprintf("\nWrote %s\n", file.path("output", "aggregate_gains.csv")))
