# Funding-source tagging — categorize each cost record by who pays the capex.
# Decoupling lead-agency-of-EIS from financing-of-project, so that Φ_i can be
# computed against the right BEA denominator (private nonresidential vs gov
# gross investment).
#
# Values:
#   private           — private equity/debt finances the capex (LNG, pipelines, mines, solar on federal land, BIA casinos, transmission cooperatives, etc.)
#   gov_federal       — federal-budget capex (USACE civil works, BR water infrastructure, military, GSA buildings, BOP prisons, FRA federal-rail, NPS/USFS construction, TVA)
#   gov_state_local   — state/local-budget capex (FHWA highways, FTA transit, state-DOT projects)
#   tribal            — tribal-budget capex (treated separately for transparency; flows through private aggregation)
#   mixed             — material cost-share between federal and non-federal (USACE projects with non-fed sponsor, RUS-financed coop transmission, FRA + state HSR)
#
# A `funding_source_basis` column records *why* — agency default vs title pattern vs explicit override.

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(purrr); library(stringr); library(tidyr)
})

library(here)

years <- 2015:2024
cost <- map_dfr(years, function(y) {
  read_csv(here("data", "processed",
                     sprintf("cost_extraction_%d.csv", y)),
           show_col_types = FALSE, col_types = cols(.default = "c")) |>
    mutate(panel_year = y) |>
    select(any_of(c("eis_number","lead_agency","state",
                    "cost_m_usd_nominal","cost_method","cost_notes","panel_year")))
}) |>
  mutate(cost_m_usd_nominal = as.numeric(cost_m_usd_nominal))

# Pull titles. arrange() before distinct() so the kept row is deterministic
# under re-orderings of the source CSV. Sort by panel_year DESC then eis_number ASC
# so the LATEST panel-year row wins when an eis_number appears twice (e.g., 20150082
# Long-term Water Transfers appears with cal_year 2015 AND 2019 — keep 2019).
clf <- read_csv(here("data", "processed", "eis_finals_with_naics.csv"),
                show_col_types = FALSE) |>
       arrange(eis_number, desc(cal_year)) |>
       distinct(eis_number, .keep_all = TRUE) |>
       select(eis_number, title, naics_code) |>
       mutate(eis_number = as.character(eis_number))

cost <- cost |> left_join(clf, by = "eis_number")

ci <- function(pattern, x) str_detect(x, regex(pattern, ignore_case = TRUE))

a <- cost$lead_agency
t <- cost$title
n <- cost$naics_code

