# Cross-year duplicate sweep: identify EIS records that may double-count the
# same underlying project across years (either via Adoption flag, or via
# Draft/Final/Revised-Final cycles spanning years).

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(purrr); library(stringr); library(tidyr)
})

library(here)

years <- 2015:2024
all_cost <- map_dfr(years, function(y) {
  read_csv(here("data", "processed",
                     sprintf("cost_extraction_%d.csv", y)),
           show_col_types = FALSE, col_types = cols(.default = "c")) |>
    mutate(panel_year = y) |>
    select(any_of(c("eis_number", "lead_agency", "state",
                    "cost_m_usd_nominal", "cost_method", "cost_notes", "panel_year")))
}) |>
  mutate(cost_m_usd_nominal = as.numeric(cost_m_usd_nominal))

clf <- read_csv(here("data", "processed", "eis_finals_with_naics.csv"),
                show_col_types = FALSE) |>
       arrange(eis_number, desc(cal_year)) |>
       distinct(eis_number, .keep_all = TRUE) |>
       select(eis_number, title) |>
       mutate(eis_number = as.character(eis_number))

all_cost <- all_cost |> left_join(clf, by = "eis_number")

# Already-flagged duplicates
dups <- all_cost |> filter(cost_method == "duplicate_of_other_eis")
cat(sprintf("=== %d duplicate-flagged records (already known) ===\n", nrow(dups)))

# Normalized title: strip ADOPTION prefix, contact lines, common boilerplate
norm <- function(s) {
  s |> str_to_lower() |>
    str_replace_all("^(adoption|adoption--|adoption ?-- ?)\\s*", "") |>
    str_replace_all("^[\\-]+\\s*", "") |>
    str_replace_all(",.*$", "") |>
    str_replace_all("\\s*review period ends.*$", "") |>
    str_replace_all("\\s*contact:.*$", "") |>
    str_replace_all("\\s*project\\b|final environmental impact statement|environmental impact statement|f?eis|record of decision", "") |>
    str_replace_all("\\s+", " ") |>
    str_trim()
}
all_cost <- all_cost |> mutate(ntitle = norm(title))

cat("\n=== Cross-year title repeats (same normalized title, multiple records) ===\n")
repeats <- all_cost |>
  group_by(ntitle) |>
  filter(n() >= 2, !is.na(ntitle), nchar(ntitle) > 15) |>
  arrange(ntitle, panel_year) |>
  select(ntitle, panel_year, eis_number, lead_agency, cost_method, cost_m_usd_nominal)
print(repeats, n = Inf, width = 240)

# Look for double-counts: same normalized title, ≥2 records with nonzero cost
cat("\n=== Suspected double-counts (same title, multiple nonzero cost entries) ===\n")
double <- all_cost |>
  group_by(ntitle) |>
  filter(n() >= 2, !is.na(ntitle), nchar(ntitle) > 15,
         sum(cost_m_usd_nominal > 0, na.rm = TRUE) >= 2) |>
  arrange(ntitle, panel_year) |>
  select(ntitle, panel_year, eis_number, lead_agency, cost_method, cost_m_usd_nominal)
print(double, n = Inf, width = 240)
