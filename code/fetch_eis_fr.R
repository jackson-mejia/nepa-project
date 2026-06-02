# Fetch EIS records from Federal Register weekly Notice of Availability docs.
#
# Each weekly NOA is published by EPA and lists every EIS filed that week with a
# consistent comma-delimited format:
#
#     EIS No. NNNNNNNN, [Doc Type], [Agency], [State], [Title], [Period] Ends: MM/DD/YYYY, Contact: [Name] [Phone]
#
# Output: data/raw/eis_records_<years>.csv with one row per EIS entry.
#
# Usage:
#   Rscript code/fetch_eis_fr.R            # default: 2024 test
#   Rscript code/fetch_eis_fr.R 2015 2024  # full window

suppressPackageStartupMessages({
  library(httr2)
  library(jsonlite)
  library(dplyr)
  library(readr)
  library(stringr)
  library(purrr)
  library(tibble)
})

library(here)
RAW_DIR <- here("data", "raw")
dir.create(RAW_DIR, recursive = TRUE, showWarnings = FALSE)

FR_API <- "https://www.federalregister.gov/api/v1/documents.json"
UA <- "NEPA-research-project/1.0 (academic)"

# -----------------------------------------------------------------------------
# 1. List all weekly NOAs in a calendar-year range via FR API.
# -----------------------------------------------------------------------------
fr_get_noa_list <- function(year_start, year_end) {
  page <- 1L
  docs <- list()
  repeat {
    resp <- request(FR_API) |>
      req_url_query(
        `conditions[agencies][]` = "environmental-protection-agency",
        `conditions[term]`       = "environmental impact statement notice of availability",
        `conditions[publication_date][gte]` = sprintf("%d-01-01", year_start),
        `conditions[publication_date][lte]` = sprintf("%d-12-31", year_end),
        per_page = 1000,
        page = page
      ) |>
      req_user_agent(UA) |>
      req_perform()

    data <- resp |> resp_body_json()
    results <- data$results
    if (length(results) == 0L) break

    # Filter strictly to the canonical weekly NOA title
    keep <- map_lgl(results, \(d) {
      startsWith(trimws(d$title %||% ""),
                 "Environmental Impact Statements; Notice of Availability")
    })
    kept <- results[keep]
    if (length(kept) > 0L) {
      docs <- c(docs, map(kept, \(d) {
        list(document_number  = d$document_number,
             publication_date = d$publication_date,
             html_url         = d$html_url)
      }))
    }

    total <- data$count %||% 0L
    if (length(docs) >= total || page * 1000L >= total) break
    page <- page + 1L
    Sys.sleep(0.3)
  }
  bind_rows(map(docs, as_tibble))
}

# -----------------------------------------------------------------------------
# 2. Fetch raw text body of one NOA.
# -----------------------------------------------------------------------------
fetch_noa_body <- function(document_number, publication_date) {
  d <- strsplit(publication_date, "-")[[1]]
  url <- sprintf(
    "https://www.federalregister.gov/documents/full_text/text/%s/%s/%s/%s.txt",
    d[1], d[2], d[3], document_number
  )
  request(url) |>
    req_user_agent(UA) |>
    req_perform() |>
    resp_body_string()
}

# -----------------------------------------------------------------------------
# 3. Parse one NOA body into structured EIS records.
# -----------------------------------------------------------------------------

# Regex for one EIS entry: starts with "EIS No. NNNNNNNN,", greedy until the
# next entry or end of listing block.
EIS_ENTRY <- paste0(
  "EIS No\\.\\s*(\\d+)\\s*,\\s*",        # group 1: EIS number
  "([^,]+?)\\s*,\\s*",                    # group 2: document type
  "([A-Z][A-Z0-9]{1,7})\\s*,\\s*",        # group 3: agency code
  "([A-Z]{2})\\s*,\\s*",                  # group 4: state
  "(.+?)",                                  # group 5: title + period + contact
  "(?=EIS No\\.\\s*\\d+|\\Z|\\nDated:)"   # lookahead: next entry or trailer
)

