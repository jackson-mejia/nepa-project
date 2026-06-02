# 2015 cost extraction — all cat(i) records (deduplicated) with full provenance.
# Same schema as 2016-2024.

suppressPackageStartupMessages({library(dplyr); library(readr); library(tibble)})

library(here)
source(here("code", "_h1_records.R"))    # H-1 audit additions
source(here("code", "_cost_helpers.R"))  # finalize_cost_year()
OUT_PATH <- here("data", "processed", "cost_extraction_2015.csv")

prov <- tribble(
  ~eis_number, ~lead_agency, ~state, ~cost_m_usd_nominal, ~cost_year, ~cost_method, ~cost_source_url, ~cost_source_title, ~cost_source_publisher, ~cost_source_date, ~cost_source_page, ~cost_quote, ~cost_confidence, ~imputed, ~imputation_basis, ~cost_notes,

  20140385L, "BLM", "NV", 300, 2015L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Long Canyon Mine. Newmont open-pit gold. Phase 1 capex ~$300M.",
    "medium", FALSE, NA_character_,
    "Elko County NV. Newmont.",

  20150016L, "FHWA", "FL", 100, 2015L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "SR 997 / Krome Avenue South Miami-Dade. FDOT corridor improvements.",
    "low", TRUE, "Suburban-arterial-widening (~$100M)",
    "Miami-Dade FL. FDOT.",

  20150024L, "FHWA", "ME", 90, 2015L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "I-395 / Route 9 Transportation System Brewer ME. New 4-mi connector. MaineDOT.",
    "low", TRUE, "Connector-highway-rural (~$90M)",
    "Brewer ME. MaineDOT.",

  20150035L, "FHWA", "TX", 300, 2015L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "US 69 / Loop 49 North Lindale Reliever Route. TxDOT new 18-mi rural reliever.",
    "low", TRUE, "Rural-reliever-route (~$300M)",
    "Smith County TX. TxDOT.",

  20150050L, "USA", "CA", 400, 2015L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Piers 2 and 3 Modernization Military Ocean Terminal Concord. Army marine terminal recap.",
    "low", TRUE, "Military-marine-terminal-recap (~$400M)",
    "Concord CA. Army Surface Deployment & Distribution.",

  20150052L, "FTA", "CA", 360, 2015L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Redlands Passenger Rail (Arrow). 9-mi diesel commuter rail. ~$360M project. SBCTA + Metrolink.",
    "high", FALSE, NA_character_,
    "Redlands-San Bernardino CA. Opened 2022.",

  20150064L, "USACE", "FL", 400, 2015L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Port Everglades Harbor Navigation. USACE deepening + widening. Federal share ~$400M.",
    "high", FALSE, NA_character_,
    "Broward County FL. USACE Jacksonville District.",

  20150077L, "USFS", "CO", 30, 2015L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Eldora Mountain Resort Ski Area Projects. Lifts + terrain expansion.",
    "low", TRUE, "Small-ski-resort-expansion (~$30M)",
    "Boulder County CO. Eldora (POWDR).",

  20150082L, "BR", "CA", 0, 2015L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Long-term Water Transfers (BR/SLDMWA). Original 2015 Final NOA — superseded by 2019 re-noticed Final (same eis_number, cal_year 2019). Underlying program reclassified to (ii).",
    "high", FALSE, NA_character_,
    "Same eis_number has TWO Final NOAs (2015 + 2019). Canonical attribution at 2019 panel; this row kept at $0 for coverage completeness.",

  20150085L, "FTA", "WA", 2900, 2015L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Lynnwood Link Extension. Sound Transit 8.5-mi LRT. $2.9B final cost.",
    "high", FALSE, NA_character_,
    "Snohomish County WA. Sound Transit. Opens 2024.",

  20150091L, "CALTRANS", "CA", 1000, 2015L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "I-405 Sepulveda Pass Improvement. Caltrans HOV lanes + interchanges. Phase work ~$1B+ federal portion (full project >$1.6B with Metro).",
    "medium", TRUE, "Urban-interstate-HOV-add (~$1B)",
    "Los Angeles CA. Caltrans + LA Metro.",

  20150092L, "BOP", "KS", 400, 2015L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Leavenworth FCI and Federal Prison Camp. BOP new federal correctional + prison camp.",
    "low", TRUE, "BOP-federal-prison-mid (~$400M)",
    "Leavenworth KS. BOP.",

  20150094L, "FERC", "AL", 0, 2015L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Martin Dam Hydroelectric Project No. 349-173 (relicensing). Existing dam relicense.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Hydro relicensing.",

  20150114L, "FHWA", "CA", 1800, 2015L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Mid County Parkway. RCTC new 16-mi corridor Perris-San Jacinto. ~$1.8B program.",
    "medium", TRUE, "New-arterial-corridor (~$1.8B for 16 mi)",
    "Riverside County CA. RCTC.",

  20150116L, "DOE", "TX", 0, 2015L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "DOE adoption of FERC Cheniere Corpus Christi LNG EIS (pre-window FERC EIS).",
    "high", FALSE, NA_character_,
    "Adoption — underlying FERC EIS pre-dates panel.",

  20150121L, "BLM", "WY", 3000, 2015L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "TransWest Express Transmission. Anschutz Corp. ~730-mi 600kV DC WY-NV. ~$3B project.",
    "high", FALSE, NA_character_,
    "WY to NV via UT/CO. Construction now underway.",

  20150131L, "FHWA", "TX", 200, 2015L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "US 281 Texas widening/upgrade. TxDOT corridor improvement.",
    "low", TRUE, "Rural-highway-upgrade (~$200M)",
    "Texas. TxDOT.",

  20150153L, "STB", "UT", 124, 2015L, "web",
    "https://utahrails.net/utahrails/six-county.html",
    "Central Utah Rail Project", "utahrails.net", "2015", NA_integer_,
    "$124 million 43-mi rail Levan-Salina UT. STB construction exemption effective Oct 2015.",
    "high", FALSE, NA_character_,
    "Six County Association of Governments. SUFCO coal mine access.",

  20150163L, "BLM", "CA", 700, 2015L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Soda Mountain Solar Project. Bechtel ~358 MW utility solar BLM CA Desert. Project cancelled but FEIS issued.",
    "medium", FALSE, NA_character_,
    "San Bernardino County CA. BrightSource Energy.",

  20150181L, "USACE", "CA", 0, 2015L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "USACE adoption of CALTRANS/FHWA I-5 North Coast Corridor EIS.",
    "high", FALSE, NA_character_,
    "Adoption — primary CALTRANS.",

  20150188L, "USACE", "SC", 580, 2015L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Charleston Harbor Post 45 Deepening. USACE harbor to -52 ft MLLW. Federal share ~$580M.",
    "high", FALSE, NA_character_,
    "Charleston SC. USACE Charleston District.",

  20150202L, "FHWA", "LA", 0, 2015L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Adoption of LADOTD I-12 to Bush highway EIS.",
    "high", FALSE, NA_character_,
    "Adoption.",

  20150204L, "BOP", "KY", 0, 2015L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Letcher County BOP USP/FPC (earlier filing of 20160066 same project).",
    "high", FALSE, NA_character_,
    "Same project as 20160066. Cost attributed to 20160066 ($510M). Zeroed here to avoid double-count.",

  20150220L, "FHWA", "ID", 80, 2015L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "US-95 Thorncreek Rd to Moscow ID. ITD realignment ~6 mi.",
    "low", TRUE, "Rural-highway-realign (~$80M)",
    "Latah County ID. ITD.",

  20150222L, "BR", "CA", 1400, 2015L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Shasta Lake Water Resources Investigation. BR dam raise study. $1.4B project. Not constructed but FEIS issued.",
    "medium", FALSE, NA_character_,
    "Shasta County CA. Reclamation. Authorization pending; counted at full FEIS-stage capex.",

  20150224L, "USFS", "CO", 20, 2015L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Breckenridge Multi-Season Recreation Projects. White River NF. Modest year-round resort capex.",
    "low", TRUE, "Ski-resort-multi-season-mod (~$20M)",
    "Summit County CO. Vail Resorts.",

  20150225L, "FRA", "FL", 4000, 2015L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "All Aboard Florida Intercity Passenger Rail Orlando-Miami (Brightline). $4B Orlando extension + initial Miami segment.",
    "high", FALSE, NA_character_,
    "Brightline Trains FL. Orlando-Miami in service 2023.",

  20150233L, "FERC", "LA", 11000, 2015L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Lake Charles Liquefaction Project. Energy Transfer / Shell. ~16.45 mtpa. ~$11B project. FID pending.",
    "high", FALSE, NA_character_,
    "Lake Charles LA. Energy Transfer (was Shell).",

  20150246L, "FHWA", "IA", 50, 2015L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Eastern Hills Drive and Connecting Roadways Iowa. Modest connector project.",
    "low", TRUE, "Urban-connector-mod (~$50M)",
    "Iowa DOT.",

  20150259L, "FRA", "NC", 4000, 2015L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Southeast HSR Richmond-Raleigh Tier II. ~162 mi conventional HSR upgrade. FRA estimate ~$4B.",
    "medium", FALSE, NA_character_,
    "VA-NC. NCDOT + VPRA + FRA.",

  20150260L, "BR", "CA", 0, 2015L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "CVP Municipal & Industrial Water Shortage Policy. Operational allocation policy, no construction.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Water allocation policy.",

  20150264L, "FHWA", "TN", 130, 2015L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Pellissippi Parkway Extension SR 162. TDOT new alignment.",
    "low", TRUE, "Suburban-arterial-extension (~$130M)",
    "Blount County TN. TDOT.",

  20150265L, "BR", "CA", 100, 2015L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "North Valley Regional Recycled Water Program. Modesto / Turlock recycled water pipeline.",
    "low", TRUE, "Recycled-water-program (~$100M)",
    "Modesto-Turlock CA. Modesto-Turlock-Del Puerto JPA.",

  20150269L, "FHWA", "NY", 7200, 2015L, "web",
    "https://www.panynj.gov/port/en/our-port/port-development/cross-harbor-freight-program.html",
    "Cross Harbor Freight Program (Port Authority)", "panynj.gov", "2015", NA_integer_,
    "Rail tunnel alternative estimated $7.2 billion in Tier 1 FEIS.",
    "high", FALSE, NA_character_,
    "NJ-Brooklyn freight rail tunnel. Tier 1 FEIS issued. Project not advanced.",

  20150270L, "FHWA", "MN", 240, 2015L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "US Highway 53 Virginia to Eveleth MN. MnDOT relocation over Rouchleau Pit. ~$240M project.",
    "high", FALSE, NA_character_,
    "Iron Range MN. MnDOT.",

  20150280L, "FTA", "WA", 700, 2015L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Link Light Rail Operations & Maintenance Facility (East). Sound Transit. LRT maintenance facility.",
    "low", TRUE, "Transit-O&M-facility (~$700M)",
    "Bellevue WA. Sound Transit.",

  20150285L, "FERC", "OR", 0, 2015L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Initial 2015 FEIS round for Jordan Cove Energy + Pacific Connector Pipeline. Counted at $0 — primary attribution at 20190276 (later Final EIS round, 2019 panel). Project ultimately cancelled Dec 2021.",
    "high", FALSE, NA_character_,
    "Coos Bay OR. Pembina. Zeroed to avoid double-count with 20190276.",

  20150299L, "NRC", "WI", 300, 2025L, "web_imputed",
    "https://www.prnewswire.com/news-releases/shine-receives-conditional-commitment-for-263-million-doe-loan-to-scale-domestic-medical-isotope-manufacturing-using-fusion-technology-302737635.html",
    "SHINE Conditional Commitment $263M DOE Loan", "prnewswire.com", "2025", NA_integer_,
    "Original construction $100M (2018 ref); subsequent DOE/NNSA cumulative funding ~$114M; conditional $263M DOE loan announced 2025 for scale-up. Total facility investment to date ~$300M.",
    "medium", TRUE, "Medical-isotope-facility-built-out (~$300M cumulative)",
    "Janesville WI. SHINE Medical Technologies. CORRECTED 2026-06-01 (spot-check): was $200M; revised up after surfacing cumulative DOE loan + investor inputs.",

  20150307L, "DOE", "VT", 1600, 2015L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "New England Clean Power Link. ~154-mi HVDC Lake Champlain to NH grid. TDI New England. ~$1.6B project.",
    "high", FALSE, NA_character_,
    "Vermont. TDI / Blackstone.",

  20150310L, "DOE", "MN", 710, 2015L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Great Northern Transmission Line. Minnesota Power. ~220-mi 500kV MN-MB Canadian intertie. ~$710M.",
    "high", FALSE, NA_character_,
    "ALLETE / Minnesota Power. In service 2020.",

  20150316L, "DOE", "OK", 2500, 2015L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Plains and Eastern Clean Line Transmission. Clean Line Energy. ~720-mi 600kV OK-TN. ~$2.5B project. Cancelled 2017 but FEIS issued.",
    "high", FALSE, NA_character_,
    "Clean Line Energy. Cancelled but FEIS issued.",

  20150319L, "BLM", "OR", 0, 2015L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "BLM adoption of FERC Jordan Cove EIS (20150285).",
    "high", FALSE, NA_character_,
    "Adoption.",

  20150324L, "FRA", "CA", 0, 2015L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Coast Corridor Improvements (Caltrain corridor services planning). Service-level improvements; programmatic Tier scope.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Service planning.",

  20150325L, "FERC", "LA", 4400, 2015L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Magnolia LNG + Lake Charles Expansion. LNG Limited. ~8 mtpa. ~$4.4B. Project sold/restarted multiple times; never reached FID under LNG Ltd. FEIS issued.",
    "medium", FALSE, NA_character_,
    "Lake Charles LA. LNG Limited (sold to GFL/Glenfarne).",

  20150331L, "USFS", "OR", 0, 2015L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "USFS adoption of FERC Jordan Cove EIS (20150285).",
    "high", FALSE, NA_character_,
    "Adoption.",

  20150341L, "NPS", "FL", 0, 2015L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "East Everglades Expansion Area Land Acquisition. Federal land acquisition for ENP. No infrastructure construction.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Land acquisition.",

  20150345L, "FHWA", "NC", 200, 2015L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "US 70 Havelock Bypass NC. NCDOT new bypass.",
    "low", TRUE, "Rural-bypass-mid (~$200M)",
    "Craven County NC. NCDOT.",

  20150347L, "FERC", "CA", 0, 2015L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Merced River and Merced Falls Hydroelectric Projects (relicensing). Existing hydro relicense.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Hydro relicensing.",

  20150360L, "FERC", "FL", 3000, 2015L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Southeast Market Pipelines Project (Sabal Trail + FSC + HHL). ~$3B project. Williams + Spectra + NextEra.",
    "high", FALSE, NA_character_,
    "AL-GA-FL. In service 2017.",
)

# Merge audit H-1 record additions (records flipped from (iii) to (i) post-audit).
prov <- bind_rows(prov, h1_records |> filter(panel_year == 2015L) |> select(-panel_year))

finalize_cost_year(prov, 2015L)
