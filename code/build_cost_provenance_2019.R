# 2019 cost extraction — all 65 cat(i) records with full provenance.
# Same schema as 2020-2024. Includes 12 cross-year adoptions (auto $0).
# Four operational EISs flagged for reclassification to (ii).

suppressPackageStartupMessages({library(dplyr); library(readr); library(tibble)})

library(here)
source(here("code", "_h1_records.R"))    # H-1 audit additions
source(here("code", "_cost_helpers.R"))  # finalize_cost_year()
OUT_PATH <- here("data", "processed", "cost_extraction_2019.csv")

prov <- tribble(
  ~eis_number, ~lead_agency, ~state, ~cost_m_usd_nominal, ~cost_year, ~cost_method, ~cost_source_url, ~cost_source_title, ~cost_source_publisher, ~cost_source_date, ~cost_source_page, ~cost_quote, ~cost_confidence, ~imputed, ~imputation_basis, ~cost_notes,

  20180331L, "FERC", "LA", 4000, 2019L, "web",
    "https://www.reuters.com/business/energy/tellurian-cuts-driftwood-lng-cost-estimates-by-12-billion-2022-03-02/",
    "Tellurian cuts Driftwood LNG cost estimates", "reuters.com", "2022-03-02", NA_integer_,
    "Tellurian estimates Phase 1 of Driftwood will cost $12.0 billion to $12.8 billion (3 trains)—use $4B per train; Phase 1 EIS authorized first units.",
    "medium", FALSE, NA_character_,
    "Driftwood LNG, Calcasieu Parish LA. 27.6 mtpa nameplate. Acquired by Woodside 2024.",

  20180332L, "FERC", "CA", 30, 2019L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Yuba River Development Project (Narrows 1/2). FERC hydro relicensing for Yuba Water Agency. No new construction.",
    "low", TRUE, "Hydro-relicensing-upgrades (~$30M)",
    "Yuba County Water Agency. Existing 380 MW Yuba River projects.",

  20180333L, "FERC", "OR", 2000, 2019L, "web_imputed",
    "https://www.power-eng.com/news/swan-lake-north-pumped-storage-project-secures-license-from-ferc/",
    "Swan Lake North Pumped Storage Project secures license", "power-eng.com", "2019", NA_integer_,
    "393.3 MW pumped storage. Industry standard ~$2,000-3,000/kW for greenfield PSH.",
    "medium", TRUE, "Pumped-storage-capex (~$2B for 393 MW)",
    "Rye Development project. Klamath County OR.",

  20180334L, "FERC", "NY", 926, 2020L, "web",
    "https://www.spglobal.com/marketintelligence/en/news-insights/latest-news-headlines/williams-cos-shareholders-approve-northeast-supply-enhancement-pipeline-cancellation-58970245",
    "Williams Northeast Supply Enhancement", "spglobal.com", "2020", NA_integer_,
    "$926 million project; Williams cancelled in 2020 after NY/NJ permit denials.",
    "high", FALSE, NA_character_,
    "Transco NESE pipeline. 26 mi offshore + onshore NJ/NY. Cancelled but EIS issued — exposure attributable.",

  20190001L, "DOE", "LA", 0, 2019L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "DOE adoption of FERC Driftwood LNG EIS (20180331).",
    "high", FALSE, NA_character_,
    "Adoption — primary EIS attributed to FERC.",

  20190003L, "FERC", "LA", 13000, 2020L, "web",
    "https://www.sempra.com/sites/default/files/2021-03/Sempra-Energy-2020-Annual-Report.pdf",
    "Sempra Energy 2020 Annual Report — Port Arthur LNG", "sempra.com", "2020", NA_integer_,
    "Port Arthur LNG Phase 1 estimated ~$13B; FID 2023 at ~$13B for two trains 13.5 mtpa.",
    "high", FALSE, NA_character_,
    "Sempra Port Arthur. FID March 2023. Bechtel EPC.",

  20190010L, "USFS", "CO", 30, 2019L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Crested Butte Mountain Resort Ski Area Projects. Lift replacements, terrain expansion, snowmaking. No capex disclosed.",
    "low", TRUE, "Ski-resort-on-mountain-improvements (~$30M)",
    "Vail Resorts. GMUG NF.",

  20190013L, "DOE", "LA", 0, 2019L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "DOE adoption of FERC Port Arthur LNG EIS (20190003).",
    "high", FALSE, NA_character_,
    "Adoption — primary EIS attributed to FERC.",

  20190017L, "GSA", "CA", 675, 2019L, "web",
    "https://www.gsa.gov/about-us/newsroom/news-releases/biden-harris-administration-announces-investment-modernize-otay-mesa-land-port-of-entry-08092022",
    "GSA Otay Mesa Land Port of Entry Modernization", "gsa.gov", "2022-08-09", NA_integer_,
    "$675 million investment to modernize Otay Mesa Land Port of Entry; funded via IRA.",
    "high", FALSE, NA_character_,
    "San Diego LPOE expansion + reconfiguration. GSA + CBP.",

  20190024L, "BR", "WA", 400, 2019L, "web_imputed",
    "https://www.kittitascountynews.com/news/article_5e8b9e02-7fa0-11ea-983f-93b91dec1e60.html",
    "Kachess Drought Relief Pumping Plant", "kittitascountynews.com", "2019", NA_integer_,
    "Pumping plant + conveyance to provide drought-year water. Ecology-estimated ~$400M.",
    "medium", TRUE, "Major-pumping-station-infrastructure (~$400M)",
    "Yakima River basin drought relief. WA Ecology + Reclamation.",

  20190026L, "FHWA", "ND", 190, 2019L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "US 85 four-lane expansion I-94 to Watford City (62 mi). NDDOT phased construction. ~$3M/lane-mile rural sector estimate.",
    "low", TRUE, "Rural-4-lane-highway-expansion (~$3M/lane-mi)",
    "Bakken oil patch access road. Multiple phases.",

  20190034L, "FERC", "TX", 4500, 2019L, "web_imputed",
    "https://www.lngprime.com/news/texas-lng-cuts-capacity-of-its-brownsville-lng-export-project/41937/",
    "Texas LNG Brownsville Project", "lngprime.com", "2019", NA_integer_,
    "4 mtpa export terminal. Glenfarne project. Industry standard ~$1.0-1.2B/mtpa for greenfield mid-Gulf LNG.",
    "medium", TRUE, "LNG-export-greenfield (~$1.1B/mtpa)",
    "Brownsville Ship Channel. Reached FID late 2025.",

  20190037L, "FHWA", "NC", 500, 2019L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "I-26 widening I-4400/I-4700 Asheville area. NCDOT phased project. ~22 miles widening.",
    "low", TRUE, "Interstate-widening-rural (~$23M/mi)",
    "Henderson + Buncombe counties NC. STIP-funded.",

  20190041L, "DOE", "TX", 0, 2019L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "DOE adoption of FERC Texas LNG EIS (20190034).",
    "high", FALSE, NA_character_,
    "Adoption — primary EIS attributed to FERC.",

  20190044L, "BLM", "NM", 383, 2019L, "web",
    "https://www.mining.com/web/themac-resources-files-feasibility-study-for-copper-flat-project-in-new-mexico/",
    "THEMAC Resources Copper Flat Feasibility Study", "mining.com", "2013", NA_integer_,
    "Total initial capex of $383M for open-pit Cu-Mo mine.",
    "high", FALSE, NA_character_,
    "Sierra County NM. THEMAC Resources Group. Past-producing brownfield.",

  20190058L, "FHWA", "NY", 1700, 2020L, "web",
    "https://www.nyc.gov/office-of-the-mayor/news/430-20/mayor-de-blasio-major-progress-hunts-point-interstate-access-improvement",
    "Mayor de Blasio Major Progress Hunts Point Interstate Access", "nyc.gov", "2020-06-26", NA_integer_,
    "$1.7 billion Hunts Point Interstate Access Improvement Project.",
    "high", FALSE, NA_character_,
    "Bronx NY. NYSDOT + FHWA. Sheridan Blvd reconstruction.",

  20190062L, "FERC", "FL", 720, 2019L, "web_imputed",
    "https://lngprime.com/news/eagle-lng-cancels-jacksonville-lng-export-project/95876/",
    "Eagle LNG cancels Jacksonville LNG export project", "lngprime.com", "2024", NA_integer_,
    "Up to 1.0 mtpa export. Smaller-scale LNG ~$700-800M/mtpa for greenfield.",
    "medium", TRUE, "Small-scale-LNG-export (~$700-800M)",
    "Eagle LNG. Jacksonville FL. Cancelled 2024.",

  20190065L, "FERC", "MS", 9000, 2019L, "web_imputed",
    "https://www.naturalgasintel.com/news/gulf-lng-secures-export-authorization-following-ferc-environmental-approval/",
    "Gulf LNG secures export authorization", "naturalgasintel.com", "2019", NA_integer_,
    "Brownfield LNG export retrofit. ~10 mtpa nameplate. Brownfield ~$900M/mtpa.",
    "low", TRUE, "LNG-brownfield-conversion (~$9B for 10 mtpa)",
    "Pascagoula MS. Kinder Morgan. Brownfield import-to-export.",

  20190069L, "FERC", "TX", 1700, 2019L, "web",
    "https://www.bizjournals.com/sanantonio/news/2021/02/19/exclusive-annova-lng-cancels-massive-export-projec.html",
    "Annova LNG cancels massive export project", "bizjournals.com", "2021-02-19", NA_integer_,
    "$1.7B 6 mtpa Annova LNG; Exelon Generation cancelled March 2021.",
    "medium", FALSE, NA_character_,
    "Brownsville TX. Exelon-led. Cancelled but EIS issued — exposure attributable.",

  20190070L, "USFS", "ID", 30, 2019L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Crow Creek Pipeline Project. Phosphate slurry/dewatering pipeline serving Itafos Caldwell Canyon mine. Modest infrastructure.",
    "low", TRUE, "Mine-support-pipeline (~$30M)",
    "Caribou-Targhee NF ID. Itafos.",

  20190072L, "DOE", "FL", 0, 2019L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "DOE adoption of FERC Eagle LNG Jacksonville EIS (20190062).",
    "high", FALSE, NA_character_,
    "Adoption — primary EIS attributed to FERC.",

  20190078L, "FHWA", "WV", 100, 2019L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "US 340 Improvement Study. Jefferson County WV improvements/bypass. WVDOT.",
    "low", TRUE, "Mid-scale-highway-improvement (~$100M)",
    "Charles Town vicinity. WVDOH.",

  20190079L, "FERC", "TX", 18000, 2023L, "web",
    "https://www.reuters.com/business/energy/nextdecade-bechtel-sign-15-bln-rio-grande-lng-construction-contract-2023-04-21/",
    "NextDecade, Bechtel sign Rio Grande LNG construction contract", "reuters.com", "2023-04-21", NA_integer_,
    "Construction contract ~$12B Phase 1 (3 trains); Train 4 + 5 ~$6B add'l. Phase 2 expansion authorized.",
    "high", FALSE, NA_character_,
    "NextDecade Rio Grande LNG, Brownsville TX. Phase 1 FID July 2023.",

  20190083L, "DOE", "MS", 0, 2019L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "DOE adoption of FERC Gulf LNG Liquefaction EIS (20190065).",
    "high", FALSE, NA_character_,
    "Adoption — primary EIS attributed to FERC.",

  20190084L, "DOE", "TX", 0, 2019L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "DOE adoption of FERC Annova LNG EIS (20190069).",
    "high", FALSE, NA_character_,
    "Adoption — primary EIS attributed to FERC.",

  20190085L, "FERC", "AK", 45, 2019L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Grant Lake Hydroelectric (~5 MW). Kenai Hydro/HEA project. Small hydro ~$8-10M/MW.",
    "low", TRUE, "Small-hydro-greenfield (~$45M)",
    "Kenai Peninsula AK. Homer Electric Association subsidiary.",

  20190090L, "BR", "CA", 0, 2019L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Central Valley Project Water Supply Contracts Conversion: contract conversion under WIIN Act. No construction. Administrative action.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Update classifier to flag 'contract conversion'/'contract renewal' patterns.",

  20190091L, "FERC", "LA", 20000, 2022L, "web",
    "https://www.spglobal.com/commodityinsights/en/market-insights/latest-news/lng/070522-venture-global-lng-orders-supplies-for-plaquemines-phase-2-expansion-from-baker-hughes",
    "Venture Global Plaquemines LNG", "spglobal.com", "2022", NA_integer_,
    "20 mtpa export + Gator Express pipeline. Industry estimate ~$20B all-in for Phases 1+2.",
    "high", FALSE, NA_character_,
    "Venture Global Plaquemines. FID May 2022 Phase 1; Phase 2 FID 2023. First LNG Dec 2024.",

  20190095L, "FHWA", "SC", 2300, 2024L, "web",
    "https://www.scdot.org/inside/pdfs/projects/Carolina_Crossroads_Fact_Sheet.pdf",
    "SCDOT Carolina Crossroads Fact Sheet", "scdot.org", "2024", NA_integer_,
    "$2.3 billion total program for I-20/I-26/I-126 corridor in Columbia SC.",
    "high", FALSE, NA_character_,
    "SCDOT. Multi-phase reconstruction Columbia SC. Largest single project in SCDOT history.",

  20190096L, "DOE", "TX", 0, 2019L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "DOE adoption of FERC Rio Grande LNG EIS (20190079).",
    "high", FALSE, NA_character_,
    "Adoption — primary EIS attributed to FERC.",

  20190100L, "USFS", "NV", 24, 2019L, "web",
    "https://www.fs.usda.gov/nfs/11558/www/nepa/108957_FSPLT3_5018252.pdf",
    "Mt. Rose Ski Tahoe Atoma Area Expansion ROD", "fs.usda.gov", "2019", NA_integer_,
    "Total project capex stated $23.5M (lift + terrain + snowmaking).",
    "high", FALSE, NA_character_,
    "Humboldt-Toiyabe NF NV. POWDR Corp.",

  20190103L, "BLM", "ID", 300, 2019L, "web_imputed",
    "https://itafos.com/wp-content/uploads/2019/06/Itafos-Investor-Presentation-June-2019-FINAL.pdf",
    "Itafos Investor Presentation June 2019", "itafos.com", "2019", NA_integer_,
    "Caldwell Canyon Mine ~30-year reserve. Construction + dev capex ~$300M (royalty payable ~$120M).",
    "low", TRUE, "Phosphate-mine-greenfield (~$300M)",
    "Soda Springs ID. Itafos. Replaces depleted Conda mine ore.",

  20190114L, "DOE", "LA", 0, 2019L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "DOE adoption of FERC Plaquemines LNG EIS (20190091).",
    "high", FALSE, NA_character_,
    "Adoption — primary EIS attributed to FERC.",

  20190116L, "FRA", "VA", 5000, 2019L, "web_imputed",
    "https://www.virginiapassengerrailauthority.com/our-projects/dc2rva/",
    "VPRA DC to Richmond Project", "virginiapassengerrailauthority.com", "2019", NA_integer_,
    "Tier II EIS for 123-mi DC-Richmond corridor improvements. Industry estimates $4-8B for full Build.",
    "low", TRUE, "Higher-speed-rail-corridor (~$5B)",
    "FRA + VPRA. Federally-funded portions only; full corridor will phase via state/federal mix.",

  20190120L, "BIA", "WI", 405, 2019L, "web",
    "https://www.bia.gov/sites/default/files/dup-assets/idc1-101751.pdf",
    "Beloit Casino Project ROD", "bia.gov", "2019", NA_integer_,
    "$405 million Beloit Casino project (Phase 1).",
    "high", FALSE, NA_character_,
    "Ho-Chunk Nation off-reservation fee-to-trust. Beloit WI.",

  20190121L, "BIA", "CA", 250, 2019L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Tule River Indian Tribe Fee-to-Trust + Eagle Mountain Casino relocation. Mid-size tribal casino ~$200-300M.",
    "low", TRUE, "Mid-size-tribal-casino (~$250M)",
    "Tulare County CA. Tule River.",

  20190129L, "BLM", "NV", 50, 2019L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Rossi Mine Expansion (Barrick). Underground/pit expansion at existing mine. No standalone capex disclosed.",
    "low", TRUE, "Mine-expansion-modest (~$50M)",
    "Elko County NV. Nevada Gold Mines/Barrick.",

  20190131L, "BLM", "NV", 50, 2019L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Gemfield Mine Project. Goldfield NV gold exploration/development. Modest greenfield.",
    "low", TRUE, "Small-gold-mine-development (~$50M)",
    "Esmeralda County NV. Waterton/Gemfield Resources.",

  20190144L, "FHWA", "ND", 80, 2019L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Little Missouri River Crossing. New bridge crossing in Bakken oil patch. Sector estimate ~$80M for major rural river crossing.",
    "low", TRUE, "Rural-river-crossing-bridge (~$80M)",
    "Billings County ND. NDDOT.",

  20190152L, "BLM", "OR", 0, 2019L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "BLM adoption of FERC Swan Lake North Pumped Storage EIS (20180333).",
    "high", FALSE, NA_character_,
    "Adoption — primary EIS attributed to FERC.",

  20190153L, "TVA", "TN", 0, 2019L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "TVA 2019 Integrated Resource Plan. Programmatic plan / resource portfolio. No site-specific authorization or construction.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Classifier already excludes 'IRP' but needs to catch 'integrated resource plan' phrasing.",

  20190156L, "VA", "CA", 0, 2019L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "VA adoption of FTA Westside Subway Extension EIS.",
    "high", FALSE, NA_character_,
    "Adoption — primary EIS attributed to FTA (not in our (i) set).",

  20190165L, "BR", "OR", 0, 2019L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "BR adoption of FERC Swan Lake North Pumped Storage EIS (20180333).",
    "high", FALSE, NA_character_,
    "Adoption — primary EIS attributed to FERC.",

  20190167L, "BLM", "NV", 300, 2019L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Deep South Expansion Project. Cortez Hills underground expansion (Nevada Gold Mines). Underground mining capex.",
    "low", TRUE, "Underground-gold-mine-expansion (~$300M)",
    "Lander County NV. Nevada Gold Mines (Barrick + Newmont JV).",

  20190175L, "USACE", "TX", 185, 2019L, "web",
    "https://www.swg.usace.army.mil/Portals/26/docs/Planning/Brazos%20River%20Floodgates%20Sediment%20Management.pdf",
    "USACE Brazos River Floodgates GIWW", "swg.usace.army.mil", "2019", NA_integer_,
    "Total project cost approx $185M for floodgate replacement at GIWW Brazos crossing.",
    "high", FALSE, NA_character_,
    "USACE Galveston District. Texas Gulf Intracoastal Waterway navigation.",

  20190197L, "FHWA", "NV", 182, 2019L, "web",
    "https://www.nevadadot.com/projects-programs/road-projects/spaghetti-bowl-reno",
    "NDOT Spaghetti Bowl Reno", "nevadadot.com", "2019", NA_integer_,
    "$182 million Phase 1 I-80/I-580/US 395 freeway interchange improvement.",
    "high", FALSE, NA_character_,
    "Reno NV. NDOT 'Spaghetti Bowl' Phase 1.",

  20190199L, "FHWA", "AL", 3500, 2024L, "web",
    "https://www.al.com/news/mobile/2024/03/35-billion-mobile-bay-bridge-and-bayway-project-gets-final-federal-environmental-approval.html",
    "$3.5 billion Mobile Bay bridge and Bayway project", "al.com", "2024-03", NA_integer_,
    "$3.5 billion project for the I-10 Mobile River Bridge and Bayway widening.",
    "high", FALSE, NA_character_,
    "ALDOT. I-10 Mobile River bridge + Bayway over Mobile Bay.",

  20190202L, "FAA", "AK", 0, 2019L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "FAA adoption of USAF Modernization and Enhancement of Ranges EIS.",
    "high", FALSE, NA_character_,
    "Adoption — primary EIS attributed to USAF.",

  20190203L, "FHWA", "NY", 1220, 2019L, "web",
    "https://www.dot.ny.gov/portal/page/portal/regional-offices/region11/projects/repository/X729.31-FactSheet.pdf",
    "NYSDOT Van Wyck Expressway Project Fact Sheet", "dot.ny.gov", "2019", NA_integer_,
    "$1.22B Van Wyck Expressway Capacity & Access Improvement Project.",
    "high", FALSE, NA_character_,
    "Queens NY. AirTrain access to JFK. NYSDOT + Port Authority.",

  20190207L, "USACE", "TX", 350, 2019L, "web_imputed",
    "https://planning.erdc.dren.mil/toolbox/library/chiefreports/matagordashipchannel-2019.pdf",
    "Matagorda Ship Channel Improvement Chief's Report", "usace.army.mil", "2019", NA_integer_,
    "Average annual cost $15.9M; BCR 2.26. Implied first-cost ~$300-400M at applicable discount rate.",
    "low", TRUE, "Ship-channel-deepening-major (~$350M)",
    "Port Lavaca/Point Comfort TX. Calhoun Port Authority NFS. Deepen to -49 ft.",

  20190227L, "BLM", "AK", 1000, 2019L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "ANWR Coastal Plain Oil and Gas Leasing Program. Initial leasing 2021 + 2024 voided. Conservative attribution of pre-development infrastructure exposure.",
    "low", TRUE, "ANWR-leasing-initial-infrastructure (~$1B)",
    "Arctic NWR 1002 Area, AK. Most leases since cancelled. Lower-bound attribution.",

  20190233L, "BLM", "CA", 1000, 2020L, "web_imputed",
    "https://www.solarpowerworldonline.com/2020/02/first-solar-completes-financing-construction-start-on-desert-quartzite-and-american-kings-solar-projects/",
    "First Solar Desert Quartzite + American Kings construction start", "solarpowerworldonline.com", "2020", NA_integer_,
    "300 MWac Desert Quartzite Solar; First Solar developer. Utility-scale ~$3-4M/MWac ≈ ~$1B.",
    "medium", TRUE, "Utility-solar-greenfield (~$1B for 300 MWac)",
    "Riverside County CA. First Solar.",

  20190236L, "USACE", "TX", 490, 2019L, "web",
    "https://www.utrwd.com/lake-ralph-hall",
    "Upper Trinity Regional Water District Lake Ralph Hall", "utrwd.com", "2019", NA_integer_,
    "$490 million Lake Ralph Hall Regional Water Supply Reservoir Project.",
    "high", FALSE, NA_character_,
    "Fannin County TX. UTRWD. Bois d'Arc tributary impoundment.",

  20150082L, "BR", "CA", 0, 2019L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Long-term Water Transfers (BR/SLDMWA). North-to-south CVP water transfers via cropland idling / groundwater substitution. Operational, no construction.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). Add 'water transfers' pattern to classifier.",

  20190247L, "BR", "CA", 0, 2020L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Duplicate of 20150082 Long-Term Water Transfers. Same program, re-noticed.",
    "high", FALSE, NA_character_,
    "Same project as 20150082 — also reclassified (ii) if not duplicate.",

  20190249L, "FHWA", "OR", 0, 2019L, "no_cost_found_web",
    "https://www.salemrivercrossing.org/",
    "Salem River Crossing — No Build ROD", "salemrivercrossing.org", "2019", NA_integer_,
    "ODOT/FHWA selected the No Build Alternative. No construction authorized.",
    "high", FALSE, NA_character_,
    "Salem OR. Process ended with No Build — but EIS still consumed real review resources. Counted at $0 capex.",

  20190257L, "RUS", "WI", 492, 2019L, "web",
    "https://www.tdworld.com/overhead-transmission/article/21164414/atc-total-cost-of-cardinal-hickory-creek-project-as-of-march-31-totaled-about-925m",
    "ATC Cardinal-Hickory Creek Total Cost", "tdworld.com", "2021", NA_integer_,
    "Approved total project cost of about $492.2M. Later climbed to ~$541M.",
    "high", FALSE, NA_character_,
    "102-mi 345 kV Iowa-Wisconsin. ATC/Dairyland/ITC Midwest JV. RUS lead.",

  20190259L, "BR", "CA", 0, 2019L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Mendota Pool Group 20-Year Exchange Program. Water exchange contract — operational. No new infrastructure.",
    "high", FALSE, NA_character_,
    "RECLASSIFY (ii). 'Exchange program' pattern → ops, not capex.",

  20190271L, "USACE", "CA", 300, 2019L, "web",
    "https://water.ca.gov/Programs/Flood-Management/Flood-Projects/Lower-Elkhorn-Basin",
    "DWR Lower Elkhorn Basin Levee Setback Project", "water.ca.gov", "2019", NA_integer_,
    "Anticipated to cost approximately $300 million. 7 mi setback levees.",
    "high", FALSE, NA_character_,
    "Yolo/Sacramento Bypasses CA. DWR + USACE + CVFPB.",

  20190275L, "USFS", "CA", 65, 2019L, "web",
    "https://snowbrains.com/palisades-tahoe-base-to-base-gondola-completed-next-winter/",
    "Palisades Tahoe Base-to-Base Gondola", "snowbrains.com", "2022", NA_integer_,
    "$65 million Base-to-Base Gondola at Palisades Tahoe.",
    "high", FALSE, NA_character_,
    "Squaw Valley/Alpine Meadows (Palisades Tahoe). Placer County CA. Tahoe NF.",

  20190276L, "FERC", "OR", 10000, 2019L, "web_imputed",
    "https://www.opb.org/article/2021/12/01/jordan-cove-pipeline-terminal-project-abandoned-by-developers/",
    "Jordan Cove project abandoned", "opb.org", "2021-12-01", NA_integer_,
    "LNG terminal + 229-mi Pacific Connector pipeline. Multiple sources cite ~$10B all-in. Cancelled Dec 2021.",
    "low", TRUE, "Large-LNG-terminal+pipeline (~$10B)",
    "Coos Bay OR. Pembina. Cancelled Dec 2021 but FEIS issued — exposure attributable.",

  20190296L, "USFS", "CA", 50, 2019L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Omya Sentinel & Butterfield Quarry Expansion (calcium carbonate). 95 acres new ground over 40 years. San Bernardino NF.",
    "low", TRUE, "Quarry-expansion-modest (~$50M)",
    "San Bernardino NF CA. Omya. 954-acre unpatented placer claims.",

  20190298L, "FDOT", "FL", 200, 2019L, "sector_impute_pending",
    "https://fdotews1.dot.state.fl.us/NorthwestFloridaRoads/projects/410981-2",
    "FDOT Gulf Coast Parkway", "fdotews1.dot.state.fl.us", "2019", NA_integer_,
    "30+ miles new 4-lane parkway Bay-Gulf County. Phase 2 alone ~$16M (1.4 mi). Full corridor estimate.",
    "low", TRUE, "New-arterial-highway-rural (~$200M for 30 mi)",
    "Bay + Gulf Counties FL. FDOT.",

  20190300L, "BIA", "NV", 300, 2019L, "web_imputed",
    "https://arevonenergy.com/news/releases/arevon-completes-eagle-shadow-mountain-solar-power-plant-in-clark-county-nevada/",
    "Arevon Completes Eagle Shadow Mountain Solar", "arevonenergy.com", "2021", NA_integer_,
    "300 MW solar on Moapa River Indian Reservation. Utility-scale ~$1M/MW ≈ ~$300M.",
    "medium", TRUE, "Utility-solar-tribal-land (~$1M/MW)",
    "Clark County NV. Moapa Band of Paiutes / Arevon (8minutenergy). BIA lead.",

  20190302L, "BLM", "NV", 1100, 2020L, "web",
    "https://www.businesswire.com/news/home/20200511005974/en/BLM-and-DOI-Issue-Final-Record-of-Decision-for-Milestone-690MW-Gemini-Solar-and-Battery-Storage",
    "BLM ROD 690MW Gemini Solar + Battery Storage", "businesswire.com", "2020-05-11", NA_integer_,
    "$1.1B per 2020 record of decision (rose to $1.2B by 2022). 690 MW + 380 MW storage.",
    "high", FALSE, NA_character_,
    "Clark County NV. Quinbrook / Primergy. Powers Google data center.",
)

# Merge audit H-1 record additions (records flipped from (iii) to (i) post-audit).
prov <- bind_rows(prov, h1_records |> filter(panel_year == 2019L) |> select(-panel_year))

finalize_cost_year(prov, 2019L)
