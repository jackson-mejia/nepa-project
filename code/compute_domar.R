# Domar-weighted NEPA exposure: Φ = Σ_i s_i · ϕ_i^total
#
# Where:
#   s_i   = Gross Output_i / GDP  (Domar weight, sourced from BEA tind_go + t115)
#   ϕ_i^structures = (NEPA-exposed annual capex in sector i, 2024$) /
#                    (BEA private nonres STRUCTURES investment in sector i, 2024$)
#
# Notes:
#   - Denominator is structures-only (Row 48 of BEA detailnonres_inv1; t595 line 7
#     for federal gov; t595 line 29 for state-local gov). Author's call: NEPA
#     review applies primarily to physical structures (pipelines, transmission,
#     facilities, dams), so structures-only is the right share-of-NEPA-relevant-
#     investment-exposed measure.
#   - Panel restricted to 2020-2024 (5 years), the recent baseline pre-reform.
#   - Σ s_i > 1 by Hulten signature (~1.7 in 2024); not a bug.
#   - The tind_go file aggregates Utilities (lines 2211/2212/2213 collapsed). Our
#     2211 (electric power) dominates that aggregate (~90% of GO, ~98% of our
#     NEPA numerator), so we use the Utilities GO as the Domar weight for the
#     combined 2211+2213 records in our project.
#   - Same single deflator (BEA Table 1.1.9 line 10, private nonres structures
#     IPD) applied to numerator + denominator + GO + GDP. The Domar ratio is
#     unit-free in the same year, so deflation is only needed to make the ϕ_i
#     numerator and denominator consistent across years.

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(readxl); library(tidyr); library(purrr); library(stringr)
})

library(here)

PANEL_YEARS <- 2020:2024   # post-2019 baseline; pre-OBBBA / EO 14154 reform years
BASE_YEAR   <- 2024

# ========================================================================
# 1. Deflator (reused from compute_phi.R logic)
# ========================================================================
defl_raw <- read_csv(here("data", "bea", "t119.csv"),
                     skip = 3, show_col_types = FALSE,
                     col_names = c("line", "label", as.character(1929:2025)))
defl_row <- defl_raw |> filter(line == "10")
defl_long <- tibble(
  year = 1929:2025,
  deflator = as.numeric(unlist(defl_row[1, as.character(1929:2025)]))
) |> filter(!is.na(deflator), year %in% 1990:2025)
defl_2024 <- defl_long$deflator[defl_long$year == BASE_YEAR]
defl_factor <- function(yr) {
  yr2 <- max(min(yr, max(defl_long$year)), min(defl_long$year))
  defl_2024 / defl_long$deflator[defl_long$year == yr2]
}

# ========================================================================
# 2. GDP and Gross Output by industry
# ========================================================================
gdp_raw <- suppressWarnings(read_csv(here("data", "bea", "t115.csv"),
                    skip = 3, show_col_types = FALSE,
                    col_names = c("line", "label", as.character(1929:2025))))
gdp_raw$line <- suppressWarnings(as.integer(gdp_raw$line))
gdp_panel <- gdp_raw |> filter(line == 1L) |>
             select(all_of(as.character(PANEL_YEARS))) |>
             unlist() |> as.numeric()
names(gdp_panel) <- as.character(PANEL_YEARS)

go_raw <- suppressWarnings(read_csv(here("data", "bea", "tind_go.csv"),
                   skip = 3, show_col_types = FALSE,
                   col_names = c("line", "label", as.character(1997:2025))))
go_raw$line <- suppressWarnings(as.integer(go_raw$line))

# Pull GO per year for the industries we map to. Returns named numeric vector.
go_for_line <- function(line_num) {
  row <- go_raw |> filter(line == line_num)
  if (nrow(row) == 0) {
    warning("No tind_go line ", line_num); return(NULL)
  }
  v <- as.numeric(unlist(row[1, as.character(PANEL_YEARS)]))
  names(v) <- as.character(PANEL_YEARS)
  v
}

# Domar weight per industry per year (unit-free; no deflation needed)
domar_weight <- function(go_line) {
  go <- go_for_line(go_line)
  if (is.null(go)) return(NULL)
  go / gdp_panel
}

