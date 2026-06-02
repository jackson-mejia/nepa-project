# Master pipeline runner — reconstruct the entire numerator from raw sources.
#
# Usage:
#   Rscript run_pipeline.R [--from STAGE] [--to STAGE]
#
# Stages (in order):
#   fetch     — pull weekly EPA NOAs from Federal Register API → data/raw/eis_records_2015-2024.csv
#   clean     — filter to Final EIS → data/processed/eis_finals_2015-2024.csv
#   classify  — assign category (i)/(ii)/(iii) → data/processed/eis_finals_classified.csv
#   naics     — assign NAICS sector → data/processed/eis_finals_with_naics.csv
#   cost      — run all 10 build_cost_provenance_<year>.R scripts → data/processed/cost_extraction_<year>.csv
#   dup       — cross-year duplicate sweep diagnostic (no writes; reports double-counts)
#   funding   — assign funding_source per record → data/processed/funding_source.csv
#   phi       — compute Φ_i (private + gov_federal + gov_state_local) → output/phi_*.csv
#   domar     — Domar-weighted Φ headline + sensitivities → output/phi_domar_*.csv
#   gains     — Table 1 (steady-state $ and % gains, dL=1)  → output/aggregate_gains.csv
#   transition — solve time-to-build transition path        → output/transition_path.{csv,png}
#   plot      — per-sector ϕ_i bar chart (Figure 1)         → output/sector_exposure.png
#
# Defaults: run all stages from `fetch` to `plot`.
#
# Notes:
#   - The `fetch` stage hits the Federal Register API (~30 weekly NOAs × 10 years ≈ 520 requests; ~10-15 min).
#   - The `cost` stage produces the year-level CSVs that hold the manually-extracted
#     cost figures with full provenance. These are NOT regenerated from a search;
#     they are explicit data baked into each build_cost_provenance_<year>.R script.
#     Re-running them is cheap (a few seconds total).

suppressPackageStartupMessages(library(here))

STAGES <- c("fetch", "clean", "classify", "naics", "cost", "dup", "funding", "phi",
            "domar", "gains", "transition", "plot")
SCRIPTS <- list(
  fetch      = "code/fetch_eis_fr.R",
  clean      = "code/clean_eis_finals.R",
  classify   = "code/classify_eis.R",
  naics      = "code/assign_naics.R",
  cost       = sprintf("code/build_cost_provenance_%d.R", 2015:2024),
  dup        = "code/dup_sweep.R",
  funding    = "code/assign_funding_source.R",
  phi        = "code/compute_phi.R",
  domar      = "code/compute_domar.R",
  gains      = "code/compute_aggregate_gains.R",
  transition = "code/nepa_transition.R",
  plot       = "code/plot_sector_exposure.R"
)

# Parse args (use a tiny inline parser to avoid optparse dep just for two flags)
args <- commandArgs(trailingOnly = TRUE)
from_idx <- which(args == "--from")
to_idx   <- which(args == "--to")
from_stage <- if (length(from_idx)) args[from_idx + 1] else STAGES[1]
to_stage   <- if (length(to_idx))   args[to_idx + 1]   else STAGES[length(STAGES)]

if (!from_stage %in% STAGES) stop("Unknown --from stage: ", from_stage)
if (!to_stage   %in% STAGES) stop("Unknown --to stage: ", to_stage)
if (which(STAGES == from_stage) > which(STAGES == to_stage))
  stop("--to (", to_stage, ") must be at or after --from (", from_stage, ") in the pipeline order. ",
       "Order: ", paste(STAGES, collapse = " → "))

run_stages <- STAGES[which(STAGES == from_stage):which(STAGES == to_stage)]
cat(sprintf("Pipeline: %s → %s\n\n", from_stage, to_stage))

run_one <- function(path) {
  cat(sprintf("[%s] sourcing %s\n", format(Sys.time(), "%H:%M:%S"), path))
  source(here(path), echo = FALSE)
  cat("\n")
}

for (s in run_stages) {
  paths <- SCRIPTS[[s]]
  for (p in paths) run_one(p)
}

cat("=== Pipeline complete ===\n")
