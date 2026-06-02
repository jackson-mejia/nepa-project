# 2021 cost extraction — all 38 cat(i) records with full provenance.
# Same schema as 2022-2024.

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(tibble)
})

library(here)
source(here("code", "_h1_records.R"))    # H-1 audit additions
source(here("code", "_cost_helpers.R"))  # finalize_cost_year()
OUT_PATH <- here("data", "processed", "cost_extraction_2021.csv")

prov <- tribble(
  ~eis_number, ~lead_agency, ~state, ~cost_m_usd_nominal, ~cost_year, ~cost_method, ~cost_source_url, ~cost_source_title, ~cost_source_publisher, ~cost_source_date, ~cost_source_page, ~cost_quote, ~cost_confidence, ~imputed, ~imputation_basis, ~cost_notes,

  20210005L, "USFS", "AZ", 7000, 2021L, "web_imputed",
    "https://resolutioncopper.com/land-exchange/",
    "Resolution Copper Project and Land Exchange", "resolutioncopper.com", "2021", NA_integer_,
    "Pre-construction $500M; ultimate mine capex not disclosed. Tier-1 underground copper mine. $1B/yr operating economic contribution.",
    "low", TRUE, "Tier-1-copper-mine-capex (~$7B based on similar Rio Tinto/BHP underground copper)",
    "Rio Tinto/BHP JV. Underground mine beneath Oak Flat. EIS for land exchange enabling mine development.",

  20210008L, "BLM", "CA", 550, 2021L, "web",
    "https://californiaglobe.com/articles/department-of-interior-approves-massive-550-million-riverside-county-solar-power-project/",
    "Department of Interior Approves Massive $550 million Riverside County Solar Power Project",
    "californiaglobe.com", "2021", NA_integer_,
    "The Crimson Solar Project represents an investment of roughly $550 million.",
    "high", FALSE, NA_character_,
    "350 MW PV + 350 MW BESS (1400 MWh). Recurrent Energy.",

  20210009L, "FTA", "PA", 3000, 2023L, "web",
    "https://billypenn.com/2023/03/17/septa-pulls-the-plug-on-kop-rail-pausing-the-3b-project-over-fta-concerns/",
    "SEPTA pulls the plug on KOP Rail", "billypenn.com", "2023-03-17", NA_integer_,
    "the latest projection was $3.02 billion.",
    "high", FALSE, NA_character_,
    "SEPTA King of Prussia Rail Extension. EIS completed 2021; project paused 2023.",

  20210018L, "BLM", "CA", 0, 2021L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Duplicate of Crimson Solar EIS (20210008) — appears twice in NOA stream.",
    "high", FALSE, NA_character_,
    "Same project as 20210008. Counted under that record.",

  20210027L, "USACE", "NE", 180, 2024L, "web",
    "https://omaha.com/news/local/its-an-expressway-u-s-275-is-now-four-lanes-from-omaha-to-west-point/article_b416bfc0-9c86-11ef-a84e-13c3e139e530.html",
    "It's an expressway! U.S. 275 is now four lanes from Omaha to West Point", "omaha.com", "2024", NA_integer_,
    "A 20-mile stretch of Highway 275 from Scribner to West Point cost around $180 million.",
    "high", FALSE, NA_character_,
    "Nebraska DOT 4-lane expansion. USACE 404 permit lead.",

  20210028L, "BOEM", "MA", 3000, 2021L, "web",
    "https://www.iberdrola.com/about-us/power/offshore-wind-energy/vineyard-wind-offshore-wind-farm",
    "Vineyard Wind I", "iberdrola.com", "2021", NA_integer_,
    "The USD 3 billion project is expected to start full operation by the end of 2025.",
    "high", FALSE, NA_character_,
    "800 MW. First US commercial-scale offshore wind. Avangrid+CIP. Final cost was $4.5B with overruns.",

  20210030L, "USAF", "SD", 1000, 2021L, "web",
    "https://listen.sdpb.org/business-economics/2022-03-15/ellsworth-air-force-base-begins-construction-for-b-21-bomber-plane",
    "Ellsworth Air Force Base begins construction for B-21 bomber plane", "listen.sdpb.org", "2022", NA_integer_,
    "estimated construction spending of more than $1 billion.",
    "medium", FALSE, NA_character_,
    "B-21 MOB 1 selected Ellsworth (SD). EIS title mentions Dyess (TX) as alternative; ROD chose Ellsworth.",

  20210031L, "FAA", "NY", 2400, 2023L, "web",
    "https://en.wikipedia.org/wiki/AirTrain_LaGuardia",
    "AirTrain LaGuardia", "wikipedia.org", "2023", NA_integer_,
    "the project's budget had increased to $2.4 billion.",
    "high", FALSE, NA_character_,
    "Cancelled in March 2023. PANYNJ 1.5-mile elevated AirTrain. Started at $450M.",

  20210036L, "BR", "WA", 50, 2021L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Leavenworth NFH Surface Water Intake Fish Screens & Fish Passage. Rehab 80-year-old intake. Cost not surfaced.",
    "low", TRUE, "Fish-hatchery-intake-rehab-typical (~$50M)",
    "Bureau of Reclamation + USFWS joint ROD April 2021.",

  20210039L, "USFS", "AZ", 30, 2021L, "web",
    "https://capstonecopper.com/news/capstones-pinto-valley-mine-gets-usfs-approval-extends-operations-to-2039/",
    "Capstone's Pinto Valley Mine Receives New US Forest Service Mine Plan of Operations", "capstonecopper.com", "2021", NA_integer_,
    "Capstone Mining announced a 10-percent expansion of the Pinto Valley open pit mine, with the project costing about $30 million.",
    "medium", FALSE, NA_character_,
    "10% expansion of existing copper mine. Capstone Resources/Copper. Mine life to 2039.",

  20210040L, "FTA", "TX", 1700, 2021L, "web",
    "https://www.wfaa.com/article/news/local/dart-d2-dallas-city-council-subway-downtown-light-rail/287-8e346d39-aa78-4888-90d4-6d5d55682746",
    "Dallas City Council gives DART green light for federal funding on $1.7 billion downtown Dallas subway",
    "wfaa.com", "2021", NA_integer_,
    "Dallas council backs federal funding for $1.7 billion downtown subway.",
    "high", FALSE, NA_character_,
    "DART D2 Subway. 2.4-mile expansion through downtown. Removed from DART 20-yr plan in 2023.",

  20210043L, "FRA", "OR", 950, 2021L, "web",
    "https://railroads.dot.gov/sites/fra.dot.gov/files/2021-04/OPR%20CIP%20Tier%201%20FEIS_AppA-1_DEIS.pdf",
    "Oregon Passenger Rail Tier 1 FEIS", "railroads.dot.gov", "2021-04", NA_integer_,
    "Alternative 1, the preferred alternative, would include anywhere from $870 to $1,025 million in capital costs.",
    "medium", FALSE, NA_character_,
    "Pacific Northwest Rail Corridor — Eugene to Portland. ODOT-led Tier 1 EIS. Phased implementation planned.",

  20210046L, "USACE", "CA", 100, 2021L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Reclamation District 17 Levee Seepage Phase 3. Cutoff walls, DSM walls, seepage berms over 19 miles of levees.",
    "low", TRUE, "USACE-major-levee-rehab (~$100M)",
    "Sacramento Delta levee improvements (Mossdale Tract). 200-year flood protection target.",

  20210055L, "FAA", "CA", 1200, 2024L, "web",
    "https://elevatebur.com/the-agreement/about-project-faq/",
    "BUR Replacement Terminal FAQ", "elevatebur.com", "2024", NA_integer_,
    "Guaranteed Maximum Price $1.11B; estimated total project cost ~$1.2B. BGPA approved GMP in 2024.",
    "high", FALSE, NA_character_,
    "355K sf 14-gate terminal. CORRECTED 2026-06-01 (spot-check): was $1.3B with stale quote; published GMP $1.11B + financing/contingency ~$1.2B total.",

  20210062L, "TREAS", "MD", 1400, 2022L, "web",
    "https://www.constructionequipmentguide.com/treasury-department-to-build-14b-facility-in-maryland-to-print-us-currency/56509",
    "Treasury Department to Build $1.4B Facility to Print U.S. Currency", "constructionequipmentguide.com", "2022", NA_integer_,
    "The new $1.4 billion facility will be on the campus of the former Beltsville Agricultural Research Center.",
    "high", FALSE, NA_character_,
    "Bureau of Engraving & Printing currency production facility. 920K sf on 104 acres.",

  20210065L, "BIA", "NV", 400, 2021L, "web_imputed",
    "https://www.bia.gov/news/bia-issues-final-eis-moapa-bands-proposed-southern-bighorn-solar-project",
    "BIA Issues Final EIS for Moapa Band's Proposed Southern Bighorn Solar Project", "bia.gov", "2021", NA_integer_,
    "400 MW total capacity across SBSP I (300 MW) + SBSP II (100 MW). Cost not stated.",
    "low", TRUE, "Solar capex (400 MW @ $1M/MW)",
    "Moapa Band of Paiute Indians + 8minute Solar Energy. Tribal trust land.",

  20210067L, "FRA", "NJ", 12300, 2021L, "web",
    "https://www.hudsontunnelproject.com/About_The_FEIS/",
    "Hudson Tunnel Project FEIS", "hudsontunnelproject.com", "2021-05-28", NA_integer_,
    "The $12.3 billion project covers... construction of a new two-track rail tunnel beneath the Hudson River.",
    "high", FALSE, NA_character_,
    "ORIGINAL Hudson Tunnel EIS. NOTE: 20230027 may be a different FRA NY project — needs verification.",

  20210070L, "USACE", "CA", 128, 2021L, "web",
    "https://www.cityofwoodland.gov/1466/Flood-Risk-Reduction-Project",
    "Lower Cache Creek Flood Risk Reduction Project", "cityofwoodland.gov", "2021", NA_integer_,
    "The estimated cost to the state is $128,235,450. The USACE is expected to fund approximately 65% of the total cost.",
    "high", FALSE, NA_character_,
    "City of Woodland + USACE + CVFPB. Levees + water conveyance channel.",

  20210079L, "CHSRA", "CA", 19700, 2021L, "web",
    "https://www.hsrail.org/blog/ca-hsr-chooses-route-through-mountains/",
    "CA HSR Chooses Route Through the Mountains", "hsrail.org", "2021", NA_integer_,
    "the total cost of the segment is an estimated $19.7 billion.",
    "high", FALSE, NA_character_,
    "Bakersfield-Palmdale segment. 83 miles, 10 miles of tunnels through Tehachapi Mountains.",

  20210082L, "FAA", "GA", 10, 2021L, "web",
    "https://thecurrentga.org/2021/12/20/spaceport-camden-clears-one-licensing-hurdle/",
    "Spaceport Camden clears one licensing hurdle", "thecurrentga.org", "2021-12-20", NA_integer_,
    "the county has spent nearly 10 years and $10 million on the environmental impact statement and associated safety and procedural reviews.",
    "low", FALSE, NA_character_,
    "Spaceport license, not capex. FAA approved 12 launches/year for 5 years. No major infrastructure capex in EIS scope.",

  20210089L, "FRA", "GA", 7000, 2021L, "web",
    "https://www.dot.ga.gov/InvestSmart/Rail/EIS/03-Introduction.pdf",
    "Atlanta to Charlotte Passenger Rail Corridor Investment Plan", "dot.ga.gov", "2021", NA_integer_,
    "The study estimated the cost to build the line at between $6.2 billion and $8.4 billion.",
    "medium", FALSE, NA_character_,
    "Southeast HSR Atlanta-Charlotte. 274-mile Greenfield Corridor preferred alternative. Midpoint $7B used.",

  20210110L, "BLM", "NV", 200, 2021L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Robinson Mine Plan of Operations Amendment. 4-year mine-life extension at existing KGHM copper mine. Waste rock disposal expansion.",
    "low", TRUE, "Mine-extension-amendment (~$200M for waste rock + minor capex)",
    "KGHM Polska Miedz. ~125 Mlbs Cu/yr existing operation.",

  20210113L, "USACE", "CA", 3600, 2021L, "web",
    "https://www.transit.dot.gov/funding/grants/grant-programs/capital-investments/westside-purple-line-extension-section-3-0",
    "Westside Purple Line Extension Section 3 Project Profile", "transit.dot.gov", "2021", NA_integer_,
    "Section 3: A 2.5-mile, $3.6-billion project that will build two new stations and connect Century City with Westwood/VA Hospital.",
    "high", FALSE, NA_character_,
    "USACE adoption of FTA Westside Purple Line EIS (Section 3 specifically). LA Metro project.",

  20210120L, "BLM", "NV", 50, 2021L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Relief Canyon Mine Expansion Amendment. Heap-leach gold mine. 91k oz/yr, 5.6-year life. Small-scale.",
    "low", TRUE, "Small-gold-mine-amendment (~$50M)",
    "Pershing Gold (now Americas Silver). Earlier expansion in 2016.",

  20210121L, "BOEM", "MA", 2000, 2024L, "web",
    "https://www.utilitydive.com/news/south-fork-wind-begins-operations-New-York-Eversource/710536/",
    "South Fork Wind becomes first US utility-scale offshore wind farm", "utilitydive.com", "2024", NA_integer_,
    "The South Fork Wind Farm ended up totaling $2 billion.",
    "high", FALSE, NA_character_,
    "132 MW. 12 Siemens Gamesa 11 MW turbines. First completed utility-scale US offshore wind farm.",

  20210143L, "FHWA", "IN", 1200, 2025L, "web",
    "https://i69ohiorivercrossing.com/section-2-i-69-bridge/",
    "Section 2: I-69 Bridge", "i69ohiorivercrossing.com", "2025", NA_integer_,
    "construction anticipated to begin in 2027 and continue through 2031 at an estimated cost of more than $1.2 billion.",
    "high", FALSE, NA_character_,
    "I-69 Ohio River Crossing bridge (Section 2). Henderson, KY-Evansville, IN. Plus $158M Section 1 (KY approach) separately.",

  20210145L, "USACE", "MT", 42, 2021L, "web",
    "https://billingsgazette.com/news/state-and-regional/montana/fort-peck-dam-repairs-to-cost-million/article_855a19ef-b75c-5ca0-a47a-ee83bccb79a0.html",
    "Fort Peck Dam repairs to cost $42.9 million", "billingsgazette.com", "2021", NA_integer_,
    "the estimated cost of projects at Fort Peck is $41.7 million.",
    "medium", FALSE, NA_character_,
    "Test release operations (4-day test, 30,000 cfs). Not new construction.",

  20210146L, "FERC", "LA", 200, 2021L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "East Lateral Xpress (TC Energy). 725 MMcf/d total capacity. Supplies Venture Global Plaquemines LNG.",
    "low", TRUE, "FERC-pipeline-LNG-feed (~$200M)",
    NA_character_,

  20210147L, "FHWA", "VA", 745, 2025L, "web",
    "https://www.vdot.virginia.gov/projects/salem-district/martinsville-southern-connector-study/",
    "Martinsville Southern Connector study", "vdot.virginia.gov", "2025", NA_integer_,
    "The preliminary cost estimate for the preferred alternative is approximately $745 million (in 2025 dollars).",
    "high", FALSE, NA_character_,
    "Route 220 Martinsville Southern Connector. New limited-access road. EIS 2021; ROD not issued.",

  20210148L, "FERC", "PA", 200, 2021L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Transco East 300 Upgrade. New compressor station + 2 existing upgrades in NJ and PA. Cost not surfaced.",
    "low", TRUE, "Compressor-station-upgrades (~$200M for new + 2 upgrades)",
    NA_character_,

  20210150L, "USACE", "CA", 170, 2021L, "web",
    "https://www.enr.com/articles/54812-port-of-long-beach-oks-170m-plan-to-deepen-ship-channel",
    "Port of Long Beach OKs $170M Plan to Deepen Ship Channel", "enr.com", "2021", NA_integer_,
    "The proposed $170-million Deep Draft Navigation Channel Deepening Project.",
    "high", FALSE, NA_character_,
    "Long Beach Approach Channel 76→80 ft. Cost-shared 50/50 federal/port.",

  20210151L, "FERC", "PA", 200, 2021L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Marcus Hook Electric Compression. NGL terminal compressor at Sunoco/Energy Transfer Marcus Hook complex.",
    "low", TRUE, "NGL-electric-compressor-mid (~$200M)",
    NA_character_,

  20210154L, "FERC", "LA", 670, 2022L, "web",
    "https://naturalgasintel.com/news/kinder-morgans-evangeline-pass-expansion-ramps-up-alongside-plaquemines-lng-terminal-startup/",
    "Kinder Morgan's Evangeline Pass Expansion", "naturalgasintel.com", "2022", NA_integer_,
    "KMI's $670 million Evangeline Pass Expansion would add about 2 Bcf/d capacity on the TGP and SNG systems.",
    "high", FALSE, NA_character_,
    "Tennessee Gas Pipeline + Southern Natural Gas joint expansion. Feeds Plaquemines LNG.",

  20210157L, "FERC", "AZ", 127, 2023L, "web",
    "https://www.gem.wiki/North_Baja_Gas_Pipeline",
    "North Baja Gas Pipeline", "gem.wiki", "2023", NA_integer_,
    "The North Baja expansion cost an estimated US$127 million.",
    "high", FALSE, NA_character_,
    "TC Energy. 495 MDth/d capacity. Ehrenberg compressor station upgrade.",

  20210165L, "CHSRA", "CA", 5000, 2021L, "web_imputed",
    "https://www.permits.performance.gov/permitting-project/dot-projects/california-high-speed-rail-program-burbank-los-angeles-project",
    "California HSR Program: Burbank to Los Angeles Project Section", "permits.performance.gov", "2021", NA_integer_,
    "~14-mile segment using LA River right-of-way. Cost not specifically stated for this segment.",
    "low", TRUE, "Per-mile HSR cost (~$350M/mile × 14 mi)",
    "Burbank-LA segment. Distinct from Palmdale-Burbank ($22.6B, 2024).",

  20210167L, "FERC", "LA", 81, 2022L, "web",
    "https://www.compressortech2.com/news/ferc-approves-new-gas-export-pipelines/8021084.article",
    "FERC approves new gas export pipelines", "compressortech2.com", "2022", NA_integer_,
    "The project is expected to cost around $81.1 million.",
    "high", FALSE, NA_character_,
    "ANR Pipeline Alberta Xpress + Lease Capacity Abandonment. 0.165 Bcf/d.",

  20210174L, "FERC", "NY", 272, 2022L, "web",
    "https://marcellusdrilling.com/2022/03/iroquois-gas-enhancement-by-compression-project-approved-by-ferc/",
    "Iroquois Gas Enhancement by Compression Project Approved by FERC", "marcellusdrilling.com", "2022", NA_integer_,
    "The $272 million Iroquois Enhancement by Compression Project.",
    "high", FALSE, NA_character_,
    "Iroquois Gas Transmission. +125 MMcf/d via compressor upgrades at Dover & Athens (NY) + Brookfield & Milford (CT).",

  20210181L, "FRA", "NY", 2000, 2025L, "web",
    "https://www.related.com/press-releases/2025-06-30/city-council-approves-financing-enables-historic-plan-develop-western",
    "City Council approves financing for Western Railyards", "related.com", "2025-06-30", NA_integer_,
    "$2 billion platform over the active rail lines.",
    "medium", FALSE, NA_character_,
    "Western Rail Yard Platform & Tunnel Encasement (Amtrak + WRY Tenant). Hudson Yards site."
)

# Merge audit H-1 record additions (records flipped from (iii) to (i) post-audit).
prov <- bind_rows(prov, h1_records |> filter(panel_year == 2021L) |> select(-panel_year))

finalize_cost_year(prov, 2021L)
