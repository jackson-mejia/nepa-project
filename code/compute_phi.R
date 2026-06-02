# Compute Φ_i — sector-level NEPA exposure ratios.
#
# Φ_i^private = (private-funded EIS-exposed capex by NAICS, 2024$)
#             ÷ (BEA private nonresidential STRUCTURES investment by NAICS, 2024$)
# Φ_federal^gov     = (gov_federal-funded EIS-exposed capex, 2024$)
#                   ÷ (BEA federal gov structures investment, 2024$)
# Φ_state_local^gov = (gov_state_local-funded EIS-exposed capex, 2024$)
#                   ÷ (BEA state-local gov structures investment, 2024$)
#
# Numerator and denominator both deflated to 2024 dollars using BEA Table 1.1.9
# line 10 (Implicit Price Deflator for private nonresidential structures
# investment, 2017=100). User decision: apply the same structures deflator to
# both private and gov sides; they differ by <1 pp/yr in practice.
#
# Mixed-funding records: split 50/50 between private and gov_federal numerators
# (sensitivity check: 70/30 and 30/70 also reported in output/).
# Tribal: folded into private (BIA casinos etc. are tribal equity → private NAICS aggregation).

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(readxl); library(tidyr); library(purrr); library(stringr)
})

library(here)
PANEL_YEARS  <- 2015:2024
BASE_YEAR    <- 2024

# ========================================================================
# 1. Structures deflator (BEA Table 1.1.9 line 10, 2017=100)
# ========================================================================
defl_raw <- read_csv(here("data", "bea", "t119.csv"),
                     skip = 3, show_col_types = FALSE,
                     col_names = c("line", "label", as.character(1929:2025)))
defl_row <- defl_raw |> filter(line == "10")
defl_long <- tibble(
  year = 1929:2025,
  deflator = as.numeric(unlist(defl_row[1, as.character(1929:2025)]))
) |> filter(!is.na(deflator), year >= 1990)
defl_2024 <- defl_long$deflator[defl_long$year == BASE_YEAR]
defl_year_range <- range(defl_long$year)
defl_factor <- function(yr) {
  if (is.na(yr)) return(NA_real_)
  # Clamp cost_year to the available deflator series. Sources sometimes carry
  # cost figures in "as-of-publication" dollars one or two years past the
  # latest deflator data point — clamping is the conservative choice (treats
  # those dollars as already-current).
  yr_clamped <- max(min(yr, defl_year_range[2]), defl_year_range[1])
  d <- defl_long$deflator[defl_long$year == yr_clamped]
  if (length(d) == 0) NA_real_ else defl_2024 / d
}
cat(sprintf("Structures deflator base year %d = %.3f\n", BASE_YEAR, defl_2024))
cat("Sample factors: ", paste(sprintf("%d→%.3f", c(2015,2020,2024),
    sapply(c(2015,2020,2024), defl_factor)), collapse = ", "), "\n\n")

# ========================================================================
# 2. Numerator — cost data + funding source, deflated to 2024$
# ========================================================================
cost <- map_dfr(PANEL_YEARS, function(y) {
  read_csv(here("data", "processed",
                     sprintf("cost_extraction_%d.csv", y)),
           show_col_types = FALSE, col_types = cols(.default = "c")) |>
    mutate(panel_year = y) |>
    select(any_of(c("eis_number","lead_agency","state","cost_m_usd_nominal","cost_year",
                    "cost_method","panel_year")))
}) |>
  mutate(cost_m_usd_nominal = as.numeric(cost_m_usd_nominal),
         cost_year = as.integer(cost_year),
         # If cost_year is NA (rare), fall back to panel_year
         cost_year = if_else(is.na(cost_year), panel_year, cost_year))

funding <- read_csv(here("data", "processed", "funding_source.csv"),
                    show_col_types = FALSE) |>
           mutate(eis_number = as.character(eis_number),
                  naics_code = as.character(naics_code)) |>
           select(panel_year, eis_number, naics_code, funding_source)

cost <- cost |> left_join(funding, by = c("panel_year","eis_number"))

# Deflate. Raise loudly on any NA in the deflated values — a NA here typically
# means a cost_year outside the deflator series range (1929-2025), which would
# silently disappear from the numerator under na.rm=TRUE in the later sum.
# Audit M-5: previously masked by na.rm; now explicit.
cost <- cost |>
  mutate(defl = map_dbl(cost_year, defl_factor),
         cost_m_usd_2024 = cost_m_usd_nominal * defl)
