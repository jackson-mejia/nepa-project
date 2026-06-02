# Classify each EIS as:
#   (i)   new private capital formation exposed to NEPA delay — include in Phi_i
#   (ii)  government management / continuation, no new K — exclude
#   (iii) ambiguous, needs review
#
# Classification logic:
#   * EXCLUSION rules fire first (override agency defaults).
#     License renewals, resource management plans, fuels/restoration management,
#     and habitat-conservation plans → (ii).
#   * INCLUSION rules: agencies/title-patterns that almost always represent new
#     private capital formation → (i).
#   * Everything else → (iii). To be reviewed manually or treated cautiously.
#
# Output adds two columns to the Finals dataset:
#   category, category_reason

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
})

library(here)
IN_PATH  <- here("data", "processed", "eis_finals_2015-2024.csv")
OUT_PATH <- here("data", "processed", "eis_finals_classified.csv")

d <- read_csv(IN_PATH, show_col_types = FALSE)
cat(sprintf("Input: %d Finals\n", nrow(d)))

# Manual classifier overrides — per-record exceptions where rules can't cleanly
# catch the case (e.g., FRA Tier-1 corridor studies whose NOA titles don't
# contain the literal "Tier 1" string). Loaded once.
manual_excl_ii <- read_csv(
  here("data", "manual_overrides", "classifier_overrides.csv"),
  show_col_types = FALSE) |>
  filter(target_category == "ii") |>
  pull(eis_number)

# ---- Build the classifier as a sequential ifelse waterfall ----
# Each rule returns a (category, reason) tuple via mutate(case_when).
# Lower bullets in case_when override higher ones if both match — careful with order.

# Helper: case-insensitive grepl wrapper
ci <- function(pattern, x) stringr::str_detect(x, regex(pattern, ignore_case = TRUE))

t <- d$title  # shorthand
a <- d$lead_agency

