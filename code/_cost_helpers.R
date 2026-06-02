# Shared finalize step for build_cost_provenance_<year>.R scripts.
#
# Every per-year script ends with the same workflow:
#   1. Write data/processed/cost_extraction_<year>.csv
#   2. Print stats (total $B, disclosed %, imputed/reclassified/adoption counts)
#   3. Coverage check against eis_finals_with_naics.csv (i)-records
#   4. Join NAICS and write cost_extraction_<year>_with_naics.csv
#
# Before this helper existed each script had a hand-copied version of those four
# steps with slight stylistic drift (2015-2019 vs 2020 vs 2021-2023 vs 2024).
# Now every year's script ends with a single call: finalize_cost_year(prov, YYYY).

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(here)
})

finalize_cost_year <- function(prov, year) {
  out_csv <- here("data", "processed",
                       sprintf("cost_extraction_%d.csv", year))
  write_csv(prov, out_csv)

  total_cost <- sum(prov$cost_m_usd_nominal, na.rm = TRUE)
  disclosed  <- sum(prov$cost_m_usd_nominal[!prov$imputed], na.rm = TRUE)
  n_imp      <- sum(prov$imputed, na.rm = TRUE)
  n_reclass  <- sum(prov$cost_method == "reclassified_to_ii", na.rm = TRUE)
  n_adopt    <- sum(prov$cost_method == "duplicate_of_other_eis", na.rm = TRUE)
  cat(sprintf("%d: %d records, $%.1fB total, %.1f%% disclosed, %d imputed, %d reclass→ii, %d adoptions\n",
              year, nrow(prov), total_cost / 1000,
              if (total_cost > 0) 100 * disclosed / total_cost else 0,
              n_imp, n_reclass, n_adopt))

  # Coverage check against canonical (i)-records for this year
  input <- read_csv(here("data", "processed", "eis_finals_with_naics.csv"),
                    show_col_types = FALSE) |>
           filter(cal_year == year, category == "i") |>
           arrange(eis_number, desc(cal_year)) |>
           distinct(eis_number, .keep_all = TRUE)
  missing <- setdiff(input$eis_number, prov$eis_number)
  extra   <- setdiff(prov$eis_number, input$eis_number)
  if (length(missing) > 0 || length(extra) > 0) {
    cat(sprintf("  coverage: %d input / %d prov / %d missing / %d extra\n",
                nrow(input), nrow(prov), length(missing), length(extra)))
    if (length(missing) > 0) cat("    missing:", paste(head(missing, 10), collapse = " "), "\n")
  }

  # NAICS-joined output
  naics <- read_csv(here("data", "processed", "eis_finals_with_naics.csv"),
                    show_col_types = FALSE) |>
           arrange(eis_number, desc(cal_year)) |>
           distinct(eis_number, .keep_all = TRUE) |>
           select(eis_number, naics_code, naics_label, naics_reason, title)
  out_naics <- here("data", "processed",
                         sprintf("cost_extraction_%d_with_naics.csv", year))
  write_csv(prov |> left_join(naics, by = "eis_number"), out_naics)

  invisible(prov)
}
