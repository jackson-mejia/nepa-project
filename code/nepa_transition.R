# NEPA reform transition dynamics — time-to-build model with adjustment costs.
#
# Solves the continuous-time transition path of capital, output, and Tobin's q
# after a one-shot reduction in the NEPA review delay L. Reports the per-year
# output semi-elasticity (∂lnY / ∂L) at the aggregate-GDP level, after scaling
# by the share of the economy exposed to NEPA review (Φ_private).
#
# Convention: we set L_reform = L_baseline - 1 so the reported gain *is* the
# one-year semi-elasticity. Multiplying by an actual reform delta in years
# converts to a project-specific reform effect (linearity in dL holds as long as
# the model is locally linear around the baseline steady state).
#
# Inputs sourced from project pipeline output:
#   output/phi_domar_headline.csv             — Φ_Domar central / lower / upper
#     (Σ_i s_i · ϕ_i^total where s_i = GO_i/GDP and ϕ_i^total uses
#      denominator = structures + equipment, ex-IPP. Bounds come from the
#      cancellation-attribution sensitivity in compute_domar.R.)
#
# Outputs:
#   output/transition_path.csv         — yearly output-gain path for lower/middle/upper Φ
#   stdout: steady-state gains and yearly semi-elasticity at t = 1, 2, 5, 10, 15, 20, 30, 50

suppressPackageStartupMessages({
  library(dplyr); library(readr)
})
have_ggplot <- requireNamespace("ggplot2", quietly = TRUE)

library(here)

# ============================================================
# Solver: time-to-build model with quadratic adjustment costs
# ============================================================
solve_ttb <- function(
    A = 1,
    alpha = 0.4,
    delta = 0.03,
    r = 0.08,
    psi = 1.5,
    L = 3,
    T = 200,
    dt = 0.05,
    K0 = NULL,
    L_old = NULL,
    tol = 1e-7,
    max_iter = 10000,
    damping = 0.1
) {
  n <- round(T / dt)
  n_L <- round(L / dt)
  t_grid <- seq(0, T - dt, by = dt)

  # New steady state. Adjustment cost Psi = (psi/2)(I/K - delta)^2 K vanishes at
  # SS (where I/K = delta), so q* and MPK* take their frictionless forms.
  q_star <- exp(r * L)
  MPK_star <- (r + delta) * q_star
  K_star <- (alpha * A / MPK_star)^(1 / (1 - alpha))
  I_star <- delta * K_star
  Y_star <- A * K_star^alpha

  # Old steady state (initial K at t = 0)
  if (is.null(L_old)) {
    K0_ss <- K_star
  } else {
    q_old_ss <- exp(r * L_old)
    MPK_old <- (r + delta) * q_old_ss
    K0_ss <- (alpha * A / MPK_old)^(1 / (1 - alpha))
  }
  if (is.null(K0)) K0 <- K0_ss
  I0 <- delta * K0

  # Initial guess for relaxation
  K <- seq(K0, K_star, length.out = n)
  I <- seq(I0, I_star, length.out = n)
  q <- rep(q_star, n)

  for (iter in 1:max_iter) {
    K_prev <- K; q_prev <- q

    K_new <- numeric(n); I_new <- numeric(n)
    K_new[1] <- K0

    for (t in 1:(n - 1)) {
      t_future <- min(t + n_L, n)
      q_future <- q[t_future]
      # FOC under Psi = (psi/2)(I/K - delta)^2 K:
      #   q(t+L) e^(-rL) = 1 + psi (I/K - delta)  =>  I/K = delta + (e^(-rL)q - 1)/psi
      I_new[t] <- max(K_new[t] * (delta + (exp(-r * L) * q_future - 1) / psi), 0)
      t_lag <- t - n_L
      I_lagged <- if (t_lag >= 1) I_new[t_lag] else I0
      K_new[t + 1] <- K_new[t] + dt * (I_lagged - delta * K_new[t])
    }
    I_new[n] <- delta * K_new[n]

    q_new <- numeric(n); q_new[n] <- q_star
    for (t in (n - 1):1) {
      IK_ratio <- I_new[t] / K_new[t]
      # Costate update for Psi = (psi/2)(I/K - delta)^2 K:
      #   dPsi/dK = -(psi/2)(I/K - delta)(I/K + delta)
      dq <- (r + delta) * q_new[t + 1] - alpha * A * K_new[t + 1]^(alpha - 1) -
            (psi / 2) * (IK_ratio - delta) * (IK_ratio + delta)
      q_new[t] <- q_new[t + 1] - dt * dq
    }

    K <- damping * K_new + (1 - damping) * K_prev
    I <- damping * I_new + (1 - damping) * I
    q <- damping * q_new + (1 - damping) * q_prev

    err <- max(abs(K - K_prev) / (abs(K_prev) + 1e-10))
    if (err < tol) break
  }

  Y <- A * K^alpha
  list(t = t_grid, K = K, I = I, q = q, Y = Y,
       K_star = K_star, Y_star = Y_star, K0 = K0, Y0 = A * K0^alpha)
}

# ============================================================
# Source Φ_Domar from project pipeline output
# ============================================================
#
# `phi_central` = 5-yr-avg Σ_i s_i · ϕ_i (panel 2020-2024)
#   where s_i = Gross Output_i / GDP (Domar weight).
#
# `phi_lower` and `phi_upper` come from the denominator-choice band inside
# compute_domar.R: lower uses ϕ_i = exposed/(structures + equipment) ex-IPP,
# upper uses ϕ_i = exposed/structures only; the band is wider than the
# cancellation-attribution sensitivity (which is reported separately in
# output/phi_domar_cancellation_sensitivity.csv).
phi_head <- read_csv(here("output", "phi_domar_headline.csv"),
                     show_col_types = FALSE)
