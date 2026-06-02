# NEPA Exposure Measure (Φ_i)

Companion code for the AFPI working paper on aggregate effects of NEPA reform.

Constructs a per-sector NEPA review exposure measure
$$\Phi_i = \frac{\text{annual capex of sector }i\text{ exposed to NEPA Final EIS review}}{\text{sectoral fixed investment in BEA private nonresidential structures for }i}$$
from public sources, with a parallel construction for government-funded capex.

Methodology and validation checks: see [`notes/methodology.md`](notes/methodology.md).

## Repo layout

```
nepa_project/
├── code/                          # All R scripts
│   ├── fetch_eis_fr.R             # Pull weekly NOAs from Federal Register API
│   ├── clean_eis_finals.R         # Filter to Final EIS only
│   ├── classify_eis.R             # Rule-based (i)/(ii)/(iii) classifier
│   ├── assign_naics.R             # Per-record NAICS assignment
│   ├── build_cost_provenance_<year>.R  # 10 year-level cost CSVs with full provenance (one per cal_year 2015–2024)
│   ├── dup_sweep.R                # Cross-year duplicate detection diagnostic
│   └── assign_funding_source.R    # Tag each record as private / gov_federal / gov_state_local / mixed / tribal
├── data/
│   ├── raw/                       # Federal Register API outputs (regenerable)
│   ├── processed/                 # Built CSVs (regenerable from /code)
│   └── bea/                       # BEA fixed-asset workbooks + structures deflator
├── notes/
│   └── methodology.md             # Step-by-step methodology + validation log
├── output/                        # Final Φ_i tables and any figures
├── run_pipeline.R                 # Master runner (sources scripts in order)
├── DESCRIPTION                    # Package metadata (used by renv for discovery)
├── renv.lock                      # Pinned R package versions for replication
├── nepa_project.Rproj             # RStudio project
└── .Rprofile                      # Auto-activates renv on session start
```

## Replicating

You need: R 4.3+ and an internet connection (for the `fetch` stage).

```bash
# 1. Clone / unzip the repo, cd into it.
cd nepa_project

# 2. Open in RStudio (double-click nepa_project.Rproj) OR start R in this directory.
#    .Rprofile will auto-bootstrap renv.

# 3. Restore the exact package versions from the lockfile.
Rscript -e 'renv::restore()'

# 4. Run the full pipeline (fetch → classify → cost extraction → dup sweep → funding tag).
Rscript run_pipeline.R

# Or run individual stages:
Rscript run_pipeline.R --from cost --to funding   # skip the API pull, rebuild from existing raw
Rscript run_pipeline.R --from dup --to dup        # just the diagnostic
```

The full pipeline takes ~15 minutes (most of which is the `fetch` stage hitting the Federal Register API). Re-runs that skip `fetch` complete in under a minute.

## Outputs

After a clean pipeline run, the key files in `data/processed/` are:

| File | What |
|---|---|
| `eis_records_2015-2024.csv` | Raw EIS list from Federal Register (2,725 rows, all entry types) |
| `eis_finals_2015-2024.csv` | Filtered to Final / Final EIS only (1,124 rows) |
| `eis_finals_classified.csv` | Adds `category` (i/ii/iii) and `category_reason` |
| `eis_finals_with_naics.csv` | Adds `naics_code`, `naics_label`, `naics_reason` |
| `cost_extraction_<year>.csv` | Per-year cat-(i) records with full provenance (URL, quote, confidence, imputation basis) |
| `cost_extraction_<year>_with_naics.csv` | Same, joined with NAICS labels |
| `funding_source.csv` | Per-record tag: private / gov_federal / gov_state_local / mixed / tribal |

The cost-extraction CSVs are the heart of the numerator. Each row carries:
- `cost_m_usd_nominal` — the project capex in nominal millions USD
- `cost_method` — `web` (high-confidence direct quote), `web_imputed` (derived from quote), `pdf`, `sector_impute_pending` (sector median), `duplicate_of_other_eis` (cross-year adoption), `reclassified_to_ii` (operational/programmatic after closer look)
- `cost_source_url`, `cost_source_title`, `cost_quote` — provenance for direct-hit records
- `imputed` (TRUE/FALSE) and `imputation_basis` for the rest
- `cost_notes` — any caveats or corrections

## Data provenance

| Source | Used for | Access |
|---|---|---|
| [Federal Register API](https://www.federalregister.gov/developers/documentation/api/v1) | Master EIS list (numerator records) | Free, no auth |
| Web search (news / agency press / SEC) | Per-project cost figures | Manual; quotes captured per row in cost CSVs |
| [BEA Table 1.1.9](https://apps.bea.gov/iTable/?reqid=19&step=4&isuri=1&categories=flatfiles) | Implicit price deflator for structures investment | `data/bea/t119.csv` (committed) |
| [BEA Fixed Assets Tables](https://apps.bea.gov/iTable/?reqid=10) | Private nonresidential investment + capital stock by NAICS | `data/bea/detailnonres_inv1.xlsx`, `detailnonres_stk2.xlsx` (committed) |

## Replication notes

- The pipeline is **deterministic** given a fixed `data/raw/` snapshot. Re-running `fetch` later may include new records as the FR API is updated; for paper-level replication use the committed `data/raw/eis_records_2015-2024.csv`.
- Cost figures are **point-in-time as of mid-2026**. Where projects have since had cost overruns or cancellations, the `cost_year` field records the vintage of the source quote.
- The classifier and NAICS assigner are **fully rule-based** (no ML, no manual per-record overrides in those scripts except for a 2-record FRA Tier-1 list). The cost-extraction scripts contain hand-curated per-project rows by design — the provenance schema lets you audit every value.

## Citing

Mejia, Jackson. "Aggregate Effects of NEPA Reform." America First Policy Institute working paper, 2026.
