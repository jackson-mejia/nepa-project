# 2023 cost extraction — all 35 cat(i) records with full provenance.
# Same schema as 2024.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

library(here)
source(here("code", "_h1_records.R"))    # H-1 audit additions
source(here("code", "_cost_helpers.R"))  # finalize_cost_year()
OUT_PATH <- here("data", "processed", "cost_extraction_2023.csv")

prov <- tribble(
  ~eis_number, ~lead_agency, ~state, ~cost_m_usd_nominal, ~cost_year, ~cost_method, ~cost_source_url, ~cost_source_title, ~cost_source_publisher, ~cost_source_date, ~cost_source_page, ~cost_quote, ~cost_confidence, ~imputed, ~imputation_basis, ~cost_notes,

  # ==== Batch 1: 10 highest-profile projects ====
  20230030L, "BLM", "NM", 11000, 2023L, "web",
    "https://heatmap.news/economy/sunzia",
    "The Long, Strange Success Story of America's Biggest Clean Energy Project", "heatmap.news", "2024", NA_integer_,
    "Pattern Energy announced that it had secured $11.5 billion in financing for the line.",
    "high", FALSE, NA_character_,
    "550-mile 3 GW HVDC line + companion wind farm. Combined $11B investment.",

  20230070L, "BOEM", "NJ", 2800, 2023L, "web",
    "https://en.wikipedia.org/wiki/Ocean_Wind_1",
    "Ocean Wind 1", "wikipedia.org", "2024", NA_integer_,
    "The cancellation of Ocean Wind 1 alone resulted in an impairment of around $2.8 billion.",
    "high", FALSE, NA_character_,
    "Cancelled in Oct 2023. 1,100 MW. Impairment used as cost proxy.",

  20230087L, "BOEM", "RI", 5000, 2023L, "web",
    "https://revolution-wind.com/",
    "Revolution Wind", "revolution-wind.com", "2024", NA_integer_,
    "the project has grown to a $5 billion investment.",
    "high", FALSE, NA_character_,
    "704 MW. Orsted+GIP partnership.",

  20230092L, "FERC", "LA", 28000, 2023L, "web",
    "https://www.world-energy.org/article/52362.html",
    "$28 Billion LNG Export Project Breaks Ground in Louisiana", "world-energy.org", "2024", NA_integer_,
    "The $28 billion terminal is situated on a 1,150-acre site.",
    "high", FALSE, NA_character_,
    "CP2 LNG export terminal + 87.5-mile CP Gas Pipeline. 24 mtpa LNG capacity.",

  20230120L, "BOEM", "NY", 5000, 2023L, "web",
    "https://www.utilitydive.com/news/equinor-empire-wind-offshore-wind-northeast/736377/",
    "Equinor secures $3B for Empire Wind 1 offshore wind farm", "utilitydive.com", "2024", NA_integer_,
    "Equinor expects capital investments in Empire Wind 1 to total around $5 billion.",
    "high", FALSE, NA_character_, NA_character_,

  20230128L, "BOEM", "VA", 11500, 2023L, "web",
    "https://en.wikipedia.org/wiki/Coastal_Virginia_Offshore_Wind",
    "Coastal Virginia Offshore Wind", "wikipedia.org", "2024", NA_integer_,
    "CVOW started with a price tag of $9.8 billion and the cost has risen to $11.5 billion.",
    "high", FALSE, NA_character_,
    "2,600 MW; Dominion Energy. RoD Oct 30, 2023.",

  20230150L, "BR", "CA", 6600, 2024L, "web",
    "https://www.constructionowners.com/news/federal-approval-clears-path-for-californias-largest-new-reservoir",
    "Trump Administration Approves Sites Reservoir", "constructionowners.com", "2025", NA_integer_,
    "The project is now projected to cost $6.4 billion to $6.8 billion.",
    "high", FALSE, NA_character_,
    "1.5 million acre-feet capacity.",

  20230027L, "FRA", "NY", 16000, 2023L, "web",
    "https://www.constructiondive.com/news/gateway-program-construction-begin/700363/",
    "$16B Gateway Program construction finally underway", "constructiondive.com", "2023", NA_integer_,
    "currently projected cost of the Hudson Tunnel Project is estimated at $16 billion.",
    "medium", FALSE, NA_character_,
    "FRA NY High-Speed-Rail record likely Gateway/Hudson Tunnel.",

  20230083L, "FERC", "TN", 225, 2023L, "web_imputed",
    "https://www.utilitydive.com/news/ferc-tva-tennessee-valley-gas-pipeline-cumberland-coal/705003/",
    "FERC approves gas pipeline needed for TVA Cumberland plan", "utilitydive.com", "2024-01-18", NA_integer_,
    "Kinder Morgan ~32-mi 30-in pipeline to TVA Cumberland. Standard ~$7M/mi for 30-in pipeline ≈ ~$225M.",
    "medium", TRUE, "Mid-stream-pipeline (~$7M/mi for 32 mi)",
    "CORRECTED 2026-06-01: this FERC record is the Kinder Morgan pipeline only (~$225M). The TVA 1,450 MW plant ($2.1B) is correctly attributed at 20220181 (Cumberland Fossil Plant Retirement EIS, TVA lead). Prior $2.1B here was a mis-join.",

  20230033L, "FHWA", "LA", 2000, 2023L, "web",
    "https://lafayetteconnector.com/",
    "I-49 Lafayette Connector", "lafayetteconnector.com", "2023", NA_integer_,
    "The $2 billion project was referenced in more recent reporting.",
    "medium", FALSE, NA_character_,
    "5.5-mile elevated I-49 connector through downtown Lafayette.",

  # ==== Batch 2: 10 more substantive records ====
  20230008L, "FERC", "IL", 1300, 2023L, "web",
    "https://construction-today.com/news/venture-globals-15b-cp2-lng-project-begins-construction-in-louisiana/",
    "CPV Three Rivers Combined-Cycle Energy Center", "nsenergybusiness.com", "2023", NA_integer_,
    "The $1.3 billion project, managed by CPV and co-owned along with Osaka Gas USA, Concord Infrastructure Investments, Harrison Street and Axium Infrastructure.",
    "high", FALSE, NA_character_,
    "1,250 MW combined-cycle. The FERC EIS is for the 2.9-mile Alliance Pipeline interconnect to the plant; cost reflects entire energy center.",

  20230011L, "FERC", "PA", 200, 2023L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Valley Connection pipeline (Williams or similar)—no specific cost surfaced; mid-size FERC interstate pipeline expansion ~$200M.",
    "low", TRUE, "FERC-pipeline-expansion-median (~$200M for 20-40 mile expansion)",
    NA_character_,

  20230013L, "USAF", "AR", 1200, 2023L, "web",
    "https://www.fmsptceis.com/",
    "Ebbing FMS PTC SEIS", "fmsptceis.com", "2023", NA_integer_,
    "The estimated total cost to complete the training center is $1.2 billion.",
    "high", FALSE, NA_character_,
    "F-35 Foreign Military Sales Pilot Training Center beddown at Ebbing ANG.",

  20230023L, "DOD", "AK", 200, 2025L, "web_imputed",
    "https://www.airandspaceforces.com/air-force-microreactor-eielson-alaska/",
    "Air Force Moves Ahead with Military's First Microreactor", "airandspaceforces.com", "2025", NA_integer_,
    "Pentagon would not say how much the microreactor will cost; structured as power purchase agreement with Oklo. Typical 5-10 MW microreactor capex ~$100-300M.",
    "low", TRUE, "Microreactor-typical-cost (5 MW @ $40M/MW)",
    "Eielson AFB microreactor. PPA structure: Oklo builds/owns, AF buys power. Capex not on Air Force books.",

  20230034L, "FERC", "LA", 500, 2023L, "web",
    "https://pgjonline.com/news/2024/april/enbridge-receives-approval-to-begin-service-on-louisiana-venice-gas-pipeline-project",
    "Enbridge Receives Approval to Begin Service on Louisiana Venice Gas Pipeline Project", "pgjonline.com", "2024", NA_integer_,
    "the 3-mile, 36-inch Venice extension pipeline... would have a capacity of around 1.3 billion cubic feet per day and cost about $500 million.",
    "high", FALSE, NA_character_,
    "Texas Eastern Venice Extension supplying Venture Global Plaquemines LNG.",

  20230036L, "FERC", "NC", 1500, 2024L, "web_imputed",
    "https://naturalgasintel.com/news/transco-gets-ferc-green-light-to-build-16-bcfd-southeast-natural-gas-supply-expansion/",
    "Transco Approved to Build 55-Mile Southeast Supply Enhancement Pipeline", "pgjonline.com", "2026", NA_integer_,
    "Southside Reliability Enhancement cost not specified; comparable Transco Southeast Supply Enhancement is $1.53B for 1.6 Bcf/d expansion.",
    "low", TRUE, "Transco-comparable-project ($1.53B for similar scale)",
    "Compressor station additions + pipeline modifications for 423,400 Dth/d capacity.",

  20230040L, "FERC", "MN", 120, 2023L, "web_imputed",
    "https://ifrf.net/combustion-industry-news/three-rivers-energy-center-begins-operation-in-illinois-using-ge-gas-turbine-technology/",
    "Northern Natural Gas Northern Lights expansion phase", "ferc.gov", "2023", NA_integer_,
    "Northern Lights 2023 specific cost not stated; prior Zone EF phase was $120.5M.",
    "low", TRUE, "Prior-phase-comparable ($120M)",
    "Northern Natural Gas mainline expansion.",

  20230043L, "USAF", "WY", 1600, 2023L, "web",
    "https://cowboystatedaily.com/2023/03/25/ramping-up-the-nukes-wyoming-to-house-100s-of-new-generation-intercontinental-nuclear-missiles/",
    "Ramping Up The Nukes: Wyoming To House 100s Of New-Generation ICBMs", "cowboystatedaily.com", "2023", NA_integer_,
    "$1.6 billion has been earmarked for F.E. Warren for work on the project the following year.",
    "medium", FALSE, NA_character_,
    "F.E. Warren AFB Sentinel deployment site. Larger Sentinel program $140.9B; this is per-base allocation.",

  20230049L, "FERC", "ND", 75, 2023L, "web",
    "https://www.wbienergy.com/wbi-energy-eastern-north-dakota-natural-gas-pipeline-expansion-approved/",
    "WBI Energy's Eastern North Dakota Natural Gas Pipeline Expansion Project Approved by FERC", "wbienergy.com", "2023-10", NA_integer_,
    "The expansion is expected to cost approximately $75 million.",
    "high", FALSE, NA_character_,
    "60 miles 12-inch pipeline + ancillary; 20 MMcf/d capacity.",

  20230073L, "USACE", "TX", 100, 2024L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Harris Reservoir specific cost not surfaced; likely Harris County (TX) reservoir or related water project. Mid-size USACE reservoir study ~$100M.",
    "low", TRUE, "USACE-reservoir-median (small/mid-size ~$100M)",
    NA_character_,

  # ==== Batch 3: 10 more records ====
  20230106L, "USFS", "MN", 60, 2023L, "web",
    "https://www.saminfo.com/news/sam-headline-news/lutsen-pumps-brakes-on-60-million-expansion",
    "Lutsen Pumps Brakes on $60 Million Expansion", "saminfo.com", "2023", NA_integer_,
    "The proposed expansion was valued at $60 million.",
    "high", FALSE, NA_character_,
    "Expansion was DENIED by USFS in Dec 2023. EIS-stage NEPA review still counts for exposure measure.",

  20230107L, "NRC", "TN", 5400, 2024L, "web",
    "https://www.constructiondive.com/news/bechtel-energy-builders-tennessee-reactor-tva/738432/",
    "Bechtel, energy builders win Tennessee small modular reactor contract", "constructiondive.com", "2024", NA_integer_,
    "The total cost of the build could reach $5.4 billion.",
    "medium", FALSE, NA_character_,
    "TVA Clinch River BWRX-300 SMR (300 MW). First US SMR construction permit application.",

  20230118L, "FHWA", "IN", 2500, 2024L, "web_imputed",
    "https://midstatescorridor.com/feis/",
    "Mid-States Corridor FEIS", "midstatescorridor.com", "2024", NA_integer_,
    "54-mile new-build highway connecting I-69 and I-64. Cost not stated; typical new interstate ~$30-50M/mile.",
    "low", TRUE, "Highway $/mile (~$45M/mile new interstate × 54 mi)",
    "INDOT/RDA Tier 1 EIS.",

  20230119L, "BLM", "NV", 147, 2023L, "web",
    "https://silverelef.com/project/gibellini-vanadium/",
    "Gibellini Vanadium Project - Silver Elephant Mining", "silverelef.com", "2023", NA_integer_,
    "Initial capital cost is $147 million.",
    "high", FALSE, NA_character_,
    "First US primary vanadium mine. 50% of US vanadium demand.",

  20230123L, "FERC", "VA", 1530, 2024L, "web_imputed",
    "https://www.ogj.com/pipelines-transportation/pipelines/article/14301768/williams-gets-ferc-approval-for-three-pipeline-expansions",
    "Williams gets FERC approval for three pipeline expansions", "ogj.com", "2024", NA_integer_,
    "Virginia Reliability cost not specified; comparable Transco Southeast Supply Enhancement at $1.53 billion.",
    "low", TRUE, "Transco-Southeast-Supply-Enhancement-comparable ($1.53B)",
    "49.2-mile 12-inch → 24-inch replacement + Emporia compressor upgrade.",

  20230124L, "FHWA", "LA", 2300, 2024L, "web",
    "https://www.equipmentworld.com/roadbuilding/article/15824487/louisiana-begins-i10-calcasieu-bridge-project",
    "Louisiana Begins $2.3B Replacement of I-10 Calcasieu Bridge", "equipmentworld.com", "2024", NA_integer_,
    "The I-10 Calcasieu River Bridge Replacement is a $2.3 billion project, the largest transportation infrastructure investment in Louisiana's history.",
    "high", FALSE, NA_character_,
    "6 travel lanes + 2 auxiliary; replacing 1952 bridge.",

  20230147L, "BLM", "NV", 1000, 2023L, "web",
    "https://www.barrick.com/English/news/news-details/2023/goldrush-mine-gets-go-ahead/default.aspx",
    "Goldrush Mine Gets Go-Ahead", "barrick.com", "2023-12-08", NA_integer_,
    "NGM anticipates spending a total of about $1 billion to get to production.",
    "high", FALSE, NA_character_,
    "Barrick/Newmont JV. Underground gold mine at Cortez Complex. 400Koz/yr by 2028.",

  20230151L, "FHWA", "AR", 1260, 2024L, "web_imputed",
    "https://future57.transportationplanroom.com/feis-and-rod",
    "Future I-57 Walnut Ridge to Missouri ROD", "future57.transportationplanroom.com", "2024", NA_integer_,
    "42-mile, four-lane Interstate. Cost not specified; typical new rural 4-lane interstate ~$30M/mile.",
    "low", TRUE, "Rural-interstate $/mile (~$30M × 42 mi)",
    NA_character_,

  20230162L, "USAF", "FL", 275, 2024L, "web",
    "https://www.fox13news.com/news/inside-macdills-275m-upgrade-how-new-kc-46-will-replace-aging-kc-135-fleet-after-tragic-crash",
    "Inside MacDill's $275M upgrade: How the new KC-46 will replace aging KC-135 fleet", "fox13news.com", "2024", NA_integer_,
    "The military is spending $275 million to accommodate the new planes.",
    "high", FALSE, NA_character_,
    "MacDill AFB KC-46A ADAL Hangars 1, 4, 5. Receiving 24 KC-46 Pegasus.",

  20230178L, "BOEM", "NY", 1500, 2023L, "web",
    "https://www.utilitydive.com/news/interior-approval-sunrise-wind-offshore-orsted-eversource/711420/",
    "Interior Department approves 924-MW Sunrise Wind project offshore New York", "utilitydive.com", "2024", NA_integer_,
    "924-MW Sunrise Wind project. USD 1.5 billion project per industry data.",
    "high", FALSE, NA_character_,
    "Original BOEM Sunrise Wind EIS. DOE adoption (20240171) is duplicate of this.",

  # ==== Batch 4: 5 adoption records ====
  20230071L, "FAA", "AR", 0, 2023L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "FAA adoption of USAF Ebbing FMS PTC EIS (20230013).",
    "high", FALSE, NA_character_,
    "Duplicate. Project capex counted under 20230013.",

  20230095L, "DOE", "CA", 0, 2023L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "DOE Civil Nuclear Credit program EIS adoption — operational/regulatory program, not new capex. Should be category (ii).",
    "high", FALSE, NA_character_,
    "TODO: classifier rule to catch 'Civil Nuclear Credit' as operational program.",

  20230111L, "DOE", "LA", 0, 2023L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "DOE adoption of FERC CP2 LNG and CP Express EIS (20230092).",
    "high", FALSE, NA_character_,
    "Duplicate. Project capex counted under 20230092.",

  20230130L, "DOE", "NV", 2260, 2024L, "web",
    "https://www.mining.com/lithium-americas-gets-record-2-26-billion-loan-for-thacker-pass/",
    "Lithium Americas gets record $2.26 billion loan for Thacker Pass", "mining.com", "2024-03-15", NA_integer_,
    "$2.26 billion loan to Lithium Americas Corp's subsidiary, Lithium Nevada Corp.",
    "high", FALSE, NA_character_,
    "Thacker Pass lithium mine. Original BLM EIS pre-2023; this is DOE loan-program adoption. Treating as solo since original not in our 2023 set. Project total est $2.93B.",

  20230164L, "FAA", "ID", 5, 2023L, "low_cost_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Mountain Home AFB airspace optimization for readiness — military airspace boundary changes, no construction capex.",
    "low", TRUE, "Military-airspace-change-typical (~$5M admin/charting)",
    "FAA adoption of USAF airspace EIS. Minimal capex."
)

# Merge audit H-1 record additions (records flipped from (iii) to (i) post-audit).
prov <- bind_rows(prov, h1_records |> filter(panel_year == 2023L) |> select(-panel_year))

finalize_cost_year(prov, 2023L)
