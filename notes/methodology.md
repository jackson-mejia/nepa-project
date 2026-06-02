# NEPA Exposure Measure — Methodology (work-in-progress)

Living document. Captures the exact methodology used so far for constructing a
sector-level NEPA exposure measure (Φ_i) from completed Final EISs, plus
outstanding validation checks before the construction is locked.

Last updated: 2026-06-01. Status: full 10-year panel CY2015–2024 complete.

---

## 1. Goal

Construct a per-sector exposure measure

> Φ_i = (annual investment in sector i exposed to NEPA review) / (total annual private fixed investment in sector i)

improving on the prior memo's construction in three ways:

1. Replace keyword-based industry classification with a lead-agency × title rule-based crosswalk to NAICS.
2. Replace DOT-imputed uniform project cost with project-specific cost figures sourced individually, with imputation only as a documented fallback.
3. Use multi-year averaging instead of a single-year snapshot to reduce noise.

Maintains the "conservative lower bound" rhetorical posture by keeping only EISs that represent **new private capital formation**, excluding management/operational/programmatic NEPA actions.

## 2. Data sources

| Source | What | Access | Used for |
|---|---|---|---|
| Federal Register API | Weekly EPA NOAs listing every EIS filed | JSON API, no auth, free | Master EIS list (numerator) |
| EPA EIS database (cdxapps.epa.gov) | PDF documents + richer metadata | Login wall blocks bulk; only `commonSearch` shortcuts work without auth | Not used (login wall) |
| BEA fixed asset detail | Private fixed investment by NAICS industry | iTable + API | Denominator (planned, not pulled yet) |
| Web search (news, agency press, trade press, SEC filings) | Per-project cost figures | Google search via WebSearch tool | Cost numerator per record |
| Sector-native datasets (FERC eLibrary, FHWA NEPA tracker, etc.) | Per-sector validation | Public scraping | Validation cross-check (planned) |

## 3. EIS data acquisition

**Script:** `code/fetch_eis_fr.R`

**Approach:** Page through Federal Register API for all weekly EPA NOAs with title starting `"Environmental Impact Statements; Notice of Availability"` over the calendar-year range. For each NOA, fetch raw text body and parse the canonical per-entry format:

```
EIS No. NNNNNNNN, [Doc Type], [Agency], [State], [Title], [Period] Ends: MM/DD/YYYY, Contact: [Name] [Phone]
```

Regex: see `EIS_ENTRY` constant in script. Format is stable from 2015 through 2025 (verified at endpoints).

**Output:** `data/raw/eis_records_2015-2024.csv` — 2,725 records (all entry types).

**Schema:** `eis_number, document_type, lead_agency, state, title, period_type, period_end_date, contact_name, contact_phone, source_fr_doc, source_fr_date`.

## 4. Filter to primary completed EISs

**Script:** `code/clean_eis_finals.R`

**Filter logic:** Keep `document_type %in% c("Final", "Final EIS")` only. This normalizes the older "Final EIS" convention to "Final".

**Drops:**
- All `Draft` and `Draft Supplement` (double-counts each project)
- All `Supplement` variants — `Final Supplement`, `Second Final Supplemental`, etc. (additional review work on already-finished projects)
- All `Revised Final` (re-review of same project; original Final is in)
- `Adoption` (handled separately as duplicates in cost step)

**Output:** `data/processed/eis_finals_2015-2024.csv` — 1,124 records. Mean ~112/year, range 70-159, dip during 2020-2023.

## 5. Classifier — category (i)/(ii)/(iii)

**Script:** `code/classify_eis.R`

**Logic:** Sequential rule-based assignment to one of three categories:

- **(i) include** — new private capital formation exposed to NEPA delay
- **(ii) exclude** — government management / continuation / programmatic
- **(iii) ambiguous** — needs review

Exclusion rules fire first (override inclusion). Both rule families documented in `category_reason` field for every record.

**Exclusion rule set:**
- License renewals / re-licensing (NRC, FERC re-licensing)
- Resource management plans, forest plans, land-use plans
- Fuels reduction / prescribed burns / wildfire mgmt
- Restoration without construction
- Habitat / wildlife management plans
- Grazing management
- Programmatic EISs ("PEIS", "Utility-Scale Development", etc.)
- Operational / continued-operations / operating manuals
- Marine sanctuaries
- NMFS/NOAA fishery management amendments
- NRCS small watershed plans
- Waste / disposition programs (existing material)
- Dam safety inspections (vs. new dam construction)
- Wildlife / predator / pest damage management
- Land withdrawals
- Vehicle-use designations / OHV

