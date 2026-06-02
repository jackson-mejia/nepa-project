# 2017 cost extraction — all cat(i) records (deduplicated) with full provenance.
# Same schema as 2018-2024.

suppressPackageStartupMessages({library(dplyr); library(readr); library(tibble)})

library(here)
source(here("code", "_h1_records.R"))    # H-1 audit additions
source(here("code", "_cost_helpers.R"))  # finalize_cost_year()
OUT_PATH <- here("data", "processed", "cost_extraction_2017.csv")

prov <- tribble(
  ~eis_number, ~lead_agency, ~state, ~cost_m_usd_nominal, ~cost_year, ~cost_method, ~cost_source_url, ~cost_source_title, ~cost_source_publisher, ~cost_source_date, ~cost_source_page, ~cost_quote, ~cost_confidence, ~imputed, ~imputation_basis, ~cost_notes,

  20160322L, "FRA", "AZ", 0, 2017L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Arizona Passenger Rail Corridor Tucson-Phoenix Tier 1. Service-level planning study only.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Tier 1 planning EIS.",

  20160326L, "FERC", "PA", 3000, 2017L, "web",
    "https://www.williams.com/2017/09/18/atlantic-sunrise-project-breaks-ground-in-pennsylvania/",
    "Atlantic Sunrise breaks ground in Pennsylvania", "williams.com", "2017", NA_integer_,
    "Nearly $3 billion expansion of Transco. 1.7 Bcf/d. In service Oct 2018.",
    "high", FALSE, NA_character_,
    "Williams/Transco. PA + neighboring states.",

  20170010L, "USFS", "ID", 15, 2017L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Lookout Pass Ski Area Expansion. Modest small-resort expansion + new lift.",
    "low", TRUE, "Small-ski-resort-expansion (~$15M)",
    "Idaho Panhandle NF ID/MT.",

  20170012L, "TVA", "TN", 100, 2017L, "sector_impute_pending",
    "https://www.tva.com/environment/environmental-stewardship/coal-combustion-residuals/bull-run",
    "TVA Bull Run CCR", "tva.com", "2017", NA_integer_,
    "New CCR landfill at Bull Run Anderson County TN. Cost not disclosed; TVA CCR landfill program impute.",
    "low", TRUE, "TVA-CCR-landfill (~$100M)",
    "Bull Run Fossil Plant. Closed 2023.",

  20170013L, "NPS", "CA", 50, 2017L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Alcatraz Ferry Embarkation. New terminal at Pier 31.5 SF. Mid-size waterfront facility.",
    "low", TRUE, "Ferry-terminal-mid (~$50M)",
    "San Francisco. NPS + Hornblower.",

  20170017L, "BR", "CA", 0, 2017L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Long-Term Plan to Protect Adult Salmon in Lower Klamath River. Operational flow management plan, no construction.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Operational flow management.",

  20170018L, "DOE", "LA", 0, 2017L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "DOE adoption of FERC Golden Pass LNG Export Project EIS (20160180).",
    "high", FALSE, NA_character_,
    "Adoption — primary EIS FERC.",

  20170044L, "USFS", "CO", 50, 2017L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Snowmass Multi-Season Recreation Projects. Aspen Snowmass year-round expansion. Mid-size resort capex.",
    "low", TRUE, "Mid-size-resort-multi-season-expansion (~$50M)",
    "White River NF CO. Aspen Skiing Co.",

  20170053L, "USAF", "NC", 200, 2017L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "KC-46A Third Main Operating Base Beddown (Seymour Johnson AFB NC). Standard tanker beddown MILCON.",
    "low", TRUE, "KC-46A-beddown-MILCON (~$200M)",
    "Seymour Johnson AFB NC. USAF tanker recap program.",

  20170055L, "FERC", "PA", 1200, 2017L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "PennEast Pipeline. 116-mi PA-NJ. UGI Energy. Estimated ~$1.2B at announcement. Cancelled Sept 2021.",
    "medium", TRUE, "Mid-stream-pipeline (~$1.2B)",
    "UGI Energy / NJR / SJI. Cancelled 2021 but FEIS issued — exposure attributable.",

  20170059L, "USACE", "NY", 200, 2017L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Mamaroneck and Sheldrake Rivers Flood Risk Management. USACE channel modifications + flood walls.",
    "low", TRUE, "Urban-flood-risk-channel (~$200M)",
    "Westchester County NY. USACE NY District.",

  20130360L, "USFS", "AZ", 1900, 2017L, "web",
    "https://www.constructiondive.com/news/arizona-court-stops-1b-rosemont-copper-mine-construction/560105/",
    "Arizona court stops $1B Rosemont copper mine construction", "constructiondive.com", "2019", NA_integer_,
    "$1.9 billion Rosemont Copper project on $3.00/lb Cu price assumption (Hudbay).",
    "high", FALSE, NA_character_,
    "Coronado NF AZ. Hudbay Minerals. ROD vacated 2019; project paused but EIS exposure attributable.",

  20170085L, "NRC", "MO", 115, 2017L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Northwest Medical Isotopes Radioisotope Production Facility (Columbia MO). University-affiliated Mo-99 production. Mid-size medical isotope facility.",
    "low", TRUE, "Medical-isotope-production-facility (~$115M)",
    "University of Missouri area. NWMI.",

  20170088L, "USACE", "HI", 345, 2017L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Ala Wai Canal Flood Risk Management Project. USACE 2017 estimated total ~$345M federal share.",
    "medium", TRUE, "USACE-flood-risk-major (~$345M)",
    "Honolulu HI. USACE Honolulu District.",

  20170096L, "USACE", "MS", 570, 2017L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Port of Gulfport Expansion. Multi-phase port deepening + restoration. Estimated total ~$570M.",
    "low", TRUE, "Port-expansion-major (~$570M)",
    "Gulfport MS. MS State Port Authority.",

  20170098L, "HUD", "CA", 0, 2017L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "HUD adoption of FTA Transbay Terminal / Caltrain DTX EIS. Underlying project led by TJPA + FTA.",
    "high", FALSE, NA_character_,
    "Adoption — primary FTA (not in our (i) set).",

  20170113L, "FERC", "WV", 7850, 2017L, "web",
    "https://www.utilitydive.com/news/mountain-valley-pipeline-construction-complete/718724/",
    "$7.85B Mountain Valley Pipeline construction complete", "utilitydive.com", "2024", NA_integer_,
    "Final cost $7.85 billion. Originally $3.5B at 2014 announcement. In service 2024.",
    "high", FALSE, NA_character_,
    "MVP. 303-mi WV-VA. Equitrans + NextEra + Con Edison + WGL + RGC.",

  20170115L, "USFS", "WV", 0, 2017L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "USFS adoption of FERC Mountain Valley Pipeline EIS (20170113).",
    "high", FALSE, NA_character_,
    "Adoption — primary EIS FERC.",

  20170130L, "FHWA", "UT", 750, 2024L, "web",
    "https://www.alliant-inc.com/projects/west-davis-corridor-design-build/",
    "West Davis Corridor Design-Build", "alliant-inc.com", "2024", NA_integer_,
    "$750M design-build contract for SR-177 / West Davis Corridor 16-mi freeway. Opened Jan 2024.",
    "high", FALSE, NA_character_,
    "Davis County UT. UDOT.",

  20170134L, "FHWA", "IL", 2700, 2017L, "web",
    "https://www.equipmentworld.com/roadbuilding/article/14967779/idots-i-290eisenhower-expressway-expansion-receives-federal-approval",
    "IDOT I-290 Eisenhower expansion gets federal approval", "equipmentworld.com", "2017", NA_integer_,
    "IDOT estimates $2.7B for the I-290 Eisenhower expansion (FHWA CER 2017: $3.2B).",
    "high", FALSE, NA_character_,
    "Chicago. Currently unfunded but ROD issued — exposure attributable.",

  20170138L, "FERC", "VA", 8000, 2020L, "web",
    "https://www.utilitydive.com/news/duke-dominion-cancel-8b-atlantic-coast-pipeline/581028/",
    "Duke, Dominion cancel $8B Atlantic Coast Pipeline", "utilitydive.com", "2020-07-05", NA_integer_,
    "$8 billion cost (rose from $4.5-5.0B). Cancelled July 2020.",
    "high", FALSE, NA_character_,
    "ACP. WV-VA-NC. Dominion + Duke. Cancelled but FEIS issued.",

  20170139L, "FHWA", "IL", 200, 2017L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "US 30 IL 136 to IL 40 Whiteside County. Rural 4-lane expansion ~35 mi.",
    "low", TRUE, "Rural-4-lane-expansion (~$6M/mi)",
    "Whiteside County IL. IDOT.",

  20170143L, "FHWA", "UT", 80, 2017L, "sector_impute_pending",
    "https://permits.performance.gov/permitting-project/dot-projects/i-80-state-street-interchange",
    "I-80 State Street Interchange Permitting Dashboard", "permits.performance.gov", "2017", NA_integer_,
    "Westbound on-ramp + frontage road + structure widening + auxiliary lane improvements at one urban interchange. Modest-scale interchange project.",
    "low", TRUE, "Modest-urban-interchange-improvement (~$80M)",
    "South Salt Lake UT. UDOT + FHWA. CORRECTED 2026-06-01 (spot-check): was $400M assuming major interchange recon; actual scope is on/off-ramp + widening only.",

  20170148L, "FERC", "WV", 3200, 2019L, "web",
    "https://www.nsenergybusiness.com/news/transcanada-mountaineer-xpress-pipeline/",
    "TransCanada $3.2bn Mountaineer Xpress pipeline enters full service", "nsenergybusiness.com", "2019", NA_integer_,
    "$3.2 billion cost (rose from $2.06B at filing). 264-mi 36-in WV.",
    "high", FALSE, NA_character_,
    "Columbia Gas Transmission / TC Energy. WV.",

  20170149L, "BOEM", "LA", 0, 2017L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "G&G Activities on the Gulf of Mexico Outer Continental Shelf PEIS. Programmatic for seismic survey permits.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Programmatic.",

  20170158L, "DOE", "NH", 1600, 2017L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Northern Pass Transmission Line. 192-mi HVDC from Quebec via NH. Eversource. ~$1.6B project. Cancelled 2019.",
    "high", FALSE, NA_character_,
    "NH Site Evaluation Committee denied permit 2018. Cancelled but FEIS issued.",

  20170184L, "FRA", "GA", 0, 2017L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Atlanta-Chattanooga High Speed Ground Transportation. Tier 1 corridor planning study only.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Tier 1 planning.",

  20170194L, "BLM", "NV", 80, 2017L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Gold Bar Mine McEwen Mining. Small-mid Nevada gold mine. ~$80M McEwen capex.",
    "low", TRUE, "Small-mid-gold-mine (~$80M)",
    "Eureka County NV. McEwen Mining.",

  20170197L, "FAA", "OR", 0, 2017L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "FAA adoption of USAF Oregon Military Training Airspace EIS.",
    "high", FALSE, NA_character_,
    "Adoption.",

  20170198L, "USAF", "MD", 375, 2017L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Presidential Aircraft Recapitalization Program. VC-25B (new Air Force One) hangar + support facilities at JBA. MILCON estimate.",
    "low", TRUE, "Presidential-aircraft-hangar-MILCON (~$375M)",
    "Joint Base Andrews MD. USAF.",

  20170199L, "FAA", "CO", 0, 2017L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "FAA adoption of Army Pinon Canyon Maneuver Site EIS.",
    "high", FALSE, NA_character_,
    "Adoption — primary EIS Army.",

  20170203L, "USACE", "KS", 0, 2017L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Kansas River Commercial Dredging EIS. Permit decision for ongoing commercial sand-and-gravel dredging. Not new construction.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Commercial-permit renewal.",

  20170213L, "FHWA", "DE", 400, 2017L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "US 113 N/S Study Millsboro-South. DelDOT corridor improvements ~12 mi.",
    "low", TRUE, "Rural-arterial-upgrade (~$400M)",
    "Sussex County DE. DelDOT.",

  20170215L, "FRA", "TX", 0, 2017L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Texas-Oklahoma Passenger Rail Service-Level FEIS. Tier 1 study only.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Tier 1 service planning.",

  20170217L, "USACE", "TX", 1600, 2017L, "web",
    "https://www.constructionequipmentguide.com/ntmwd-builds-16b-bois-darc-lake/42934",
    "NTMWD Builds $1.6B Bois d'Arc Lake", "constructionequipmentguide.com", "2017", NA_integer_,
    "Estimated construction cost $1.6 billion for the lake and associated projects.",
    "high", FALSE, NA_character_,
    "Lower Bois d'Arc Creek Reservoir. NTMWD. Fannin County TX. USACE 404 permit.",

  20170228L, "FHWA", "NY", 110, 2017L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Scajaquada Expressway NY 198 Corridor Project (Buffalo). NYSDOT conversion to boulevard. Mid-size urban project.",
    "low", TRUE, "Urban-arterial-conversion (~$110M)",
    "Buffalo NY. NYSDOT.",

  20170237L, "TVA", "KY", 200, 2017L, "sector_impute_pending",
    "https://www.tva.com/environment/environmental-stewardship/coal-combustion-residuals/shawnee",
    "TVA Shawnee CCR", "tva.com", "2017", NA_integer_,
    "Shawnee Fossil Plant CCR management. Closure-in-place + new process water basin. Cost not disclosed. TVA CCR sector impute.",
    "low", TRUE, "TVA-CCR-landfill-closure (~$200M)",
    "Paducah KY. TVA CCR.",

  20170241L, "BLM", "WV", 0, 2017L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "BLM adoption/joint review of FERC Mountain Valley Pipeline + Equitrans Expansion EIS (20170113).",
    "high", FALSE, NA_character_,
    "CORRECTED 2026-06-01 (dup_sweep): not a standalone coal lease. Same project as 20170113 MVP/Equitrans. Was erroneously imputed $50M.",

  20170247L, "FHWA", "NC", 2200, 2017L, "web",
    "https://www.fhwa.dot.gov/ipd/project_profiles/nc_complete_540_phase_1.aspx",
    "FHWA Complete 540 Phase 1 Project Profile", "fhwa.dot.gov", "2017", NA_integer_,
    "Phase 1 $1.3B + Phase 2 ~$1.3B = ~$2.5B total program. 28-mi expressway extension.",
    "high", FALSE, NA_character_,
    "NCDOT/NCTA. Triangle Expressway SE Extension. Raleigh.",
)

# Merge audit H-1 record additions (records flipped from (iii) to (i) post-audit).
prov <- bind_rows(prov, h1_records |> filter(panel_year == 2017L) |> select(-panel_year))

finalize_cost_year(prov, 2017L)
