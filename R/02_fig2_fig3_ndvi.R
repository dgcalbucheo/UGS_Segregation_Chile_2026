# =====================================================================
# 02_fig2_fig3_ndvi.R
# Fig. 2: distribución de NDVI de los parques por ciudad
# Fig. 3: tamaño poblacional de la ciudad vs. NDVI medio
#
# Entradas : outputs/intermediate/parks_analysis_tbl.rds
# Salidas  : outputs/figures/fig2_ndvi_histogram_by_city.{png,pdf}
#            outputs/figures/fig3_population_ndvi.{png,pdf}
#            outputs/tables/fig3_population_ndvi_summary.csv
# =====================================================================

source(here::here("R", "00_setup.R"))
ugs_load(c("dplyr", "readr", "ggplot2", "ggrepel"))

parks_analysis_tbl <- load_analysis_tables()$parks

# ---- Fig. 2: histogramas de NDVI -----------------------------------------
fig2_ndvi_data <- parks_analysis_tbl %>%
  mutate(CITY = factor(CITY, levels = city_levels)) %>%
  filter(!is.na(MEAN_NDVI), !is.na(CITY))

fig2_ndvi_hist <- ggplot(fig2_ndvi_data, aes(x = MEAN_NDVI)) +
  geom_histogram(bins = 30, color = "black", fill = "grey75") +
  facet_wrap(~ CITY, ncol = 2, scales = "free_y") +
  labs(x = "Mean NDVI", y = "Number of parks") +
  theme_bw() +
  theme(
    strip.background = element_rect(fill = "grey90", color = "black"),
    strip.text       = element_text(face = "bold"),
    panel.grid.minor = element_blank()
  )

save_fig(fig2_ndvi_hist, "fig2_ndvi_histogram_by_city", width = 8, height = 6)

# ---- Fig. 3: población vs. NDVI medio ---------------------------------------
mean_ndvi_city <- parks_analysis_tbl %>%
  group_by(CITY) %>%
  summarise(
    NDVI_mean = mean(MEAN_NDVI, na.rm = TRUE),
    NDVI_se   = sd(MEAN_NDVI, na.rm = TRUE) / sqrt(sum(!is.na(MEAN_NDVI)))
  )

# Población en miles de habitantes (valores del script original de la figura).
population_city_tbl <- tibble::tribble(
  ~CITY,          ~population_thousands,
  "Antofagasta",   361.9,
  "La Serena",     534.2,
  "Valparaíso",    909.2,
  "Santiago",     6254.3,
  "Concepción",   1187.2,
  "Puerto Montt",  308.1
)

fig3_population_ndvi_data <- mean_ndvi_city %>%
  left_join(population_city_tbl, by = "CITY") %>%
  mutate(CITY = factor(CITY, levels = city_levels))

save_table(fig3_population_ndvi_data, "fig3_population_ndvi_summary.csv")

fig3_population_ndvi <- ggplot(
  fig3_population_ndvi_data,
  aes(x = population_thousands, y = NDVI_mean, label = CITY, color = CITY)
) +
  geom_pointrange(
    aes(ymin = NDVI_mean - 1.96 * NDVI_se, ymax = NDVI_mean + 1.96 * NDVI_se),
    linewidth = 0.7, fatten = 4, alpha = 0.9
  ) +
  ggrepel::geom_text_repel(size = 4, show.legend = FALSE) +
  scale_x_log10(
    breaks = c(300, 500, 1000, 2000, 5000),
    labels = c("300", "500", "1,000", "2,000", "5,000")
  ) +
  scale_color_manual(values = city_colors) +
  theme_minimal(base_size = 14) +
  labs(
    x = expression("Population " %*% 10^3 * " - log scale"),
    y = "NDVI"
  ) +
  theme(
    legend.position  = "none",
    panel.grid.minor = element_blank(),
    axis.line        = element_line(linewidth = 0.35, colour = "black"),
    axis.ticks       = element_line(linewidth = 0.35, colour = "black")
  )

save_fig(fig3_population_ndvi, "fig3_population_ndvi", width = 7, height = 4.5)
