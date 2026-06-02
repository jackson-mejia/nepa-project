# Plot per-sector NEPA exposure rate ϕ_i^structures.
#
# Reads the per-sector decomposition written by compute_domar.R and produces a
# horizontal bar chart showing each sector's exposure rate (% of sector
# structures investment passing through a Final EIS, 2020-2024 panel).
#
# This is the "intensity" view (ignores Domar weight). It answers: which
# sectors face the largest NEPA-exposure share of their own investment?
#
# Output: output/sector_exposure.png

suppressPackageStartupMessages({
  library(dplyr); library(readr); library(ggplot2)
})

library(here)

d <- read_csv(here("output", "phi_domar_by_sector.csv"),
              show_col_types = FALSE) |>
     filter(phi_agg_avg > 0) |>
     mutate(phi_pct  = 100 * phi_agg_avg,
            # Tidy long labels for the chart
            label = recode(go_label,
              "Arts, entertainment, recreation, accommodation, and food services" =
                "Arts, recreation, accommodation",
              "Other transportation and support activities" =
                "Other transportation/support",
              "Agriculture, forestry, fishing, and hunting" =
                "Agriculture, forestry, fishing"
            )) |>
     arrange(phi_pct) |>
     mutate(label = factor(label, levels = label))

p <- ggplot(d, aes(x = label, y = phi_pct)) +
  geom_col(fill = "grey25", width = 0.7) +
  coord_flip() +
  labs(
    title = NULL,
    x = NULL,
    y = "Share of sector structures investment passing through a Final EIS (%)"
  ) +
  theme_minimal() +
  theme(
    axis.title = element_text(size = 16),
    axis.text = element_text(size = 14)
  )

png_path <- here("output", "sector_exposure.png")
ggsave(png_path, p, width = 10, height = 5, dpi = 300)
cat(sprintf("Saved sector-exposure plot to %s\n", png_path))
