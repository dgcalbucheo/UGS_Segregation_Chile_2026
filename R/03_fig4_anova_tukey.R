# =====================================================================
# 03_fig4_anova_tukey.R
# Fig. 4: NDVI de los parques por categoría ISMT (boxplots)
# ANOVA de una vía por ciudad (NDVI ~ ISMT_LEVEL)
# Table A.2: TukeyHSD por ciudad
#
# Entradas : outputs/intermediate/parks_analysis_tbl.rds
# Salidas  : outputs/figures/fig4_ndvi_ismt_boxplots.{png,pdf}
#            outputs/tables/Fig4_ANOVA_NDVI_ISMT_by_city.csv
#            outputs/tables/Table_A2_Tukey_NDVI_ISMT_by_city.csv
#            outputs/tables/Table_A2_Tukey_NDVI_ISMT_by_city.txt   (salida cruda de TukeyHSD)
# =====================================================================

source(here::here("R", "00_setup.R"))
ugs_load(c("dplyr", "tidyr", "tibble", "readr", "ggplot2", "broom"))

parks_analysis_tbl <- load_analysis_tables()$parks

# ---- Datos --------------------------------------------------------------
fig4_ndvi_ismt_data <- parks_analysis_tbl %>%
  filter(!is.na(CITY), !is.na(MEAN_NDVI), !is.na(ISMT_LEVEL)) %>%
  mutate(
    CITY       = factor(CITY, levels = city_levels),
    ISMT_LEVEL = factor(ISMT_LEVEL, levels = ismt_levels)
  ) %>%
  filter(!is.na(CITY), !is.na(ISMT_LEVEL))

# Parques por ciudad y categoría. OJO: Antofagasta no tiene parques "Low",
# por eso su Tukey tiene 3 comparaciones y no 6.
print(fig4_ndvi_ismt_data %>% count(CITY, ISMT_LEVEL) %>%
        pivot_wider(names_from = ISMT_LEVEL, values_from = n), n = Inf)

# ---- ANOVA por ciudad -----------------------------------------------------
anova_ndvi_ismt_tbl <- fig4_ndvi_ismt_data %>%
  group_by(CITY) %>%
  group_modify(~ {
    d <- droplevels(.x)
    if (nlevels(d$ISMT_LEVEL) < 2) return(tibble())
    broom::tidy(aov(MEAN_NDVI ~ ISMT_LEVEL, data = d))
  }) %>%
  ungroup()

save_table(anova_ndvi_ismt_tbl, "Fig4_ANOVA_NDVI_ISMT_by_city.csv")

# ---- Table A.2: TukeyHSD por ciudad -----------------------------------------
# Se ajusta un aov por ciudad y se aplica TukeyHSD() (comparaciones por pares,
# ajuste de Tukey para comparaciones múltiples). Se guardan:
#   - la tabla ordenada (CSV)
#   - la salida cruda de TukeyHSD() por ciudad (TXT), tal como se ve en consola.
tukey_models <- fig4_ndvi_ismt_data %>%
  group_by(CITY) %>%
  group_map(~ {
    d <- droplevels(.x)
    if (nlevels(d$ISMT_LEVEL) < 2) return(NULL)
    TukeyHSD(aov(MEAN_NDVI ~ ISMT_LEVEL, data = d), "ISMT_LEVEL")
  }, .keep = TRUE)

names(tukey_models) <- levels(fig4_ndvi_ismt_data$CITY)[
  levels(fig4_ndvi_ismt_data$CITY) %in% as.character(fig4_ndvi_ismt_data$CITY)
]

tukey_ndvi_ismt_tbl <- purrr::imap_dfr(
  purrr::compact(tukey_models),
  ~ tibble::as_tibble(.x$ISMT_LEVEL, rownames = "comparison") %>%
    mutate(CITY = .y, .before = 1)
) %>%
  rename(lower = lwr, upper = upr, p_adj = `p adj`) %>%
  mutate(
    significant = case_when(
      p_adj < 0.001 ~ "***",
      p_adj < 0.01  ~ "**",
      p_adj < 0.05  ~ "*",
      TRUE          ~ "ns"
    )
  )

save_table(tukey_ndvi_ismt_tbl, "Table_A2_Tukey_NDVI_ISMT_by_city.csv")

# Salida cruda (texto) de TukeyHSD por ciudad
tukey_txt <- file.path(dir_tables, "Table_A2_Tukey_NDVI_ISMT_by_city.txt")
sink(tukey_txt)
for (city in names(purrr::compact(tukey_models))) {
  cat("\n==================== ", city, " ====================\n", sep = "")
  print(tukey_models[[city]])
}
sink()
message("Tabla exportada: outputs/tables/Table_A2_Tukey_NDVI_ISMT_by_city.txt")

print(tukey_ndvi_ismt_tbl, n = Inf)

# ---- Fig. 4: boxplots ----------------------------------------------------------
city_labels_fig4 <- c(
  "Antofagasta"  = "A Antofagasta",
  "La Serena"    = "B La Serena",
  "Valparaíso"   = "C Valparaíso",
  "Santiago"     = "D Santiago",
  "Concepción"   = "E Concepción",
  "Puerto Montt" = "F Puerto Montt"
)

fig4_ndvi_ismt <- ggplot(
  fig4_ndvi_ismt_data,
  aes(x = ISMT_LEVEL, y = MEAN_NDVI, colour = ISMT_LEVEL)
) +
  geom_boxplot(outlier.alpha = 0.35, width = 0.65) +
  facet_wrap(~ CITY, ncol = 2, labeller = labeller(CITY = city_labels_fig4)) +
  labs(x = "ISMT category", y = "Mean NDVI") +
  theme_bw(base_size = 12) +
  theme(
    legend.position  = "none",
    strip.text       = element_text(face = "bold"),
    axis.text.x      = element_text(angle = 35, hjust = 1),
    panel.grid.minor = element_blank()
  )

save_fig(fig4_ndvi_ismt, "fig4_ndvi_ismt_boxplots", width = 6, height = 10)