# ========================================================================
# 3. Crosswalk: our project's BEA codes → tind_go NIPA line numbers
# ========================================================================
crosswalk <- tribble(
  ~bea_code, ~go_line, ~go_label,
  "113F",   3,  "Agriculture, forestry, fishing, and hunting",
  "2110",   7,  "Oil and gas extraction",
  "2120",   8,  "Mining, except oil and gas",
  "2130",   9,  "Support activities for mining",
  "2211",  10,  "Utilities",
  "2212",  10,  "Utilities",
  "2213",  10,  "Utilities",
  "2300",  11,  "Construction",
  "4810",  41,  "Air transportation",
  "4820",  42,  "Rail transportation",
  "4830",  43,  "Water transportation",
  "4850",  45,  "Transit and ground passenger transportation",
  "4860",  46,  "Pipeline transportation",
  "487S",  47,  "Other transportation and support activities",
  "4930",  48,  "Warehousing and storage",
  "7130",  81,  "Arts, entertainment, recreation, accommodation, and food services"
)

# ========================================================================
# 4. Sectoral capex (STRUCTURES + EQUIPMENT, ex-IPP) from detailnonres_inv1.xlsx
# ========================================================================
BEA_FILE <- here("data", "bea", "detailnonres_inv1.xlsx")

read_industry_capex <- function(sheet) {
  # Read BOTH structures (Row 48) and equipment (Row 8) so the headline + bounds
  # computation can use either denominator (S vs S+E).
  d <- suppressMessages(read_excel(BEA_FILE, sheet = sheet, col_names = FALSE,
                                    .name_repair = "minimal"))
  if (nrow(d) < 48) return(NULL)
  year_row   <- suppressWarnings(as.integer(unlist(d[6, ])))
  equipment  <- suppressWarnings(as.numeric(unlist(d[8,  ])))
  structures <- suppressWarnings(as.numeric(unlist(d[48, ])))
  if (!grepl("TOTAL STRUCTURES", toupper(d[[2]][48])))
    stop("Sheet '", sheet, "' lacks 'TOTAL STRUCTURES' at row 48 in ",
         basename(BEA_FILE), " — verify BEA workbook layout has not changed.")
  if (!grepl("TOTAL EQUIPMENT", toupper(d[[2]][8])))
    stop("Sheet '", sheet, "' lacks 'TOTAL EQUIPMENT' at row 8 in ",
         basename(BEA_FILE), " — verify BEA workbook layout has not changed.")
  tibble(bea_code = sheet, year = year_row,
         structures_m_nom = structures, equipment_m_nom = equipment) |>
    filter(!is.na(year), !is.na(structures_m_nom), year %in% PANEL_YEARS)
}

cat("Reading per-industry capex (structures + equipment) from BEA workbook...\n")
priv_capex <- map_dfr(crosswalk$bea_code, read_industry_capex) |>
              mutate(defl       = map_dbl(year, defl_factor),
                     struct_m_2024     = structures_m_nom * defl,
                     equip_m_2024      = equipment_m_nom * defl,
                     struct_eq_m_2024  = struct_m_2024 + equip_m_2024)

# ========================================================================
# 5. Pull NEPA numerator per BEA code per year (from compute_phi.R output)
# ========================================================================
# phi_private_by_sector_year.csv has num_m_2024 per (bea_code, panel_year)
priv_num_year <- read_csv(here("output", "phi_private_by_sector_year.csv"),
                          show_col_types = FALSE) |>
                 rename(year = panel_year)

# ========================================================================
# 7. Build per-(go_line, year) Domar weights
# ========================================================================
# For each (go_line, year), s_i_year = GO_i / GDP. Built independently of
# sector_year so the row count stays at one-per-(go_line, year).
domar_long <- crosswalk |> distinct(go_line, go_label) |>
  rowwise() |>
  mutate(s_per_year = list(tibble(year = PANEL_YEARS, s = domar_weight(go_line)))) |>
  unnest(s_per_year) |>
  ungroup()