bad_defl <- cost |> filter(is.na(cost_m_usd_2024) & !is.na(cost_m_usd_nominal))
if (nrow(bad_defl) > 0) {
  stop("Deflation produced NA for ", nrow(bad_defl),
       " record(s) with non-NA nominal cost; investigate cost_year out of range. First few: ",
       paste(head(bad_defl$eis_number, 5), collapse = ", "))
}

cat(sprintf("Loaded %d cost records, %d with funding tag\n",
            nrow(cost), sum(!is.na(cost$funding_source))))
cat(sprintf("Total nominal: $%.1fB ; Total 2024$: $%.1fB\n\n",
            sum(cost$cost_m_usd_nominal, na.rm=TRUE)/1000,
            sum(cost$cost_m_usd_2024, na.rm=TRUE)/1000))

# Split mixed 50/50 (private/gov_federal); fold tribal into private
cost <- cost |>
  mutate(
    share_private = case_when(
      funding_source == "private"         ~ 1.0,
      funding_source == "tribal"          ~ 1.0,
      funding_source == "mixed"           ~ 0.5,
      TRUE                                ~ 0.0
    ),
    share_gov_federal = case_when(
      funding_source == "gov_federal"     ~ 1.0,
      funding_source == "mixed"           ~ 0.5,
      TRUE                                ~ 0.0
    ),
    share_gov_state_local = case_when(
      funding_source == "gov_state_local" ~ 1.0,
      TRUE                                ~ 0.0
    )
  )

# ========================================================================
# 3. Private denominator — BEA detailnonres_inv1.xlsx, STRUCTURES total per industry
# ========================================================================
# Each industry sheet has Row 6 = year headers (col 3 = 1901 ... col 126 = 2024).
# Row 48 = "TOTAL STRUCTURES" (label in col 2 = "TOTAL STRUCTURES").
# We extract structures investment for 2015-2024 for each BEA-code sheet.

BEA_FILE <- here("data", "bea", "detailnonres_inv1.xlsx")
bea_sheets <- excel_sheets(BEA_FILE)
industry_sheets <- setdiff(bea_sheets, c("readme", "Datasets"))

read_industry_structures <- function(sheet) {
  d <- suppressMessages(read_excel(BEA_FILE, sheet = sheet, col_names = FALSE,
                                    .name_repair = "minimal"))
  # Years are in row 6 from col 3 onward. Coercing label cells in cols 1-2 to
  # integer produces "NAs introduced by coercion" warnings — benign, suppressed
  # per audit L-4 since the filter() below drops those NA-year columns anyway.
  year_row <- suppressWarnings(as.integer(unlist(d[6, ])))
  # Row 48: TOTAL STRUCTURES
  if (nrow(d) < 48) return(NULL)
  structures <- suppressWarnings(as.numeric(unlist(d[48, ])))
  # Validate row 48 label
  if (!isTRUE(grepl("TOTAL STRUCTURES", d[[2]][48], ignore.case = TRUE))) {
    return(NULL)
  }
  tibble(bea_code = sheet, year = year_row, struct_m_nominal = structures) |>
    filter(!is.na(year), !is.na(struct_m_nominal), year %in% PANEL_YEARS)
}

cat("Reading BEA private structures investment by industry (76 sheets)...\n")
priv_struct <- map_dfr(industry_sheets, read_industry_structures)
cat(sprintf("Loaded %d industry-year structures observations\n", nrow(priv_struct)))

# Deflate
priv_struct <- priv_struct |>
  mutate(defl = map_dbl(year, defl_factor),
         struct_m_2024 = struct_m_nominal * defl)

# ========================================================================
# 4. NAICS → BEA code crosswalk (from BEA readme sheet at row 17+)
# ========================================================================
# Our cost data uses NAICS codes assigned by assign_naics.R. Map to BEA codes:
naics_to_bea <- tribble(
  ~naics_code, ~bea_code,
  "211",      "2110",   # Oil & gas extraction
  "2111",     "2110",
  "212",      "2120",   # Mining ex oil/gas
  "2121",     "2120",
  "2122",     "2120",
  "213",      "2130",   # Mining support
  "2211",     "2211",   # Electric power
  "2212",     "2212",   # Natural gas distribution
  "2213",     "2213",   # Water/sewage
  "236",      "2300",   # Construction (residential buildings)
  "237",      "2300",   # Construction (heavy and civil)
  "237310",   "2300",
  "238",      "2300",
  "481",      "4810",   # Air transportation
  "482",      "4820",   # Rail transportation
  "483",      "4830",   # Water transportation
  "484",      "484",    # Truck transportation (not in our (i) set)
  "485",      "4850",   # Transit and ground passenger
  "486",      "4860",   # Pipeline
  "487",      "487S",   # Scenic & sightseeing
  "488",      "487S",   # Support activities for transportation
  "493",      "4930",   # Warehousing
  "511",      "5110",
  "512",      "5120",
  "513",      "5130",
  "514",      "5140",
  "521",      "5210",
  "522",      "5221",
  "523",      "5223",
  "524",      "524A",
  "525",      "5250",
  "531",      "5310",
  "532",      "5320",
  "541",      "5411",
  "5411",     "5411",
  "5412",     "5412",
  "5415",     "5415",
  "55",       "5500",
  "561",      "5610",
  "562",      "5620",
  "611",      "6100",
  "621",      "6210",
  "622",      "622H",
  "623",      "6230",
  "624",      "6240",
  "711",      "711A",
  "713",      "7130",
  "7132",     "7130",
  "713210",   "7130",   # Casinos / tribal gaming
  "721",      "7210",
  "722",      "7220",
  "81",       "8100",
  "11",       "113F",
  "113",      "113F",
  "1133",     "113F",
)

