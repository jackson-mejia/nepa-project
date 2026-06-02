# Audit H-1 record additions — cost provenance for 30 EIS records that flipped
# from (iii) to (i) after the audit-driven classifier patches. Sourced by each
# build_cost_provenance_<year>.R script; each year filters this table to its own
# panel_year subset and bind_rows() into the year prov tibble. Schema matches the
# per-year prov tibbles.

suppressPackageStartupMessages({
  library(dplyr); library(tibble)
})


h1_records <- tribble(
  ~panel_year, ~eis_number, ~lead_agency, ~state, ~cost_m_usd_nominal, ~cost_year, ~cost_method, ~cost_source_url, ~cost_source_title, ~cost_source_publisher, ~cost_source_date, ~cost_source_page, ~cost_quote, ~cost_confidence, ~imputed, ~imputation_basis, ~cost_notes,

  # ===== 2015 =====
  2015L, 20150015L, "BPA", "ID", 10, 2015L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Hooper Springs Transmission — small BPA tie line, ~15 mi. Sector benchmark for short BPA transmission.",
    "low", TRUE, "Short-rural-115kV-transmission (~$10M)",
    "H-1 audit addition. BPA Idaho.",

  2015L, 20150083L, "USFS", "AK", 75, 2015L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Resurrection Creek Phase II Stream Restoration + Hope Mining Company Plan of Operations. Combined restoration + small-scale gold mining.",
    "low", TRUE, "Small-gold-mine-with-restoration (~$75M)",
    "L-6 audit addition (was excluded by restoration regex; fixed). USFS Chugach NF Alaska.",

  2015L, 20150086L, "USN", "CA", 1000, 2015L, "web",
    "https://www.coronadonewsca.com/news/coronado_city_news/work-on-1-billion-navy-coastal-campus-to-begin-in-early-fall/article_3ccede34-5316-11e5-8d46-43b1d8671b2e.html",
    "Work on $1 Billion Navy Coastal Campus to Begin", "coronadonewsca.com", "2015", NA_integer_,
    "$1 billion total cost ($700M buildings + $200M design/equipment + $100M infra).",
    "high", FALSE, NA_character_,
    "H-1 audit addition. Naval Base Coronado Coastal Campus, NSWC SEAL ops. 10-yr build.",

  2015L, 20150119L, "OSM", "NM", 300, 2015L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Four Corners Power Plant + Navajo Mine Energy Project. Mine expansion + coal-fueled power plant. EIS covered mine extension + plant emissions controls.",
    "low", TRUE, "Coal-mine-extension-with-power-controls (~$300M)",
    "H-1 audit addition. OSM-led, San Juan County NM.",

  # ===== 2016 =====
  2016L, 20160065L, "WAPA", "CA", 324, 2016L, "web",
    "https://www.wapa.gov/about-wapa/regions/sn/san-luis-transmission-project/",
    "WAPA San Luis Transmission Project", "wapa.gov", "2016", NA_integer_,
    "Current project cost estimate is $323.5 million. 85-mi 230-kV Tracy to San Luis/O'Neill/Dos Amigos.",
    "high", FALSE, NA_character_,
    "H-1 audit addition. WAPA + Duke-American Transmission JV. Westlands Solar support.",

  2016L, 20160083L, "USACE", "TX", 200, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "USACE Section 404 permitting for surface coal and lignite mining. East Texas. Sector imputation for mid-size coal/lignite operation.",
    "low", TRUE, "Coal-lignite-mine-mid (~$200M)",
    "H-1 audit addition. USACE Galveston District.",

  2016L, 20160157L, "USN", "WA", 500, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Bangor Naval Base Land-Water Interface + Service Pier Extension. Major submarine-support pier MILCON.",
    "low", TRUE, "Major-naval-pier-MILCON (~$500M)",
    "H-1 audit addition. USN Bangor WA (Trident submarine base).",

  2016L, 20160233L, "USMC", "CA", 400, 2016L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Santa Margarita River Conjunctive Use. Camp Pendleton water infrastructure (groundwater + surface use coordination). Mid-size water project.",
    "low", TRUE, "Military-water-infrastructure (~$400M)",
    "H-1 audit addition. USMC Camp Pendleton CA.",

  # ===== 2017 =====
  2017L, 20170046L, "NSA", "MD", 4600, 2017L, "web",
    "https://comptroller.war.gov/Portals/45/Documents/defbudget/FY2025/budget_justification/pdfs/07_Military_Construction/11-National_Security_Agency.pdf",
    "NSA East Campus Integration Program FY2025 MILCON Justification", "comptroller.war.gov", "2025", NA_integer_,
    "East Campus Integration Program — 5 buildings, ~2.88M sf, FY 2019-2029. Total program $4.6B.",
    "high", FALSE, NA_character_,
    "H-1 audit addition. NSA Fort Meade headquarters consolidation.",

  2017L, 20170099L, "NIGC", "WA", 0, 2017L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "NIGC adoption of BIA Cowlitz Indian Tribe Trust Acquisition + Casino EIS.",
    "high", FALSE, NA_character_,
    "H-1 audit addition. Adoption — primary BIA EIS attributed at $0 unless found.",

  2017L, 20170110L, "USN", "RI", 50, 2017L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Naval Station Newport Disposal and Reuse of Surplus Property. Base realignment / land-disposal action. Small-scale.",
    "low", TRUE, "Naval-base-realignment-property-disposal (~$50M)",
    "H-1 audit addition. USN BRAC-style action.",

  2017L, 20170230L, "BPA", "WA", 30, 2017L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Melvin R. Sampson Hatchery, Yakima Basin Coho. BPA fish-mitigation hatchery. Small-mid hatchery facility.",
    "low", TRUE, "Salmon-hatchery-mid (~$30M)",
    "H-1 audit addition. BPA fish & wildlife mitigation.",

  2017L, 20170234L, "USMC", "DC", 100, 2017L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Marine Barracks Washington DC. Multiple projects supporting historic 8th & I barracks (housing, training, support). MILCON portfolio.",
    "low", TRUE, "MILCON-historic-barracks-portfolio (~$100M)",
    "H-1 audit addition. USMC ceremonial unit.",

  # ===== 2018 =====
  2018L, 20180059L, "WAPA", "CO", 500, 2018L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Estes-Flatiron 115kV Transmission Lines Rebuild Project. WAPA rebuilds + structure upgrades, ~30 mi.",
    "low", TRUE, "Transmission-rebuild-mid (~$500M)",
    "H-1 audit addition. WAPA Loveland-area Colorado.",

  2018L, 20180067L, "USACE", "AK", 7400, 2021L, "web",
    "https://www.theglobeandmail.com/business/article-barrick-selling-stake-in-giant-alaska-gold-project-donlin-for-us1/",
    "Donlin Gold project cost", "theglobeandmail.com", "2021", NA_integer_,
    "Cost to build pegged at US$7.4 billion in 2021 engineering study (rose to ~$9.2B by 2025 inflation update; use 2021 ROD-era estimate).",
    "high", FALSE, NA_character_,
    "H-1 audit addition. USACE 404 permit for Donlin Gold (NovaGold/Paulson/formerly Barrick). 27-yr mine life. SW Alaska.",

  2018L, 20180204L, "USACE", "AZ", 300, 2018L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Ray Mine Tailings Storage Facility (ASARCO/Grupo Mexico). USACE 404 for new tailings impoundment at existing copper mine.",
    "low", TRUE, "Tailings-facility-mid-mine (~$300M)",
    "H-1 audit addition. USACE 404 / Pinal County AZ.",

  2018L, 20180209L, "GSA", "MD", 500, 2018L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "2018 Master Plan for the Consolidation of U.S. FDA HQ. Major federal HQ consolidation Beltsville/White Oak Maryland.",
    "low", TRUE, "Federal-HQ-consolidation-master-plan (~$500M)",
    "H-1 audit addition. GSA + FDA. Long-range program.",

  2018L, 20180211L, "NIGC", "CA", 0, 2018L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "NIGC adoption of BIA Wilton Rancheria EIS (20160300, $500M attributed there).",
    "high", FALSE, NA_character_,
    "H-1 audit addition. Adoption.",

  2018L, 20180288L, "OSM", "MT", 100, 2018L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Western Energy Company Rosebud Mine Area F. Coal mine area extension.",
    "low", TRUE, "Coal-mine-area-extension (~$100M)",
    "H-1 audit addition. OSM Montana.",

  # ===== 2019 =====
  2019L, 20190023L, "OSM", "NM", 50, 2019L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "San Juan Mine Deep Lease Extension Mining Plan Modification. Lease extension + mine plan modification at operating coal mine.",
    "low", TRUE, "Coal-mine-extension-small (~$50M)",
    "H-1 audit addition. OSM New Mexico (Four Corners area).",

  2019L, 20190149L, "OSM", "UT", 0, 2019L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "OSM adoption — Alton Coal Tract Lease by Application.",
    "high", FALSE, NA_character_,
    "H-1 audit addition. Adoption.",

  2019L, 20190200L, "BR", "CA", 500, 2019L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "B.F. Sisk Dam Safety of Dams MODIFICATION Project. Structural seismic upgrade + raise, not inspection. Mid-size dam-modification capex.",
    "low", TRUE, "Major-dam-structural-modification (~$500M)",
    "L-6 audit addition (was excluded by dam_safety regex; fixed for 'modification'/'structural' keywords). BR Sisk Dam, San Luis Reservoir CA.",

  # ===== 2020 =====
  2020L, 20200011L, "USAF", "CA", 2000, 2023L, "web",
    "https://www.edwards.af.mil/News/Article/3289170/largest-private-public-collaboration-in-department-of-defense-history-reflects/",
    "Largest Private-Public Collaboration in DoD History", "edwards.af.mil", "2023", NA_integer_,
    "$2 billion Edwards Sanborn Solar + Energy Storage Project; 57% located on Edwards AFB. 807 MW + storage. 35-yr lease.",
    "high", FALSE, NA_character_,
    "H-1 audit addition. Terra-Gen / Edwards AFB Enhanced Use Lease.",

  2020L, 20200148L, "USACE", "AK", 5000, 2020L, "web_imputed",
    "https://en.wikipedia.org/wiki/Pebble_Mine",
    "Pebble Mine Wikipedia / project estimates", "wikipedia.org", "2020", NA_integer_,
    "Major copper-gold mine, would have been one of largest in N.A. EIS-completed before permit denied Nov 2020. Industry estimates $5-10B project capex. Use $5B (lower bound, conservative).",
    "medium", TRUE, "Major-copper-gold-mine-mid (~$5B)",
    "H-1 audit addition. Permit denied 2020 but EIS issued — exposure attributable.",

  2020L, 20200158L, "BPA", "OR", 0, 2020L, "reclassified_to_ii", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Columbia River System Operations — basin-wide operational EIS (14 dams + reservoirs). No new construction; operational reset.",
    "high", FALSE, NA_character_,
    "H-1 audit addition then RECLASSIFY: 'System Operations' is operational not capex. Added 'system operations' to combined_ops classifier exclusion.",

  # ===== 2021 =====
  2021L, 20210026L, "GSA", "CA", 300, 2021L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Chet Holifield Federal Building Tenant Relocation. GSA major federal-building reposition / tenant move-out and adjacent construction.",
    "low", TRUE, "Federal-building-relocation (~$300M)",
    "H-1 audit addition. Laguna Niguel CA — IRS + USCIS + others.",

  2021L, 20210175L, "WAPA", "WY", 500, 2022L, "web",
    "https://www.connectgenllc.com/western-area-power-administration-issues-record-of-decision-for-interconnection-of-connectgens-504-mw-wind-project/",
    "WAPA ROD for ConnectGen 504 MW Wind", "connectgenllc.com", "2022", NA_integer_,
    "Capital investment of more than $500 million in Albany County, Wyoming. 504 MW / ~120 turbines.",
    "high", FALSE, NA_character_,
    "H-1 audit addition. Repsol Renewables (acquired ConnectGen). WAPA interconnection.",

  # ===== 2022 =====
  2022L, 20220146L, "USN", "HI", 3600, 2022L, "web",
    "https://www.dvidshub.net/news/440192/navfac-pacific-awards-28-billion-contract-task-order-pearl-harbor-dry-dock-replacement",
    "NAVFAC Pacific awards $2.8B contract — Pearl Harbor Dry Dock", "dvidshub.net", "2022", NA_integer_,
    "Dry Dock 3 replacement: $2.8B contract task order to Dragados/Hawaiian Dredging/Orion JV; Navy 5-yr plan estimates $3.6B for the dry dock project. Use $3.6B.",
    "high", FALSE, NA_character_,
    "H-1 audit addition. Pearl Harbor Naval Shipyard SIOP. Largest naval-yard capex in panel.",

  # ===== 2023 =====
  2023L, 20230048L, "GSA", "MD", 300, 2023L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "U.S. FDA Muirkirk Road Campus Master Plan. GSA + FDA infrastructure planning for Beltsville campus.",
    "low", TRUE, "Federal-campus-master-plan (~$300M)",
    "H-1 audit addition. GSA Maryland.",

  # ===== 2024 =====
  2024L, 20240021L, "NSA", "MD", 100, 2024L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "O'Brien Road Access Modernization. NSA Fort Meade road access upgrade / security infrastructure.",
    "low", TRUE, "Federal-facility-access-road (~$100M)",
    "H-1 audit addition. NSA support infrastructure.",

  # ========================================================================
  # H-1 ROUND 2 AUDIT ADDITIONS (2026-06-02)
  # Records that flipped from (iii) to (i) after the round-2 classifier patches
  # (named BLM/USFS extractive whitelist, USACE coastal storm/shore protection,
  # HUD Rebuild by Design, transmission-adoption, expanded mineral list).
  # Costs sourced from official agency documents, company filings, and news
  # coverage; FEIS-era estimates used where the project cost has since grown.
  # Two adoption records carry cost = 0 because their parent EISs are already
  # counted at full cost elsewhere in the panel.
  # ========================================================================

  2015L, 20150137L, "USACE", "CA", 190, 2015L, "web",
    "http://westsacfloodprotect.com/projects",
    "Levee Projects", "City of West Sacramento", "2015", NA_integer_,
    "Southport Sacramento River EIP: 6-mile setback levee, estimated cost $190 million; first phase ($5M) of construction at Village Parkway South.",
    "medium", FALSE, NA_character_,
    "H-1 Round 2 audit addition. USACE flood-risk Early Implementation Project, West Sacramento.",

  2016L, 20160189L, "BLM", "WY", 122, 2016L, "web",
    "https://www.energyfuels.com/sheep-mountain-project/",
    "Sheep Mountain Project", "Energy Fuels Inc.", "2016", NA_integer_,
    "Sheep Mountain Uranium PFS: planned total project capex $122.4 million (pre-2022 update; later raised to $152.6M in July 2022 PFS revision).",
    "medium", FALSE, NA_character_,
    "H-1 Round 2 audit addition. Energy Fuels in-situ recovery uranium, Fremont County WY. Use FEIS-era PFS estimate.",

  2016L, 20160207L, "USACE", "NY", 615, 2016L, "web",
    "https://www.nan.usace.army.mil/Portals/37/docs/civilworks/projects/ny/coast/StatenIsland/SOUTH%20SHORE%20STAT%20UPDATE/9_AppenIV_FinalCosts.pdf",
    "South Shore of Staten Island Final Costs Appendix", "USACE New York District", "2016", NA_integer_,
    "South Shore Staten Island CSRM: engineering & design estimate $559.7M; current estimate $615M (October 2025 city council mention of $1.7B reflects scope/inflation creep post-FEIS).",
    "high", FALSE, NA_character_,
    "H-1 Round 2 audit addition. Use FEIS-era $615M estimate; treated as mixed via USACE civil-works funding-source hint.",

  2017L, 20170101L, "HUD", "NY", 480, 2017L, "web",
    "https://dep.nj.gov/floodresilience/rebuild-by-design-hudson-river/rebuild-by-design-hudson-river-project-overview/",
    "Rebuild by Design Hudson River — Project Overview", "NJDEP", "2017", NA_integer_,
    "Total project budget $480M: $230M HUD CDBG-DR grant + $150M City of Hoboken funding + $100M State of New Jersey.",
    "high", FALSE, NA_character_,
    "H-1 Round 2 audit addition. HUD-led Sandy resilience in Hoboken/Weehawken/Jersey City.",

  2017L, 20170182L, "USACE", NA_character_, 0, 2017L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "ADOPTION--Plains and Eastern Clean Line Transmission Line Project. Underlying EIS already counted as 20150316 (DOE/private, cancelled).",
    "high", FALSE, NA_character_,
    "H-1 Round 2 audit addition. Cost = 0 because underlying project already at full cost in 2015 cohort.",

  2018L, 20180043L, "USACE", "NC", 35, 2018L, "web",
    "https://coastalreview.org/2018/04/holden-beach-says-no-to-terminal-groin/",
    "Holden Beach Says 'No' to Terminal Groin", "Coastal Review", "2018", NA_integer_,
    "Holden Beach East End Shore Protection: estimated $30-40 million in protection costs over 30 years for 10-20 properties on the east end of the island.",
    "medium", FALSE, NA_character_,
    "H-1 Round 2 audit addition. USACE coastal civil works (project later withdrawn by Town).",

  2018L, 20180196L, "BLM", "AK", 1400, 2018L, "web",
    "https://www.akbizmag.com/industry/oil-gas/first-oil-from-greater-mooses-tooth-2/",
    "First Oil from Greater Mooses Tooth #2", "Alaska Business Magazine", "2022", NA_integer_,
    "GMT2 project: ~$1.4B gross capex including construction and drilling; peak production ~30,000 BOEPD; first oil December 2021 under budget.",
    "high", FALSE, NA_character_,
    "H-1 Round 2 audit addition. ConocoPhillips Alpine Satellite Development Plan for GMT2, NPR-A.",

  2018L, 20180251L, "HUD", "NJ", 244, 2018L, "web",
    "https://dep.nj.gov/floodresilience/rebuild-by-design-meadowlands-project-overview/",
    "Rebuild by Design Meadowlands — Project Overview", "NJDEP", "2018", NA_integer_,
    "Build Plan funded with $150M HUD CDBG-DR grant + $36M FEMA BRIC + $17M NOAA CRRC + $42M NJ Flood Control Capital appropriation; total ≈ $244M.",
    "high", FALSE, NA_character_,
    "H-1 Round 2 audit addition. HUD lead chosen over NJDEP for the canonical entry (eis_number dedup).",

  2018L, 20180275L, "USACE", "VA", 1600, 2018L, "web",
    "https://www.warner.senate.gov/public/index.cfm/2021/12/warner-kaine-request-federal",
    "Warner & Kaine Request Federal Funding for Norfolk Coastal Storm Risk Management Project", "U.S. Senate", "2021", NA_integer_,
    "Norfolk CSRM total estimated construction $1.6B (~$1.043B federal + $562M non-federal) per WRDA 2020 authorization; later revised upward to $2.6B in 2023 agreement. Use FEIS-era estimate.",
    "high", FALSE, NA_character_,
    "H-1 Round 2 audit addition. Large USACE coastal program; uses 2018 FEIS-era cost.",

  2018L, 20180310L, "BLM", "WY", 400, 2018L, "web",
    "http://www.zeroco2.no/projects/riley-ridge-gas-plant-eor",
    "Riley Ridge Gas Plant & EOR", "zeroco2.no", "2018", NA_integer_,
    "Riley Ridge to Natrona 243-mile CO2 pipeline, sweetening plant, and 230 kV transmission line; estimated construction cost ~$400 million.",
    "medium", FALSE, NA_character_,
    "H-1 Round 2 audit addition. Denbury Resources CO2 pipeline for Wyoming EOR.",

  2018L, 20180320L, "BLM", "WY", 46, 2018L, "web",
    "https://www.ur-energy.com/news-media/press-releases/detail/357/ur-energy-files-updated-s-k-1300-reports-for-the-lost-creek",
    "Ur-Energy Files Updated S-K 1300 Reports for Lost Creek ISR Uranium Property", "Ur-Energy Inc.", "2022", NA_integer_,
    "Lost Creek ISR facility: initial capital costs $46.5M incurred and expended prior to economic-analysis starting date.",
    "high", FALSE, NA_character_,
    "H-1 Round 2 audit addition. Ur-Energy in-situ recovery uranium modifications.",

  2020L, 20200043L, "USACE", "NY", 1700, 2020L, "web",
    "https://www.governor.ny.gov/news/governor-hochul-announces-us-army-corps-construction-kick-major-flood-risk-management-project",
    "Governor Hochul Announces US Army Corps Construction Kick-Off for Major Flood Risk Management Project on Long Island", "Office of the Governor of NY", "2024", NA_integer_,
    "Fire Island to Montauk Point (FIMP) project: $1.7 billion comprehensive coastal storm risk management for 83 miles of Long Island shoreline, 100% federally funded under Sandy supplemental (PL 113-2).",
    "high", FALSE, NA_character_,
    "H-1 Round 2 audit addition. Major Long Island coastal program.",

  2020L, 20200074L, "BLM", "AK", 672, 2020L, "web",
    "https://www.dermotcole.com/reportingfromalaska/2025/11/13/aidea-sticks-to-low-ball-ambler-road-estimate",
    "AIDEA sticks to low-ball Ambler road estimate", "Reporting From Alaska (Dermot Cole)", "2025", NA_integer_,
    "Ambler Road preferred route: BLM 2024 decision document estimated cost $672 million; AIDEA's own estimate $350 million; third-party study puts state cost above $2 billion including financing.",
    "high", FALSE, NA_character_,
    "H-1 Round 2 audit addition. Use BLM 2024 ROD cost estimate ($672M) as defensible mid-range.",

  2020L, 20200166L, "BLM", "AK", 7000, 2020L, "web",
    "https://www.worldoil.com/news/2025/11/6/conocophillips-lifts-willow-project-cost-to-9-billion-first-oil-set-for-early-2029/",
    "ConocoPhillips lifts Willow project cost to $9 billion, first oil set for early 2029", "World Oil", "2025", NA_integer_,
    "ConocoPhillips Willow: initially estimated $7 billion to $7.5 billion; recently lifted to as much as $9 billion (inflation + construction costs added ~$700M to higher range). Use FEIS-era $7B estimate.",
    "high", FALSE, NA_character_,
    "H-1 Round 2 audit addition. Use FEIS-era $7B estimate for the 2020 panel-year; current estimate is $9B.",

  2021L, 20210123L, "USACE", "FL", 2600, 2021L, "web",
    "https://keysweekly.com/42/2-6b-storm-and-sea-level-rise-project-on-tap-for-florida-keys/",
    "$2.6B Storm and Sea Level Rise Project on Tap for Florida Keys", "Keys Weekly", "2021", NA_integer_,
    "Florida Keys CSRM: total project $2.6 billion ($1.7B federal at 65% + $893M non-federal at 35%); includes home elevations (~$2B) and floodproofing (~$400M).",
    "high", FALSE, NA_character_,
    "H-1 Round 2 audit addition.",

  2022L, 20220089L, "USACE", "SC", 1300, 2022L, "web",
    "https://www.postandcourier.com/charleston_sc/charleston-seawall-battery-extension-pay/article_abb72d94-f524-4d90-a09f-a33f1e1132c9.html",
    "As Charleston's $1.3B seawall project moves forward, how will the city pay its $455M share?", "Post and Courier", "2022", NA_integer_,
    "Charleston Peninsula CSRM: 8-mile perimeter seawall + 4,000-foot offshore breakwater; total cost ~$1.3 billion (was $1.4B in earlier draft; ranged up to $2.2B in initial USACE draft).",
    "high", FALSE, NA_character_,
    "H-1 Round 2 audit addition. Final feasibility report sent to Congress 2022.",

  2022L, 20220193L, "FEMA", "NY", 0, 2022L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "ADOPTION--Rebuild by Design--Hudson River (RBD-HR). Underlying EIS already counted as 20170101 (HUD lead).",
    "high", FALSE, NA_character_,
    "H-1 Round 2 audit addition. Cost = 0 because underlying project already at full cost in 2017 cohort.",
)