phi_central <- phi_head$phi_domar_headline[1]
phi_lower   <- phi_head$phi_domar_lower[1]
phi_upper   <- phi_head$phi_domar_upper[1]

cat(sprintf("Φ_private (sourced from output/): central=%.4f, lower=%.4f, upper=%.4f\n",
            phi_central, phi_lower, phi_upper))

# ============================================================
# Model parameters
# ============================================================
# Production / preferences
alpha <- 0.4    # capital share
r     <- 0.08   # discount rate
delta <- 0.03   # depreciation rate
psi   <- 1.5    # quadratic adjustment cost parameter

# NEPA review delay: baseline vs. one-year reduction. The 1-year delta makes the
# reported output gain *exactly* the one-year semi-elasticity ∂lnY / ∂L; multiply
# by the policy-relevant reform delta in years to scale up.
L_baseline <- 4.2              # Liscow (2025) measured baseline EIS review duration
L_reform   <- L_baseline - 1   # 1-year reduction (dL = 1)

# ============================================================
# Solve baseline and reform paths
# ============================================================
baseline <- solve_ttb(L = L_baseline, L_old = L_baseline,
                      alpha = alpha, r = r, delta = delta, psi = psi)
reform   <- solve_ttb(L = L_reform,   L_old = L_baseline,
                      alpha = alpha, r = r, delta = delta, psi = psi)

# Sector-level output gain (unscaled by Φ — this is the gain within the part of
# the economy actually exposed to NEPA delays)
t       <- baseline$t
dlog_Y  <- log(reform$Y) - log(baseline$Y[1])

# Scale by Φ to convert to aggregate-GDP gain (% of GDP per year of delay reduction)
scale_phi <- function(phi) 100 * dlog_Y * phi
gain_lower  <- scale_phi(phi_lower)
gain_central <- scale_phi(phi_central)
gain_upper  <- scale_phi(phi_upper)

# Steady-state semi-elasticity
ss_dlog <- log(reform$Y_star) - log(baseline$Y_star)
ss_gain_lower  <- 100 * ss_dlog * phi_lower
ss_gain_central <- 100 * ss_dlog * phi_central
ss_gain_upper  <- 100 * ss_dlog * phi_upper

# Analytical check: in steady state, dlnY ≈ α * r / (1 - α) * dL (small-Δ limit)
analytical_ss <- 100 * alpha * r / (1 - alpha) * 1 * phi_central  # dL = 1

# ============================================================
# Report
# ============================================================
cat("\n=== One-year semi-elasticity ∂lnY / ∂L (% of GDP per year of delay reduction) ===\n")
cat(sprintf("Steady-state gain: lower=%.3f%%  central=%.3f%%  upper=%.3f%%\n",
            ss_gain_lower, ss_gain_central, ss_gain_upper))
cat(sprintf("(analytical check at central Φ: %.3f%%)\n\n", analytical_ss))
cat("Transition path (semi-elasticity at horizon t):\n")
cat(sprintf("%6s %10s %10s %10s\n", "Year", "Lower", "Central", "Upper"))
for (yr in c(1, 2, 5, 10, 15, 20, 30, 50)) {
  idx <- which.min(abs(t - yr))
  cat(sprintf("%6d %10.3f %10.3f %10.3f\n", yr,
              gain_lower[idx], gain_central[idx], gain_upper[idx]))
}


# ============================================================
# Save and plot
# ============================================================
out_dir <- here("output")
dir.create(out_dir, showWarnings = FALSE)
transition_csv <- file.path(out_dir, "transition_path.csv")
write.csv(data.frame(year = t, lower = gain_lower,
                     central = gain_central, upper = gain_upper),
          transition_csv, row.names = FALSE)
cat(sprintf("\nSaved transition path to %s\n", transition_csv))

if (have_ggplot) {
  plot_data <- data.frame(year = t, lower = gain_lower, middle = gain_central, upper = gain_upper)
  plot_data <- plot_data[plot_data$year <= 50, ]
  plot_data_b <- plot_data %>% mutate(year = 2026 + year) %>%
    filter(year < 2051)
  plot_long <- data.frame(
    year = rep(plot_data_b$year, 3),
    gain = c(plot_data_b$lower, plot_data_b$middle, plot_data_b$upper),
    scenario = rep(c("Lower", "Middle", "Upper"), each = nrow(plot_data_b))
  )
  plot_long$scenario <- factor(plot_long$scenario, levels = c("Upper", "Middle", "Lower"))

  p <- ggplot2::ggplot(plot_long, ggplot2::aes(x = year, y = gain, linetype = scenario)) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::scale_linetype_manual(values = c("Upper" = "dashed", "Middle" = "solid", "Lower" = "dashed")) +
    ggplot2::labs(
      x = "Years after reform",
      y = "Output gain (%)",
      linetype = "NEPA exposure"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title  = ggplot2::element_text(size = 14, face = "bold"),
      axis.title  = ggplot2::element_text(size = 14),
      axis.text  = ggplot2::element_text(size = 14),
      legend.position = "none",
      axis.title.x = ggplot2::element_text(margin = ggplot2::margin(t = 10))
    )

  png_path <- file.path(out_dir, "transition_path.png")
  ggplot2::ggsave(png_path, p, width = 10, height = 5, dpi = 300)
  cat(sprintf("Saved plot to %s\n", png_path))
} else {
  cat("\nNote: ggplot2 not installed - skipping plot. CSV output is in output/transition_path.csv.\n")
}
