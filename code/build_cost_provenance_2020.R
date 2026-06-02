# 2020 cost extraction — all 47 cat(i) records with full provenance.
# Same schema as 2021-2024.

suppressPackageStartupMessages({library(dplyr); library(readr); library(tibble)})

library(here)
source(here("code", "_h1_records.R"))    # H-1 audit additions
source(here("code", "_cost_helpers.R"))  # finalize_cost_year()
OUT_PATH <- here("data", "processed", "cost_extraction_2020.csv")

prov <- tribble(
  ~eis_number, ~lead_agency, ~state, ~cost_m_usd_nominal, ~cost_year, ~cost_method, ~cost_source_url, ~cost_source_title, ~cost_source_publisher, ~cost_source_date, ~cost_source_page, ~cost_quote, ~cost_confidence, ~imputed, ~imputation_basis, ~cost_notes,

  20200000L, "HCIDLA", "CA", 110, 2023L, "web",
    "https://www.hacla.org/en/news/hacla-and-related-california-open-first-phase-redevelopment-rose-hill-courts-public-housing",
    "Rose Hill Courts Redevelopment", "hacla.org", "2023", NA_integer_,
    "Phase I $54M (bonds + equity + state) + Phase II $58M = ~$112M total.",
    "medium", FALSE, NA_character_,
    "HACLA + Related California. 185 units replacement. 1942 public housing complex.",

  20200005L, "USN", "NV", 100, 2020L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Fallon Range Training Complex Modernization. Land withdrawal + training infrastructure. No capex disclosed.",
    "low", TRUE, "Navy-range-training-infrastructure (~$100M)",
    "NDAA FY2021 extended withdrawal but did not include modernization. Land withdrawal action.",

  20200007L, "USACE", "MS", 50, 2020L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Bayou Casotte Harbor Channel Improvement. ROD signed Aug 2020. Cost not surfaced; impute small port channel.",
    "low", TRUE, "Small-port-channel-improvement (~$50M)",
    "Pascagoula MS port. Channel improvement.",

  20200009L, "BLM", "CA", 1000, 2020L, "web",
    "https://www.blm.gov/press-release/blm-approves-haiwee-geothermal-leasing-area",
    "BLM approves Haiwee Geothermal Leasing Area", "blm.gov", "2020", NA_integer_,
    "supports $1 billion in investments; $72 million annually during peak construction.",
    "high", FALSE, NA_character_,
    "Haiwee Geothermal Leasing Area. ~4,460 acres. ~117K homes.",

  20200022L, "BIA", "CA", 500, 2020L, "web_imputed",
    "https://www.federalregister.gov/documents/2020/02/10/2020-02669/final-environmental-impact-statement-for-the-proposed-campo-wind-energy-project-san-diego-california",
    "Final EIS for Campo Wind Energy Project", "federalregister.gov", "2020-02-10", NA_integer_,
    "252 MW capacity. Up to 60 turbines @ 4.2 MW. Cost not stated.",
    "low", TRUE, "Wind-capex (~$2M/MW × 252 MW)",
    "Campo Wind + Boulder Brush. Terra-Gen developer. BIA + County of SD.",

  20200023L, "FERC", "CA", 20, 2022L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Bucks Creek Hydroelectric (84.8 MW) FERC relicensing. Existing facility, no new construction. License upgrades only.",
    "low", TRUE, "Hydro-relicensing-upgrades (~$20M)",
    "PG&E + City of Santa Clara. 40-year license to 2062.",

  20200024L, "FHWA", "NC", 1800, 2026L, "web",
    "https://changeflow.com/govping/transportation/1-8b-i-26-connector-breaks-ground-asheville-2026-04-25",
    "NCDOT Breaks Ground on $1.8B I-26 Connector", "changeflow.com", "2026", NA_integer_,
    "The entire project is estimated at $1.8 billion.",
    "high", FALSE, NA_character_,
    "I-26 Asheville Connector, 7 miles. Full project up to $2.1B per STIP.",

  20200026L, "USACE", "TX", 1000, 2025L, "web",
    "https://www.businesswire.com/news/home/20250618441353/en/Houston-Ship-Channel-Expansion-Project-11-Funded-to-Completion",
    "Houston Ship Channel Expansion – Project 11 Funded to Completion", "businesswire.com", "2025-06-18", NA_integer_,
    "Multi-year USACE Project 11. FY26 allocations: $161M USACE + $53.6M O&M + prior years. Rough total ~$1B.",
    "medium", FALSE, NA_character_,
    "Widening 170 ft along Galveston Bay reach. Complete 2029.",

  20200038L, "FRA", "MS", 25, 2024L, "web",
    "https://www.irpt.net/hcphc-receives-7-32-million-funding-for-port-bienville-intermodal-expansion-project-phase-1/",
    "HCPHC Port Bienville Intermodal Expansion", "irpt.net", "2024", NA_integer_,
    "total project cost of $25.4 million.",
    "high", FALSE, NA_character_,
    "Hancock County Port. 7-track classification yard + Phase 2 intermodal yard.",

  20200039L, "DOE", "OR", 0, 2020L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "DOE adoption of FERC Jordan Cove Energy Project EIS (20190276, $10B).",
    "high", FALSE, NA_character_,
    "CORRECTED 2026-06-01 (dup_sweep): primary FERC EIS is at 20190276 (2019 panel). Was erroneously counted $6B here as separate.",

  20200041L, "FERC", "NC", 500, 2025L, "web",
    "https://pgjonline.com/news/2025/june/court-ruling-allows-mvp-s-500-million-southgate-pipeline-extension-to-proceed",
    "MVP Southgate $500 Million Pipeline Extension", "pgjonline.com", "2025", NA_integer_,
    "MVP's $500 Million Southgate Pipeline Extension.",
    "high", FALSE, NA_character_,
    "MVP Southgate. 31 miles 30-inch pipeline VA-NC.",

  20200044L, "BLM", "WY", 4250, 2020L, "web_imputed",
    "https://www.blm.gov/press-release/bureau-land-management-issues-record-decision-moneta-divide-project",
    "BLM Issues Record of Decision for Moneta Divide Project", "blm.gov", "2020-08", NA_integer_,
    "4,250 wells over 15 years; project generates $182M/yr federal royalties.",
    "low", TRUE, "Oil-gas-well-cost (~$1M/well × 4250 wells)",
    "Aethon Energy + Burlington Resources. 18.16 Tcf gas + 254M bbl oil.",

  20200051L, "USAF", "WI", 105, 2020L, "web",
    "https://www.115fw.ang.af.mil/News/Article-Display/Article/3380773/wisconsin-air-national-guard-receives-f-35s/",
    "Wisconsin Air National Guard receives F-35s", "115fw.ang.af.mil", "2023", NA_integer_,
    "The Draft EIS estimates that construction required to support the F-35A beddown at Truax Field would cost between $90 and $120 million.",
    "high", FALSE, NA_character_,
    "115th Fighter Wing Truax Field Madison. F-35As arrived April 2023.",

  20200056L, "USACE", "CT", 200, 2020L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "New Haven Harbor 40 ft Plan. 4.5M cy dredged material. Cost not stated.",
    "low", TRUE, "Mid-size-port-deepening (~$200M)",
    "Construction expected fall 2026.",

  20200057L, "FHWA", "NH", 62, 2020L, "web",
    "https://www.i93exit4a.com/",
    "Derry-Londonderry I-93 Exit 4A", "i93exit4a.com", "2020", NA_integer_,
    "The total project cost is $61.6M.",
    "high", FALSE, NA_character_,
    "New interchange + connector road. Construction in 3 phases.",

  20200062L, "USACE", "CA", 545, 2020L, "web",
    "https://www.valleywater.org/shoreline",
    "South SF Bay Shoreline Phase I", "valleywater.org", "2020", NA_integer_,
    "The total project cost is $545 million.",
    "high", FALSE, NA_character_,
    "Coastal flood risk + ecosystem restoration + recreation.",

  20200065L, "TVA", "TN", 500, 2020L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Allen Fossil Plant Ash Closure-by-Removal. 3.5M cy CCR to offsite landfill. Cost not stated specifically.",
    "low", TRUE, "TVA-coal-ash-CCR-removal-typical (~$500M)",
    "Memphis riverfront site. Possible future inland port.",

  20200066L, "FERC", "AK", 44000, 2020L, "web",
    "https://alaskabeacon.com/2025/12/22/alaskas-44-billion-bet-on-natural-gas/",
    "Alaska's $44 billion bet on natural gas", "alaskabeacon.com", "2025", NA_integer_,
    "The estimated cost for the Alaska LNG project is approximately USD 44 billion.",
    "high", FALSE, NA_character_,
    "807-mile pipeline + Nikiski LNG export terminal. 20 MTPA LNG. FERC May 2020.",

  20200071L, "UDOT", "UT", 78, 2024L, "web",
    "https://www.stgeorgeutah.com/news/officials-celebrate-new-i-15-interchange-in-washington-city-marking-end-of-78m-project/article_073580a8-bcf1-11ef-8f9a-337654e0c1b6.html",
    "I-15 interchange Washington City $78M", "stgeorgeutah.com", "2024", NA_integer_,
    "marking end of $78M project.",
    "high", FALSE, NA_character_,
    "I-15 Milepost 11 St George area new interchange.",

  20200072L, "DOE", "AK", 0, 2020L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "DOE adoption of FERC Alaska LNG EIS (20200066).",
    "high", FALSE, NA_character_,
    "Duplicate. Counted under 20200066.",

  20200073L, "USACE", "CT", 100, 2020L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Westchester County Byram River Basin Flood Risk Management. Greenwich CT + Port Chester NY. US-1 bridge replacement.",
    "low", TRUE, "USACE-flood-feasibility-typical (~$100M)",
    "Removal/replacement of US-1 bridges at higher elevation.",

  20200089L, "BLM", "OR", 30, 2020L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Tucker Hill Perlite Mine Plan of Operations Amendment 7. Cornerstone. 262 acres expansion. Small mineral mine.",
    "low", TRUE, "Small-perlite-mine-expansion (~$30M)",
    "Lakeview District BLM. Preserves 30 jobs, 25-year life.",

  20200096L, "USACE", "CA", 200, 2020L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Westminster-East Garden Grove Flood Risk Management. ~74 sq mi watershed, 700K residents benefit.",
    "low", TRUE, "USACE-urban-flood-typical (~$200M)",
    "Orange County. 50/50 cost share with OCFCD.",

  20200097L, "FTA", "NJ", 546, 2020L, "web",
    "https://www.masstransitmag.com/technology/miscellaneous/press-release/21084658/fta-grant-to-help-fund-nj-transitgrid-project",
    "FTA grant to help fund NJ TRANSITGRID project", "masstransitmag.com", "2020", NA_integer_,
    "$409.7 million plus $136.6 million from the New Jersey State Transportation Trust Fund for a total cost of $546.3 million.",
    "high", FALSE, NA_character_,
    "104-140 MW natural gas microgrid + 19.6 miles transmission for NJ Transit + Amtrak.",

  20200113L, "DOT", "TX", 30000, 2020L, "web",
    "https://en.wikipedia.org/wiki/Texas_Central_Railway",
    "Texas Central Railway", "wikipedia.org", "2020", NA_integer_,
    "In 2020, project estimates were updated again to $30 billion.",
    "medium", FALSE, NA_character_,
    "Dallas-Houston HSR. Texas Central Partners. Now believed $40B+; uses 2020 vintage figure.",

  20200140L, "FERC", "CA", 50, 2020L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Don Pedro (168 MW) + La Grange (4.7 MW) Hydroelectric relicensing. Existing facilities, license-only changes.",
    "low", TRUE, "Hydro-relicensing-upgrades (~$50M for both)",
    "Turlock + Modesto Irrigation Districts.",

  20200143L, "USACE", "IL", 100, 2020L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Chicago Area Waterway System Dredged Material Management Plan. 20-year base plan. Cost not stated.",
    "low", TRUE, "USACE-DMMP-typical (~$100M)",
    "USACE ROD withdrawn 2025 after IL legislation block.",

  20200149L, "BLM", "WY", 5000, 2020L, "web_imputed",
    "https://www.blm.gov/press-release/blm-wyoming-issues-decision-converse-county-oil-and-gas-project",
    "BLM Wyoming Converse County Oil & Gas ROD", "blm.gov", "2020", NA_integer_,
    "5,000 new oil/gas wells over 10 years; $18-28B federal revenues over project life.",
    "low", TRUE, "Oil-gas-well-cost (~$1M/well × 5000)",
    "Anadarko/Chesapeake/Devon/EOG/Northwoods. 1.5M acres. Vacated by court 2026.",

  20200167L, "TVA", "TN", 899, 2020L, "web",
    "https://www.oversight.gov/reports/gallatin-ash-pond-complex-closure-and-restoration",
    "Gallatin Ash Pond Complex Closure and Restoration", "oversight.gov", "2020", NA_integer_,
    "total estimated project cost of approximately $899 million.",
    "high", FALSE, NA_character_,
    "14M cy CCR removal. State settlement: 20 years to complete, $640M.",

  20200169L, "USAF", "TX", 150, 2020L, "web_imputed",
    "https://www.301fw.afrc.af.mil/News/Article-Display/Article/2466375/301-fw-selected-to-receive-f-35a/",
    "301 FW Selected to Receive F-35A", "301fw.afrc.af.mil", "2020", NA_integer_,
    "F-35A AFRC beddown at NAS JRB Fort Worth. Specific MILCON not surfaced. New 55K sf squadron ops + simulator.",
    "low", TRUE, "F-35A-AFRC-beddown-MILCON (~$150M)",
    NA_character_,

  20200172L, "UDOT", "UT", 250, 2020L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Parley's Interchange I-80/I-215 Eastside. Major urban interchange redesign. Cost not surfaced.",
    "low", TRUE, "Urban-interchange-rebuild (~$250M)",
    "Alternative B selected. ROD 2020-08-11.",

  20200178L, "BLM", "NV", 700, 2020L, "web_imputed",
    "https://www.blm.gov/press-release/bureau-land-management-approves-yellow-pine-solar-project",
    "BLM Approves Yellow Pine Solar Project", "blm.gov", "2020-11", NA_integer_,
    "500 MW PV + BESS + 230 kV substation. ~$297M economic impact for local; full capex ~$700M.",
    "low", TRUE, "Solar+BESS (500 MW @ $1M/MW + storage)",
    "NextEra Energy Resources. Pahrump, NV.",

  20200180L, "FRA", "DC", 2300, 2024L, "web",
    "https://tam-america.com/article/virginia-breaks-ground-on-long-bridge-replacement-largest-trv-project",
    "Virginia breaks ground on $2.3B Long Bridge Replacement", "tam-america.com", "2024", NA_integer_,
    "$2.3 billion project to construct a new Long Bridge.",
    "high", FALSE, NA_character_,
    "Potomac River rail bridge. Amtrak + VRE + CSX. Complete 2030.",

  20200183L, "BR", "CA", 500, 2024L, "web",
    "https://sjvwater.org/eight-years-ten-miles-and-325-million-later-first-phase-of-friant-kern-canal-fix-celebrated/",
    "Friant-Kern Canal first phase $325M", "sjvwater.org", "2024", NA_integer_,
    "$325 million construction project... estimated $500 million cost of the entire project has been surpassed.",
    "medium", FALSE, NA_character_,
    "33 miles of repairs. Subsidence damage repair. Phase 1 complete 2024.",

  20200193L, "BR", "CA", 35, 2024L, "web",
    "https://www.usbr.gov/mp/lbao/truckee-canal.html",
    "Truckee Canal Public Safety Improvement", "usbr.gov", "2024", NA_integer_,
    "$35 million for Phase 1 of the Truckee Canal Public Safety Improvement Project.",
    "high", FALSE, NA_character_,
    "Newlands Project canal lining. 31 miles, post-2008 breach safety.",

  20200196L, "FTA", "CA", 500, 2020L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "FTA CA FEIS/FEIR 2020 — title truncated in source data. Likely transit project. Cost not extractable without full title.",
    "low", TRUE, "Mid-size CA transit project (~$500M)",
    "TODO: re-acquire full title from EIS document for proper cost research.",

  20200197L, "TVA", "IL", 50, 2025L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Sugar Camp Energy Mine No. 1 Boundary Revision 6. TVA-owned mineral rights lease extension. Underground longwall mining.",
    "low", TRUE, "Mine-boundary-revision-low (~$50M)",
    "Coal lease, not new mine capex. 253M tons over 25 years.",

  20200202L, "GSA", "AZ", 308, 2023L, "web",
    "https://www.gsa.gov/about-us/newsroom/news-releases/bidenharris-administration-breaks-ground-on-308-06272023",
    "Biden-Harris Administration breaks ground on $308 million port modernization", "gsa.gov", "2023-06-27", NA_integer_,
    "$308 million port modernization and expansion project.",
    "high", FALSE, NA_character_,
    "San Luis I LPOE. Expansion from 8 to 16 northbound POV lanes.",

  20200204L, "BIA", "OK", 1000, 2020L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Osage County Oil and Gas EIS. Programmatic management of 1,476,500-acre trust mineral estate.",
    "low", TRUE, "Programmatic-oil-gas-mineral-estate (~$1B)",
    "BIA-managed for Osage Nation. Replaces 1979 EA. ROD Dec 15, 2020.",

  20200207L, "BIA", "CA", 600, 2020L, "web",
    "https://www.tejoneis.com/",
    "Tejon Indian Tribe Trust Acquisition and Casino Project", "tejoneis.com", "2020", NA_integer_,
    "addresses impacts from the tribe's proposed $600 million gaming development.",
    "high", FALSE, NA_character_,
    "Tejon Tribe + Hard Rock International. 306-acre fee-to-trust, 400-room hotel + casino.",

  20200209L, "BIA", "MI", 180, 2020L, "web",
    "https://news.worldcasinodirectory.com/little-river-band-of-ottawa-indians-180-million-muskegon-county-casino-proposal-inches-forward-92809",
    "Little River Band $180M Muskegon County casino", "worldcasinodirectory.com", "2020", NA_integer_,
    "$180 million casino project in Fruitport Township.",
    "high", FALSE, NA_character_,
    "Little River Band of Ottawa Indians. Off-reservation. Denied by Gov Whitmer 2025.",

  20200213L, "FHWA", "WI", 1200, 2023L, "web",
    "https://urbanmilwaukee.com/pressrelease/gov-evers-wisdot-celebrate-progress-on-new-i-41-and-southbridge-road-interchange-in-brown-county/",
    "South Bridge Connector cost $1.2B", "urbanmilwaukee.com", "2023", NA_integer_,
    "The overall project will cost $1.2 billion.",
    "high", FALSE, NA_character_,
    "New road + I-41 interchange + Fox River crossing. Brown County WI.",

  20200243L, "BR", "ND", 100, 2024L, "web",
    "https://www.cramer.senate.gov/news/press-releases/bureau-of-reclamation-announces-108-million-to-support-north-dakota-water-supply",
    "Bureau of Reclamation $108M to Support North Dakota Water Supply", "cramer.senate.gov", "2024", NA_integer_,
    "$100 million for construction of the Eastern North Dakota Alternate Water Supply project.",
    "high", FALSE, NA_character_,
    "Phase 1 funding. Bulk water from McClusky Canal/Missouri River to eastern ND.",

  20200244L, "USAF", "FL", 5000, 2024L, "web",
    "https://www.enr.com/articles/57199-five-years-after-cat-5-hurricane-hit-florida-afbs-5b-rebuild-focuses-on-resilience",
    "Five Years After Cat-5 Hurricane Hit, Florida AFB's $5B Rebuild", "enr.com", "2024", NA_integer_,
    "$5-billion rebuild of Florida's Tyndall Air Force Base.",
    "high", FALSE, NA_character_,
    "Tyndall AFB F-35A + MQ-9 beddown. Post-Hurricane Michael full rebuild.",

  20200251L, "USCG", "GU", 0, 2020L, "duplicate_of_other_eis", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "USCG adoption of US Navy Mariana Islands Training and Testing EIS-OEIS.",
    "high", FALSE, NA_character_,
    "Duplicate. Navy EIS would be primary; not in our 2020 set.",

  20200253L, "BR", "CO", 100, 2020L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Paradox Valley Unit (Colorado Salinity Control). Brine extraction infrastructure. Cost not surfaced.",
    "low", TRUE, "Salinity-control-infrastructure (~$100M)",
    "Dolores River brine extraction. Authorized 1974.",

  20200254L, "USFS", "WY", 50, 2020L, "sector_impute_pending", NA_character_, NA_character_, NA_character_, NA_character_, NA_integer_,
    "Snow King Mountain Resort On-Mountain Improvements. Largest capex in resort history. Sunnyside Lift + 8-passenger gondola + snowmaking + ski terrain expansion.",
    "low", TRUE, "Major-ski-resort-expansion (~$50M)",
    "100-acre USFS boundary expansion. Jackson WY.",
)

# Merge audit H-1 record additions (records flipped from (iii) to (i) post-audit).
prov <- bind_rows(prov, h1_records |> filter(panel_year == 2020L) |> select(-panel_year))

finalize_cost_year(prov, 2020L)
