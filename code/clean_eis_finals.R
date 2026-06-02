# Take the raw EIS records (drafts + finals + supplements) and produce a
# clean baseline of completed primary EISs — one row per project.
#
# Decisions:
#   * Keep primary completed EISs: document_type %in% c("Final", "Final EIS").
#     "Final EIS" is the older convention used in some years for the same thing.
#     Drop "Draft" (avoids double-counting each project with its draft entry).
#     Drop all "Supplement" variants (additional review work on already-finished projects;
#     they re-expose a fraction of the project but not new capex).
#     Drop "Revised Final" (same project being re-reviewed; its original Final is already in).
#     Drop "Adoption" (agency adopts another agency's EIS — would double-count).
#   * Add derived fields: calendar year and federal fiscal year (from FR pub date).
#
# Output: data/processed/eis_finals_2015-2024.csv

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(lubridate)
})

library(here)
RAW   <- here("data", "raw",       "eis_records_2015-2024.csv")
PROC  <- here("data", "processed", "eis_finals_2015-2024.csv")
dir.create(dirname(PROC), recursive = TRUE, showWarnings = FALSE)

raw <- read_csv(RAW, show_col_types = FALSE)
cat(sprintf("Raw records: %d\n", nrow(raw)))

# Inspect document_type distribution before filter
cat("\nDocument type breakdown:\n")
print(raw |> count(document_type, sort = TRUE), n = Inf)

finals <- raw |>
  filter(document_type %in% c("Final", "Final EIS")) |>
  mutate(
    document_type = "Final",   # normalize the two synonyms
    fr_date     = as.Date(source_fr_date),
    cal_year    = year(fr_date),
    # Federal FY: Oct 1, year-1 through Sep 30, year
    fiscal_year = if_else(month(fr_date) >= 10L, cal_year + 1L, cal_year)
  ) |>
  arrange(fr_date, eis_number)

cat(sprintf("\nFinals after filter: %d\n", nrow(finals)))

# Sanity: per-year counts (CY)
cat("\nFinals by calendar year:\n")
print(finals |> count(cal_year), n = Inf)

cat("\nFinals by federal fiscal year:\n")
print(finals |> count(fiscal_year), n = Inf)

# Save
write_csv(finals, PROC)
cat(sprintf("\nWrote %d records to %s\n", nrow(finals), PROC))