# ========================================================================
# 5. Government denominators — BEA Table 5.9.5
# ========================================================================
gov_raw <- read_csv(here("data", "bea", "t595.csv"),
                    skip = 3, show_col_types = FALSE,
                    col_names = c("line", "label", as.character(1929:2024)))

gov_line <- function(line_num) {
  row <- gov_raw |> filter(line == as.character(line_num))
  if (nrow(row) == 0) return(NULL)
  tibble(year = 1929:2024,
         value_b_nominal = as.numeric(unlist(row[1, as.character(1929:2024)]))) |>
    filter(!is.na(value_b_nominal), year %in% PANEL_YEARS)
}

# Key gov-investment series (denominators, in $B nominal)
# NB: line numbers are NIPA-table line IDs (col 1 of t595.csv), not file row numbers.
gov_series <- bind_rows(
  gov_line(7)  |> mutate(series = "federal_structures"),
  gov_line(29) |> mutate(series = "state_local_structures"),
  gov_line(40) |> mutate(series = "state_local_highways"),
  gov_line(38) |> mutate(series = "state_local_transportation"),
  gov_line(41) |> mutate(series = "state_local_sewer"),
  gov_line(42) |> mutate(series = "state_local_water"),
  gov_line(12) |> mutate(series = "federal_military_facilities")
) |>
  mutate(value_m_nominal = value_b_nominal * 1000,
         defl = map_dbl(year, defl_factor),
         value_m_2024 = value_m_nominal * defl)

cat(sprintf("Loaded %d gov-series-year observations\n", nrow(gov_series)))

# ========================================================================
# 6. Compute Φ — bucket-level (10-year average + per-year)
# ========================================================================

# 6a. Private bucket aggregate
cost_priv <- cost |>
  mutate(allocated_2024 = cost_m_usd_2024 * share_private) |>
  filter(allocated_2024 > 0) |>
  left_join(naics_to_bea, by = "naics_code")

# Records that didn't map to a BEA code (gov-funded NAICS like 9281, 9241; or
# unmapped); for those we don't have a private NAICS denominator. Drop with note.
unmapped_priv <- cost_priv |> filter(is.na(bea_code))
cat(sprintf("\nPrivate-bucket records with no BEA NAICS match: %d records, $%.1fB 2024$\n",
            nrow(unmapped_priv), sum(unmapped_priv$allocated_2024, na.rm=TRUE)/1000))
if (nrow(unmapped_priv) > 0) {
  print(unmapped_priv |> count(naics_code, wt = allocated_2024, sort = TRUE, name = "m_2024$"))
}

# Per-sector private Φ_i (10-year averages)
priv_num <- cost_priv |> filter(!is.na(bea_code)) |>
  group_by(bea_code, panel_year) |>
  summarise(num_m_2024 = sum(allocated_2024, na.rm=TRUE), .groups = "drop")

priv_den <- priv_struct |>
  rename(panel_year = year) |>
  select(bea_code, panel_year, den_m_2024 = struct_m_2024)

# Join, ensure all denominator industries appear (even if numerator zero).
# The coalesce(., 0) here is intentional: industries with NO NEPA-exposed records
# in a given year should report Φ_i = 0 / denom, not NA. Without this, those rows
# would drop out of the headline sector table.
priv_joined <- priv_den |>
  left_join(priv_num, by = c("bea_code","panel_year")) |>
  mutate(num_m_2024 = coalesce(num_m_2024, 0))