# ========================================================================
# 8. Core aggregation function: takes a denominator column name (struct_m_2024
#    or struct_eq_m_2024) and returns the full Φ_Domar breakdown.
#
# Called TWICE below — once with structures-only (upper bound) and once with
# structures + equipment (lower bound).
# ========================================================================
compute_phi_domar <- function(denom_col) {
  sector_year <- crosswalk |>
    inner_join(priv_capex,   by = "bea_code") |>
    left_join(priv_num_year, by = c("bea_code","year")) |>
    mutate(num_m_2024 = coalesce(num_m_2024, 0),
           den_m_2024 = .data[[denom_col]])

  # Two-step: collapse BEA codes within (year, go_line) first, then attach s.
  agg <- sector_year |>
    group_by(year, go_line, go_label) |>
    summarise(num_m_2024 = sum(num_m_2024, na.rm = TRUE),
              den_m_2024 = sum(den_m_2024, na.rm = TRUE),
              phi_aggregated = num_m_2024 / den_m_2024,
              .groups = "drop")

  py <- agg |>
    left_join(domar_long, by = c("go_line","go_label","year")) |>
    mutate(contribution = s * phi_aggregated)
  py
}

phi_per_year_per_line <- compute_phi_domar("struct_m_2024")   # private side, structures-only headline

phi_domar_by_year <- phi_per_year_per_line |>
  group_by(year) |>
  summarise(phi_domar = sum(contribution, na.rm = TRUE),
            .groups = "drop")

phi_domar_headline <- mean(phi_domar_by_year$phi_domar)

sector_decomp <- phi_per_year_per_line |>
  group_by(go_line, go_label) |>
  summarise(s_avg          = mean(s, na.rm = TRUE),
            phi_agg_avg    = mean(phi_aggregated, na.rm = TRUE),
            contribution_avg = mean(contribution, na.rm = TRUE),
            .groups = "drop") |>
  arrange(desc(contribution_avg))

# ========================================================================
# 8b. Add government sectors (gov_federal + gov_state_local) to Φ_Domar
# ========================================================================
# Gov capex flows through gov-sector gross output in the Hulten framework.
# Two new "sectors":
#   - Federal (gen gov + defense + nondefense + federal gov enterprises) — tind_go line 90
#   - State and local (gen gov + state-local gov enterprises)            — tind_go line 95
#
# Denominators are structures + equipment ex-IPP, parallel to the private side:
#   - Federal capex_year = t595 line 7 (Federal structures) + line 47 (Federal equipment)
#   - State-local capex  = t595 line 29 (S-L structures)    + line 56 (S-L equipment)
#
# Numerators come straight from the funding-source allocation:
#   - gov_federal_num = sum over records where funding_source=gov_federal (+ 50% of mixed)
#   - gov_state_local_num = sum where funding_source=gov_state_local

# Read gov denominators (in $B nominal, multiply by 1000 to get $M)
gov_t595 <- suppressWarnings(read_csv(here("data", "bea", "t595.csv"),
                     skip = 3, show_col_types = FALSE,
                     col_names = c("line","label",as.character(1929:2024))))
gov_t595$line <- suppressWarnings(as.integer(gov_t595$line))

gov_line_series <- function(line_num) {
  r <- gov_t595 |> filter(line == line_num)
  v <- as.numeric(unlist(r[1, as.character(PANEL_YEARS)]))
  names(v) <- as.character(PANEL_YEARS); v
}

fed_struct_b <- gov_line_series(7)              # Federal structures (t595)
fed_equip_b  <- gov_line_series(47)             # Federal equipment
sl_struct_b  <- gov_line_series(29)            # State-local structures
sl_equip_b   <- gov_line_series(56)            # State-local equipment

# Deflate both denominator versions
defl_yr <- map_dbl(PANEL_YEARS, defl_factor)
fed_struct_m_2024    <- fed_struct_b * 1000 * defl_yr
fed_struct_eq_m_2024 <- (fed_struct_b + fed_equip_b) * 1000 * defl_yr
sl_struct_m_2024     <- sl_struct_b  * 1000 * defl_yr
sl_struct_eq_m_2024  <- (sl_struct_b + sl_equip_b)   * 1000 * defl_yr