PERIOD_RE  <- "(Comment Period|Review Period)\\s+Ends:\\s*(\\d{2}/\\d{2}/\\d{4})"
CONTACT_RE <- "Contact:\\s*([^,]+?)(?:\\s+(\\d{3}[-\\s]?\\d{3}[-\\s]?\\d{4}))?(?:[\\.,]|$)"

parse_noa <- function(body, source_doc, source_date) {
  region_start <- str_locate(body, fixed("Pursuant to CEQ Guidance"))[, 1]
  if (is.na(region_start)) region_start <- str_locate(body, fixed("EIS No."))[, 1]
  if (is.na(region_start)) return(tibble())

  region_end <- str_locate(str_sub(body, region_start), fixed("\nDated:"))[, 1]
  region <- if (is.na(region_end)) {
    str_sub(body, region_start)
  } else {
    str_sub(body, region_start, region_start + region_end - 1)
  }
  # Collapse line wraps so each entry sits on one logical line
  region <- str_replace_all(region, "\\s+", " ")

  matches <- str_match_all(region, EIS_ENTRY)[[1]]
  if (nrow(matches) == 0L) return(tibble())

  tail_str <- matches[, 6]
  tail_clean <- str_trim(str_replace(tail_str, "\\.$", ""))

  period_m <- str_match(tail_clean, PERIOD_RE)
  contact_m <- str_match(tail_clean, CONTACT_RE)

  # Title = everything before the period clause (if any), else the whole tail
  title <- if_else(
    is.na(period_m[, 1]),
    tail_clean,
    str_trim(str_replace(
      str_sub(tail_clean, 1L, str_locate(tail_clean, fixed(period_m[, 1]))[, 1] - 1L),
      ",\\s*$", ""))
  )

  tibble(
    eis_number       = matches[, 2],
    document_type    = str_trim(matches[, 3]),
    lead_agency      = str_trim(matches[, 4]),
    state            = matches[, 5],
    title            = title,
    period_type      = period_m[, 2],
    period_end_date  = period_m[, 3],
    contact_name     = str_trim(contact_m[, 2]),
    contact_phone    = contact_m[, 3],
    source_fr_doc    = source_doc,
    source_fr_date   = source_date
  )
}

# -----------------------------------------------------------------------------
# 4. Main pipeline.
# -----------------------------------------------------------------------------
main <- function(year_start, year_end, output_name = NULL) {
  message(sprintf("=== Fetching NOA list for %d-%d ===", year_start, year_end))
  docs <- fr_get_noa_list(year_start, year_end)
  message(sprintf("Found %d weekly NOAs.", nrow(docs)))

  records_list <- vector("list", nrow(docs))
  for (i in seq_len(nrow(docs))) {
    d <- docs[i, ]
    out <- tryCatch({
      body <- fetch_noa_body(d$document_number, d$publication_date)
      parse_noa(body, d$document_number, d$publication_date)
    }, error = function(e) {
      message(sprintf("  [%d/%d] FAILED %s: %s",
                      i, nrow(docs), d$document_number, conditionMessage(e)))
      tibble()
    })
    records_list[[i]] <- out
    if (i %% 25L == 0L || i == nrow(docs)) {
      cum <- sum(map_int(records_list, \(x) if (is.null(x)) 0L else nrow(x) %||% 0L))
      out_n <- if (is.null(out)) 0L else nrow(out) %||% 0L
      message(sprintf("  [%d/%d] %s %s: %d entries (cumulative: %d)",
                      i, nrow(docs), d$publication_date, d$document_number,
                      out_n, cum))
    }
    Sys.sleep(0.4)
  }
  records <- bind_rows(records_list)

  if (is.null(output_name)) {
    output_name <- sprintf("eis_records_%d-%d.csv", year_start, year_end)
  }
  out_path <- file.path(RAW_DIR, output_name)
  write_csv(records, out_path)
  message(sprintf("\nWrote %d records to %s", nrow(records), out_path))
  invisible(records)
}

# -----------------------------------------------------------------------------
# Entry point
# -----------------------------------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
if (length(args) >= 2L) {
  main(as.integer(args[1]), as.integer(args[2]))
} else {
  main(2024L, 2024L, output_name = "eis_records_2024_test.csv")
}