# Per-bea-code 10-yr summary
priv_phi_sector <- priv_joined |>
  group_by(bea_code) |>
  summarise(num_b_2024 = sum(num_m_2024)/1000,
            den_b_2024 = sum(den_m_2024)/1000,
            phi_10yr = num_b_2024 / den_b_2024,
            .groups = "drop") |>
  arrange(desc(phi_10yr))

# Add BEA labels for readability — pull from readme sheet
readme <- suppressMessages(read_excel(BEA_FILE, sheet = "readme",
                                       col_names = FALSE, .name_repair = "minimal"))
bea_labels <- tibble(
  bea_code = unlist(readme[, 2]),
  bea_label = unlist(readme[, 1])
) |> filter(!is.na(bea_code), bea_code != "BEA Code",
            nchar(bea_code) <= 5) |>
  # Strip non-breaking spaces and trim
  mutate(bea_label = str_replace_all(bea_label, "\\s+", " ") |> str_trim())

priv_phi_sector <- priv_phi_sector |> left_join(bea_labels, by = "bea_code")

# 6b. Gov_federal Φ
gov_fed_num <- cost |>
  mutate(allocated_2024 = cost_m_usd_2024 * share_gov_federal) |>
  group_by(panel_year) |>
  summarise(num_m_2024 = sum(allocated_2024, na.rm=TRUE), .groups = "drop")

gov_fed_den <- gov_series |> filter(series == "federal_structures") |>
  select(panel_year = year, den_m_2024 = value_m_2024)

gov_fed_phi <- gov_fed_num |> left_join(gov_fed_den, by = "panel_year") |>
  mutate(phi = num_m_2024 / den_m_2024,
         num_b = round(num_m_2024/1000,2), den_b = round(den_m_2024/1000,2))

# 6c. Gov_state_local Φ
gov_sl_num <- cost |>
  mutate(allocated_2024 = cost_m_usd_2024 * share_gov_state_local) |>
  group_by(panel_year) |>
  summarise(num_m_2024 = sum(allocated_2024, na.rm=TRUE), .groups = "drop")

gov_sl_den <- gov_series |> filter(series == "state_local_structures") |>
  select(panel_year = year, den_m_2024 = value_m_2024)

gov_sl_phi <- gov_sl_num |> left_join(gov_sl_den, by = "panel_year") |>
  mutate(phi = num_m_2024 / den_m_2024,
         num_b = round(num_m_2024/1000,2), den_b = round(den_m_2024/1000,2))

# ========================================================================
# 7. Headline output
# ========================================================================

cat("\n=========================================================\n")
cat("            HEADLINE Φ_i — 10-year averages (2015–2024)\n")
cat("=========================================================\n\n")

# Private — top 15 sectors
cat("── Private (per BEA NAICS industry, structures-investment denominator) ──\n")
priv_phi_sector |>
  filter(num_b_2024 > 0) |>
  head(20) |>
  mutate(phi_pct = round(100 * phi_10yr, 1),
         num_b_2024 = round(num_b_2024,1),
         den_b_2024 = round(den_b_2024,1),
         bea_label = substr(bea_label, 1, 35)) |>
  select(bea_code, bea_label, num_b_2024, den_b_2024, phi_pct) |>
  print(n = Inf)

# Private — aggregate
priv_agg <- priv_joined |>
  summarise(num_b = sum(num_m_2024)/1000, den_b = sum(den_m_2024)/1000) |>
  mutate(phi = num_b / den_b)
cat(sprintf("\n  AGGREGATE private (sum of mapped sectors, 10-yr):  num=$%.0fB  den=$%.0fB  Φ_avg=%.1f%%\n",
            priv_agg$num_b, priv_agg$den_b, 100*priv_agg$phi))

# Gov federal
cat("\n── Gov_federal (federal-budget capex / BEA federal structures investment) ──\n")
print(gov_fed_phi |> mutate(phi_pct = round(100*phi,1)) |>
        select(panel_year, num_b, den_b, phi_pct), n = Inf, width = 100)
gov_fed_agg <- gov_fed_phi |>
  summarise(num_b = sum(num_m_2024)/1000, den_b = sum(den_m_2024)/1000) |>
  mutate(phi = num_b / den_b)
cat(sprintf("  AGGREGATE gov_federal 10-yr:  num=$%.1fB  den=$%.1fB  Φ_avg=%.1f%%\n",
            gov_fed_agg$num_b, gov_fed_agg$den_b, 100*gov_fed_agg$phi))

# Gov state-local
cat("\n── Gov_state_local (state-local capex / BEA state-local structures investment) ──\n")
print(gov_sl_phi |> mutate(phi_pct = round(100*phi,1)) |>
        select(panel_year, num_b, den_b, phi_pct), n = Inf, width = 100)
