# 2016 cost extraction — all cat(i) records (deduplicated) with full provenance.
# Same schema as 2017-2024.

suppressPackageStartupMessages({library(dplyr); library(readr); library(tibble)})

library(here)
source(here("code", "_h1_records.R"))    # H-1 audit additions
source(here("code", "_cost_helpers.R"))  # finalize_cost_year()
OUT_PATH <- here("data", "processed", "cost_extraction_2016.csv")

prov <- tribble(
  ~eis_number, ~lead_agency, ~state, ~cost_m_usd_nominal, ~cost_year, ~cost_method, ~cost_source_url, ~cost_source_title, ~cost_source_publisher, ~cost_source_date, ~cost_source_page, ~cost_quote, ~cost_confidence, ~imputed, ~imputation_basis, ~cost_notes,

  20160001L, "FHWA", "CO", 1300, 2018L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "I-70 East (Central 70) Denver. CDOT design-build. ~$1.3B project (10-mi widening + lowered freeway).",
    "high", FALSE, NA_character_,
    "Denver. CDOT. Kiewit Meridiam Partners. Opened 2022.",

  20160010L, "FHWA", "UT", 80, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "1800 North (SR-37) Project. UDOT corridor widening Davis County.",
    "low", TRUE, "Suburban-arterial-widening (~$80M)",
    "Davis County UT. UDOT.",

  20160012L, "FHWA", "LA", 1500, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Baton Rouge Loop Tier 1. New ~30-mi outer beltway program. Tier 1 selected corridor preserved.",
    "low", TRUE, "New-beltway-program (~$1.5B Tier 1 scale)",
    "Baton Rouge LA. DOTD + Capital Area Expressway Authority.",

  20160016L, "FHWA", "TX", 400, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "SH 249 Extension TX. New 38-mi toll segment Pinehurst-Navasota. TxDOT.",
    "medium", TRUE, "New-rural-tollway (~$400M)",
    "Houston-area TX. TxDOT.",

  20160028L, "FHWA", "WI", 1200, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "I-94 East-West Corridor (70th-16th) Milwaukee. WisDOT 3.5-mi urban interstate reconstruction.",
    "medium", TRUE, "Urban-interstate-recon (~$1.2B)",
    "Milwaukee WI. WisDOT. Construction late 2024.",

  20160029L, "BPA", "WA", 400, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "I-5 Corridor Reinforcement transmission. BPA 500kV ~75-mi WA-OR. Project paused 2017.",
    "low", TRUE, "500kV-transmission-mid (~$400M)",
    "BPA. Paused/cancelled mid-2017 but FEIS issued.",

  20160041L, "FTA", "NC", 2400, 2016L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Durham-Orange Light Rail. 17.7-mi LRT GoTriangle. Cost estimate $2.4B. Cancelled March 2019 but FEIS issued.",
    "high", FALSE, NA_character_,
    "Durham-Chapel Hill NC. GoTriangle. Cancelled 2019.",

  20160045L, "TVA", "TN", 0, 2016L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "TVA Floating Houses Policy Review EIS. Operational policy on existing structures. No construction.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Policy review, not capex.",

  20160048L, "USAF", "AK", 550, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "F-35A Operational Beddown Pacific (Eielson AFB). 54 aircraft beddown MILCON.",
    "low", TRUE, "F-35-beddown-MILCON (~$550M)",
    "Eielson AFB AK. USAF.",

  20160049L, "DOE", "NM", 0, 2016L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Disposal of GTCC Low-Level Radioactive Waste PEIS. Programmatic — no specific facility authorized.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Programmatic.",

  20160066L, "BOP", "KY", 510, 2016L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Letcher County USP. $510M BOP federal prison project. Cancelled by BOP 2019 but FEIS issued.",
    "medium", FALSE, NA_character_,
    "Letcher County KY. BOP. Surface mine reclamation site.",

  20160076L, "BLM", "WY", 2200, 2016L, "web",
    "https://americanwildhorse.org/stories/wy-continental-divide-creston-gas-drilling-project-raises-concerns-for-wild-horses-3518",
    "BLM Continental Divide-Creston Gas project", "americanwildhorse.org", "2016", NA_integer_,
    "BP investing up to $2.2 billion to double production from its acreage. Up to 8,950 wells.",
    "high", FALSE, NA_character_,
    "Carbon + Sweetwater WY. BP + Anadarko et al. Wamsutter field.",

  20160091L, "FERC", "ID", 60, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Bear River Narrows Hydroelectric. New ~14 MW hydro on Bear River ID.",
    "low", TRUE, "Small-hydro-greenfield (~$60M)",
    "Caribou County ID. Twin Lakes Canal Company.",

  20160099L, "USFS", "OR", 30, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Granite Creek Watershed Mining Project. Small mining plan of operations.",
    "low", TRUE, "Small-mining-POO (~$30M)",
    "Wallowa-Whitman NF OR.",

  20160100L, "FTA", "MN", 2750, 2018L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Southwest LRT (METRO Green Line Extension). 14.5-mi LRT Minneapolis-Eden Prairie. $2.75B estimate (rose to $2.86B+).",
    "high", FALSE, NA_character_,
    "Metro Transit + FTA CIG. Construction ongoing.",

  20160104L, "BLM", "WY", 3000, 2016L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Energy Gateway South Transmission. PacifiCorp 500kV ~400 mi WY-UT. Industry estimate ~$3B.",
    "medium", TRUE, "500kV-transmission-major (~$3B for 400 mi)",
    "PacifiCorp.",

  20160105L, "BLM", "NV", 100, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Coeur Rochester Mine POO Amendment 10. Coeur Mining silver-gold mine expansion. Plan of Permanent Closure.",
    "low", TRUE, "Mine-expansion-mid (~$100M)",
    "Pershing County NV. Coeur Mining.",

  20160114L, "FHWA", "TX", 300, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Grand Parkway SH 99 Segment B. ~52-mi outer beltway Houston. TxDOT toll.",
    "medium", TRUE, "New-tollway-rural (~$6M/mi)",
    "Houston TX. TxDOT.",

  20160124L, "FERC", "AK", 200, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Sweetheart Lake Hydroelectric. New ~19.8 MW hydro. Juneau Hydropower.",
    "low", TRUE, "Small-hydro-AK-greenfield (~$200M)",
    "Juneau AK area.",

  20160125L, "BIA", "NV", 300, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Aiya Solar Project. Moapa Band of Paiutes. ~200 MW tribal land solar.",
    "low", TRUE, "Utility-solar-tribal-land (~$1.5M/MW)",
    "Clark County NV. Moapa River Indian Reservation.",

  20160128L, "USACE", "NC", 50, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Morehead City Harbor Integrated Dredged Material Management Plan. DMMP — disposal facility siting + operations.",
    "low", TRUE, "USACE-DMMP-mid (~$50M)",
    "Morehead City NC. USACE Wilmington District.",

  20160133L, "FTA", "VA", 370, 2016L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Potomac Yard Metrorail Station. WMATA infill station. ~$370M project (rose to $400M+).",
    "high", FALSE, NA_character_,
    "Alexandria VA. WMATA. Opened May 2023.",

  20160136L, "USACE", "PA", 2700, 2016L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Upper Ohio Navigation Study. USACE 3-locks replacement (Emsworth + Dashields + Montgomery). Total ~$2.7B program.",
    "medium", TRUE, "USACE-locks-replacement-major (~$2.7B)",
    "Pittsburgh PA. USACE Pittsburgh District.",

  20160139L, "BLM", "UT", 500, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Monument Butte Oil and Gas Development. ~5,750 wells over 15 years. Newfield Exploration.",
    "low", TRUE, "Utah-oil-gas-development (~$500M)",
    "Duchesne + Uintah UT. Newfield/Encana.",

  20160142L, "BLM", "NV", 200, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Bald Mountain Mine North/South Operations Area. Barrick / Kinross. Mine expansion.",
    "low", TRUE, "Gold-mine-expansion-mid (~$200M)",
    "White Pine County NV. Barrick.",

  20160147L, "USFS", "AK", 35, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Kake to Petersburg Transmission Line Intertie. Tongass NF. ~57-mi transmission. Sealaska Heritage interties.",
    "low", TRUE, "Rural-transmission-intertie (~$35M)",
    "SE Alaska. USFS + Inside Passage Electric Cooperative.",

  20160149L, "BIA", "FL", 50, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Seminole Tribe of Florida Fee-to-Trust. Land transfer for tribal economic development. Modest project scale.",
    "low", TRUE, "Tribal-fee-to-trust-mod (~$50M)",
    "Florida. Seminole Tribe.",

  20160155L, "FTA", "MN", 1500, 2016L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Bottineau LRT METRO Blue Line Extension. 13-mi LRT Minneapolis-Brooklyn Park. Original $1.5B (rose to $2.95B+, project withdrew from CIG 2020 but rejoined).",
    "medium", FALSE, NA_character_,
    "Metro Transit + FTA. Hennepin County MN.",

  20160160L, "BR", "CA", 200, 2016L, "sector_impute_pending",
    "https://www.restoresjr.net/projects/restoration/2b-and-mendota-reach-bypass/",
    "SJRRP Reach 2B and Mendota Pool Bypass", "restoresjr.net", "2016", NA_integer_,
    "Half-mile river-like fish-passage bypass channel around Mendota Pool + Reach 2B channel improvements. Phase 1 of SJRRP construction.",
    "low", TRUE, "Fish-passage-channel-construction (~$200M)",
    "Fresno County CA. BR + SJRRP. CORRECTED 2026-06-01: this is the Reach 2B Bypass CONSTRUCTION project, distinct from 20190259 Mendota Pool Group Exchange Program (water trading contract, correctly reclassified to (ii)).",

  20160163L, "DOE", "LA", 0, 2016L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "DOE adoption of FERC Lake Charles Liquefaction EIS (20150233).",
    "high", FALSE, NA_character_,
    "Adoption — primary FERC.",

  20160170L, "BIA", "IN", 80, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Pokagon Band Potawatomi Fee-to-Trust Tribal Village. Mid-size tribal residential + community development.",
    "low", TRUE, "Tribal-village-development (~$80M)",
    "South Bend IN. Pokagon Band.",

  20160178L, "BLM", "CO", 0, 2016L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Previously Issued Oil and Gas Leases in White River NF. Lease validity reanalysis. No new authorization.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Lease reanalysis.",

  20160180L, "FERC", "TX", 10000, 2019L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Golden Pass LNG Export Project. ExxonMobil + Qatar Petroleum. 18 mtpa. Construction ~$10B+.",
    "high", FALSE, NA_character_,
    "Sabine Pass TX. ExxonMobil/Qatar Energy. First LNG late 2025/2026.",

  20160181L, "FERC", "OH", 4200, 2018L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Rover Pipeline. Energy Transfer. 713-mi WV/PA/OH/MI. ~$4.2B project.",
    "high", FALSE, NA_character_,
    "Energy Transfer Rover. In service 2018.",

  20160183L, "USFS", "CO", 20, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Arapahoe Basin Ski Area Projects. White River NF. Modest resort capex.",
    "low", TRUE, "Ski-resort-on-mountain-mod (~$20M)",
    "Summit County CO. A-Basin.",

  20160194L, "FAA", "AK", 40, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Angoon Airport Project. New ~3,300-ft rural airport. Tongass NF. FAA AK Region.",
    "low", TRUE, "Rural-airport-greenfield (~$40M)",
    "Angoon AK. ADOT.",

  20160203L, "FERC", "OH", 1600, 2017L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Leach XPress + Rayne XPress Expansions. Columbia Gas Transmission. ~$1.6B total program.",
    "medium", FALSE, NA_character_,
    "OH/WV/VA. TC Energy/Columbia.",

  20160216L, "HUD", "NY", 700, 2016L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Lambert Houses Redevelopment Bronx. ~1,665 units replacement + new mixed-use. Phipps Houses. ~$700M+.",
    "medium", FALSE, NA_character_,
    "Bronx NY. HUD HOPE / mixed-finance.",

  20160223L, "DOE", "LA", 0, 2016L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "DOE adoption of FERC Magnolia LNG + Lake Charles Expansion EIS (20150325).",
    "high", FALSE, NA_character_,
    "Adoption — primary FERC.",

  20160225L, "BR", "NM", 0, 2016L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Continued Implementation of 2008 Operating Agreement for the Rio Grande Project. Operational agreement, no construction.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Operational agreement.",

  20160229L, "DOE", "ID", 1650, 2016L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Recapitalization of Infrastructure Supporting Naval Spent Nuclear Fuel Handling. NRF Idaho. Spent Fuel Handling Recap Project ~$1.65B.",
    "medium", FALSE, NA_character_,
    "Naval Reactors Facility, INL ID. DOE-NNPP.",

  20160236L, "FAA", "OR", 0, 2016L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "FAA adoption of Oregon Military Training Airspace EIS.",
    "high", FALSE, NA_character_,
    "Adoption.",

  20160241L, "BLM", "WA", 50, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Vantage to Pomona Heights 230kV Transmission. PSE ~70-mi 230kV.",
    "low", TRUE, "230kV-transmission (~$50M for 70 mi)",
    "Yakima WA area. Puget Sound Energy.",

  20160245L, "BR", "MT", 58, 2016L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Lower Yellowstone Intake Diversion Dam Fish Passage. USACE/BR ~$58M federal project.",
    "high", FALSE, NA_character_,
    "Glendive MT. Pallid sturgeon fish passage.",

  20160270L, "FTA", "WA", 3100, 2016L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Federal Way Link Extension. Sound Transit ~7.8-mi LRT extension. ~$3.1B.",
    "high", FALSE, NA_character_,
    "King County WA. Sound Transit. Opens 2026.",

  20160273L, "FHWA", "FL", 80, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "SR 87 Connector Florida. FDOT new arterial Panhandle.",
    "low", TRUE, "New-arterial-rural (~$80M)",
    "Santa Rosa County FL. FDOT.",

  20160276L, "FRA", "MD", 6000, 2016L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Baltimore Potomac Tunnel Replacement (NEC). Amtrak. New ~1.4-mi tunnel. ~$6B project (rose since).",
    "high", FALSE, NA_character_,
    "Baltimore MD. Amtrak NEC Frederick Douglass Tunnel.",

  20160277L, "USCG", "LA", 1000, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Port Delfin Project Deepwater Port (FLNG). Delfin LNG. ~$1B+ project. FID still pending.",
    "low", TRUE, "Floating-LNG-deepwater (~$1B)",
    "Cameron Parish LA offshore. Delfin LNG.",

  20160279L, "BOEM", "LA", 0, 2016L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "OCS Oil and Gas Leasing Program 2017-2022. Programmatic 5-year plan.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Programmatic 5-year plan.",

  20160289L, "FERC", "OH", 2600, 2017L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "NEXUS Gas Transmission + Texas Eastern Appalachian Lease. ~257-mi 36-in OH/MI. ~$2.6B.",
    "high", FALSE, NA_character_,
    "Enbridge + DTE. In service 2018.",

  20160293L, "NPS", "VA", 0, 2016L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "NPS adoption of FTA Potomac Yard Metro EIS (20160133).",
    "high", FALSE, NA_character_,
    "Adoption — primary FTA.",

  20160300L, "BIA", "CA", 500, 2016L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Wilton Rancheria Fee-to-Trust + Casino. Mid-size tribal casino. ~$500M project.",
    "medium", FALSE, NA_character_,
    "Sacramento County CA. Wilton Rancheria.",

  20160308L, "USFS", "WY", 0, 2016L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Oil and Gas Leasing in Wyoming Range Bridger-Teton NF. Lease cancellation analysis. No development authorized.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Lease decision.",

  20160309L, "BOEM", "AK", 0, 2016L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Cook Inlet Planning Area OCS Lease Sale 244. Lease sale EIS only — no specific project.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Lease sale.",

  20160318L, "BR", "CA", 17000, 2016L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Bay Delta Conservation Plan / California WaterFix (twin tunnels). DWR/BR. ~$17B project. Withdrawn by Newsom 2019 but FEIS issued.",
    "high", FALSE, NA_character_,
    "Sacramento-San Joaquin Delta CA. DWR. Cancelled but FEIS issued — exposure attributable.",
)

# Merge audit H-1 record additions (records flipped from (iii) to (i) post-audit).
prov <- bind_rows(prov, h1_records |> filter(panel_year == 2016L) |> select(-panel_year))

finalize_cost_year(prov, 2016L)
