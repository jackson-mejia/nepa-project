# 2022 cost extraction — all 37 cat(i) records with full provenance.
# Same schema as 2023 and 2024.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tibble)
})

library(here)
source(here("code", "_h1_records.R"))    # H-1 audit additions
source(here("code", "_cost_helpers.R"))  # finalize_cost_year()
OUT_PATH <- here("data", "processed", "cost_extraction_2022.csv")

prov <- tribble(
  ~eis_number, ~lead_agency, ~state, ~cost_m_usd_nominal, ~cost_year, ~cost_method, ~cost_source_url, ~cost_source_title, ~cost_source_publisher, ~cost_source_date, ~cost_source_page, ~cost_quote, ~cost_confidence, ~imputed, ~imputation_basis, ~cost_notes,

  20220001L, "USPS", "DC", 6000, 2022L, "web",
    "https://about.usps.com/newsroom/national-releases/2022/0324-usps-places-order-for-next-gen-delivery-vehicles-to-be-electric.htm",
    "USPS places order for next-gen delivery vehicles", "about.usps.com", "2022-03-24", NA_integer_,
    "The contract, which is valued at $6 billion, was awarded to Oshkosh Defense.",
    "high", FALSE, NA_character_,
    "USPS NGDV acquisition program (50-165K vehicles over 10yr). Initial 50K order = $2.98B; full contract $6B.",

  20220009L, "FTA", "OR", 2750, 2022L, "web",
    "https://en.wikipedia.org/wiki/Southwest_Corridor_(TriMet)",
    "Southwest Corridor TriMet", "wikipedia.org", "2022", NA_integer_,
    "At an estimated cost of $2.6 billion to $2.9 billion, the project was included in a regional transportation funding measure.",
    "medium", FALSE, NA_character_,
    "Project paused 2020 after voter rejection. EIS completed. 12-mile MAX extension.",

  20220018L, "CHSRA", "CA", 3500, 2022L, "web_imputed",
    "https://hsr.ca.gov/project-overview/",
    "California High-Speed Rail Program: San Jose to Merced", "hsr.ca.gov", "2022", NA_integer_,
    "Segment-specific cost not stated; imputed from $/mile of nearby segments.",
    "low", TRUE, "CHSRA-segment $/mile (~$40M/mile for non-tunneled × 89 mi)",
    "San Jose-Merced segment. 89 miles, mostly at-grade or blended with UPRR alignment.",

  20220019L, "DOD", "ID", 300, 2022L, "web",
    "https://en.wikipedia.org/wiki/Project_Pele",
    "Project Pele Mobile Microreactor", "wikipedia.org", "2022", NA_integer_,
    "The estimated cost of this prototype is approximately 300 million USD.",
    "high", FALSE, NA_character_,
    "BWXT-built 1-5 MWe microreactor at INL. Delivered 2024.",

  20220023L, "USAF", "TX", 72, 2022L, "web",
    "https://jbsa.t-7anepadocuments.com/about",
    "T-7A JBSA Recapitalization", "jbsa.t-7anepadocuments.com", "2022", NA_integer_,
    "The estimated cost for delivering T-7A infrastructure at JBSA over the next 5-10 years is $72 million.",
    "high", FALSE, NA_character_,
    "Up to 72 T-7A aircraft replacing T-38C at JBSA-Randolph.",

  20220026L, "FERC", "UT", 200, 2022L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Kern River Delta Lateral — 35-mile 24-inch pipeline to IPP Delta UT. Cost not stated. Typical mid-size pipeline ~$5-6M/mile × 35 mi.",
    "low", TRUE, "Mid-size FERC pipeline $/mile (~$5-6M/mile)",
    "Operates by Kern River Gas Transmission (not Dominion). 140,000 Dth/d capacity.",

  20220030L, "BR", "WY", 89, 2024L, "web",
    "https://wyofile.com/hyattville-dam-cost-jumps-69-to-59m/",
    "Hyattville dam cost jumps 69% to $59M", "wyofile.com", "2024", NA_integer_,
    "Big Horn County's Upper Leavitt Reservoir expansion is now estimated to cost $89 million.",
    "medium", FALSE, NA_character_,
    "BR adoption of WY state EIS. State-funded with limited federal share.",

  20220036L, "FERC", "WY", 200, 2022L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Clear Creek Expansion (Spire). Major storage capacity expansion (5x compression, 5x storage). Cost not published.",
    "low", TRUE, "FERC-storage-expansion-median (~$200M for major compression/storage)",
    "Compression from 3,740 to 24,340 hp; storage from 4 to 20 Bcf.",

  20220038L, "FERC", "WI", 80, 2022L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Wisconsin Access Project (ANR/TC Energy). 50,707 Dth/d capacity increase via existing pipeline + meter station modifications. Small project.",
    "low", TRUE, "Small-FERC-meter-station-modification (~$50-100M)",
    NA_character_,

  20220049L, "FHWA", "NY", 2250, 2022L, "web",
    "https://www.enr.com/articles/54131-ny-moves-ahead-on-syracuse-i-81-viaduct-replacement-project",
    "NY Moves Ahead on Syracuse I-81 Viaduct Replacement Project", "enr.com", "2022", NA_integer_,
    "The I-81 Viaduct project is a $2.25 billion project, with a $2.3-billion interstate highway replacement project mentioned in more recent reporting.",
    "high", FALSE, NA_character_,
    "1.4-mile elevated viaduct removal + Community Grid Alternative.",

  20220050L, "FERC", "LA", 400, 2022L, "web_imputed",
    "https://semprainfrastructure.com/what-we-do/energy-networks/la-storage-hackberry/",
    "LA Storage Hackberry - Sempra Infrastructure", "semprainfrastructure.com", "2023", NA_integer_,
    "20-bcf natural gas salt dome storage + 3 conversions + 16 miles 42-inch pipeline. Cost not stated.",
    "low", TRUE, "FERC-major-storage-project-median (~$400M)",
    "Sempra LA Storage Hackberry. Phase 1 FID Sept 2023, construction start Mar 2025.",

  20220053L, "MARAD", "CA", 1567, 2022L, "web",
    "https://www.enr.com/articles/58291-15b-rail-facility-set-to-begin-at-port-of-long-beach",
    "$1.5B Rail Facility Set to Begin at Port of Long Beach", "enr.com", "2024", NA_integer_,
    "The overall project cost is $1.567 billion.",
    "high", FALSE, NA_character_,
    "Pier B On-Dock Rail Support Facility. 10 construction projects in $1.815B program. Triples on-dock rail capacity to 4.7M TEU.",

  20220057L, "FHWA", "MD", 7150, 2022L, "web",
    "https://www.nbcwashington.com/news/local/maryland-transit-officials-approve-15b-bay-bridge-replacement-plan/4031236/",
    "Maryland officials approve $15B Bay Bridge replacement plan", "nbcwashington.com", "2025-12-18", NA_integer_,
    "Tier 1 study estimated $5.4-8.9B; Tier 2 now $14.8-16B. Midpoint of Tier 1 used as 2022-vintage figure.",
    "medium", FALSE, NA_character_,
    "Tier 1 NEPA for Chesapeake Bay Crossing. Replacement of 1952/1973 dual-span Bay Bridge.",

  20220068L, "TVA", "AL", 200, 2022L, "web_imputed",
    "https://www.federalregister.gov/documents/2022/07/01/2022-14125/north-alabama-utility-scale-solar-facility-environmental-impact-statement",
    "North Alabama Utility-Scale Solar Facility EIS", "federalregister.gov", "2022-07-01", NA_integer_,
    "Approximately 200 MW solar PV + 200 MWh BESS. Cost not stated.",
    "low", TRUE, "Solar+BESS capex (200 MW @ $1M/MW + 200 MWh @ $300/kWh)",
    NA_character_,

  20220070L, "DOE", "ID", 4500, 2022L, "web",
    "https://www.enr.com/articles/50801-bechtel-team-to-build-3b-6b-nuclear-test-reactor-in-idaho",
    "Bechtel Team to Build $3B-$6B Nuclear Test Reactor in Idaho", "enr.com", "2020-11-24", NA_integer_,
    "The project will cost from $3 billion to $6 billion.",
    "medium", FALSE, NA_character_,
    "Versatile Test Reactor at INL. Funding cancelled in 2022 but EIS completed; counts for exposure measure. Midpoint $4.5B used.",

  20220074L, "CHSRA", "CA", 3500, 2022L, "web_imputed",
    "https://www.permits.performance.gov/permitting-project/dot-projects/california-high-speed-rail-program-san-francisco-san-jose-project",
    "California HSR Program: San Francisco to San Jose Project Section", "permits.performance.gov", "2022", NA_integer_,
    "Segment cost may range from $2.0 billion to $5.0 billion per CHSRA.",
    "medium", FALSE, NA_character_,
    "SF-SJ segment. Caltrain electrification + HSR-ready infrastructure.",

  20220078L, "FRA", "CA", 1000, 2022L, "web",
    "https://secretlosangeles.com/1-billion-train-la-to-coachella-valley/",
    "The $1 Billion Train Route From LA To Coachella Valley", "secretlosangeles.com", "2022", NA_integer_,
    "The project is estimated to cost $1 billion.",
    "high", FALSE, NA_character_,
    "Coachella Valley-San Gorgonio Pass Rail Corridor Service. LA-Indio Amtrak service plan.",

  20220081L, "FHWA", "MD", 3700, 2022L, "web",
    "https://www.constructiondive.com/news/maryland-announces-p3-short-list-for-first-phase-of-9b-plus-capital-beltwa/582586/",
    "Maryland P3 short list for first phase of $9B-plus Capital Beltway", "constructiondive.com", "2022", NA_integer_,
    "The first phase of the project would cost about $3.7 billion. With the total project estimated value at $9 billion.",
    "high", FALSE, NA_character_,
    "I-495 & I-270 Managed Lanes (HOT lanes). Phase 1 used; total program ~$9B.",

  20220087L, "FERC", "LA", 75, 2022L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Golden Pass Pipeline MP66-69 Compressor Relocation. ~3-mile pipeline relocation + compressor mods. Cost not published.",
    "low", TRUE, "Small-compressor-relocation (~$50-100M)",
    "Connected action with Golden Pass LNG.",

  20220108L, "TVA", "TN", 0, 2022L, "reclassified_to_ii",
    NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Clinch River Advanced Nuclear Reactor Technology Park PEIS — programmatic, not specific project. Should be (ii).",
    "high", FALSE, NA_character_,
    "TVA programmatic EIS — Final EIS title literally says 'Programmatic'. Underlying project (Clinch River SMR) has its own EIS 20230107.",

  20220109L, "FERC", "PA", 950, 2023L, "web",
    "https://www.utilitydive.com/news/ferc-transco-gas-pipeline-ghg-policy-review/738349/",
    "FERC reinstates Transco gas pipeline approval", "utilitydive.com", "2025", NA_integer_,
    "FERC in January 2023 approved Transco's roughly $950 million Regional Energy Access expansion project.",
    "high", FALSE, NA_character_,
    "Williams/Transco. 829 MMcf/d into existing interstate system.",

  20220113L, "FTA", "IL", 5750, 2022L, "web",
    "https://www.constructiondive.com/news/chicago-red-line-transit-extension-groundbreaking/818707/",
    "Chicago breaks ground on $5.7B Red Line transit extension", "constructiondive.com", "2026-04", NA_integer_,
    "The 5.6-mile, $5.75 billion project will move the Red Line's south end from 95th to 130th Street.",
    "high", FALSE, NA_character_,
    "CTA Red Line Extension. $1.9B BIL FTA New Starts. 4 new stations + rail yard.",

  20220124L, "FERC", "KY", 200, 2022L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Texas Gas Henderson County Expansion — 24-mile 20-inch pipeline serving 220 MMcf/d to CenterPoint AB Brown plant. Cost not published.",
    "low", TRUE, "Mid-size FERC pipeline $/mile (~$8M/mile × 24 mi)",
    NA_character_,

  20220126L, "FERC", "CA", 450, 2022L, "web",
    "https://www.asce.org/publications-and-news/civil-engineering-source/civil-engineering-magazine/article/2023/05/construction-begins-on-removal-of-4-klamath-river-dams",
    "Construction begins on removal of 4 Klamath River dams", "asce.org", "2023", NA_integer_,
    "The project's total budget is $450 million.",
    "high", FALSE, NA_character_,
    "Klamath dam removal (4 dams). Largest dam removal project in US history. Note: this is removal capex, not new generation.",

  20220127L, "UDOT", "UT", 729, 2023L, "web",
    "https://www.ksl.com/article/50684958/udot-moves-forward-with-gondola-buses-and-tolling-for-little-cottonwood-canyon",
    "UDOT moves forward with gondola, buses and tolling for Little Cottonwood Canyon", "ksl.com", "2023", NA_integer_,
    "the agency says it is now expected to cost $729 million.",
    "medium", FALSE, NA_character_,
    "Little Cottonwood Canyon SR-210. Gondola Alternative B + enhanced bus + tolling. Phased.",

  20220134L, "FERC", "LA", 11000, 2022L, "web",
    "https://www.offshore-energy.biz/11-billion-us-lng-project-in-louisiana-bags-final-ferc-approval-ahead-of-fid/",
    "$11 billion US LNG project in Louisiana bags final FERC approval ahead of FID", "offshore-energy.biz", "2022", NA_integer_,
    "Commonwealth LNG's phase 1 development is forecast to bring an investment of more than $11 billion to Louisiana.",
    "high", FALSE, NA_character_,
    "9.5 Mtpa liquefaction facility on Calcasieu Ship Channel. $4B original budget; $11B current.",

  20220135L, "FERC", "LA", 1500, 2022L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Driftwood Line 200/300. 69 miles 42-inch pipelines + 211k HP Indian Bayou compressor station. Supplies Woodside LNG.",
    "low", TRUE, "Large-FERC-pipeline+compressor (~$20M/mile × 69 mi + $100M compressor)",
    "Connected to Woodside Driftwood LNG facility.",

  20220145L, "FHWA", "SC", 1500, 2022L, "web",
    "https://abcnews4.com/news/local/scdot-looks-for-more-comments-on-i-526-east-lowcountry-corridor-project-estimated-at-4b-wciv",
    "I-526 Lowcountry Corridor West", "abcnews4.com", "2022", NA_integer_,
    "For the I-526 West project, the highway project is $1.5 billion dollars.",
    "high", FALSE, NA_character_,
    "I-526 Lowcountry Corridor West portion. Full $7B program also includes East ($4B).",

  20220149L, "FERC", "MO", 287, 2022L, "web",
    "https://www.gem.wiki/Spire_STL_Pipeline",
    "Spire STL Pipeline - Global Energy Monitor", "gem.wiki", "2022", NA_integer_,
    "the pipeline's construction ultimately cost $287 million.",
    "high", FALSE, NA_character_,
    "FERC reissued permanent certificate Dec 2022. 65-mile 24-inch pipeline.",

  20220152L, "USCG", "ND", 300, 2022L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "BNSF Bridge 196.6 Missouri River replacement (Bismarck-Mandan). Replacing 1880s bridge. Major rail bridge build.",
    "low", TRUE, "Major-rail-bridge-replacement (~$300M)",
    "USCG-led EIS as bridge over navigable water. Private BNSF capex.",

  20220155L, "BOEM", "AK", 50, 2022L, "web_imputed",
    "https://www.boem.gov/oil-gas-energy/leasing/lease-sale-258",
    "Cook Inlet Lease Sale 258", "boem.gov", "2022", NA_integer_,
    "Sale generated one bid for one tract ($63,983, Hilcorp Alaska). No development plan finalized.",
    "low", TRUE, "Lease-sale-with-minimal-uptake-low (~$50M placeholder)",
    "EIS for OCS lease offering. Actual capex commitment minimal — only one bid received.",

  20220176L, "FERC", "ID", 75, 2022L, "web",
    "https://undergroundinfrastructure.com/news/2024/april/ferc-approves-tc-energys-northwest-xpress-gas-pipeline-expansion-despite-opposition",
    "FERC approves TC Energy's Northwest Xpress gas pipeline expansion", "undergroundinfrastructure.com", "2024-04", NA_integer_,
    "The cost of the expansion project is approximately $75 million.",
    "high", FALSE, NA_character_,
    "Gas Transmission Northwest pipeline expansion. 150 MMcf/d capacity increase via 3 compressor station mods.",

  20220177L, "DOE", "LA", 0, 2022L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "DOE adoption of FERC Commonwealth LNG EIS (20220134).",
    "high", FALSE, NA_character_,
    "Duplicate. Project capex counted under 20220134.",

  20220181L, "TVA", "TN", 2100, 2023L, "web",
    "https://www.publicpower.org/periodical/article/tva-retire-coal-fired-power-plant-construct-1450-mw-combined-cycle-natural-gas-plant",
    "TVA to Retire Coal-Fired Power Plant, Construct 1,450-MW Combined-Cycle Natural Gas Plant", "publicpower.org", "2023", NA_integer_,
    "TVA approved replacement generation with 1,450-MW combined cycle gas plant. ENR previously reported TVA Cumberland multi-billion-dollar.",
    "medium", FALSE, NA_character_,
    "Cumberland Fossil Plant Retirement EIS. Replacement plant cost ~$2.1B (per Cumberland coverage). Pipeline (20230083) is separate $225M.",

  20220186L, "TVA", "TN", 100, 2022L, "web",
    "https://thelynchburgtimes.com/moore-county-solar-farm/",
    "Tiny Moore County earns $100 million plus solar farm investment", "thelynchburgtimes.com", "2022", NA_integer_,
    "an over $100 million investment in renewable energy — the largest solar project ever announced in the state of Tennessee.",
    "medium", FALSE, NA_character_,
    "200 MW solar PV in Moore County. Silicon Ranch developer; TVA PPA.",

  20220189L, "USACE", "CA", 90, 2022L, "web",
    "https://www.cvwd.org/369/Thousand-Palms-Flood-Control-Project",
    "Thousand Palms Flood Control Project", "cvwd.org", "2022", NA_integer_,
    "the Thousand Palms Flood Control Program is a $90 million project currently underway.",
    "high", FALSE, NA_character_,
    "Coachella Valley Water District + USACE joint EIR/EIS. Levees, channels, sediment basin.",

  20220190L, "FERC", "VA", 500, 2022L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Virginia Electrification Project (Transco). Specific project cost not surfaced. Mid-size Transco expansion.",
    "low", TRUE, "Mid-size FERC pipeline expansion (~$500M)",
    "Different project from later Southeast Supply Enhancement Project (2026, $1.53B)."
)

# Merge audit H-1 record additions (records flipped from (iii) to (i) post-audit).
prov <- bind_rows(prov, h1_records |> filter(panel_year == 2022L) |> select(-panel_year))

finalize_cost_year(prov, 2022L)