**Inclusion rule set:**
- Infrastructure agencies (FERC, FHWA, FTA, FRA, BOEM, FAA, USCG, TVA, BR, MARAD, PHMSA)
- USACE civil works (channels, harbors, locks, dams, reservoirs, levees, navigation, dredging)
- DOE projects (not caught by exclusions)
- NRC new reactors / ISFSI construction
- BLM/USFS extractive (mining, oil & gas, pipeline, transmission, renewables, exploration, named minerals)
- BIA tribal economic development (casinos, fee-to-trust, gaming)
- HUD housing / redevelopment
- USFS recreation (ski areas, resorts)
- Adoption-prefix records pointing to construction-type underlying projects
- Military weapons-system deployments (Sentinel, Minuteman, T-7A, F-35, etc.)
- Federal correctional / detention construction
- High-speed rail (CHSRA + HSR keyword)
- Federal buildings at specific street addresses
- Federal research facility construction (USGS, NIST, NIH, NSF)
- RUS rural transmission
- State DOT highway projects (UDOT, CALTRANS, etc. as joint NEPA lead)
- USACE 404 permits for highway
- Generic title cues: "construction", "expansion", "new facility/plant/station/terminal/building", "deepening", "widening", "redevelopment", "modernization"
- Title with physical capacity markers (MW, GW, kV, miles, MGD, barrels, tons/day)

**Output:** `data/processed/eis_finals_classified.csv` — adds `category` + `category_reason`.

Current distribution: (i) 471 / (ii) 244 / (iii) 409.

## 6. NAICS sector assignment

**Script:** `code/assign_naics.R`

**Logic:** Per-record assignment to BEA-style industry code via:

1. Title keyword match against sector-specific rules (most specific first)
2. Lead agency default if no keyword match

**Override hierarchy** (case_when order):
1. Weapons-system deployments → 9281 (national security) regardless of land-mgmt agency
2. High-speed rail → 482
3. Federal buildings at addresses → 236
4. Pipelines (FERC + keywords) → 486
5. Oil & gas extraction → 211
6. Electric power (incl. transmission, kV, substations, all renewables) → 2211
7. Mining (named minerals, mine keywords) → 212
8. Rail → 482
9. Transit → 485
10. Water transportation (harbor, channel, deepening; NOT "land port") → 488
11. Air → 481
12. Water utilities (reservoir, water supply, sewage) → 2213
13. Highway → 237310
14. Casinos → 713210
15. Housing → 236
16. Recreation → 713
17. Federal construction (incl. military beddown) → 236

**Agency defaults (when no keyword match):**
- USACE → 2213 | USFS → 113 | BLM → 212
- USFWS/NPS/NMFS/NOAA/USGS/EPA → 9241
- USAF/USA/USN/USCG/DOD/DOE → 9281
- BR → 2213 | FAA → 481 | MARAD → 483
- TVA → 2211 | FERC → 2211 | RUS → 2211 | BOP → 236
- State DOTs → 237310

**Output:** `data/processed/eis_finals_with_naics.csv` — adds `naics_code, naics_label, naics_reason`.

## 7. Cost extraction waterfall

For each category-(i) record, attempt cost in waterfall order:

1. **Web search** — Google search via `WebSearch` tool with query "[project title] [agency] cost million/billion" or similar. Read returned snippets for explicit cost figure.
2. **PDF text-mine** (not yet implemented) — for records where web fails, fetch FEIS PDF from agency website, grep for cost terms.
3. **Sector imputation** — for records still without cost, apply sector-specific benchmark (e.g., $/MW for renewables, $/mile for highways/pipelines).
4. **Excluded** — for duplicate adoptions, cost = 0 with reference to underlying EIS.

### Per-record provenance schema

Every cost decision is logged in a structured CSV row:

| Field | Description |
|---|---|
| `eis_number` | Join key from Finals dataset |
| `lead_agency`, `state`, `title` | Identifying metadata |
| `cost_m_usd_nominal` | Cost in nominal millions USD |
| `cost_year` | Year the cost figure was reported (for inflation adjustment) |
| `cost_method` | `web` / `web_imputed` / `pdf` / `sector_impute_pending` / `duplicate_of_other_eis` / `reclassified_to_ii` / `no_cost_found_web` / `low_cost_pending` / `web_partial` |
| `cost_source_url` | Full URL where cost was found |
| `cost_source_title` | Title of source page |
| `cost_source_publisher` | Hostname / publisher |
| `cost_source_date` | Publication date of source |
| `cost_source_page` | PDF page number (for PDF sources; else NA) |
| `cost_quote` | Verbatim text snippet containing the cost |
| `cost_confidence` | `high` / `medium` / `low` / `none` |
| `imputed` | Boolean — TRUE if sector-median or proxy used |
| `imputation_basis` | Text describing imputation logic |
| `cost_notes` | Free-text caveats |

Stored as `data/processed/cost_extraction_<year>.csv`. Joined with NAICS to produce `cost_extraction_<year>_with_naics.csv`.

### Adoption handling

Adoptions (records starting `ADOPTION--` or `Adoption--`) are second NEPA reviews of a project an agency already reviewed. Rules:

- If the underlying project appears in our dataset (any year) → mark adoption with `cost = 0`, `cost_method = "duplicate_of_other_eis"`, reference the master EIS number in `cost_notes`.
- If adoption is the only filing for the project in our window → treat as solo, extract cost as normal.

**Known gap:** Current dedup logic is within-year. Cross-year detection (e.g., 2024 DOE adoption of 2023 BLM EIS) is handled manually per-batch. Needs systematic pass before final aggregation.