# Headline path uses structures-only
fed_total_capex_m_2024 <- fed_struct_m_2024
sl_total_capex_m_2024  <- sl_struct_m_2024

# Gov numerators per year (already in 2024$ — re-derive from raw cost data + funding)
cost_raw <- map_dfr(PANEL_YEARS, function(y) {
  read_csv(here("data", "processed",
                     sprintf("cost_extraction_%d.csv", y)),
           show_col_types = FALSE, col_types = cols(.default = "c")) |>
    mutate(panel_year = y) |>
    select(any_of(c("eis_number","cost_m_usd_nominal","cost_year","panel_year")))
}) |>
  mutate(cost_m_usd_nominal = as.numeric(cost_m_usd_nominal),
         cost_year = suppressWarnings(as.integer(cost_year)),
         cost_year = if_else(is.na(cost_year), panel_year, cost_year),
         defl = map_dbl(cost_year, defl_factor),
         cost_m_usd_2024 = cost_m_usd_nominal * defl)

funding_src <- read_csv(here("data", "processed", "funding_source.csv"),
                        show_col_types = FALSE) |>
               mutate(eis_number = as.character(eis_number)) |>
               select(panel_year, eis_number, funding_source)

cost_raw <- cost_raw |> left_join(funding_src, by = c("panel_year","eis_number")) |>
  mutate(share_fed = case_when(funding_source == "gov_federal" ~ 1.0,
                               funding_source == "mixed"       ~ 0.5,
                               TRUE                            ~ 0.0),
         share_sl  = case_when(funding_source == "gov_state_local" ~ 1.0,
                               TRUE                                ~ 0.0))

gov_fed_num_year <- cost_raw |>
  mutate(alloc = cost_m_usd_2024 * share_fed) |>
  group_by(panel_year) |> summarise(num_m_2024 = sum(alloc, na.rm = TRUE), .groups = "drop")
gov_sl_num_year <- cost_raw |>
  mutate(alloc = cost_m_usd_2024 * share_sl) |>
  group_by(panel_year) |> summarise(num_m_2024 = sum(alloc, na.rm = TRUE), .groups = "drop")

# Domar weights for gov sectors
s_fed_year <- go_for_line(90) / gdp_panel    # named vector by year
s_sl_year  <- go_for_line(95) / gdp_panel

# Assemble per-year contributions
gov_phi <- tibble(
  year = PANEL_YEARS,
  fed_num   = gov_fed_num_year$num_m_2024[match(PANEL_YEARS, gov_fed_num_year$panel_year)],
  fed_den   = fed_total_capex_m_2024,
  fed_phi   = fed_num / fed_den,
  fed_s     = s_fed_year[as.character(PANEL_YEARS)],
  fed_contrib = fed_s * fed_phi,
  sl_num    = gov_sl_num_year$num_m_2024[match(PANEL_YEARS, gov_sl_num_year$panel_year)],
  sl_den    = sl_total_capex_m_2024,
  sl_phi    = sl_num / sl_den,
  sl_s      = s_sl_year[as.character(PANEL_YEARS)],
  sl_contrib = sl_s * sl_phi
)

# Add gov rows to the per-(year, sector) table so they appear in the decomposition
gov_per_year <- bind_rows(
  gov_phi |> transmute(year, go_line = 90L, go_label = "Federal government",
                       num_m_2024 = fed_num, den_m_2024 = fed_den,
                       phi_aggregated = fed_phi, s = fed_s, contribution = fed_contrib),
  gov_phi |> transmute(year, go_line = 95L, go_label = "State and local government",
                       num_m_2024 = sl_num, den_m_2024 = sl_den,
                       phi_aggregated = sl_phi, s = sl_s, contribution = sl_contrib)
)

phi_per_year_per_line <- bind_rows(phi_per_year_per_line, gov_per_year)

# Recompute the aggregations now that gov is included
phi_domar_by_year <- phi_per_year_per_line |>
  group_by(year) |>
  summarise(phi_domar = sum(contribution, na.rm = TRUE), .groups = "drop")

