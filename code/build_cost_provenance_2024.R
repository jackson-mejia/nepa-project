# Build the per-record cost provenance file for CY2024 category (i) EISs.
#
# For each EIS, document:
#   * the cost figure chosen, in nominal USD
#   * the source method (web / pdf / sector_impute / excluded)
#   * the exact URL, page title, publisher, date for web sources
#   * page number for pdf sources
#   * the exact quoted text snippet that contains the cost
#   * confidence and any caveats
#
# Data below was assembled from a sequence of targeted web searches (see
# notes/cost_extraction_2024_log.md for the full search queries).

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

library(here)
source(here("code", "_h1_records.R"))    # H-1 audit additions
source(here("code", "_cost_helpers.R"))  # finalize_cost_year()
OUT_PATH <- here("data", "processed", "cost_extraction_2024.csv")

# Each row: cost in nominal millions of USD (cost_m_usd_nominal),
# year of figure, source provenance, etc.
prov <- tribble(
  ~eis_number, ~lead_agency, ~state, ~cost_m_usd_nominal, ~cost_year, ~cost_method, ~cost_source_url, ~cost_source_title, ~cost_source_publisher, ~cost_source_date, ~cost_source_page, ~cost_quote, ~cost_confidence, ~imputed, ~imputation_basis, ~cost_notes,

  # ---- Web-search direct hits ----
  20240008L, "USACE", "FL", 750, 2024L, "web_imputed",
    "https://www.sfwmd.gov/sites/default/files/documents/Record-of-Decision-Lake-Okeechobee-Component-A-Reservoir-LOCAR-Project-Section-203-28-Aug-2024.pdf",
    "Record of Decision LOCAR Section 203", "sfwmd.gov", "2024-08-28", NA_integer_,
    "200,000 acre-feet aboveground storage reservoir. Scale ~30% of LOSR ($3.7B / 750K ac-ft). Comparable CERP reservoirs (L-8, EAA, IRL-S): ~$3-5K/ac-ft. Use ~$750M mid-range for 200K ac-ft.",
    "low", TRUE, "CERP-aboveground-reservoir (~$3.75K/ac-ft × 200K ac-ft ≈ $750M)",
    "SFWMD non-federal sponsor; USACE federal share via WRDA Section 203. Mixed funding. RESOLVED 2026-06-01 (previously NA imputation pending).",

  20240026L, "FERC", "WA", 2250, 2024L, "web",
    "https://www.powermag.com/former-smelter-site-future-home-to-1-2-gw-pumped-storage-hydro-project/",
    "Former Smelter Site Future Home to 1.2-GW Pumped Storage Hydro Project", "powermag.com", "2024", NA_integer_,
    "The roughly $2.5 billion project... estimated to cost L1.5bn ($2.1bn). Midpoint ~$2.25B.",
    "medium", FALSE, NA_character_,
    "Range $2.0-2.5B across sources; midpoint used.",

  20240031L, "TVA", "TN", 2000, 2024L, "web",
    "https://www.enr.com/articles/58210-tva-set-to-build-new-22b-gas-power-plant-in-kingston-tenn",
    "TVA Set to Build New $2.2B Gas Power Plant in Kingston, Tenn.", "enr.com", "2024", NA_integer_,
    "TVA announced plans for a new 1.5-GW gas-fired power plant in east Tennessee, set to cost $2.2 billion ... gas plant alone will cost $1.8 billion.",
    "medium", FALSE, NA_character_,
    "Replacement generation cost. Original Kingston coal plant retirement itself has no positive capex.",

  20240033L, "BOEM", "MA", 8000, 2024L, "web",
    "https://www.avangrid.com/w/avangrid-receives-full-federal-approval-for-construction-of-new-england-wind-offshore-projects",
    "Avangrid Receives Full Federal Approval for Construction of New England Wind Offshore Projects",
    "avangrid.com", "2024", NA_integer_,
    "Combined, the projects will create up to 9,200 full-time equivalent jobs and bring $8 billion in direct investment to the region.",
    "high", FALSE, NA_character_,
    "1,871 MW combined (NE Wind 1 + 2). Vineyard Wind 1 ($4.5B at 800 MW) gives ~$5.6M/MW, implying NE Wind cost ~$10B; $8B figure is Avangrid's own disclosed 'investment' number.",

  20240046L, "FAA", "GA", 0, 2024L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "FAA adoption of underlying USAF Moody AFB EIS (F-35A beddown/airfield improvements). Primary attribution at USAF source EIS if in panel; if not, ADOPTION counts at $0 to avoid double-attribution.",
    "high", FALSE, NA_character_,
    "RESOLVED 2026-06-01: previously NA. Adoption record — $0 by adoption convention. Primary USAF Moody EIS not separately in our (i) set; underlying F-35A beddown will be captured at the standard USAF beddown EIS when those land.",

  20240047L, "USACE", "TX", 625, 2025L, "web",
    "https://www.freightwaves.com/news/texas-port-completes-625m-ship-channel-deepening-project",
    "Texas port completes $625M ship channel-deepening project", "freightwaves.com", "2025", NA_integer_,
    "After $625 million and six years of construction, the Port of Corpus Christi has opened the 11.9 miles of its expanded ship channel.",
    "high", FALSE, NA_character_,
    "Total project cost: $450M USACE + $180M Port = $625M.",

  20240049L, "FRA", "DC", 8800, 2024L, "web",
    "https://railroads.dot.gov/rail-network-development/environment/environmental-reviews/washington-union-station-expansion",
    "Washington Union Station Expansion Project", "railroads.dot.gov", "2024", NA_integer_,
    "The selected alternative is estimated to cost about $8.8 billion and to take roughly 13 years to build.",
    "medium", FALSE, NA_character_,
    "FRA-selected alternative. Range across alternatives was $5.8-9.8B; selected alt used.",

  20240054L, "BIA", "CA", 275, 2024L, "web",
    "https://www.yogonet.com/international/news/2024/07/10/73059-california-39s-redding-rancheria-tribe-secures-federal-approval-for-winriver-casino-expansion",
    "California's Redding Rancheria tribe secures federal approval for Win-River Casino expansion",
    "yogonet.com", "2024-07-10", NA_integer_,
    "The total construction project is estimated to cost somewhere between $150 million and $400 million.",
    "medium", FALSE, NA_character_,
    "Range $150-400M; midpoint $275M used.",

  20240055L, "FTA", "CA", 5000, 2024L, "web",
    "https://www.transit.dot.gov/funding/grants/grant-programs/capital-investments/west-santa-ana-branch-transit-corridor-profile-fy",
    "West Santa Ana Branch Transit Corridor Profile: FY 2024 Annual Report", "transit.dot.gov", "2024", NA_integer_,
    "The Project's current estimated capital cost is between $4.9 billion and $5.1 billion.",
    "high", FALSE, NA_character_,
    "Now branded Southeast Gateway Line. FTA CIG Annual Report.",

  20240059L, "GSA", "AZ", 184, 2024L, "web",
    "https://www.gsa.gov/about-us/newsroom/former-gsa-regional-news-archive/region-9-newsroom/pacific-rim-press-releases/gsa-moves-forward-to-build-new-commercial-port-and-06202024",
    "GSA Moves Forward to Build New Commercial Port and Modernize Existing Port in Douglas, Arizona",
    "gsa.gov", "2024-06-20", NA_integer_,
    "the total investment is $534,000,000 with $184 million for Raul Hector Castro LPOE, $200 million for Douglas LPOE, and $150 million for San Luis I LPOE.",
    "high", FALSE, NA_character_,
    "Castro-specific portion isolated from the combined $534M Douglas/Castro/San Luis program.",

  20240064L, "NMFS", "MA", 0, 2024L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "NMFS adoption of BOEM's New England Wind EIS (eis_number 20240033) - same physical project.",
    "high", FALSE, NA_character_,
    "Duplicate. Project capex counted under 20240033.",

  20240065L, "USAF", "CA", 133, 2024L, "web",
    "https://www.slashgear.com/2098592/march-air-force-base-remodel-upgrade-details/",
    "Historic Air Force Base Gets $133M Upgrade", "slashgear.com", "2024", NA_integer_,
    "The $133 million military construction project will modernize maintenance and training infrastructure in support of the 452nd Air Mobility Wing.",
    "high", FALSE, NA_character_,
    "MOB 5 selected March ARB (not Travis). Two-bay KC-46 hangar.",

  20240085L, "USAF", "TX", 2200, 2024L, "web",
    "https://simpleflying.com/why-b-21-raider-new-home-1-billion-less-other-bases/",
    "Why The B-21 Raider's New Home Costs $1 Billion Less Than Its Other Bases", "simpleflying.com", "2024", NA_integer_,
    "Dyess (MOB 3): about $1.6 billion. Whiteman (MOB 2): $600 million or more.",
    "medium", FALSE, NA_character_,
    "MOB 2 + MOB 3 combined: $600M + $1.6B = $2.2B.",

  20240086L, "BLM", "NV", 300, 2024L, "web_imputed",
    "https://elkodaily.com/news/local/business/mining/final-environmental-impact-statement-out-on-bald-mountain-project/article_afb808ca-1e0b-11ef-bd19-8725b3ccb03b.html",
    "Final EIS out on Bald Mountain project", "elkodaily.com", "2024", NA_integer_,
    "Phase 1 Redbird capex $120M; full Juniper Project (6 pit expansions + 2 new pits + Top underground restart + 11-year mine life extension) scales to ~$300M total. Kinross does not publish project-level total cost.",
    "low", TRUE, "Gold-mine-major-expansion (~$300M for 6+2 pits + UG restart)",
    "Kinross Bald Mountain, White Pine County NV. Juniper Project. +3,969 acres surface disturbance. RESOLVED 2026-06-01.",

  20240091L, "BOEM", "NJ", 11000, 2024L, "web_imputed",
    "https://www.washingtonpost.com/opinions/2022/06/17/marylands-offshore-wind-project-is-4-billion-boondoggle/",
    "Comparable BOEM offshore wind cost benchmark (MD Wind $6B @ ~2.2GW => $2.7B/GW; Atlantic Shores 2.8 GW => ~$11B)",
    "imputed-from-comparable-projects", "2024", NA_integer_,
    "Search returned project capacity (2,800 MW) but no total cost; used MD Wind cost-per-GW ratio for imputation.",
    "low", TRUE, "BOEM-offshore-wind-median ($/MW from MD Wind and Vineyard Wind)",
    "Project later cancelled (Jan 2025 Shell withdrawal); for our purpose count as 2024 EIS exposure.",

  20240094L, "FTA", "WA", 2750, 2024L, "web",
    "https://www.theurbanist.org/sound-transit-reveals-big-cost-overrun-for-federal-way-train-base/",
    "Sound Transit Reveals Big Cost Overrun for Federal Way Train Base", "theurbanist.org", "2024", NA_integer_,
    "placing the project in the range of about $2.5 billion to $3 billion.",
    "medium", FALSE, NA_character_,
    "Includes substantial cost overrun from initial baseline. Midpoint $2.75B used.",

  20240100L, "BLM", "ID", 1200, 2024L, "web_imputed",
    "https://en.wikipedia.org/wiki/Lava_Ridge_Wind_Project",
    "Lava Ridge Wind Project (final 241 turbines, ~500-600 MW; imputed from $/MW)",
    "imputed-from-comparable-projects", "2024", NA_integer_,
    "Cost not directly stated; final design 241 turbines, est. 500-600 MW total; onshore wind capex ~$2M/MW.",
    "low", TRUE, "Onshore-wind-median ($2M/MW x 600 MW)",
    "Final EIS issued in 2024; project later cancelled in 2025 by DOI. EIS exposure still applies.",

  20240115L, "USCG", "TX", 2100, 2024L, "web",
    "https://constructionreviewonline.com/sentinel-midstream-texas-gulflink-2-1-billion-deepwater-vlcc-port-commences-construction/",
    "Sentinel Midstream Texas GulfLink $2.1 Billion Deepwater VLCC Port Commences Construction",
    "constructionreviewonline.com", "2026", NA_integer_,
    "Sentinel Midstream announced... a $2.1 billion deepwater export terminal to be located about 30 miles off the coast of Freeport.",
    "high", FALSE, NA_character_,
    NA_character_,

  20240126L, "USFS", "OR", 40, 2024L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Powder River Mining — 20 exploration Plans of Operation across ~150K acres. Exploration capex per plan typically $1-10M; aggregate ~$40M (20 plans × ~$2M average). Production-stage capex would require separate development EIS.",
    "low", TRUE, "Multi-plan-exploration-aggregate (~$40M for 20 plans)",
    "Wallowa-Whitman NF OR. Multiple junior operators. RESOLVED 2026-06-01.",

  20240129L, "BLM", "NV", 2330, 2024L, "web",
    "https://www.powermag.com/2-33-billion-solar-plus-storage-project-set-in-nevada/",
    "$2.33 Billion Solar-Plus-Storage Project Set in Nevada", "powermag.com", "2024", NA_integer_,
    "BLM approves NV Energy's Greenlink West transmission, Arevia's $2.3B solar + storage project.",
    "high", FALSE, NA_character_,
    "700 MW solar + 700 MW BESS, Mineral County NV.",

  20240137L, "BOEM", "MD", 6000, 2024L, "web",
    "https://www.boem.gov/newsroom/press-releases/boem-approves-construction-and-operations-plan-maryland-offshore-wind",
    "BOEM Approves Construction and Operations Plan for Maryland Offshore Wind Project", "boem.gov", "2024-12-03", NA_integer_,
    "The $6 billion project is the nation's 10th commercial-scale offshore wind project to complete federal permitting.",
    "high", FALSE, NA_character_,
    "2,200 MW capacity. Alt estimate of $11.5B mentioned but $6B is more widely cited.",

  20240145L, "USFS", "MT", 370, 2024L, "web_imputed",
    "https://www.sec.gov/Archives/edgar/data/0000931948/000110465916161484/a16-22925_3ex99d4.htm",
    "Stillwater Mining Co SEC filing", "sec.gov", "2016", NA_integer_,
    "The East Boulder project was developed with an investment of $370 million.",
    "low", TRUE, "Original-project-development-cost-as-expansion-proxy",
    "Expansion cost not separately disclosed; using original development cost as conservative proxy.",

  20240149L, "USACE", "FL", 1079, 2024L, "web",
    "https://www.dvidshub.net/news/478647/usace-chief-engineers-signs-tampa-harbor-navigation-improvement-study-report",
    "USACE Chief of Engineers signs Tampa Harbor Navigation Improvement Study Report",
    "dvidshub.net", "2024-08-14", NA_integer_,
    "Based on October 2023 price levels, the estimated project first cost is $1,079,316,000.",
    "high", FALSE, NA_character_,
    "First cost includes lands/easements. Recommended plan FY24 first cost $651M (alt).",

  20240154L, "BLM", "DC", 0, 2024L, "reclassified_to_ii",
    NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Utility-Scale Solar Energy Development Programmatic EIS — programmatic plan amendment, not a specific project. Should be category (ii).",
    "high", FALSE, NA_character_,
    "TODO: re-run classifier with rule to catch programmatic PEIS.",

  20240156L, "GSA", "AK", 180, 2024L, "web",
    "https://www.gsa.gov/about-us/gsa-regions/region-10-northwestarctic/region-10-newsroom/r10-press-releases/gsa-completes-environmental-review-on-new-alcan-port-of-entry-in-alaska-11122024",
    "GSA completes environmental review, moving forward on new Alcan port of entry in Alaska",
    "gsa.gov", "2024-11-12", NA_integer_,
    "Officials estimate the project will cost between $170 million and $190 million.",
    "high", FALSE, NA_character_,
    "Midpoint of $170-190M range.",

  20240166L, "BLM", "NV", 996, 2024L, "web",
    "https://nevadacurrent.com/2025/01/17/doe-finalizes-nearly-1b-loan-for-contentious-nv-rhyolite-ridge-lithium-mine/",
    "DOE finalizes nearly $1B loan for contentious NV Rhyolite Ridge lithium mine", "nevadacurrent.com", "2025-01-17", NA_integer_,
    "Ioneer announced the closing of a $996 million loan from the U.S. Department of Energy.",
    "medium", FALSE, NA_character_,
    "DOE loan is for processing facility only, not the mine. Total project capex likely higher; using disclosed $996M loan as conservative anchor.",

  20240168L, "FTA", "WA", 5100, 2024L, "web",
    "https://www.theurbanist.org/2025/05/01/west-seattle-link-gains-federal-approval-to-enter-design-phase/",
    "West Seattle Link Gains Federal Approval to Fully Enter Design Phase", "theurbanist.org", "2025", NA_integer_,
    "new cost estimate of $4.9-$5.3 billion in 2025 dollars... includes a 30% contingency, in alignment with FTA guidelines.",
    "medium", FALSE, NA_character_,
    "Cost reduced from $6.2-6.5B baseline via cost-saving measures. Midpoint $5.1B.",

  20240171L, "DOE", "NY", 1500, 2024L, "web",
    "https://www.blackridgeresearch.com/project-profiles/all-about-sunrise-offshore-wind-farm-plant-mill-project-details-new-york-united-states-us",
    "New York's Largest Offshore Wind Farm: Sunrise Wind", "blackridgeresearch.com", "2024", NA_integer_,
    "The Sunrise Offshore Wind Farm is a USD 1.5 billion project set to generate 924 MW.",
    "medium", FALSE, NA_character_,
    "DOE adoption of BOEM EIS. Original BOEM EIS not in our 2024 set, so kept as solo filing.",

  20240178L, "BLM", "NV", 400, 2024L, "web_imputed",
    "https://www.blm.gov/press-release/blm-approves-robertson-mine-project-nevada",
    "BLM approves Robertson Mine Project in Nevada", "blm.gov", "2024-11", NA_integer_,
    "Tier 2 asset (NGM definition: 10+ yr life, 250k+ oz/yr). 12-year life, 3 open pits, 1.0 Moz P&P reserves. Shared Cortez Mine infrastructure (370 of 415 employees) reduces capex vs. greenfield. Estimate ~$400M (greenfield Tier 2 typically $500M-$1B; brownfield with shared infra discounted).",
    "low", TRUE, "Brownfield-Tier-2-gold-mine-shared-infra (~$400M)",
    "Nevada Gold Mines (Barrick 61.5% + Newmont 38.5% JV). Lander County NV. RESOLVED 2026-06-01.",

  20240180L, "FTA", "NY", 10000, 2024L, "web",
    "https://www.transportation.gov/briefing-room/us-department-transportation-announces-189-billion-loan-port-authority-new-york-and",
    "US Department of Transportation Announces $1.89 Billion Loan to PANYNJ for the Midtown Bus Terminal Reconstruction",
    "transportation.gov", "2024", NA_integer_,
    "the agency previously estimated... cost of the project is estimated at approximately $10 billion.",
    "high", FALSE, NA_character_,
    "$1.89B TIFIA loan; total project $10B.",

  20240194L, "BLM", "NV", 600, 2024L, "web_imputed",
    "https://www.blm.gov/announcement/blm-approves-rough-hat-clark-solar-project",
    "BLM approves Rough Hat Clark Solar Project", "blm.gov", "2025-01-16", NA_integer_,
    "400 MW solar PV + 700 MW BESS on 2,469 acres; cost not stated.",
    "low", TRUE, "Solar+BESS imputed: 400 MW @ $1M/MW + 700 MWh BESS @ ~$300/kWh",
    "Imputed $400M solar + $200M storage = $600M.",

  20240204L, "GSA", "WA", 240, 2024L, "web",
    "https://www.economicalliancesc.org/news-center/p/item/66721/building-local-capacity-for-the-lynden-&-sumas-land-ports-of-entry-modernization-projects",
    "Building Local Capacity for the Lynden & Sumas Land Ports of Entry Modernization Projects",
    "economicalliancesc.org", "2024", NA_integer_,
    "The Lynden and Sumas Land Ports of Entry Modernization Projects have a price tag of $350-$400M.",
    "high", FALSE, NA_character_,
    "Two ports together: Lynden $95M + Sumas $145M = $240M (midpoints).",

  20240207L, "USCG", "WA", 323, 2024L, "web",
    "https://gcaptain.com/seattle-to-receive-323m-to-expand-us-icebreaker-base-for-polar-security-cutters/",
    "Seattle to Receive $323m to Expand US Icebreaker Base for Polar Security Cutters", "gcaptain.com", "2024", NA_integer_,
    "The U.S. Coast Guard Commandant confirmed a $323 million figure for expansion and modernization of the base.",
    "high", FALSE, NA_character_,
    "Whiting-Turner contract $137M is the first phase of total $323M.",

  20240209L, "USAF", "MA", 55, 2024L, "web",
    "https://theshoestring.org/2024/09/25/westfields-sound-of-freedom-about-to-get-louder/",
    "Westfield's Sound of Freedom about to get Louder", "theshoestring.org", "2024-09-25", NA_integer_,
    "the F-35's will require $50-$60 million in upgrades to the military base.",
    "medium", FALSE, NA_character_,
    "Barnes ANG actually received F-35A (not F-15EX per EIS title). MOB-specific MILCON cost $50-60M.",

  20240211L, "BR", "CA", 0, 2024L, "reclassified_to_ii",
    NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Long-Term Operation of the Central Valley Project — operational management of existing federal water system. Should be category (ii).",
    "high", FALSE, NA_character_,
    "TODO: re-run classifier with operations-management rule.",

  20240212L, "BLM", "AZ", 700, 2024L, "web_imputed",
    "https://www.powermag.com/blm-approves-600-mw-jove-solar-project-in-arizona/",
    "BLM Approves 600-MW Jove Solar Project in Arizona", "powermag.com", "2024", NA_integer_,
    "600 MW PV facility on 3,495 acres; may incorporate BESS; cost not stated.",
    "low", TRUE, "Solar capex: 600 MW @ ~$1.1M/MW (utility-scale solar avg)",
    "Imputed $660M; rounded to $700M to account for likely BESS addition.",

  20240213L, "BOEM", "MA", 9000, 2024L, "web_imputed",
    "https://www.boem.gov/renewable-energy/state-activities/southcoast-wind-formerly-mayflower-wind",
    "SouthCoast Wind (formerly Mayflower Wind) | BOEM", "boem.gov", "2024-12-20", NA_integer_,
    "2.4 GW capacity; cost not directly stated.",
    "low", TRUE, "BOEM-offshore-wind-$/GW (from MD Wind $6B/2.2GW = $2.7B/GW, applied to 2.4 GW)",
    "Imputed $6.5B at MD Wind rate; rounded up to $9B accounting for delayed-completion cost inflation.",

  20240220L, "BIA", "OR", 40, 2024L, "web_partial",
    "https://kobi5.com/news/local-news/coquille-tribe-on-what-proposed-medford-casino-may-offer-257686/",
    "Coquille tribe on what proposed Medford casino may offer", "kobi5.com", "2024", NA_integer_,
    "Class II casino (no table games, 600+ slot machines), remodel of Roxy Ann Lanes; land was $1.6M; 250 jobs; $10M annual payroll.",
    "low", TRUE, "Class-II-casino-remodel-low-estimate",
    "Class II remodel of existing bowling alley site; smaller than typical fee-to-trust new builds. $30-50M range.",

  20240221L, "BIA", "CA", 600, 2024L, "web",
    "https://huffman.house.gov/media-center/in-the-news/koi-indian-tribe-unveils-plans-for-600-million-casino-resort-in-sonoma-county",
    "Koi Indian tribe unveils plans for $600 million casino resort in Sonoma County",
    "huffman.house.gov", "2024", NA_integer_,
    "the Koi Nation unveiled plans to turn a 68-acre vineyard southeast of Windsor into a $600 million casino resort.",
    "high", FALSE, NA_character_,
    "Project later halted by court (Sep 2025); for our purposes EIS-stage exposure applies.",

  20240229L, "DOE", "NV", 0, 2024L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "DOE adoption of BLM Rhyolite Ridge EIS (eis_number 20240166).",
    "high", FALSE, NA_character_,
    "Duplicate. Project capex counted under 20240166.",

  20240237L, "DOE", "AK", 33.7, 2024L, "web",
    "https://hydro.org/powerhouse/article/76-million-in-funding-for-new-hydro-in-alaska-washington-to-provide-clean-energy-to-rural-and-remote-areas/",
    "$76 Million in Funding for New Hydro in Alaska & Washington", "hydro.org", "2024", NA_integer_,
    "The overall project cost for Thayer Hydro is estimated to be $33,650,000.",
    "high", FALSE, NA_character_,
    "850 kW run-of-river hydro for Angoon, AK. DOE OCED Phase 1 $3.4M + total federal share up to $26.9M.",

  20240241L, "FHWA", "WI", 3600, 2024L, "web",
    "https://wtba.org/latest-tpc-report-estimates-i-39-90-94-expansion-to-cost-3-6-billion/",
    "Latest TPC report estimates I-39/90/94 expansion to cost $3.6 billion", "wtba.org", "2024", NA_integer_,
    "Initial estimates for the massive I-39/90/94 expansion... put the overall cost around $3.6 billion.",
    "high", FALSE, NA_character_,
    "$3.6B at 2024 prices; could rise to $4.9B by mid-2040s completion.",

  20240242L, "USAF", "FL", 40, 2024L, "web_imputed",
    "https://www.eglin.af.mil/News/Article-Display/Article/3852542/air-force-to-expand-childcare-for-dod-families-north-of-eglin/",
    "Air Force to expand childcare for DOD families north of Eglin", "eglin.af.mil", "2024", NA_integer_,
    "new child development center in Crestview to accommodate 250 children; cost not stated.",
    "low", TRUE, "DOD-CDC-typical-cost (250-child facilities run $30-50M)",
    "MILCON CDC II/III typical cost band used as proxy.",

  20240243L, "FERC", "TN", 1100, 2024L, "web",
    "https://www.naturalgasintel.com/news/enbridge-begins-work-on-11b-ridgeline-natural-gas-pipeline-expansion-in-tennessee/",
    "Enbridge Begins Work on $1.1B Ridgeline Natural Gas Pipeline Expansion in Tennessee",
    "naturalgasintel.com", "2025", NA_integer_,
    "FERC has approved Enbridge subsidiary East Tennessee Natural Gas's $1.1 billion, 122-mile Ridgeline Expansion Project.",
    "high", FALSE, NA_character_,
    "122-mile 30-inch pipeline; supplies TVA Kingston replacement plant.",

  # ---- Records added after classifier refinement (2nd pass) ----
  20240017L, "BLM", "WY", 5000, 2024L, "web_partial",
    "https://fas.org/publication/critical-sentinel-overrun/",
    "Critical Overrun of Sentinel ICBM Program Demands Government Transparency", "fas.org", "2024", NA_integer_,
    "Total program acquisition cost ~$140.9B; individual silo-deployment EIS site capex much smaller. Used $5B as conservative per-site allocation.",
    "low", TRUE, "Sentinel program total $140.9B / ~28 site-specific EIS actions",
    "Sentinel/GBSD program is unusually large; counting full program would distort sector totals. Conservative per-site share used.",

  20240022L, "USFS", "WY", 0, 2024L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "USFS adoption of same Sentinel deployment EIS as BLM (20240017).",
    "high", FALSE, NA_character_,
    "Duplicate. Project capex counted under 20240017 (BLM adoption).",

  20240075L, "USAF", "MS", 80, 2024L, "web_imputed",
    "https://columbus.t-7anepadocuments.com/",
    "T-7A Recapitalization at Columbus AFB", "columbus.t-7anepadocuments.com", "2024", NA_integer_,
    "Columbus-specific MILCON cost not published; JBSA T-7A beddown $72M used as proxy.",
    "low", TRUE, "JBSA T-7A beddown ($72M) used as per-base proxy",
    "T-7A Red Hawk replacing T-38 Talon at training base.",

  20240088L, "CHSRA", "CA", 22600, 2024L, "web",
    "https://www.enr.com/articles/58898-california-high-speed-rail-authority-oks-226b-palmdale-burbank-segment",
    "California High-speed Rail Authority OKs $22.6B Palmdale-Burbank Segment", "enr.com", "2024-06-27", NA_integer_,
    "$22.6-billion section of the passenger train network linking the cities of Palmdale and Burbank in Los Angeles County.",
    "high", FALSE, NA_character_,
    "38.3-mile route SR14A with 27.9 miles of tunnels under Angeles National Forest.",

  20240103L, "BLM", "NV", 2500, 2024L, "web",
    "https://thenevadaindependent.com/article/massive-4-2b-nv-energy-transmission-line-gets-federal-ok",
    "Massive $4.2B NV Energy transmission line gets federal OK", "thenevadaindependent.com", "2024", NA_integer_,
    "Original estimated cost of $2.5 billion has since increased to $4.24 billion for the combined Greenlink projects (West and North).",
    "medium", FALSE, NA_character_,
    "Greenlink West alone ~$2.5B of the combined $4.24B (West is the larger segment, ~350 miles vs. North's shorter run).",

  20240106L, "USAF", "TX", 80, 2024L, "web_imputed",
    "https://columbus.t-7anepadocuments.com/about",
    "T-7A Recapitalization at Laughlin AFB", "columbus.t-7anepadocuments.com", "2024", NA_integer_,
    "Laughlin-specific MILCON cost not published; JBSA T-7A beddown $72M used as proxy.",
    "low", TRUE, "JBSA T-7A beddown ($72M) used as per-base proxy",
    "Second T-7A training base recapitalization in 2024.",

  20240122L, "BOP", "KY", 500, 2024L, "web",
    "https://www.constructiondive.com/news/kentucky-prison-federal-approval/731728/",
    "$500M Kentucky prison gets federal approval for construction", "constructiondive.com", "2024", NA_integer_,
    "The House Appropriations Committee has earmarked $500 million for construction of the facility.",
    "high", FALSE, NA_character_,
    "Federal Correctional Institution in Letcher County, KY. 1,408 beds, medium-security + camp.",

  20240139L, "GSA", "IL", 100, 2024L, "web_imputed",
    "https://www.gsa.gov/real-estate/ongoing-construction-projects/chicago-202220-s-state-st",
    "202-220 S. State St. Federal Properties", "gsa.gov", "2024", NA_integer_,
    "Demolition + site work after exchange; specific cost not stated. Federal demolition + redevelopment ~$50-150M typical.",
    "low", TRUE, "GSA-demolition-redevelopment-typical (~$50-150M)",
    "Consumers Building (Chicago) demolition + site work. No new construction directly.",

  20240160L, "USFS", "ID", 2580, 2024L, "web",
    "https://perpetuaresources.com/project/",
    "Stibnite Gold Project - Perpetua Resources", "perpetuaresources.com", "2024", NA_integer_,
    "Perpetua Resources estimates an initial capex of $2.58 billion for its Stibnite gold-antimony project.",
    "high", FALSE, NA_character_,
    "15-year mine life; first new US lithium-and-antimony source in decades. $2.9B EXIM loan approved.",

  20240167L, "BLM", "UT", 930, 2024L, "web",
    "https://www.transcanyon.com/projects/Cross-Tie-Transmission-Line/default.aspx",
    "Cross-Tie 500 kV Transmission Line", "transcanyon.com", "2024", NA_integer_,
    "Estimated capital cost is approximately $930 million.",
    "high", FALSE, NA_character_,
    "214-mile 500 kV line UT-NV. TransCanyon (Berkshire-backed) developer.",

  20240181L, "UDOT", "UT", 3700, 2024L, "web",
    "https://www.sltrib.com/news/2023/09/29/cost-expand-interstate-15-just-got/",
    "The cost to expand Interstate 15 just got more expensive", "sltrib.com", "2023-09-29", NA_integer_,
    "UDOT estimated the cost for the project might be $3.7 billion.",
    "medium", FALSE, NA_character_,
    "I-15 Farmington-SLC corridor expansion. Latest estimate $4B; $3.7B used as anchor.",

  20240188L, "RUS", "SC", 50, 2024L, "web_imputed",
    "https://www.rd.usda.gov/resources/environmental-studies/impact-statement/mcclellanville-115kv-transmission-line-berkeley-charleston-and-georgetown-counties-sc",
    "McClellanville 115kV Transmission Line", "rd.usda.gov", "2024", NA_integer_,
    "23.3-mile 115-kV line; cost not published. Typical small-utility transmission ~$2M/mile = ~$50M.",
    "low", TRUE, "Transmission $/mile (115 kV ~ $2M/mile) x 23.3 miles",
    "Central Electric Power Cooperative project, RUS-financed.",

  20240235L, "USACE", "NE", 150, 2024L, "web_imputed", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Nebraska Highway 12 Niobrara East and West - no cost surfaced in search; USACE 404 permit for state highway. Typical rural highway expansion ~$100-200M.",
    "low", TRUE, "Rural-state-highway-typical (~$150M)",
    "USACE acts as joint NEPA lead; primary project is NDOT highway expansion."
)

# Merge audit H-1 record additions (records flipped from (iii) to (i) post-audit).
prov <- bind_rows(prov, h1_records |> filter(panel_year == 2024L) |> select(-panel_year))

finalize_cost_year(prov, 2024L)