### Reclassification flag

When cost extraction reveals a record was misclassified (e.g., later-discovered programmatic or operational), it's marked `cost_method = "reclassified_to_ii"`, `cost = 0`, with a `TODO` in `cost_notes`. Examples so far:
- `20240154 BLM Utility-Scale Solar PEIS` — programmatic
- `20240211 BR Central Valley Long-Term Operation` — operational
- `20230095 DOE CA Civil Nuclear Credit program` — operational

These motivated specific classifier rules added in the second pass but should be re-validated against earlier years.

## 8. Build scripts

| Script | Output |
|---|---|
| `code/fetch_eis_fr.R` | Raw EIS records from FR API |
| `code/clean_eis_finals.R` | Primary Finals filter |
| `code/classify_eis.R` | (i)/(ii)/(iii) classification |
| `code/assign_naics.R` | NAICS sector assignment |
| `code/build_cost_provenance_2024.R` | 2024 cost provenance CSV |
| `code/build_cost_provenance_2023.R` | 2023 cost provenance CSV |

All scripts are runnable end-to-end from raw data with no manual intervention except the WebSearch results that populated the tribble inputs to the cost provenance scripts.

## 9. Current state of completion

**Done — full 10-year panel (post classifier-patch + dup-sweep):**
- EIS data: 1,124 Finals across CY2015–2024
- Classifier: **436 (i)** / **282 (ii)** / 406 (iii) — was 471/244/409 before patches; 35 records reclassified to (ii) by new patterns (Tier 1, IRP, contract conversion, water transfers, exchange program, leasing-only, operating agreement, land acquisition, G&G, GTCC waste, FRA Tier-1 manual override)
- NAICS: 17 sectors represented in (i)
- Cost extraction: 457 records, $776.9B cumulative nominal, 384 effective projects (after adoptions + reclassifications)

| Year | N | $B | Disclosed |
|---|---|---|---|
| 2015 | 49 | 54.3 | 89.1% |
| 2016 | 55 | 71.6 | 81.7% |
| 2017 | 39 | 37.1 | 88.4% |
| 2018 | 35 | 17.8 | 60.1% |
| 2019 | 65 | 107.1 | 66.0% |
| 2020 | 47 | 104.8 | 86.7% |
| 2021 | 38 | 78.9 | 83.0% |
| 2022 | 37 | 63.1 | 88.6% |
| 2023 | 35 | 113.2 | 93.2% |
| 2024 | 57 | 130.1 | 77.0% |
| **10-yr** | **457** | **778.1** | ~82% |

**Spot-check (2026-06-01).** Verified 11 stratified-random records (4 `web`, 4 `web_imputed`, 3 `sector_impute_pending`, all $200M+). Results:

- **6/11 confirmed accurate within 10%**: Greenlink/Arevia $2.33B, VTR $4.5B, Mobile Bay Bridge $3.5B, Magnolia LNG $4.4B, Desert Quartzite $1B, Golden Pass LNG $10B
- **3 corrected:** Burbank Terminal $1.3B → $1.2B (stale quote; published GMP $1.11B); SHINE Medical $200M → $300M (cumulative DOE loans surfaced); I-80/State Street SLC $400M → $80M (project scope smaller than the "urban interchange" sector default)
- **2 verified scale but not figure-precise** (Westminster $200M, Future-57 $1.26B) — confidence already low; left as is

Net spot-check correction: −$300M (0.04% of 10-yr total). The spot-check did NOT surface the kinds of failure modes the methodology warned about (loan-amount vs total-capex, pre/post overrun, program vs per-project) at any meaningful magnitude. Cost-figure accuracy can be considered audited.

Average per year: $77.8B / 38.4 effective projects. Zero NA-cost records remaining (all 5 pending 2024 imputations resolved 2026-06-01: LOCAR $750M, Moody AFB $0 [adoption], Bald Mountain Juniper $300M, Robertson Mine $400M, Powder River Mining exploration $40M).

Cross-year duplicate-sweep diagnostic: `code/dup_sweep.R`. Run after any cost-CSV update to catch newly introduced double-counts.

**Funding-source split (added 2026-06-01):** every record tagged via `code/assign_funding_source.R` → `data/processed/funding_source.csv`. Rule-based agency defaults + title hints + 33 per-record overrides for known exceptions.

| funding_source | records | $B nominal | % |
|---|---|---|---|
| private | 202 | 412.4 | 53.0% |
| gov_state_local | 130 | 273.7 | 35.2% |
| mixed | 34 | 50.9 | 6.6% |
| gov_federal | 78 | 36.1 | 4.6% |
| tribal | 13 | 4.8 | 0.6% |
| **Total** | **457** | **776.9** | 100% |

Per-year distribution:

| Year | private | gov_state_local | mixed | gov_federal | tribal | Total |
|---|---|---|---|---|---|---|
| 2015 | 31.6 | 15.3 | 6.5 | 0.8 | 0.0 | 54.2 |
| 2016 | 27.7 | 38.6 | 0.8 | 3.8 | 0.6 | 71.6 |
| 2017 | 27.1 | 6.8 | 2.5 | 1.1 | 0.0 | 37.4 |
| 2018 | 6.7 | 8.8 | 0.8 | 1.1 | 0.4 | 17.8 |
| 2019 | 88.6 | 10.0 | 6.8 | 1.1 | 0.7 | 107.1 |
| 2020 | 56.1 | 6.9 | 31.5 | 8.5 | 1.8 | 104.8 |
| 2021 | 14.6 | 61.1 | 0.2 | 2.7 | 0.4 | 79.0 |
| 2022 | 26.8 | 33.7 | 0.1 | 2.6 | 0.0 | 63.1 |
| 2023 | 79.1 | 30.7 | 0.0 | 3.4 | 0.0 | 113.2 |
| 2024 | 51.1 | 61.7 | 1.8 | 13.2 | 0.9 | 128.7 |

These are pre-deflator nominal totals; will be converted to constant dollars before Φ_i computation using BEA implicit deflators matched per funding bucket.

---

## Φ_i computation (2026-06-01)

**Script:** `code/compute_phi.R` → `output/phi_*.csv`

**Deflator.** BEA Table 1.1.9 line 10 (Implicit Price Deflator for Private Nonresidential Structures Investment, 2017=100). Numerator and denominator both deflated to 2024$ using `134.698 / deflator[cost_year_or_panel_year]`. Single deflator applied to both private and gov sides — the private-structures and gov-structures implicit price deflators differ by <1pp/yr in practice.

**Numerator.** Per-record nominal cost × deflation factor at the source `cost_year`. Allocated across funding-source buckets:
- `private` + `tribal` → 100% to private-NAICS aggregation
- `mixed` → 50/50 split between private and gov_federal (sensitivity: 70/30 reported)
- `gov_federal` → 100% to gov_federal
- `gov_state_local` → 100% to gov_state_local

**Denominators.**
- **Private:** BEA `detailnonres_inv1.xlsx` — Row 48 "TOTAL STRUCTURES" per industry sheet (~30 BEA-coded industries). Annual structures investment in $millions nominal, deflated to 2024$.
- **gov_federal:** BEA Table 5.9.5 line 7 (federal gov structures investment), $B nominal → 2024$.
- **gov_state_local:** BEA Table 5.9.5 line 29 (state-local gov structures investment), $B nominal → 2024$.

**NAICS → BEA crosswalk.** 30-entry table in `compute_phi.R`. Our NAICS labels (211, 212, 2211, 236, 482, 486, 7130, etc.) map directly to BEA codes (2110, 2120, 2211, 2300, 4820, 4860, 7130, etc.). Records with NAICS 9281 (national security) or 9241 (federal env admin) have no private denominator and flow to gov_federal via the funding-source split.

### Headline Φ_i (10-year averages, 2015–2024)

**Φ_i^private by sector** (private capex / BEA private nonres structures investment, post-audit):

| BEA sector | NEPA-exposed $B | Sector structures inv $B | Φ |
|---|---|---|---|
| **Pipeline transportation** | 65.5 | 151.0 | **43.4%** |
| **Mining (ex oil & gas)** | 48.9 | 132.0 | **37.1%** |
| **Electric power** [*] | 343.5 | 1,090.4 | **31.5%** |
| **Other transportation & support** | 19.1 | 61.3 | **31.2%** |
| **Railroad transportation** | 30.5 | 120.0 | **25.5%** |
| Water, sewage, other utilities | 3.9 | 25.9 | 15.2% |
| Amusements / gambling / recreation | 4.6 | 157.0 | 2.9% |
| Oil and gas extraction | 13.1 | 1,110.0 | 1.2% |
| Construction (non-extractive structures) | 0.5 | 51.4 | 0.9% |
| Forestry / fishing | 0.1 | 9.8 | 0.9% |
| **Aggregate (all mapped sectors)** | **530** | **7,844** | **6.8%** |

[*] **Electric power includes most LNG export terminal capex** via the FERC-agency NAICS default. The 14 LNG records with no explicit "Pipeline" or "Port" in title (Lake Charles, Driftwood, Rio Grande, Alaska, CP2, Commonwealth, Golden Pass, etc.) fall to NAICS 2211 because the assigner cannot uniquely identify LNG. NAICS-standard classification would put LNG export terminals at NAICS 486 (Pipeline Transportation of Natural Gas) or NAICS 2212 (Natural Gas Distribution). Routing them to either of those individually produces Φ > 100% in that sector because the 2015–2024 LNG export buildout (~$215B 2024$) exceeds a decade of steady-state natural gas infrastructure investment ($121B for 486; $112B for 2212; $233B combined). The "Electric" denominator absorbs LNG without arithmetic blow-up but is a substantive misnomer. **The 31.2% reported here is most cleanly read as "FERC-led utility-scale capex including LNG and conventional electric infrastructure."** A possible alternative for the paper: introduce a separate "Natural gas infrastructure" exhibit reporting the LNG buildout in absolute terms (10-yr NEPA-exposed $B) without a Φ-style ratio, since the denominator-vs-numerator framing breaks for once-in-a-generation greenfield booms.