phi_domar_headline <- mean(phi_domar_by_year$phi_domar)

sector_decomp <- phi_per_year_per_line |>
  group_by(go_line, go_label) |>
  summarise(s_avg            = mean(s, na.rm = TRUE),
            phi_agg_avg      = mean(phi_aggregated, na.rm = TRUE),
            contribution_avg = mean(contribution, na.rm = TRUE),
            .groups = "drop") |>
  arrange(desc(contribution_avg))

# ========================================================================
# 9. Report
# ========================================================================
cat(sprintf("\nΦ_Domar headline (%d-year avg %d-%d, denominator = structures only): %.4f (%.2f%%)\n",
            length(PANEL_YEARS), min(PANEL_YEARS), max(PANEL_YEARS),
            phi_domar_headline, 100 * phi_domar_headline))

cat("\n=== Φ_Domar by year ===\n")
print(phi_domar_by_year |> mutate(phi_pct = round(100 * phi_domar, 2)))

cat("\n=== Sector-level decomposition (10-yr avg) ===\n")
print(sector_decomp |> mutate(s_pct = round(100*s_avg, 2),
                              phi_pct = round(100*phi_agg_avg, 2),
                              contrib_pct = round(100*contribution_avg, 3)) |>
      select(go_line, go_label, s_pct, phi_pct, contrib_pct), n = Inf, width = 200)

# Sanity: sum of Domar weights for our included sectors (should be a fraction of total)
total_s <- sector_decomp |> summarise(sum(s_avg)) |> pull()
cat(sprintf("\nΣ s_i for sectors we cover = %.3f  (Hulten note: Σ s for all industries ≈ 1.73)\n", total_s))

# ========================================================================
# 9b. Denominator-choice sensitivity: structures+equipment → lower bound
# ========================================================================
# Per author's call: lower bound uses denominator = structures + equipment
# (smaller ϕ_i^total → smaller Φ_Domar); upper bound = structures only (current
# headline). The two define the headline band; central reported as the upper.

priv_lower <- compute_phi_domar("struct_eq_m_2024")

# Gov side with structures+equipment denominators
gov_lower <- tibble(
  year = PANEL_YEARS,
  fed_num     = gov_fed_num_year$num_m_2024[match(PANEL_YEARS, gov_fed_num_year$panel_year)],
  fed_den     = fed_struct_eq_m_2024,
  fed_phi     = fed_num / fed_den,
  fed_s       = s_fed_year[as.character(PANEL_YEARS)],
  fed_contrib = fed_s * fed_phi,
  sl_num      = gov_sl_num_year$num_m_2024[match(PANEL_YEARS, gov_sl_num_year$panel_year)],
  sl_den      = sl_struct_eq_m_2024,
  sl_phi      = sl_num / sl_den,
  sl_s        = s_sl_year[as.character(PANEL_YEARS)],
  sl_contrib  = sl_s * sl_phi
)

priv_lower_by_year <- priv_lower |>
  group_by(year) |>
  summarise(phi = sum(contribution, na.rm = TRUE), .groups = "drop")

phi_domar_lower_by_year <- priv_lower_by_year |>
  left_join(gov_lower |> transmute(year, gov_phi = fed_contrib + sl_contrib), by = "year") |>
  mutate(phi_domar = phi + coalesce(gov_phi, 0)) |>
  select(year, phi_domar)

phi_domar_lower_headline <- mean(phi_domar_lower_by_year$phi_domar)

cat(sprintf("\nΦ_Domar LOWER bound (denominator = structures + equipment): %.4f (%.2f%%)\n",
            phi_domar_lower_headline, 100 * phi_domar_lower_headline))
cat(sprintf("Φ_Domar UPPER bound (denominator = structures only):        %.4f (%.2f%%)\n",
            phi_domar_headline, 100 * phi_domar_headline))
cat(sprintf("Φ_Domar BAND midpoint:                                       %.4f (%.2f%%)\n",
            (phi_domar_headline + phi_domar_lower_headline)/2,
            100 * (phi_domar_headline + phi_domar_lower_headline)/2))