classified <- d |>
  mutate(

    # ============================
    # EXCLUSION rules — category (ii)
    # ============================
    cat_excl_lic_renewal = ci("license renewal|subsequent license|operating license renewal|license extension", t),
    cat_excl_re_license = a == "FERC" & ci("relicens|re-licens", t),
    # Plural-aware: matches "resource management plan", "resources management plan",
    # "resource management plans", and "general management plan" (NPS).
    cat_excl_rmp = ci("\\bresources? management plans?\\b|^RMP\\b| RMP\\b|RMP amendment|forest plan|land use plan|land management plan|general management plan", t),
    cat_excl_fuels = ci("fuels? (reduction|treatment|management|project)|hazardous fuels|prescribed (burn|fire)|wildfire (risk|fuel)|\\bvegetation management\\b", t) &
                     !ci("construction|new facility|new structure", t),
    cat_excl_restoration = ci("restoration project|habitat restoration|stream restoration|forest restoration|ecological restoration|\\becosystem restoration\\b", t) &
                           !ci("construction|new facility|new structure|mining plan|plan of operations|mining (project|company)", t),
    cat_excl_habitat = ci("habitat conservation plan|habitat management plan|wildlife management plan", t),
    cat_excl_grazing = ci("grazing (allotment|permit|management|plan)", t) & !ci("new ", t),
    cat_excl_nrc_renewal = a == "NRC" & ci("renewal|continued storage|continued operation", t),
    cat_excl_programmatic = ci("programmatic environmental impact|generic environmental impact statement|^PROGRAMMATIC--|^Programmatic | PEIS\\b|Programmatic EIS|^Utility.Scale.*Development", t),
    cat_excl_combined_ops = ci("combined operational plan|operational plan\\b|continued operations|operating manual|system operating|system operations|long.term operation|operations and maintenance manual", t),
    cat_excl_oilgas_lease_sale = a %in% c("BLM", "BOEM") & ci("lease sale\\b", t) & !ci("project|development", t),
    # Wildlife / pest / predator management — pure management, no new K
    cat_excl_wildlife_mgmt = ci("(wildlife|predator|invasive|pest|species) (damage )?management|barred owl|bison management|backcountry access|over.snow vehicle|motorized travel|public motorized|recreation access plan|vehicle use designation|wilderness stewardship", t),
    # Land withdrawals / lease moratoria
    cat_excl_withdrawal = ci("withdrawal\\b|land withdrawal|ANCSA 17.d", t),
    # Marine sanctuary designations and amendments
    cat_excl_marine_sanctuary = ci("national marine sanctuary|marine sanctuary (final|management|amendment)", t),
    # Fishery / tuna / wildlife consolidated management
    cat_excl_fishery = a %in% c("NMFS","NOAA") & ci("incidental take|consolidated atlantic|amendment \\d|fishery management|tuna|hms|conservation program|prey availability", t),
    # NRCS small watershed plans
    cat_excl_nrcs_watershed = a == "NRCS" & ci("watershed", t),
    # Waste / disposition programs (existing material, ongoing operations)
    cat_excl_waste = ci("(surplus|plutonium|spent fuel) (disposition|management|storage)|waste isolation|nuclear waste|radioactive waste management|tank waste|remedial action|disposal of (greater.than.class.c|GTCC)|low.level radioactive waste", t),
    # Dam safety inspections / existing facility safety (vs. new dam construction)
    cat_excl_dam_safety = ci("dam safety\\b", t) &
                           !ci("new dam|construction of (a )?new|\\bmodification (project|of dams)\\b|structural (modification|upgrade)", t),

    # --- PATCHES added 2026-06-01 from manual reclassifications surfaced during cost extraction ---

    # Tier 1 / Tier I planning EISs — corridor selection, no project authorization
    # Tier 1 / service-level planning EISs — corridor selection, no project authorization.
    # Guarded against construction context so "Tier-1 LNG facility construction" doesn't trip.
    cat_excl_tier1 = ci("\\btier (1|i)\\b|tier[- ]1\\b|tier[- ]i (final )?(environmental|f?eis)|service.level (final )?(f?eis|environmental)", t) &
                     !ci("construction|new facility|\\bproject\\b", t),

    # Per-record manual override list (loaded above as `manual_excl_ii`)
    cat_excl_fra_tier1 = d$eis_number %in% manual_excl_ii,

    # Integrated Resource Plans (utility planning)
    cat_excl_irp = ci("integrated resource plan|\\bIRP\\b", t),

    # Contract conversion / renewal / amendment (water, etc. — administrative)
    cat_excl_contract = ci("contract(s)? (conversion|renewal|amendment|update)|water supply contracts?( |\\b)|cvp.* contracts? under (public law|pl) ", t),

    # Water transfers / exchange programs (operational, not construction)
    cat_excl_water_program = ci("\\bwater transfers?\\b|water exchange|exchange program\\b", t) &
                              !ci("construction|new facility|pipeline construction|treatment plant|reservoir construction", t),

    # Operating agreement / continued implementation / policy review
    # Policy/operating-agreement exclusions. EIS dropped from the alternation per audit
    # L-4 because it was matching real construction-project titles containing "Policy"
    # somewhere in the name plus "EIS" in the suffix.
    cat_excl_policy = ci("operating agreement\\b|continued implementation|policy review\\b|^.* policy\\b.*(review|update|amendment)|water shortage policy|floating houses policy", t),

    # Land acquisition (federal land purchase, no construction)
    cat_excl_land_acq = ci("land acquisition\\b", t) & !ci("for (construction|new|expansion)", t),

    # Geological and geophysical / seismic survey permits (programmatic)
    cat_excl_gng = ci("geological and geophysical|seismic survey", t),

    # Leasing-only EISs (geothermal, oil/gas, OCS lease sales) without specific project
    cat_excl_leasing = ci("geothermal leasing|leasing program\\b|\\bleasing (final|environmental)|previously issued (oil and gas )?leases|oil and gas leasing in", t) &
                       !ci("development project|specific (project|development)|mine plan|drilling plan", t),

    # Long-term protection plans (operational, e.g., salmon, fish, habitat continuation)
    cat_excl_longterm_plan = ci("long.?term plan to protect|salmon protection plan|fish (passage|protection) (plan|implementation)", t) &
                              !ci("dam (raise|construction)|new dam|reservoir construction|new fish ladder", t),

    # Commercial dredging permits (renewal of existing commercial sand-and-gravel)
    cat_excl_commercial_dredge = ci("commercial dredging|commercial (sand|gravel) dredging", t),

    # USFS leasing decisions (Wyoming Range, etc.)
    cat_excl_usfs_leasing = a == "USFS" & ci("\\bleases? in the\\b|oil and gas leasing|leasing in (portions of )?the", t),

    excluded = cat_excl_lic_renewal | cat_excl_re_license | cat_excl_rmp |
               cat_excl_fuels | cat_excl_restoration | cat_excl_habitat |
               cat_excl_grazing | cat_excl_nrc_renewal | cat_excl_programmatic |
               cat_excl_combined_ops | cat_excl_oilgas_lease_sale |
               cat_excl_wildlife_mgmt | cat_excl_withdrawal | cat_excl_marine_sanctuary |
               cat_excl_fishery | cat_excl_nrcs_watershed | cat_excl_waste | cat_excl_dam_safety |
               cat_excl_tier1 | cat_excl_fra_tier1 | cat_excl_irp | cat_excl_contract |
               cat_excl_water_program | cat_excl_policy | cat_excl_land_acq | cat_excl_gng |
               cat_excl_leasing | cat_excl_longterm_plan | cat_excl_commercial_dredge |
               cat_excl_usfs_leasing,

    excl_reason = case_when(
      cat_excl_lic_renewal ~ "license renewal/extension",
      cat_excl_re_license  ~ "FERC relicensing of existing facility",
      cat_excl_rmp         ~ "programmatic management/forest/land-use plan",
      cat_excl_fuels       ~ "fuels reduction/management activity",
      cat_excl_restoration ~ "restoration without construction",
      cat_excl_habitat     ~ "habitat/wildlife management plan",
      cat_excl_grazing     ~ "grazing management (existing leases)",
      cat_excl_nrc_renewal ~ "NRC license renewal / continued operation",
      cat_excl_programmatic ~ "programmatic/generic EIS (PEIS, not a specific project)",
      cat_excl_combined_ops ~ "operational plan / continued operations / operating manual",
      cat_excl_oilgas_lease_sale ~ "BLM lease sale without specific project",
      cat_excl_wildlife_mgmt ~ "wildlife/species management / recreation access plan",
      cat_excl_withdrawal  ~ "land withdrawal / lease moratorium",
      cat_excl_marine_sanctuary ~ "marine sanctuary management",
      cat_excl_fishery     ~ "NMFS/NOAA fishery management amendment",
      cat_excl_nrcs_watershed ~ "NRCS small watershed plan",
      cat_excl_waste       ~ "waste disposition / existing-material management",
      cat_excl_dam_safety  ~ "dam safety inspection (not new dam construction)",
      cat_excl_tier1       ~ "Tier 1 / service-level planning EIS (no project authorization)",
      cat_excl_fra_tier1   ~ "manual override (data/manual_overrides/classifier_overrides.csv)",
      cat_excl_irp         ~ "integrated resource plan (utility planning, no specific project)",
      cat_excl_contract    ~ "contract conversion/renewal (administrative)",
      cat_excl_water_program ~ "water transfer / exchange program (operational)",
      cat_excl_policy      ~ "operating agreement / policy review (no construction)",
      cat_excl_land_acq    ~ "land acquisition (no construction)",
      cat_excl_gng         ~ "geological/geophysical survey permits (programmatic)",
      cat_excl_leasing     ~ "leasing-only EIS (no specific project)",
      cat_excl_longterm_plan ~ "long-term operational protection plan",
      cat_excl_commercial_dredge ~ "commercial dredging permit (existing operation)",
      cat_excl_usfs_leasing ~ "USFS oil/gas leasing decision (no specific project)",
      TRUE                 ~ NA_character_
    ),

    # ============================
    # INCLUSION rules — category (i)
    # ============================

    # By agency: infrastructure-heavy agencies almost always do new capital projects.
    # BPA + WAPA (federal power administrations — transmission); NSA (federal-facility
    # construction); USMC (military construction parallel to USAF/USA); NIGC (tribal
    # gaming, parallel to BIA); OSM (surface mining) — all added per audit H-1 finding.
    incl_infra_agency = a %in% c("FERC", "FHWA", "FTA", "FRA", "BOEM", "FAA", "USCG",
                                  "TVA", "BR", "MARAD", "USPS", "PHMSA",
                                  "BPA", "WAPA", "NSA", "USMC", "NIGC", "OSM"),

    # USACE: civil works construction (channels, locks, dams, harbors, levees, shore
    # protection, flood-reduction studies, early implementation projects) — not all.
    incl_usace_civil = a == "USACE" &
                       ci("channel|harbor|lock and dam|^lock\\b|dam\\b|reservoir|levee|flood|navigation|seawall|breakwater|dredg|deepening|widening|civil works|shore protection|early implementation|flood reduction|flood damage reduction|reformulation study|coastal storm risk", t),

    # USACE Section 404 permitting for mining projects (e.g., Donlin Gold) — USACE permits
    # but the project itself is private mining capex. Added per audit H-1.
    incl_usace_mining = a == "USACE" &
                       ci("\\bgold\\b|\\bsilver\\b|\\bcopper\\b|\\bcoal\\b|\\bmine\\b|mining|critical mineral|quarry", t),

    # DOE: most EISs are for new facilities / cleanup / demonstration
    incl_doe = a == "DOE" & !excluded,

    # NRC: new reactors and ISFSI construction (not license renewals — those caught by exclusion)
    incl_nrc_new = a == "NRC" & ci("new (reactor|nuclear)|reactor construction|small modular|advanced reactor|ISFSI|spent fuel", t),

    # BLM/USFS: renewable energy, mining, oil & gas, pipelines, transmission.
    # Expanded mineral list per audit H-1 (uranium, niobium, tantalum, tellurium, tin,
    # tungsten, zinc, zirconium, antimony added so Lost Creek Uranium et al. classify).
    incl_blm_usfs_extractive = a %in% c("BLM", "USFS", "BIA") &
                               ci("solar|wind|geothermal|hydroelectric|hydro |pumped storage|battery|energy storage|mine\\b|mining|oil and gas|natural gas|pipeline|transmission|generation|lease sale|exploration|gold (project|mine)|silver mine|copper (project|mine)|lithium|nickel|cobalt|rare earth|critical mineral|stibnite|gas (well|field)|uranium|niobium|tantalum|tellurium|\\btin\\b|tungsten|\\bzinc\\b|zirconium|antimony", t),

    # Whitelist of major BLM/USFS extractive projects whose short titles don't carry
    # the keywords above (Greater Mooses Tooth, Willow, Ambler Road, Riley Ridge, etc.).
    # Per audit H-1.
    incl_blm_named_project = a %in% c("BLM", "USFS", "BIA") &
                             ci("greater mooses tooth|\\bGMT[- ]?[12]\\b|willow master development|\\bambler road\\b|\\bambler mining\\b|riley ridge|\\bNPR.A\\b|coastal plain (oil|leasing|drilling)|lost creek uranium|stibnite gold|\\bpolymet\\b|donlin gold|chuitna|pebble mine", t),

    # USFWS, NPS, NMFS: typically not capital formation, but exceptions for new construction
    incl_other_construction = a %in% c("USFWS", "NPS", "NMFS", "NRCS", "USGS", "EPA") &
                              ci("construction|new facility|new (visitor|operations)|expansion|ferry|embarkation|dock|wharf|terminal|visitor center", t),

    # BIA: tribal economic development, casinos, fee-to-trust developments — new capital
    incl_bia_dev = a == "BIA" & ci("casino|gaming|fee.to.trust|trust acquisition|resort|hotel|new (community|development)|housing|economic development", t),

    # HUD: housing redevelopment/construction
    incl_hud = a == "HUD" & ci("redevelopment|housing|construction|new (development|building)|revitalization", t),

    # USFS recreation: ski areas, lift expansions, new recreation projects — private capex
    incl_usfs_rec = a == "USFS" & ci("ski (area|resort)|chair lift|gondola|recreation project|resort|multi.season recreation", t),

    # Adoption-prefix records: the agency is adopting another agency's EIS for the same project.
    # Title typically includes "ADOPTION--" then the underlying project description.
    # Treat as (i) if the underlying-project text matches construction/extraction keywords.
    # Transmission/HVDC/clean line/kV added per audit H-1 (Plains and Eastern Clean Line adoption).
    incl_adoption_construction = ci("^ADOPTION--.*\\b(construction|transit|hydroelectric|pipeline|highway|mine|terminal|station|extension|subway|rail|new|transmission|HVDC|clean line|kV)\\b", t),

    # HUD "Rebuild by Design" Sandy-recovery resilience projects (e.g., Meadowlands
    # NJDEP-led flood control). Added per audit H-1.
    incl_rebuild_by_design = ci("rebuild by design", t),

    # Military: range/base expansions, beddowns, MILCON, weapons-system deployments,
    # on-base renewable energy (solar/wind/geothermal at military installations).
    # Added solar/wind per audit H-1 (Edwards AFB Solar was in (iii)).
    incl_military = a %in% c("USAF", "USN", "USA", "USCG", "DOD") &
                    ci("construction|beddown|MILCON|new (facility|hangar|range)|expansion|modernization|upgrade|recapitalization|deployment|sentinel|minuteman|t-7a|t-38|kc-46|f-15|f-35|b-21|b-52|\\bsolar\\b|\\bwind\\b|geothermal|renewable", t),

    # Joint/co-led military weapons deployment (BLM or USFS as land-mgmt partner for AF program)
    incl_weapons_deployment = ci("sentinel.*deployment|minuteman III deployment|GBSD|GSBD|ground based strategic deterrent", t),

    # Federal correctional / penitentiary construction
    incl_correctional = a == "BOP" |
                        ci("correctional institution|federal prison|penitentiary|federal detention|federal correctional", t),

    # High-speed rail and major rail authority projects
    incl_high_speed_rail = ci("high.speed rail|HSR\\b", t) | a == "CHSRA",

    # Federal/state buildings at specific street addresses (GSA construction etc.)
    incl_address_buildings = ci("buildings? at \\d|\\d+ (north|south|east|west) (state|main|federal|broadway) street", t),

    # USGS / federal facility construction (USGS, NIST, NIH, etc.)
    incl_fed_research = a %in% c("USGS", "NIST", "NIH", "NSF") &
                        ci("new facility|new (laboratory|research)|construction|expansion|replacement (facility|building)", t),

    # Rural Utilities Service transmission (electric coops)
    incl_rus_transmission = a == "RUS" & ci("transmission|substation|line|interconnection", t),

    # State DOT highway projects (UDOT, CALTRANS, etc. acting as joint NEPA lead with FHWA)
    incl_state_dot_highway = a %in% c("UDOT", "CALTRANS", "FDOT", "TXDOT", "VADOT", "NCDOT", "ODOT") |
                             ci("I-\\d+|interstate \\d|US-\\d+|highway (\\d|expansion|widening)", t),

    # USACE highway-adjacent projects (when USACE is processing 404 permits for highway)
    incl_usace_highway = a == "USACE" & ci("highway|interstate|bridge|road construction", t),

    # Federal buildings: GSA
    incl_gsa = a == "GSA" & ci("construction|new (federal|courthouse|building)|land port of entry|modernization|expansion", t),

    # GSA federal-facility planning EISs ("Master Plan", "Tenant Relocation", "FDA HQ"
    # consolidation) — these authorize specific federal-building construction projects.
    # Added per audit H-1.
    incl_gsa_planning = a == "GSA" & ci("master plan|tenant relocation|consolidation|headquarters", t),

    # Naval shipyards / federal centers / federal complexes / large naval bases.
    # Added per audit H-1 (Pearl Harbor Naval Shipyard $3.4B was in (iii)).
    incl_naval_federal_facility = ci("naval shipyard|naval station|naval base|federal center|federal complex|federal building.*(master plan|consolidation|tenant)|shipyard.*(dry dock|maintenance facility|production facility)", t),


    # Generic title cues across all agencies
    incl_title_construction = ci("\\bconstruction\\b|\\bexpansion\\b|\\bnew (facility|plant|station|terminal|building)\\b|deepening|widening|new (highway|interchange|bridge)|redevelopment|modernization (project|expansion)", t),

    # Title contains physical capacity markers (MW, miles of pipeline, etc.)
    incl_title_capacity = ci("\\d+[ -]?(MW|GW|kW|MMBtu|MMcf|miles?|million gallons|MGD|barrels|tons per (day|year))\\b", t),

    included = (incl_infra_agency | incl_usace_civil | incl_usace_mining | incl_doe | incl_nrc_new |
                incl_blm_usfs_extractive | incl_blm_named_project | incl_other_construction | incl_bia_dev |
                incl_hud | incl_usfs_rec | incl_adoption_construction | incl_rebuild_by_design |
                incl_military | incl_weapons_deployment | incl_correctional |
                incl_high_speed_rail | incl_address_buildings | incl_fed_research |
                incl_rus_transmission | incl_state_dot_highway | incl_usace_highway |
                incl_gsa | incl_gsa_planning | incl_naval_federal_facility |
                incl_title_construction |
                incl_title_capacity) & !excluded,

    incl_reason = case_when(
      !included ~ NA_character_,
      incl_infra_agency           ~ sprintf("infrastructure agency (%s)", a),
      incl_usace_civil            ~ "USACE civil works (water infra)",
      incl_doe                    ~ "DOE (energy/cleanup/demonstration)",
      incl_nrc_new                ~ "NRC new reactor/storage construction",
      incl_blm_usfs_extractive    ~ "BLM/USFS extractive or renewable energy project",
      incl_blm_named_project      ~ "named major BLM/USFS extractive project (whitelist)",
      incl_bia_dev                ~ "BIA tribal economic development (casino/housing)",
      incl_hud                    ~ "HUD housing/redevelopment",
      incl_usfs_rec               ~ "USFS recreation/ski-area project (private capex)",
      incl_adoption_construction  ~ "adoption of another agency's construction EIS",
      incl_rebuild_by_design      ~ "HUD Rebuild by Design (Sandy-recovery resilience)",
      incl_weapons_deployment     ~ "military weapons system deployment (e.g., Sentinel/Minuteman)",
      incl_correctional           ~ "federal correctional/detention facility",
      incl_high_speed_rail        ~ "high-speed rail project",
      incl_address_buildings      ~ "federal/state buildings at specific address",
      incl_fed_research           ~ "federal research facility construction",
      incl_rus_transmission       ~ "RUS rural electric transmission",
      incl_state_dot_highway      ~ "state DOT highway project (joint NEPA with FHWA)",
      incl_usace_highway          ~ "USACE 404 permit for highway",
      incl_other_construction     ~ "explicit construction/expansion",
      incl_military               ~ "military new construction/beddown",
      incl_gsa                    ~ "GSA federal building construction",
      incl_gsa_planning           ~ "GSA federal-facility consolidation / master plan / tenant relocation",
      incl_naval_federal_facility ~ "naval shipyard / federal center / federal complex (large federal capital)",
      incl_usace_mining           ~ "USACE 404 permit for mining project (e.g., Donlin Gold)",
      incl_title_construction     ~ "title indicates new construction/expansion",
      incl_title_capacity         ~ "title indicates physical capacity (MW/miles/etc.)",
      TRUE                        ~ NA_character_
    ),

    # ============================
    # Final assignment
    # ============================
    category = case_when(
      excluded  ~ "ii",
      included  ~ "i",
      TRUE      ~ "iii"
    ),

    category_reason = case_when(
      category == "ii"  ~ excl_reason,
      category == "i"   ~ incl_reason,
      TRUE              ~ "no rule matched — needs manual review"
    )
  ) |>
  # Drop intermediate flag columns
  select(-starts_with("cat_excl_"), -starts_with("incl_"),
         -excluded, -included, -excl_reason, -any_of("naics_pipeline"))

# ---- Summary ----
cat("\n=== Category distribution (overall) ===\n")
print(classified |> count(category, sort = TRUE))

cat("\n=== Top category × agency combinations ===\n")
print(
  classified |>
    count(category, lead_agency, sort = TRUE) |>
    group_by(category) |>
    slice_head(n = 8) |>
    ungroup(),
  n = Inf
)

cat("\n=== Top exclusion reasons ===\n")
print(classified |> filter(category == "ii") |>
        count(category_reason, sort = TRUE) |> head(10))

cat("\n=== Top inclusion reasons ===\n")
print(classified |> filter(category == "i") |>
        count(category_reason, sort = TRUE) |> head(10))

cat("\n=== Sample of ambiguous (category iii) — needs review ===\n")
set.seed(42)
print(
  classified |> filter(category == "iii") |>
    slice_sample(n = 10) |>
    select(eis_number, lead_agency, title),
  n = Inf
)

write_csv(classified, OUT_PATH)
cat(sprintf("\nWrote %d classified records to %s\n", nrow(classified), OUT_PATH))
