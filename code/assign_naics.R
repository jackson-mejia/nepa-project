# Assign NAICS sector to each EIS based on lead_agency + title keywords.
#
# Target taxonomy: BEA's ~70-industry detail (the level used in IO tables and
# Domar weight construction). Each row gets:
#   naics_code  -- BEA-style industry code (e.g., "212" for non-oil mining)
#   naics_label -- human-readable label
#   naics_reason -- which rule fired
#
# Coverage focus: category (i) records, but rules apply to all 1,124 for completeness.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})

library(here)
IN_PATH  <- here("data", "processed", "eis_finals_classified.csv")
OUT_PATH <- here("data", "processed", "eis_finals_with_naics.csv")

d <- read_csv(IN_PATH, show_col_types = FALSE)
cat(sprintf("Input: %d records\n", nrow(d)))

ci <- function(p, x) str_detect(x, regex(p, ignore_case = TRUE))

t <- d$title
a <- d$lead_agency

# ---- NAICS / BEA-industry assignment ----
# Single-pass case_when waterfall. Most-specific patterns first, agency defaults last.
# (Previously had a vestigial first pass whose outputs were never read; removed.)

final <- d |>
  mutate(
    naics_pipeline = ci("pipeline|gas line|gas expansion|compressor station|riley ridge to natrona", t) |
                     (a == "FERC" & ci("expansion|gas service", t)),
    naics_mining = ci("\\bmine\\b|mining|\\bgold\\b|\\bcopper\\b|\\blithium\\b|\\bborate\\b|\\bboron\\b|\\brare earth\\b|\\bsilver\\b|\\bnickel\\b|\\bcobalt\\b|\\bcoal\\b|\\bgraphite\\b|critical mineral|\\bquarry\\b|\\bquarries\\b", t),
    # Named BLM Alaska oil/gas projects whose short titles lack the oil/gas keyword.
    # Added per H-1 Round 2 audit (C001 fact-check finding): without this, these
    # records default to NAICS 212 (Mining) via the BLM agency default and inflate
    # Mining's ϕ_i past 1.0.
    naics_oilgas = ci("oil and gas|crude oil|natural gas (well|drilling|extraction|lease)|deepwater port|offshore.*(oil|gas)|tar sands|oil shale|greater mooses tooth|\\bGMT[- ]?[12]\\b|alpine satellite|willow master development|\\bNPR.A\\b|national petroleum reserve", t),
    naics_elec_gen = ci("solar|wind|geothermal|hydroelectric|hydro |pumped storage|battery|energy storage|nuclear|combined cycle|gas plant|generating station|power plant|generation|\\btransmission\\b|\\bkV\\b|kilovolt|substation|interconnection|\\bHVDC\\b|clean power (link|line)|power line|electric line", t) |
                     (a %in% c("BOEM", "FERC") & ci("wind|solar|hydro|pumped storage|energy storage", t)) |
                     (a == "NRC" & !ci("waste|storage of spent fuel", t)) |
                     (a == "RUS"),
    naics_rail = ci("railroad|freight rail|amtrak|union station|rail extension|rail corridor", t) | (a == "FRA"),
    naics_transit = ci("transit|subway|light rail|bus terminal|bus rapid|metro|streetcar|operations and maintenance facility", t) | (a == "FTA"),
    naics_water_trans = (ci("harbor|channel|deepening|dredg|navigation improvement|breakwater|seawall|lock and dam", t) |
                         (ci("\\bport\\b", t) & !ci("land port|airport|spaceport|port of entry", t))),
    naics_air = ci("\\bairport\\b|airfield|runway|hangar|aircraft|kc-46|b-21|f-15|f-35", t) | (a == "FAA"),
    naics_water_util = ci("reservoir|water supply|water storage|sewage|wastewater|water system|recovery management", t),
    naics_highway = ci("interstate|highway|i-\\d+|route \\d|\\bbridge\\b|corridor.*expansion", t) | (a == "FHWA"),
    naics_casino = (a == "BIA" & ci("casino|gaming|resort|fee.to.trust", t)) | ci("\\bcasino\\b|gaming facility|resort.*casino", t),
    naics_housing = (a == "HUD") | ci("\\bhousing\\b|redevelopment.*residential", t),
    naics_recreation = (a == "USFS" & ci("ski|resort|recreation", t)),
    naics_fed_construction = ci("federal courthouse|federal building|land port of entry|^lpoe|base.*modernization|expansion and modernization|beddown|cantonment|barracks|military construction|new federal", t) |
                             (a == "GSA" & ci("construction|new |expansion|modernization", t)) |
                             (a %in% c("USAF","USA","USN","USCG") & ci("construction|beddown|expansion|modernization|childcare|community", t)),
    # "Sentinel" must be paired with weapons-context to avoid matching the Omya Sentinel Quarry.
    naics_weapons = ci("sentinel (deployment|.*ICBM|.*GBSD|.*decommissioning|missile)|minuteman|\\bGBSD\\b|\\bGSBD\\b|ground based strategic deterrent|weapons system", t),
    naics_hsr = ci("high.speed rail|HSR\\b", t) | (lead_agency == "CHSRA"),
    naics_addr_building = ci("buildings? at \\d|\\d+ (north|south|east|west) (state|main|federal|broadway) street", t),

    naics_code = case_when(
      naics_weapons          ~ "9281",   # weapons system deployment overrides everything
      naics_hsr              ~ "482",    # high-speed rail
      naics_addr_building    ~ "236",    # buildings at street addresses
      naics_pipeline         ~ "486",
      naics_oilgas           ~ "211",    # check before mining (deepwater port etc.)
      naics_elec_gen         ~ "2211",   # check before mining
      naics_mining           ~ "212",
      naics_rail             ~ "482",
      naics_transit          ~ "485",
      naics_water_trans      ~ "488",
      naics_air              ~ "481",
      naics_water_util       ~ "2213",
      naics_highway          ~ "237310",
      naics_casino           ~ "713210",
      naics_housing          ~ "236",
      naics_recreation       ~ "713",
      naics_fed_construction ~ "236",
      lead_agency == "USACE" ~ "2213",
      lead_agency == "USFS"  ~ "113",
      lead_agency == "BLM"   ~ "212",
      lead_agency %in% c("USFWS","NPS","NMFS","NOAA","USGS","EPA") ~ "9241",
      lead_agency %in% c("USAF","USA","USN","USCG","DOD")          ~ "9281",
      lead_agency == "DOE"   ~ "9281",
      lead_agency == "BR"    ~ "2213",
      lead_agency == "FAA"   ~ "481",
      lead_agency == "MARAD" ~ "483",
      lead_agency == "STB"   ~ "482",    # Surface Transportation Board → rail
      lead_agency == "TVA"   ~ "2211",
      lead_agency == "FERC"  ~ "2211",
      lead_agency == "RUS"   ~ "2211",
      lead_agency == "BOP"   ~ "236",
      lead_agency %in% c("UDOT","CALTRANS","FDOT","TXDOT","NCDOT","ODOT","VADOT") ~ "237310",
      TRUE                   ~ "999"
    ),

    naics_label = recode(naics_code,
      "486"    = "Pipeline transportation",
      "212"    = "Mining (except oil & gas)",
      "211"    = "Oil & gas extraction",
      "2211"   = "Electric power generation/transmission/distribution",
      "482"    = "Rail transportation",
      "485"    = "Transit & ground passenger transportation",
      "488"    = "Support activities for water transportation",
      "481"    = "Air transportation",
      "2213"   = "Water, sewage, & other systems",
      "237310" = "Highway, street, and bridge construction",
      "713210" = "Casinos (tribal gaming)",
      "236"    = "Construction of buildings",
      "713"    = "Amusement, gambling, recreation",
      "113"    = "Forestry & logging",
      "9241"   = "Federal admin of environmental quality",
      "9281"   = "National security",
      "483"    = "Water transportation",
      "999"    = "Unclassified"
    ),

    naics_reason = case_when(
      naics_weapons          ~ "weapons system deployment (national security)",
      naics_hsr              ~ "high-speed rail",
      naics_addr_building    ~ "GSA federal buildings at address",
      naics_pipeline         ~ "pipeline / compressor / gas service",
      naics_oilgas           ~ "oil & gas extraction",
      naics_elec_gen         ~ "electricity generation / transmission",
      naics_mining           ~ "mining / mineral extraction",
      naics_rail             ~ "rail (FRA, Amtrak, freight)",
      naics_transit          ~ "transit / light rail / bus terminal",
      naics_water_trans      ~ "water transportation infrastructure",
      naics_air              ~ "air / aviation / airfield / aircraft beddown",
      naics_water_util       ~ "water supply / sewage / reservoir",
      naics_highway          ~ "highway / bridge / interstate",
      naics_casino           ~ "casino / tribal gaming",
      naics_housing          ~ "housing / HUD",
      naics_recreation       ~ "USFS recreation / ski",
      naics_fed_construction ~ "federal construction / military beddown",
      lead_agency == "USACE" ~ "USACE default → water systems",
      lead_agency == "USFS"  ~ "USFS default → forestry",
      lead_agency == "BLM"   ~ "BLM default → mining",
      lead_agency %in% c("USFWS","NPS","NMFS","NOAA","USGS","EPA") ~ "regulatory / environmental admin",
      lead_agency %in% c("USAF","USA","USN","USCG","DOD","DOE")   ~ "national security default",
      lead_agency == "BR"    ~ "Bureau of Reclamation = water",
      lead_agency == "FAA"   ~ "FAA = aviation",
      lead_agency == "TVA"   ~ "TVA = electric utility",
      lead_agency == "FERC"  ~ "FERC default = electric power",
      lead_agency == "RUS"   ~ "RUS = rural electric",
      lead_agency == "BOP"   ~ "BOP = federal prison construction",
      lead_agency %in% c("UDOT","CALTRANS","FDOT","TXDOT","NCDOT","ODOT","VADOT") ~ "state DOT = highway",
      TRUE                   ~ "no rule matched"
    )
  ) |>
  select(-starts_with("naics_pipeline"), -starts_with("naics_mining"),
         -starts_with("naics_oilgas"), -starts_with("naics_elec_gen"),
         -starts_with("naics_rail"), -starts_with("naics_transit"),
         -starts_with("naics_water_trans"), -starts_with("naics_air"),
         -starts_with("naics_water_util"), -starts_with("naics_highway"),
         -starts_with("naics_casino"), -starts_with("naics_housing"),
         -starts_with("naics_recreation"), -starts_with("naics_fed_construction"),
         -starts_with("naics_weapons"), -starts_with("naics_hsr"),
         -starts_with("naics_addr_building"))

cat(sprintf("Output: %d records\n", nrow(final)))

cat("\n=== NAICS distribution within category (i) (the ones we cost-extract) ===\n")
print(final |> filter(category == "i") |> count(naics_code, naics_label, sort = TRUE), n = Inf)

write_csv(final, OUT_PATH)
cat(sprintf("\nWrote %d records to %s\n", nrow(final), OUT_PATH))
