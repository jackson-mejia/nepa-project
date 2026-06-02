# 2018 cost extraction — all cat(i) records (deduplicated) with full provenance.
# Same schema as 2019-2024.

suppressPackageStartupMessages({library(dplyr); library(readr); library(tibble)})

library(here)
source(here("code", "_h1_records.R"))    # H-1 audit additions
source(here("code", "_cost_helpers.R"))  # finalize_cost_year()
OUT_PATH <- here("data", "processed", "cost_extraction_2018.csv")

prov <- tribble(
  ~eis_number, ~lead_agency, ~state, ~cost_m_usd_nominal, ~cost_year, ~cost_method, ~cost_source_url, ~cost_source_title, ~cost_source_publisher, ~cost_source_date, ~cost_source_page, ~cost_quote, ~cost_confidence, ~imputed, ~imputation_basis, ~cost_notes,

  20180002L, "FHWA", "MO", 237, 2025L, "web",
    "https://www.modot.org/projects/improvei70kc",
    "MoDOT Improve I-70 Kansas City", "modot.org", "2025", NA_integer_,
    "Programmed budget is $237 million for KC section. Tier II EIS covered 6.8-mi segment.",
    "high", FALSE, NA_character_,
    "MoDOT I-70 KC Tier 2. Larger I-70 Wentzville-KC program is $3B over 199 mi.",

  20180004L, "BR", "NM", 280, 2018L, "web",
    "https://www.santafecountynm.gov/public-works/aamodt",
    "Aamodt Settlement Pojoaque Basin Regional Water System", "santafecountynm.gov", "2018", NA_integer_,
    "Total cost ~$279.2M for Aamodt settlement implementation (federal $162.3M + state/local $116.9M).",
    "high", FALSE, NA_character_,
    "Bureau of Reclamation. Aamodt Indian Water Rights Settlement Act 2010.",

  20180009L, "FHWA", "CO", 0, 2018L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "US 50 Corridor East Tier 1 FEIS. Planning document — defers all project-level decisions to Tier 2 NEPA. No construction authorized.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Add 'Tier 1' / 'Tier I' planning study pattern.",

  20180016L, "FHWA", "IN", 1500, 2018L, "web_imputed",
    "https://www.in.gov/indot/3193.htm",
    "INDOT I-69 Section 6 Martinsville to Indianapolis", "in.gov/indot", "2018", NA_integer_,
    "27-mile interstate completion. INDOT total program cost ~$1.5B for Section 6 (last segment to Indianapolis).",
    "medium", TRUE, "Interstate-upgrade-urban (~$56M/mi)",
    "Section 6 of I-69 Evansville-Indianapolis program. Now complete (2024).",

  20180026L, "USFS", "ID", 100, 2018L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Big Creek Geothermal Leasing Project. Geothermal exploration/development leases. Small-scale geothermal sector.",
    "low", TRUE, "Geothermal-leasing-initial-dev (~$100M)",
    "Caribou-Targhee NF ID. Small-scale.",

  20180032L, "FTA", "IN", 945, 2018L, "web",
    "https://www.transit.dot.gov/grant-programs/capital-investments/west-lake-corridor-project-profile-fy-2023-annual-report",
    "FTA West Lake Corridor Project Profile", "transit.dot.gov", "2023", NA_integer_,
    "$852M eligible project costs (FTA CIG basis). Total program ~$945M with NICTD additions.",
    "high", FALSE, NA_character_,
    "NICTD South Shore Line extension Hammond-Munster-Dyer. 8 miles. FTA CIG.",

  20130018L, "BIA", "WA", 400, 2018L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Spokane Tribe West Plains Casino + Mixed-Use Development. Adoption of 2013 BIA EIS, project approved 2017. Mid-size tribal casino + hotel.",
    "low", TRUE, "Mid-size-tribal-casino-resort (~$400M)",
    "Spokane Tribe. Off-reservation fee-to-trust. Adoption record.",

  20180039L, "FHWA", "AK", 350, 2018L, "web",
    "https://www.adn.com/alaska-news/2023/08/03/cooper-landing-highway-project-estimate-more-than-doubles-in-cost/",
    "Cooper Landing highway project estimate doubles", "adn.com", "2023", NA_integer_,
    "Estimated $350M at 2018 ROD; rose to $840M by 2023.",
    "high", FALSE, NA_character_,
    "Sterling Highway MP 45-60. Cooper Landing Bypass AK. AKDOT.",

  20180056L, "FHWA", "WA", 1900, 2023L, "web",
    "https://www.seattletimes.com/seattle-news/seattles-massive-2b-convention-center-finally-opens-after-delays/",
    "Seattle's massive $2B convention center finally opens", "seattletimes.com", "2023", NA_integer_,
    "Final cost $1.9 billion. Construction began August 2018 per 2018 ROD.",
    "high", FALSE, NA_character_,
    "Washington State Convention Center Addition (Summit). Seattle. King County financed via lodging tax.",

  20180065L, "TVA", "TN", 200, 2018L, "sector_impute_pending",
    "https://www.federalregister.gov/documents/2018/06/07/2018-12236/cumberland-fossil-plant-coal-combustion-residuals-management-operations-final-environmental-impact",
    "Cumberland Fossil Plant CCR Operations FEIS", "federalregister.gov", "2018-06-07", NA_integer_,
    "Bottom ash dewatering facility + onsite landfill + closure-in-place. Cost not disclosed in FEIS. TVA CCR landfill program impute.",
    "low", TRUE, "CCR-landfill-dewatering-facility (~$200M)",
    "Cumberland TN. TVA CCR management per 2015 EPA rule.",

  20180075L, "BR", "CA", 1400, 2018L, "web",
    "https://www.sandiego.gov/public-utilities/sustainability/pure-water-sd/news181127",
    "EPA Awards $614M WIFIA Loan for Pure Water San Diego", "sandiego.gov", "2018-11-27", NA_integer_,
    "First phase estimated to cost $1.4 billion. EPA WIFIA loan ~$614M closed 2018.",
    "high", FALSE, NA_character_,
    "Pure Water San Diego Phase 1 — North City. Indirect potable reuse 30 MGD.",

  20180093L, "USFS", "NM", 0, 2018L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Santa Fe National Forest Geothermal Leasing FEIS. Leasing decision only — no specific project. Subsequent project-level NEPA required.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Add 'geothermal leasing' pattern (similar to oil/gas leasing programmatic).",

  20180128L, "USFS", "CO", 35, 2018L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Steamboat Ski Area Improvements. Routt NF. Lifts, snowmaking, terrain. Modest resort capex.",
    "low", TRUE, "Ski-resort-on-mountain-improvements (~$35M)",
    "Steamboat (Alterra). Routt NF CO.",

  20180129L, "FTA", "CA", 300, 2018L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Geary BRT San Francisco. 6.5 miles Center-Running BRT. SFMTA capital project ~$300M (Phase 1 + Phase 2).",
    "medium", TRUE, "BRT-urban-corridor (~$300M for 6.5 mi)",
    "SFMTA + FTA Small Starts. Geary Blvd SF.",

  20180135L, "USAF", "CA", 200, 2018L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "KC-46A MOB 4 Beddown at Travis AFB. Standard tanker beddown MILCON package.",
    "low", TRUE, "KC-46A-beddown-MILCON (~$200M)",
    "Travis AFB CA. Air Force aerial refueling tanker recapitalization.",

  20180137L, "BLM", "WY", 1500, 2018L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Normally Pressured Lance (NPL) Natural Gas Development Project. Jonah Energy. Up to 3,500 wells. Major Wyoming gas development.",
    "low", TRUE, "Wyoming-large-gas-development (~$1.5B)",
    "Sublette County WY. Jonah Energy. 220k acres.",

  20180139L, "USFS", "CA", 80, 2018L, "web_imputed",
    "https://www.fs.usda.gov/r04/humboldt-toiyabe/projects/archive/36656",
    "Humboldt-Toiyabe NF Bordertown to California 120kV", "fs.usda.gov", "2018", NA_integer_,
    "11.9 mi 120kV transmission. NV Energy. Standard ~$5-8M/mi for 120kV in mountainous terrain.",
    "low", TRUE, "120kV-transmission (~$80M for 12 mi)",
    "Reno-area transmission upgrade. NV Energy.",

  20180144L, "FERC", "OK", 300, 2018L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Midcontinent Supply Header Interstate Pipeline (MSHIP). Energy Transfer. ~38 mi 42-in pipeline + compression. ~$300M project.",
    "low", TRUE, "Mid-stream-pipeline (~$300M)",
    "Oklahoma. Energy Transfer Partners. SCOOP/STACK takeaway.",

  20180145L, "FHWA", "NV", 500, 2018L, "web_imputed",
    "https://www.pyramidhighway.com/",
    "Pyramid Highway Project (RTC Washoe)", "pyramidhighway.com", "2018", NA_integer_,
    "Six-phase Pyramid/US-395 Connection. Phase 1 $66M; total program ~$500M+ over 6 phases.",
    "medium", TRUE, "Multi-phase-suburban-highway (~$500M)",
    "Reno NV. RTC Washoe + NDOT + FHWA. Spanish Springs connector.",

  20180169L, "BLM", "NV", 150, 2018L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Gold Rock Mine Project. Fiore Gold / Calibre Mining. Small-mid Nevada gold mine.",
    "low", TRUE, "Small-mid-gold-mine (~$150M)",
    "White Pine County NV. Fiore Gold (acquired by Calibre).",

  20180175L, "FERC", "CA", 30, 2018L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Lassen Lodge Hydroelectric. Small hydro on Mill Creek CA. ~9 MW.",
    "low", TRUE, "Small-hydro-greenfield (~$30M)",
    "Tehama County CA. Mill Creek.",

  20180202L, "FAA", "AZ", 250, 2018L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Tucson International Airport Airfield Safety Enhancement. Runway/taxiway reconfiguration.",
    "low", TRUE, "Airport-runway-reconfig (~$250M)",
    "TUS Tucson Airport Authority + FAA.",

  20180219L, "USACE", "CA", 400, 2018L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Delta Islands and Levees Integrated Feasibility Study. Habitat + flood control acquisitions/improvements.",
    "low", TRUE, "Delta-levee-habitat-program (~$400M)",
    "Sacramento-San Joaquin Delta CA. USACE + state.",

  20180237L, "USACE", "AZ", 80, 2018L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Little Colorado River at Winslow Flood Risk Management. Levee improvements.",
    "low", TRUE, "Levee-flood-risk-mid (~$80M)",
    "Navajo County AZ. USACE.",

  20180238L, "FHWA", "UT", 250, 2018L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "SR 30 Logan to West 1000 West (UDOT joint lead). New alignment northern Cache Valley.",
    "low", TRUE, "Rural-arterial-new (~$250M)",
    "Cache County UT. UDOT.",

  20180241L, "FAA", "AK", 0, 2018L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "FAA adoption of USAF Modernization and Enhancement of Ranges EIS.",
    "high", FALSE, NA_character_,
    "Adoption — primary EIS USAF.",

  20180242L, "FAA", "GA", 0, 2018L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "FAA adoption of USAF Townsend Bombing Range Modernization EIS.",
    "high", FALSE, NA_character_,
    "Adoption — primary EIS USAF.",

  20180252L, "FHWA", "CA", 90, 2018L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "US 50/South Shore Community Revitalization Project. Lake Tahoe arterial improvements + roundabouts.",
    "low", TRUE, "Urban-arterial-revitalization (~$90M)",
    "South Lake Tahoe CA. Caltrans + TRPA.",

  20180258L, "FERC", "LA", 4500, 2019L, "web",
    "https://www.offshore-technology.com/projects/calcasieu-pass-lng-export-facility-louisiana/",
    "Calcasieu Pass LNG Export Facility", "offshore-technology.com", "2019", NA_integer_,
    "10 mtpa export facility + 23.4-mi pipeline. Venture Global construction ~$4.5B. FID Aug 2019.",
    "high", FALSE, NA_character_,
    "Cameron Parish LA. Venture Global. First LNG Jan 2022.",

  20180265L, "DOE", "LA", 0, 2018L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "DOE adoption of FERC Calcasieu Pass EIS (20180258).",
    "high", FALSE, NA_character_,
    "Adoption — primary EIS FERC.",

  20180287L, "UDOT", "UT", 25, 2018L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "I-15 Payson Main Street Interchange. Reconfigured DDI. Modest interchange project.",
    "low", TRUE, "Interchange-reconfig (~$25M)",
    "Utah County UT. UDOT.",

  20180300L, "USACE", "CA", 130, 2018L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Upper Llagas Creek Flood Protection Project. Santa Clara Valley Water District. Channel improvements + detention.",
    "low", TRUE, "Urban-flood-control-channel (~$130M)",
    "Morgan Hill CA. SCVWD.",

  20180305L, "FTA", "TX", 1100, 2018L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "DART Cotton Belt Regional Rail (Silver Line). 26-mi commuter rail DFW Airport to Plano. ~$1.1B FTA project.",
    "high", FALSE, NA_character_,
    "DART. Opens 2026. RRIF + private financing.",

  20180311L, "FAA", "TX", 0, 2018L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "FAA adoption of FTA DART Cotton Belt Corridor Regional Rail EIS (20180305).",
    "high", FALSE, NA_character_,
    "CORRECTED 2026-06-01 (dup_sweep): not a standalone airport project. Adoption of 20180305 DART Cotton Belt. Was erroneously imputed $200M.",

  20180321L, "DOE", "CA", 600, 2018L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Santa Susana Field Lab Area IV + Northern Buffer Zone Remediation. DOE share of multi-party SSFL cleanup. Mid-range federal remediation.",
    "low", TRUE, "Federal-environmental-remediation (~$600M)",
    "Ventura County CA. DOE + Boeing + NASA. SSFL Area IV sodium reactor + radioactive material cleanup.",
)

# Merge audit H-1 record additions (records flipped from (iii) to (i) post-audit).
prov <- bind_rows(prov, h1_records |> filter(panel_year == 2018L) |> select(-panel_year))

finalize_cost_year(prov, 2018L)