# ========================================================================
# 10. Cancellation-attribution sensitivity (mirrors compute_phi.R H-4 logic)
# ========================================================================
cancellation_phi <- function(factor_pct) {
  # Returns Φ_Domar (gov-inclusive) under a given cancelled-attribution factor.

  pcs <- read_csv(here("output", "phi_private_by_sector_year.csv"),
                  show_col_types = FALSE)
  # Reload raw cost data to identify cancelled records
  cost <- map_dfr(PANEL_YEARS, function(y) {
    read_csv(here("data", "processed",
                       sprintf("cost_extraction_%d.csv", y)),
             show_col_types = FALSE, col_types = cols(.default = "c")) |>
      mutate(panel_year = y)
  }) |>
    mutate(cost_m_usd_nominal = as.numeric(cost_m_usd_nominal),
           cost_year          = suppressWarnings(as.integer(cost_year)),
           cost_year          = if_else(is.na(cost_year), panel_year, cost_year),
           is_cancelled       = str_detect(coalesce(cost_notes, ""),
                                           regex("cancel", ignore_case = TRUE)),
           defl               = map_dbl(cost_year, defl_factor),
           cost_m_usd_2024    = cost_m_usd_nominal * defl,
           weight             = if_else(is_cancelled, factor_pct / 100, 1))

  funding <- read_csv(here("data", "processed", "funding_source.csv"),
                      show_col_types = FALSE) |>
             mutate(eis_number = as.character(eis_number),
                    naics_code = as.character(naics_code)) |>
             select(panel_year, eis_number, naics_code, funding_source)

  cost <- cost |> left_join(funding, by = c("panel_year","eis_number")) |>
          mutate(share_private = case_when(
            funding_source %in% c("private","tribal") ~ 1.0,
            funding_source == "mixed"                  ~ 0.5,
            TRUE                                       ~ 0.0
          ))

  # Map naics_code to bea_code (same crosswalk used in compute_phi.R; minimal copy)
  naics_to_bea <- tribble(
    ~naics_code, ~bea_code,
    "211","2110","2111","2110",
    "212","2120","2121","2120","2122","2120",
    "213","2130",
    "2211","2211","2212","2212","2213","2213",
    "236","2300","237","2300","237310","2300","238","2300",
    "481","4810","482","4820","483","4830","485","4850",
    "486","4860","487","487S","488","487S","493","4930",
    "713","7130","7132","7130","713210","7130",
    "11","113F","113","113F","1133","113F"
  )
  # Reshape the tribble (it's stored linearly above)
  naics_to_bea <- tibble(
    naics_code = c("211","2111","212","2121","2122","213","2211","2212","2213",
                   "236","237","237310","238","481","482","483","485","486",
                   "487","488","493","713","7132","713210","11","113","1133"),
    bea_code   = c("2110","2110","2120","2120","2120","2130","2211","2212","2213",
                   "2300","2300","2300","2300","4810","4820","4830","4850","4860",
                   "487S","487S","4930","7130","7130","7130","113F","113F","113F")
  )
  cost <- cost |> left_join(naics_to_bea, by = "naics_code")

  # Aggregate weighted private numerator per (bea_code, year)
  cost_agg <- cost |>
    mutate(alloc_2024 = cost_m_usd_2024 * share_private * weight) |>
    group_by(bea_code, panel_year) |>
    summarise(num_m_2024 = sum(alloc_2024, na.rm = TRUE), .groups = "drop") |>
    rename(year = panel_year)

  # Same per-sector denominator + Domar weight as the headline calc
  sy <- crosswalk |>
    inner_join(priv_capex, by = "bea_code", relationship = "many-to-many") |>
    left_join(cost_agg,    by = c("bea_code","year")) |>
    mutate(num_m_2024 = coalesce(num_m_2024, 0))

  # Two-step: collapse BEA codes within (year, go_line) FIRST, then attach Domar s.
  # (Single-step with s in group_by triple-counts when multiple BEA codes share
  # the same go_line — see headline path comment.)
  agg <- sy |>
    group_by(year, go_line, go_label) |>
    summarise(num = sum(num_m_2024, na.rm = TRUE),
              den = sum(struct_m_2024, na.rm = TRUE),   # headline denominator
              .groups = "drop") |>
    mutate(phi_agg = num / den)

  py <- agg |>
    left_join(domar_long, by = c("go_line","go_label","year")) |>
    mutate(contrib = s * phi_agg)

  # Private contribution per year
  priv_per_year <- py |> group_by(year) |> summarise(phi = sum(contrib, na.rm = TRUE),
                                                     .groups = "drop")

  # Gov contribution per year (cancellation factor applies to cancelled records inside gov too)
  cost_gov <- cost |>
    mutate(share_fed = case_when(funding_source == "gov_federal"     ~ 1.0,
                                 funding_source == "mixed"           ~ 0.5,
                                 TRUE                                ~ 0.0),
           share_sl  = case_when(funding_source == "gov_state_local" ~ 1.0,
                                 TRUE                                ~ 0.0))

  gov_fed_n <- cost_gov |>
    mutate(alloc = cost_m_usd_2024 * share_fed * weight) |>
    group_by(panel_year) |> summarise(n = sum(alloc, na.rm = TRUE), .groups = "drop")
  gov_sl_n <- cost_gov |>
    mutate(alloc = cost_m_usd_2024 * share_sl * weight) |>
    group_by(panel_year) |> summarise(n = sum(alloc, na.rm = TRUE), .groups = "drop")

  gov_per_year <- tibble(
    year = PANEL_YEARS,
    fed_contrib = s_fed_year[as.character(PANEL_YEARS)] *
                  (gov_fed_n$n[match(PANEL_YEARS, gov_fed_n$panel_year)] / fed_total_capex_m_2024),
    sl_contrib  = s_sl_year[as.character(PANEL_YEARS)] *
                  (gov_sl_n$n[match(PANEL_YEARS, gov_sl_n$panel_year)] / sl_total_capex_m_2024)
  ) |> mutate(gov_phi = fed_contrib + sl_contrib)

  total_per_year <- priv_per_year |>
    left_join(gov_per_year |> select(year, gov_phi), by = "year") |>
    mutate(phi = phi + coalesce(gov_phi, 0))

  mean(total_per_year$phi)
}