gov_sl_agg <- gov_sl_phi |>
  summarise(num_b = sum(num_m_2024)/1000, den_b = sum(den_m_2024)/1000) |>
  mutate(phi = num_b / den_b)
cat(sprintf("  AGGREGATE gov_state_local 10-yr:  num=$%.1fB  den=$%.1fB  Φ_avg=%.1f%%\n",
            gov_sl_agg$num_b, gov_sl_agg$den_b, 100*gov_sl_agg$phi))

# ========================================================================
# 8. Sensitivities on mixed-bucket split
# ========================================================================
mixed_share_sens <- function(pct_to_private) {
  c <- cost |>
    mutate(sp = case_when(funding_source %in% c("private","tribal") ~ 1.0,
                          funding_source == "mixed" ~ pct_to_private/100,
                          TRUE ~ 0.0),
           sf = case_when(funding_source == "gov_federal" ~ 1.0,
                          funding_source == "mixed" ~ (100-pct_to_private)/100,
                          TRUE ~ 0.0))
  priv_num_b <- sum(c$cost_m_usd_2024 * c$sp, na.rm=TRUE) / 1000
  fed_num_b  <- sum(c$cost_m_usd_2024 * c$sf, na.rm=TRUE) / 1000
  tibble(pct_to_private = pct_to_private,
         priv_num_b = priv_num_b,
         fed_num_b  = fed_num_b)
}
sens <- bind_rows(mixed_share_sens(50),
                  mixed_share_sens(70),
                  mixed_share_sens(30))
cat("\n── Mixed-bucket allocation sensitivity (10-yr numerator $B 2024) ──\n")
print(sens)

# Cancelled-project sensitivity (audit H-4). Identify cancelled records by
# scanning cost_notes for "cancel" stem. Report Φ_private under 0% / 50% / 100%
# attribution of cancelled-project capex.
cancelled_ids <- map_dfr(PANEL_YEARS, function(y) {
  read_csv(here("data", "processed",
                     sprintf("cost_extraction_%d.csv", y)),
           show_col_types = FALSE, col_types = cols(.default = "c")) |>
    filter(str_detect(coalesce(cost_notes, ""), regex("cancel", ignore_case = TRUE))) |>
    select(eis_number) |>
    mutate(panel_year = y)
})

priv_num_cancel_factor <- function(factor_pct) {
  c <- cost |>
    mutate(allocated_2024 = cost_m_usd_2024 * share_private,
           is_cancelled = paste(panel_year, eis_number) %in%
                          paste(cancelled_ids$panel_year, cancelled_ids$eis_number),
           adj_2024 = if_else(is_cancelled, allocated_2024 * factor_pct / 100, allocated_2024))
  sum(c$adj_2024, na.rm = TRUE) / 1000  # $B
}

cancel_sens <- tibble(
  cancelled_attribution_pct = c(0, 50, 100),
  priv_num_b = c(priv_num_cancel_factor(0),
                 priv_num_cancel_factor(50),
                 priv_num_cancel_factor(100))
) |> mutate(priv_phi_pct = round(100 * priv_num_b / priv_agg$den_b, 2))

cat("\n── Cancelled-project capex sensitivity (private bucket, 10-yr 2024$) ──\n")
print(cancel_sens)
cancel_total_b <- sum(cost$cost_m_usd_2024[paste(cost$panel_year, cost$eis_number) %in%
                      paste(cancelled_ids$panel_year, cancelled_ids$eis_number)],
                      na.rm = TRUE) / 1000
priv_total_2024 <- sum(cost$cost_m_usd_2024 * cost$share_private, na.rm = TRUE) / 1000
cat(sprintf("  (%d records flagged cancelled, $%.1fB 2024$ at full attribution = %.1f%% of private numerator)\n",
            nrow(cancelled_ids), cancel_total_b, 100 * cancel_total_b / priv_total_2024))

# ========================================================================
# 9. Write output files
# ========================================================================
dir.create(here("output"), showWarnings = FALSE)
write_csv(priv_phi_sector, here("output", "phi_private_by_sector.csv"))
write_csv(priv_joined,     here("output", "phi_private_by_sector_year.csv"))
write_csv(gov_fed_phi,     here("output", "phi_gov_federal_by_year.csv"))
write_csv(gov_sl_phi,      here("output", "phi_gov_state_local_by_year.csv"))
write_csv(sens,            here("output", "phi_mixed_sensitivity.csv"))
write_csv(cancel_sens,     here("output", "phi_cancellation_sensitivity.csv"))

cat("\nWrote 6 output files to /output/\n")
cat("Done.\n")