cost <- cost |>
  mutate(
    # ============================
    # Title-based hints (highest precedence)
    # ============================
    hint_lng_pipe = ci("LNG|liquefaction|pipeline|natural gas (project|development|export|terminal)", t),
    hint_mining = ci("mine\\b|mining|copper|gold|silver|lithium|nickel|phosphate|quarry|coal mine", t),
    hint_oilgas = ci("oil and gas|natural gas (well|development|drilling)|drilling project", t),
    hint_renewable = ci("solar|wind farm|geothermal|hydroelectric|hydro|pumped storage|battery storage|generation", t),
    hint_transmission = ci("transmission|kV\\b|substation|interconnection|electric line", t),
    hint_lng_or_extractive = hint_lng_pipe | hint_mining | hint_oilgas | hint_renewable,
    hint_military = ci("beddown|MILCON|sentinel|minuteman|F-35|KC-46|T-7A|B-21|B-52|hangar|presidential aircraft|range modernization|townsend bombing|fallon range|range training|military|spent nuclear fuel|naval (spent|reactor)|defense|nuclear weapon", t),
    hint_highway = ci("\\bI-\\d+|interstate|highway|parkway|bypass|loop|connector|interchange|bridge\\b", t) &
                    !ci("transmission|pipeline|trail", t),
    hint_transit = ci("light rail|LRT|streetcar|BRT|metro\\b|metrorail|subway|transit|commuter rail|gondola", t),
    hint_hsr = ci("high.speed rail|HSR\\b|passenger rail|brightline|all aboard florida", t),
    hint_lpoe = ci("land port of entry|port of entry|courthouse|federal building|convention center", t),
    hint_corrections = ci("correctional|penitentiary|federal prison|detention", t),
    hint_federal_research = ci("research facility|medical isotope|medical radioisotope|isotope production", t),
    hint_tribal = ci("tribal|fee.to.trust|tribe|rancheria|pueblo|reservation|casino|gaming|Aamodt|spokane tribe", t),
    hint_usace_civil = ci("levee|flood (risk|control|protection)|navigation channel|harbor (deepening|navigation|expansion)|deepening|widening (project|channel)|dredg|reservoir construction|new reservoir|fish passage|lock|seawall|breakwater", t),
    hint_water_utility = ci("water supply|recycled water|water reclamation|treatment plant|regional water system|pure water|sewage|wastewater", t),

    # ============================
    # Agency-based defaults (fallback if title doesn't disambiguate)
    # ============================
    agency_default = case_when(
      # Private-finance lead agencies
      a == "FERC"                                  ~ "private",
      a == "RUS"                                   ~ "mixed",   # rural electric coops (federal-backed debt + member equity)
      a == "PHMSA"                                 ~ "private",
      a == "BOEM"                                  ~ "private",
      a == "NRC"                                   ~ "private",

      # Federal-budget lead agencies
      a %in% c("USACE")                            ~ "gov_federal", # default federal — many have non-fed sponsor
      a %in% c("BR")                               ~ "gov_federal",
      a %in% c("GSA")                              ~ "gov_federal",
      a %in% c("USAF","USN","USA","USMC","DOD","USCG")    ~ "gov_federal",
      a %in% c("USPS")                             ~ "gov_federal",
      a == "TVA"                                   ~ "gov_federal", # federal corporation
      a %in% c("BOP")                              ~ "gov_federal",
      a %in% c("NPS","USFWS","USGS","NIST","NIH","NSF","EPA","NOAA","NMFS","NRCS","OSM") ~ "gov_federal",
      a == "NSA"                                   ~ "gov_federal", # National Security Agency
      a == "WAPA"                                  ~ "mixed",       # Western Area Power — federal but capex usually private offtake
      a == "NIGC"                                  ~ "tribal",      # tribal gaming oversight; underlying capex tribal

      # State/local-budget lead agencies (federal NEPA but state/local pays)
      a == "FHWA"                                  ~ "gov_state_local",
      a == "FTA"                                   ~ "gov_state_local",
      a == "FRA"                                   ~ "gov_state_local", # state HSR / passenger rail
      a == "FAA"                                   ~ "gov_state_local", # airport sponsors
      a == "MARAD"                                 ~ "gov_state_local",
      a %in% c("UDOT","CALTRANS","FDOT","TXDOT","VADOT","NCDOT","ODOT") ~ "gov_state_local",
      a == "STB"                                   ~ "private",         # rail line owners private/coop
      # NSA, USMC moved up to gov_federal block above (audit-cleanup additions)
      a == "HCIDLA"                                ~ "gov_state_local",
      a == "CHSRA"                                 ~ "gov_state_local", # CA HSR Authority — Prop 1A state bonds
      a == "DOT"                                   ~ "gov_federal",     # cabinet-level lead
      a == "BPA"                                   ~ "gov_federal",     # federal power authority
      a == "TREAS"                                 ~ "gov_federal",
      a == "VA"                                    ~ "gov_federal",     # Veterans Affairs

      # Tribal-lead agencies
      a == "BIA"                                   ~ "tribal",

      # Land-management agencies — depends on project type; default private (most are extractive/renewable)
      a %in% c("BLM","USFS")                       ~ "private",

      # DOE — depends, default private (mostly LNG adoptions + private transmission)
      a == "DOE"                                   ~ "private",

      # HUD — typically PPP / mixed (LIHTC + federal + state)
      a == "HUD"                                   ~ "mixed",

      TRUE                                         ~ "unknown"
    ),

    # ============================
    # Apply title hints to override agency defaults (only where stronger evidence)
    # ============================
    funding_source = case_when(
      # Title clearly says private extractive / energy → override
      hint_lng_or_extractive & agency_default %in% c("gov_federal","gov_state_local","unknown") ~ "private",

      # Military → always gov_federal
      hint_military & agency_default == "gov_state_local" ~ "gov_federal",

      # Highway / transit → state-local even if lead agency is federal partner
      hint_highway & agency_default == "gov_federal" ~ "gov_state_local",
      hint_transit & agency_default == "gov_federal" ~ "gov_state_local",
      hint_hsr & agency_default == "gov_federal" ~ "mixed",

      # GSA LPOEs / federal buildings → gov_federal (rare override)
      hint_lpoe & a == "GSA" ~ "gov_federal",

      # Tribal projects (BIA already → tribal; non-BIA tribal projects)
      hint_tribal & agency_default == "gov_federal" ~ "tribal",

      # USACE civil works with non-fed sponsor (most have local sponsor share)
      a == "USACE" & hint_usace_civil ~ "mixed",

      # BR water infrastructure with local sponsor share
      a == "BR" & hint_water_utility ~ "mixed",

      TRUE ~ agency_default
    )
  )