cat("\n=== Cancellation-attribution sensitivity on Φ_Domar ===\n")
cancel_domar <- tibble(
  cancelled_attribution_pct = c(0, 50, 100),
  phi_domar = c(cancellation_phi(0), cancellation_phi(50), cancellation_phi(100))
) |> mutate(phi_pct = round(100 * phi_domar, 3))
print(cancel_domar)

# ========================================================================
# 11. Write outputs
# ========================================================================
out_dir <- here("output")
dir.create(out_dir, showWarnings = FALSE)

write_csv(phi_per_year_per_line, file.path(out_dir, "phi_domar_by_sector_year.csv"))
write_csv(sector_decomp,         file.path(out_dir, "phi_domar_by_sector.csv"))
write_csv(phi_domar_by_year,     file.path(out_dir, "phi_domar_by_year.csv"))
write_csv(cancel_domar,          file.path(out_dir, "phi_domar_cancellation_sensitivity.csv"))
# Headline bounds use the denominator-choice band (per author's preference):
#   lower = structures + equipment denominator
#   upper = structures-only denominator
# (Cancellation sensitivity remains available in phi_domar_cancellation_sensitivity.csv
#  as a separate, narrower band.)
phi_upper_val <- phi_domar_headline              # structures-only
phi_lower_val <- phi_domar_lower_headline        # structures + equipment
phi_mid_val   <- (phi_upper_val + phi_lower_val) / 2
write_csv(tibble(phi_domar_headline = phi_mid_val,
                 phi_domar_lower    = phi_lower_val,
                 phi_domar_upper    = phi_upper_val),
          file.path(out_dir, "phi_domar_headline.csv"))

cat(sprintf("\nWrote 5 Φ_Domar files to %s\n", out_dir))
cat("Done.\n")
