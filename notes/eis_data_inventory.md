# EIS Data Inventory — CY2015–2024

## Source

Federal Register API (`api/v1/documents.json`), filtered to weekly EPA notices titled
"Environmental Impact Statements; Notice of Availability." Each NOA lists EISs filed
that week. Body text parsed via regex on the canonical per-entry format:

```
EIS No. NNNNNNNN, [Doc Type], [Agency], [State], [Title], [Period] Ends: MM/DD/YYYY, Contact: [Name] [Phone]
```

Format is stable from 2015 through 2025 (verified at endpoints).

## Pipeline

- `code/fetch_eis_fr.R` — pulls weekly NOAs, parses entries, writes `data/raw/eis_records_2015-2024.csv` (2,725 rows, all entry types).
- `code/clean_eis_finals.R` — filters to primary completed EISs, writes `data/processed/eis_finals_2015-2024.csv` (1,124 rows).

## Schema

| Column | Type | Notes |
|---|---|---|
| `eis_number` | int (8-digit) | Unique per filing; first 4 digits = year |
| `document_type` | char | "Final" (normalized; "Final EIS" merged in) |
| `lead_agency` | char | 2–7-letter agency code (69 distinct values in final cut) |
| `state` | char(2) | 2-letter state/territory code |
| `title` | char | Project title (free text) |
| `period_type` | char | "Comment Period" or "Review Period" |
| `period_end_date` | char (MM/DD/YYYY) | Comment/review deadline |
| `contact_name` | char | Often filled, occasionally missing |
| `contact_phone` | char | Sometimes missing |
| `source_fr_doc` | char | FR document number of the NOA that carried this entry |
| `source_fr_date` | date | FR publication date |
| `fr_date` | Date (added in clean step) | Same as source_fr_date as Date |
| `cal_year` | int | Calendar year of FR publication |
| `fiscal_year` | int | Federal FY (Oct–Sep) |

## Coverage

### Counts by year (Finals only)

| Cal Year | Finals | FY | Finals |
|---:|---:|---:|---:|
| 2015 | 159 | 2015 | 123 |
| 2016 | 145 | 2016 | 143 |
| 2017 | 102 | 2017 | 115 |
| 2018 | 128 | 2018 | 109 |
| 2019 | 144 | 2019 | 167 |
| 2020 | 110 | 2020 | 108 |
| 2021 | 74  | 2021 | 81 |
| 2022 | 70  | 2022 | 71 |
| 2023 | 77  | 2023 | 73 |
| 2024 | 115 | 2024 | 97 |

**10-year mean: 112 Finals/year (calendar) — consistent with CEQ-reported ~110–130/yr benchmark.**

Notable: 2021–2023 dip (~75/yr) coincides with COVID disruption and the 2020 CEQ rule changes. 2024 recovery to 115. The mean for the more recent five years (2020–2024) is 89/yr, which may be the more relevant calibration anchor.

### Top 25 lead agencies (full window)

| Rank | Agency | Finals | Cumulative % |
|---:|---|---:|---:|
| 1 | USFS  | 201 | 18% |
| 2 | BLM   | 142 | 31% |
| 3 | USACE | 115 | 41% |
| 4 | FERC  | 68  | 47% |
| 5 | FHWA  | 62  | 52% |
| 6 | USFWS | 41  | 56% |
| 7 | NPS   | 37  | 59% |
| 8 | DOE   | 33  | 62% |
| 9 | NMFS  | 33  | 65% |
| 10 | BR   | 32  | 68% |
| 11 | USAF | 31  | 70% |
| 12 | FTA  | 23  | 72% |
| 13 | NOAA | 23  | 74% |
| 14 | NRC  | 23  | 76% |
| 15 | BIA  | 19  | 78% |
| 16 | USN  | 19  | 79% |
| 17 | BOEM | 17  | 81% |
| 18 | FRA  | 17  | 83% |
| 19 | TVA  | 16  | 84% |
| 20 | FAA  | 15  | 85% |
| 21 | GSA  | 10  | 86% |
| 22 | USA  | 9   | 87% |
| 23 | HUD  | 8   | 88% |
| 24 | NRCS | 8   | 89% |
| 25 | USCG | 8   | 89% |

Top 5 cover 52% of Finals. Top 10 cover 68%. Top 25 cover 89%. The remaining 44 agencies each have ≤7 Finals over the decade.

### State agencies in the dataset

A small handful of records (CALTRANS, CTDOH, FDOT, MDA, NJDEP, NYCOMB, WDFW) show
state-level lead agencies. These are state-led joint NEPA reviews under federal
authority (typically state DOTs as FHWA's joint lead). They should be reclassified
to their federal counterpart agency for NAICS mapping purposes — flag for the
crosswalk task.

## Field completeness

| Field | Missing | % |
|---|---:|---:|
| `title` | 0 | 0% |
| `lead_agency` | 0 | 0% |
| `state` | 0 | 0% |
| `period_end_date` | ~200 | ~18% |
| `contact_phone` | ~150 | ~13% |

`period_end_date` is missing primarily for supplements and Adoption entries (not in
the Finals cut), and for older records with non-standard formatting. For the Finals
cut specifically, completeness is higher (~95% have a period_end_date).

## Known limitations

1. **EPA EIS database vs. Federal Register**: We pulled from FR, not from the EPA EIS
   database directly (cdxapps.epa.gov). The EPA database has PDFs and richer metadata
   (cooperating agencies, EPA comment ratings). For cost extraction (Phase 2), we'll
   need to bridge eis_number → EPA database lookups.

2. **EIS number coverage**: Some old-style numbers don't follow the YYYYxxxx convention,
   but all 1,124 Finals in our cut have parseable 8-digit numbers.

3. **No project cost data**: NOAs do not list project costs — this is a separate task.

4. **State-led joint reviews**: ~10 records have state DOT lead agencies (CALTRANS, FDOT,
   etc.). These are still federal NEPA reviews (joint lead with FHWA) but the federal
   partner agency isn't captured. Need to remap during crosswalk construction.