# ============================
# Explicit per-record overrides for known exceptions
# ============================
overrides <- tribble(
  ~eis_number, ~funding_source, ~override_reason,

  # Federal civilian capex via permitting agencies (GSA already gov_federal by default;
  # 20190017 listed only to make the LPOE basis explicit in the basis column)
  "20190017", "gov_federal", "GSA Otay Mesa LPOE — federal MILCON-style funding",
  # NOTE: removed prior overrides for 20240063 and 20240137 — they were the wrong
  # eis_numbers. The actual GSA LPOEs in 2024 are 20240059/20240156/20240204 and the
  # federal building at 20240139, all of which already default to gov_federal via GSA agency.

  # 20240137 is actually "Maryland Offshore Wind" (BOEM) — force to private to ensure
  # title hint catches it (defensive — agency default for BOEM is already private)
  "20240137", "private", "Maryland Offshore Wind — US Wind private developer",

  # BIA tribal solar — BIA is tribal-default but utility solar on tribal land is private capex
  "20190300", "private", "Eagle Shadow Mountain Solar — Arevon (private utility-scale PV)",
  "20200022", "private", "Campo Wind — Terra-Gen + Boulder Brush private wind",
  "20160125", "private", "Aiya Solar Moapa — utility-scale PV by private developer",
  "20200148", "private", "Moapa Solar utility-scale",

  # BIA casinos stay tribal (default)

  # USACE civil works that are essentially federal-only (no major non-fed sponsor)
  "20170059", "gov_federal", "Mamaroneck flood — primarily federal",
  "20180237", "gov_federal", "Winslow flood — primarily federal",
  "20170088", "mixed", "Ala Wai — fed + state of Hawaii",
  "20170217", "mixed", "Bois d'Arc — NTMWD non-federal sponsor majority",
  "20190236", "mixed", "Lake Ralph Hall — UTRWD non-federal sponsor",
  "20190271", "mixed", "Lower Elkhorn Levee Setback — DWR + USACE",
  "20200026", "mixed", "Houston Ship Channel — Port + USACE cost share",

  # BR mega-projects that are predominantly state-led despite federal BR lead
  "20150222", "mixed", "Shasta Lake — CA state water contractors + BR (never built)",
  "20160318", "gov_state_local", "CA WaterFix (twin tunnels) — DWR state-led, cancelled",
  "20230150", "gov_state_local", "Sites Reservoir — Sites JPA state-led",

  # USACE harbor/channel deepening projects (port sponsors pay significant share)
  "20150188", "mixed", "Charleston Harbor Post 45 — SCSPA non-fed sponsor",
  "20150064", "mixed", "Port Everglades — Broward Port non-fed sponsor",
  "20170096", "mixed", "Port of Gulfport — MS State Port Authority",
  "20190207", "mixed", "Matagorda Ship Channel — Calhoun Port Authority",

  # FRA HSR — state-led mostly
  "20150225", "private", "Brightline All Aboard Florida — private rail (FECI)",
  "20190116", "mixed", "DC-Richmond HSR — VPRA state + federal",
  "20150259", "mixed", "SE HSR Richmond-Raleigh — NCDOT + FRA",

  # NRC private reactors / isotope facilities
  "20150299", "private", "SHINE Medical — private",
  "20170085", "private", "NWMI medical isotopes — private",

  # DOE LNG adoptions are already $0; DOE energy transmission projects are private
  "20150307", "private", "TDI New England Clean Power Link — private HVDC",
  "20150310", "private", "Minnesota Power Great Northern Transmission — investor-owned utility",
  "20150316", "private", "Plains and Eastern Clean Line — private (cancelled)",
  "20170158", "private", "Northern Pass — Eversource (cancelled)",

  # BLM gas/solar that are private capex (BLM-default is already private; reinforce)
  # No overrides needed — already private by default

  # Mixed FERC pumped-storage (often investor-owned utility but with state/coop equity)
  "20180333", "private", "Swan Lake North Pumped Storage — Rye Development private",

  # Santa Susana DOE remediation — federal
  "20180321", "gov_federal", "Santa Susana Field Lab — DOE/Boeing remediation",

  # DOE Versatile Test Reactor — federal R&D, not private LNG (INL national lab project)
  "20220070", "gov_federal", "VTR Idaho National Lab — DOE federal nuclear R&D",
  "20240048", "gov_federal", "DOE VTR (adoption record) — same federal R&D",

  # NPS Alcatraz Ferry — concession is private but flows through federal-owned facility;
  # categorize as mixed since federal site improvements + private concession capex
  "20170013", "mixed", "Alcatraz Ferry — Hornblower concession + NPS site",

  # (TDI NECPL override above at line 215 covers this case; duplicate removed per audit L-6.)

  # USAF Tyndall rebuild — federal (already default)
  # USA Pier MOTCO — federal

  # Convention Center Seattle — gov_state_local (King County lodging tax + state)
  "20180056", "gov_state_local", "Seattle Convention Center — King County + WA state",

  # Pure Water San Diego — gov_state_local (city utility + EPA WIFIA loan)
  "20180075", "gov_state_local", "Pure Water SD — City of San Diego utility",

  # TVA Cumberland CCR landfill etc — TVA is federal corp but operates on rate-payer revenue, count as gov_federal
  # already default

  # Sentinel BLM/USAF — gov_federal (already default for USAF; BLM normally private but Sentinel is military)
  "20240017", "gov_federal", "Sentinel deployment on BLM land — federal MILCON",
  "20230043", "gov_federal", "Sentinel USAF activity EIS — federal MILCON",

  # USCG Delfin LNG — private (USCG just permits the deepwater port)
  "20160277", "private", "Delfin LNG Deepwater Port — Delfin Midstream private",
  "20240115", "private", "Texas Gulflink Deepwater Port — Sentinel Midstream private",
)