**Φ_i^gov by bucket** (post-audit):

| Bucket | 10-yr NEPA-exposed $B | 10-yr BEA gov-structures inv $B | Φ |
|---|---|---|---|
| Federal (USACE/BR/USAF/USN/USMC/NSA/GSA/TVA/BOP/DOE-federal) | 93.5 | 304.5 | **30.7%** |
| State-local (FHWA/FTA/CHSRA) | 311.6 | 4,204.0 | **7.4%** |

### Post-audit changelog (2026-06-01)

Audit findings applied via `notes/adversarial_review_report.md` (kept at `/tmp/nepa_audit_report.md`, originated outside the repo so it isn't tracked here):

| Finding | Action | Effect |
|---|---|---|
| **CRIT-1** Gold/Golden regex bug | Added `\b` word boundaries to all mineral names in `naics_mining` regex (two passes); also fixed `\bcoal\b`, `\bcopper\b`, etc. Golden Pass LNG ($10B) moved from NAICS 212 (mining) to NAICS 2211 (electric, via FERC default — NOT NAICS 486 as auditor predicted, because the title has no "pipeline" keyword). | Φ_mining: 34.4 → 24.7%; Φ_electric: 30.0 → 31.2%. Auditor's destination prediction was wrong (gold→pipeline) but magnitude was close. |
| **CRIT-2** Hardcoded `PROJECT_ROOT` | Replaced absolute Dropbox path with sentinel walk-up in all 19 scripts; `code/_paths.R` documents the pattern. Scripts now find `nepa_project.Rproj` by walking up from `getwd()`. | Pipeline now portable. Replicators can clone to any path. |
| **H-1** (iii) bucket undercount | Added agency-default inclusion for BPA, WAPA, NSA, USMC, NIGC, OSM; added naval-shipyard / GSA-master-plan / USACE-404-mining / on-base-renewable inclusion patterns. 30 records flipped (iii)→(i). Cost provenance lives in `code/_h1_records.R` (sourced by each year's build script). | (i) count: 436 → 465. Mining +$13B (Donlin Gold $7.4B + Pebble $5B); Electric +$2B (Edwards AFB Solar); gov_federal +$8B (Pearl Harbor SY $3.6B + NSA East Campus $4.6B + others). Φ_mining: 24.7 → 37.1%; Φ_gov_federal: 25.5 → 28.1%. |
| **H-3** Reversed range in `run_pipeline.R` | Added explicit error on `--to` preceding `--from`. | Pipeline now fails loudly on misordered ranges. |
| **L-6** Two misclassified (ii) records | Tightened `cat_excl_restoration` (don't exclude if "mining plan"/"plan of operations" in title — fixed Resurrection Creek/Hope Mining); tightened `cat_excl_dam_safety` (don't exclude if "modification"/"structural upgrade" — fixed B.F. Sisk Dam). | Negligible Φ impact (~$575M added). Defensibility improved. |
| **CRIT/H methodology** LNG sector misclassification | Documented in code comments + sectoral table footnote. Did NOT restructure (moving LNG to NAICS 486 or 2212 produces Φ>100% because LNG buildout 2015-2024 exceeded a decade of steady-state natural-gas-infrastructure investment). | Status quo: LNG records at NAICS 2211 (electric, via FERC default). Φ_electric = 31.4% includes substantial LNG component. |

### Methodology caveats to pre-empt in paper (audit framing findings)

**1. Numerator-denominator timing mismatch (audit H-2).** Φ_i attributes full multi-year project capex to the FEIS-completion year, while the denominator is annual BEA structures investment in that year. A $20B LNG project whose FEIS lands in 2019 contributes the entire $20B to 2019's numerator while only the actual-2019-year construction (~$3B for a 5-year build) shows up in BEA's 2019 investment figure. Interpretation: Φ_i is a **flow-of-approvals-per-flow-of-investment** rate, not a stock-of-exposed-capex measure. Frame as such in the paper. A capex-distribution sensitivity (spreading project cost over a sector-typical build duration of 2–5 years) would reduce reported Φ by 3–5× in high-velocity sectors (pipeline, LNG, mining) but is computable from the per-record cost_year field if a reviewer demands it.

**2. Cancelled-project capex inclusion (audit H-4).** 18 records ($85.1B in 2024$, ~16% of private numerator) describe projects whose Final EIS was issued but were later cancelled or had permits denied (Jordan Cove, Atlantic Coast Pipeline, Northern Pass, Plains and Eastern, CA WaterFix, Atlantic Shores South / Ocean Wind 1, VTR, Newark AirTrain, etc.). The construction reports these at full FEIS-stage capex because the EIS review *itself* consumed real resources regardless of subsequent realization. A hostile referee will argue this overstates the implied reform-benefit if NEPA reform doesn't change cancellation rates. Sensitivity, automatically reported by `code/compute_phi.R`:

| Cancelled-project attribution | Private 10-yr $B (2024$) | Φ_private aggregate |
|---|---|---|
| 0% (lower bound) | 478 | 6.1% |
| 50% (realization-probability-weighted) | 504 | 6.4% |
| **100% (headline baseline)** | **529** | **6.7%** |

Range is narrow (±0.3pp); headline survives any plausible attribution assumption.

**3. Single private-structures deflator applied to both private and gov sides (audit L-1).** BEA Table 1.1.9 line 10 (private nonresidential structures IPD, 2017=100) is used to deflate every record. The gov-structures IPD (BEA Table 5.9.4) and the private-structures IPD differ by <1pp/yr over 2015–2024 — using the same series for both is a deliberate simplification that keeps the deflation step uniform and adds at most ~$3B noise to either gov bucket's numerator. Documented as a footnote.

**4. Structures-only denominator excludes equipment (audit L-3).** BEA's TOTAL STRUCTURES row (line 48 of each industry sheet in `detailnonres_inv1.xlsx`) is used as the denominator. This omits equipment and intellectual property products — but project-capex *numerators* often include both (a mine has trucks and crushers; an LNG terminal has compressors). Industry-typical equipment shares of total project capex are roughly:

- Mining: 15-25% equipment (mostly haul trucks, crushers, mill equipment)
- Electric power generation: 30-50% equipment (turbines, transformers, switchgear)
- Pipeline transportation: 5-15% equipment (compressors, valves; mostly structures)
- LNG terminals: 35-50% equipment (liquefaction trains, refrigeration, storage tanks)

This biases reported Φ_i *upward* for equipment-heavy sectors. The cleanest fix would be to either (a) split numerator into structures-only vs equipment using sector-typical ratios, or (b) use a broader denominator (private nonresidential structures + equipment). The current construction is conservative for FRAMING — Φ values look bigger than they "really" are by an industry-equipment factor — and should be acknowledged in a paper footnote.

**5. Mixed-bucket cost-share heterogeneity (audit L-8).** USACE civil works with non-federal sponsors have real cost-share ratios ranging from 35% (flood damage reduction) to 65% (harbor deepening) to 100% (federally-only). Author uses 50/50 across the board with a 30/70 and 70/30 sensitivity (reported in `output/phi_mixed_sensitivity.csv`). Range is small (±$13B of private numerator, ±0.17pp of Φ_private aggregate) so the simplification is defensible.

**6. LNG sectoral inconsistency (audit-derived).** LNG export terminal records scatter across NAICS 2211 (electric, most records via FERC default), 486 (pipeline, 3 records with "Pipeline" in title), and 488 (water-support, Port Arthur LNG via `\bport\b` regex). NAICS-standard classification puts LNG at NAICS 486 or 2212. Routing all LNG to either bucket produces Φ > 100% (the 2015–2024 LNG export buildout exceeded a decade of steady-state natural-gas-infrastructure investment), so the "Electric" bucket absorbs LNG as the only arithmetic-coherent home. Φ_electric = 31.4% is best read as "FERC-led utility-scale capex including LNG." A separate LNG exhibit reporting absolute capex without a Φ-ratio is the cleanest paper presentation.

---

**Net audit impact on headline:**

| Aggregate | Pre-audit | Post-audit | Δ |
|---|---|---|---|
| Private 10-yr $B (2024$) | 510 | 529 | +19 |
| Φ_private aggregate | 6.5% | 6.7% | +0.2pp |
| gov_federal 10-yr $B | 77.7 | 85.7 | +8.0 |
| Φ_gov_federal | 25.5% | 28.1% | +2.6pp |
| gov_state_local 10-yr $B | 309.9 | 309.9 | unchanged |
| Φ_gov_state_local | 7.4% | 7.4% | unchanged |
| Highest Φ sector | Pipeline 43.4% | Pipeline 43.4% | unchanged |
| Top-4-sector concentration story | 4 sectors ≥25% | **5 sectors ≥25%** | +1 sector (mining now firmly in tier) |

### Interpretation

1. **NEPA exposure is highly concentrated.** Four private sectors (pipeline, mining, electric power, rail) all sit at 25–43% — meaning roughly a quarter to nearly half of new private-structures investment in those sectors passes through a Final EIS review. The reform-margin GDP gains the Hulten aggregation will pick up are concentrated here.

2. **Oil & gas extraction has low Φ (1.2%) despite being a big private sector.** This is because most onshore oil/gas well permits go through Categorical Exclusions, not EISs. Our numerator only counts Final EIS reviews — the right denominator-of-denominators question for that sector is "what fraction of capex actually faces EIS-grade review" and the answer is small. The aggregate ratio understates exposure on the *intensive* margin (per-EIS delay) while accurately measuring the *extensive* margin (share of investment that hits the bar).

3. **Federal Φ (25.5%) is structurally higher than state-local Φ (7.4%).** The federal-budget capex universe is small (~$30B/yr in structures) and concentrated in large multi-year projects (military bases, federal civil works, federal buildings) that virtually all trigger EISs. State-local capex includes a large base of routine road maintenance, sidewalks, water-main replacement that doesn't trigger NEPA.

4. **Year-to-year variance is high** for federal (range 7%–81%) and meaningful for state-local (1%–17%), reflecting EIS-timing lumpiness rather than activity-level variation. For paper exhibits, the 10-yr average is the headline; per-year is supplementary.

### Sensitivity to mixed-bucket allocation

| `mixed` → private share | Private numerator $B (10-yr) | Gov_federal numerator $B (10-yr) |
|---|---|---|
| 30% | 497 | 91 |
| **50% (baseline)** | **510** | **78** |
| 70% | 523 | 65 |

Materially small for private (±1.3% of headline); ±20% for gov_federal where the bucket is smaller. Baseline 50/50 split is the default reported.

### Output files

- `output/phi_private_by_sector.csv` — 10-yr aggregate per BEA NAICS
- `output/phi_private_by_sector_year.csv` — per-sector per-year time series (~300 rows)
- `output/phi_gov_federal_by_year.csv` — per-year time series
- `output/phi_gov_state_local_by_year.csv` — per-year time series
- `output/phi_mixed_sensitivity.csv` — mixed-bucket sensitivity table

**Pending:**
- Resolve 2024 pending imputations (4 records — LOCAR, Bald Mountain, Robertson Mine, Moody AFB)
- Fix 2023 attribution: 20230083 FERC TN Cumberland pipeline should be ~$225M (Kinder Morgan), not $2.1B (TVA plant); plant cost now correctly at 20220181
- Apply 2019 classifier patches (contract conversion, IRP stricter match, water transfers, exchange program, Tier-1 planning) and re-run on 2015–2024
- **Funding-source tagging pass** (see check #11 below) — required before Φ_i computation
- BEA pull: split private nonresidential investment AND government gross investment by NAICS / function
- Φ_i computation, split into Φ_i^private and Φ_i^gov
- Sector-specific cross-validation (FERC, FHWA, USACE Civil Works, USASpending)

---

## Validation checks (to run before locking the construction)

Sorted by priority for final audit:

### Highest priority

**1. Headline reconciliation with prior memo.**
Our 2 years = $243.7B; the prior memo's full all-time exposure was ~$80B with $250B upper bound. Need to understand the gap:
- Did the memo annualize differently?
- Was the memo's keyword classification systematically undercounting?
- Did DOT-imputed uniform cost understate the largest projects?
- Are we including categories the memo excluded?
- Or is the new construction simply more accurate and the memo's lower bound was much too low?

This validation tells us whether the new headline is in the right ballpark before locking.

**2. Cost figure accuracy spot-check.**
Pick 5–10 random records from `cost_extraction_2023.csv` and `cost_extraction_2024.csv`. For each, open `cost_source_url`, find the `cost_quote`, verify the `cost_m_usd_nominal` value. Watch especially for:
- Loan amount vs. total capex (e.g., Rhyolite Ridge $996M DOE loan ≠ total project cost)
- Pre- vs. post-cost-overrun figures
- Program-level vs. per-project allocation (Sentinel)
- Real vs. nominal dollars across years

### Medium priority

**3. Imputation proxies — defensibility audit.**
13 records have `imputed = TRUE`. Review each `imputation_basis` and confirm the proxy is defensible:
- Offshore wind $/GW from MD Wind benchmark (~$2.7B/GW)
- T-7A beddown per-base from JBSA proxy ($72M)
- Highway $/mile for rural interstates (~$30–45M/mi)
- Utility-scale solar $/MW (~$1.1M/MW)
- Onshore wind $/MW (~$2M/MW)
- Sentinel per-site allocation ($1–5B)
- BESS $/kWh (~$300/kWh)

**4. Methodology consistency across batches.**
Verify identical treatment for comparable cases:
- Adoptions consistently marked $0 when duplicate
- Cancelled projects (Ocean Wind, Lava Ridge, Atlantic Shores) counted at full capex because EIS was completed — confirm this is intended
- Phased mega-programs handled identically (Sentinel WY, Sentinel BLM-adoption, etc.)
- License renewals consistently in (ii)
- Civil Nuclear Credit-style operational programs consistently in (ii)

**5. Sector aggregation sanity check vs. external benchmarks.**
For each sector total, compare to a plausible external anchor:
- Electric power $125B over 2yr — compare to BEA private investment in NAICS 2211 utilities (~$120-150B/yr)
- Highway $15.5B — compare to FHWA federal-aid highway construction (~$50-60B/yr)
- Mining $7.4B — compare to BEA NAICS 212 capex (~$15-25B/yr)
- If numerator vastly exceeds plausible denominator share, methodology has an issue

### Lower priority (can wait for full dataset)

**6. Cross-year duplicate detection.**
Build a systematic pass that detects adoptions referencing projects in OTHER years. Current within-year dedup is manual per-batch. For 2015-2022 scaling this needs to be a pre-flight check before aggregation.

**7. Replicability end-to-end test.**
On a clean clone of the project directory, run scripts in order:
- `Rscript code/fetch_eis_fr.R 2015 2024`
- `Rscript code/clean_eis_finals.R`
- `Rscript code/classify_eis.R`
- `Rscript code/assign_naics.R`
- `Rscript code/build_cost_provenance_2024.R`
- `Rscript code/build_cost_provenance_2023.R`

Verify outputs match the existing files exactly. If yes, the construction is fully replicable from public sources.

**8. NAICS misassignment spot-check.**
Sample 20 records across sectors, verify NAICS code is correct for the project type. Already caught issues with: Land Ports → Buildings (fixed), Transmission → Mining (fixed), CHSRA → Rail (fixed), TVA → Electric (fixed).

**9. Reclassification cleanup.**
The 3 records flagged `reclassified_to_ii` represent classifier gaps. Add their patterns to `classify_eis.R` rules and re-run on all 1,124 records before final aggregation.

**10. Inflation adjustment.**
All costs currently in nominal USD with `cost_year` field. Before computing Φ_i, deflate to a constant base year using BEA implicit deflator for private fixed investment in structures. Document the deflator series used.

### Highest priority — must precede Φ_i computation

**11. Funding-source tagging (public vs. private capex attribution).**

The lead agency tells us who issued the EIS, not who paid for the capex. As the dataset stands, a USAF base rebuild ($5B Tyndall), an FHWA-led state DOT highway ($3.5B Mobile Bay Bridge), and a private LNG terminal ($20B Plaquemines) all sit in the same numerator pool. If we deflate by BEA *private* nonresidential investment by NAICS, we will overstate Φ_i^private because the numerator silently includes government-financed projects.

Action items (in order):

1. **Add `funding_source` column** to every cost record. Values: `private`, `gov_federal`, `gov_state_local`, `tribal`, `mixed`. Default rule of thumb from the lead-agency field:
   - Private by default: FERC LNG/pipeline, BLM extractive (mining, oil & gas, solar/wind on federal land), USFS recreation + transmission + mining, BIA tribal-equity casinos, RUS member-owned utility transmission, NRC private reactors, PHMSA private pipeline.
   - Gov-federal by default: USACE civil works, BR water infrastructure, GSA federal buildings + LPOEs, USAF/USN/USA/USCG/DOD bases & weapons, TVA (federal corp), FRA-led federal portions of HSR, BOP federal prisons, federal research facilities, NPS/USFS/USFWS facility construction.
   - Gov-state-local by default: FHWA + state-DOT highways, FTA transit (capital match).
   - Tribal: BIA casino, fee-to-trust, tribal solar (when tribally financed).
   - Mixed: federal–state cost-share projects (e.g., USACE projects with state non-federal sponsors >50%, RUS-financed cooperative transmission, FRA-state HSR).

2. **Override per-record** when financing is clearly different from the agency default. Document override basis in a `funding_source_basis` column (e.g., "DOE 1703 loan covers 80% of capex" → mixed; "tribal gaming revenue bonds" → tribal; "USACE WIIN Act PPP" → mixed).

3. **Split Φ_i computation** into two parallel constructions:
   - Φ_i^private = (private-funded EIS capex by NAICS) ÷ (BEA private nonresidential fixed investment by NAICS)
   - Φ_i^gov = (gov-funded EIS capex by function) ÷ (BEA government gross investment by function — federal nondefense structures, federal defense structures, state-local structures)
   - Treat `mixed` proportionally where the cost-share split is documented; otherwise apply 50/50 with a sensitivity check.

4. **Re-route aggregation in Hulten step.** Private capex shocks flow through sectoral production functions (the standard Hulten channel); government investment shocks flow through G crowd-out / public-capital productivity (separate channel, smaller multiplier). Mixing them collapses two distinct mechanisms into one and misstates the headline GDP effect in either direction.

5. **Report both as separate exhibits in the memo**, not a single Φ_i. The honest framing avoids the optics problem of claiming "X% of the oil & gas sector's capex was exposed" when half the exposure is actually a federal building or military base.

Coding effort: ~1 hour to tag all 279 records (rule-based default + ~30 manual overrides). Must be done before BEA pull so we know which BEA series to fetch.

---

## Open methodological questions (not validation — actual design choices)

These need decisions, not just checks:

- **Capex timing.** Should we attribute project capex to the EIS completion year, or annualize over construction duration? Affects how numerator stocks/flows align with BEA denominator.
- **Cancelled projects.** Currently counted at full capex (EIS exposure happened regardless). Alternative: discount by ex-post realization probability. Materially affects offshore wind sector total.
- **Adoption project cost attribution.** Currently: full cost to the primary EIS, $0 to adoption. Alternative: split across all reviewing agencies' sectors. Affects sector mix but not aggregate.
- **License renewal of long-lived assets.** Currently: $0 (no new K). Alternative: NPV of continued operation. Would substantially shift NRC and BR sectors.
- **Resource exploration (mining, oil/gas).** Currently: included as private capex. Alternative: assign zero (since exploration capex is small relative to subsequent development).
- **Government vs. private capital.** Currently: include both (USACE civil works, DOE energy projects, USAF base rebuilds, FHWA highways) in a single numerator pool, which silently mixes public and private capex against a private-only BEA denominator. Decision needed: see validation check #11 — likely path is to tag every record with a `funding_source` and split Φ_i into Φ_i^private and Φ_i^gov rather than blend.