overrides <- overrides |> distinct(eis_number, .keep_all = TRUE)  # defensive
cost <- cost |>
  left_join(overrides, by = "eis_number", suffix = c("", "_ovr")) |>
  mutate(
    funding_source = coalesce(funding_source_ovr, funding_source),
    funding_source_basis = case_when(
      !is.na(funding_source_ovr) ~ paste0("override: ", override_reason),
      hint_lng_or_extractive & agency_default %in% c("gov_federal","gov_state_local","unknown") ~ "title hint: private extractive/energy",
      hint_military & agency_default == "gov_state_local" ~ "title hint: military",
      hint_highway & agency_default == "gov_federal" ~ "title hint: highway (state DOT pays)",
      hint_transit & agency_default == "gov_federal" ~ "title hint: transit (state/local pays)",
      hint_hsr & agency_default == "gov_federal" ~ "title hint: HSR (mixed)",
      hint_lpoe & a == "GSA" ~ "title hint: GSA LPOE",
      hint_tribal & agency_default == "gov_federal" ~ "title hint: tribal",
      a == "USACE" & hint_usace_civil ~ "USACE civil works (mixed with sponsor share)",
      a == "BR" & hint_water_utility ~ "BR water infra (mixed with sponsor share)",
      TRUE ~ paste0("agency default (", a, ")")
    )
  ) |>
  select(-funding_source_ovr, -override_reason, -starts_with("hint_"), -agency_default)

# Sanity summary
cat("=== funding_source distribution (count) ===\n")
print(cost |> count(funding_source, sort = TRUE))

cat("\n=== funding_source distribution ($B nominal) ===\n")
print(
  cost |> group_by(funding_source) |>
    summarise(records = n(),
              total_b = round(sum(cost_m_usd_nominal, na.rm = TRUE) / 1000, 1)) |>
    arrange(desc(total_b))
)

cat("\n=== Top 10 records by cost in each funding bucket ===\n")
walk(c("private","gov_federal","gov_state_local","mixed","tribal"), function(fs) {
  cat(sprintf("\n--- %s ---\n", fs))
  cost |> filter(funding_source == fs) |>
    arrange(desc(cost_m_usd_nominal)) |>
    head(10) |>
    select(panel_year, eis_number, lead_agency, cost_m_usd_nominal, title) |>
    print(width = 200)
})

out <- cost |>
  select(panel_year, eis_number, lead_agency, naics_code, cost_m_usd_nominal,
         funding_source, funding_source_basis, title)
write_csv(out, here("data", "processed", "funding_source.csv"))
cat(sprintf("\nWrote %d funding_source rows\n", nrow(out)))
