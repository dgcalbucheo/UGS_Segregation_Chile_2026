# =====================================================================
# 05_fig6_entropy_timelines.R
# Fig. 6: entropía social media por hora, según greenness del parque
#         (y, como material complementario, según categoría ISMT)
#
# Entradas : outputs/intermediate/{parks,entropy}_analysis_tbl.rds
# Salidas  : outputs/figures/fig6_timeline_greenness_all_cities.{png,pdf}
#            outputs/tables/fig6_timeline_greenness_mean_entropy.csv
#            outputs/tables/fig6_timeline_ismt_mean_entropy.csv
# =====================================================================

source(here::here("R", "00_setup.R"))
ugs_load(c("dplyr", "tidyr", "readr", "ggplot2"))

tables <- load_analysis_tables()
parks_analysis_tbl   <- tables$parks
entropy_analysis_tbl <- tables$entropy

# ---- Entropía en formato largo + atributos del parque -----------------------
entropy_long_tbl <- entropy_analysis_tbl %>%
  pivot_longer(cols = `0`:`23`, names_to = "hour", values_to = "H") %>%
  mutate(hour = as.integer(hour))

park_attrs_tbl <- parks_analysis_tbl %>%
  select(ID, CITY, GREENNESS_LEVEL, ISMT_LEVEL) %>%
  distinct()

entropy_timeline_data <- entropy_long_tbl %>%
  # Table_parks.csv tiene varias filas por ID (polígonos fragmentados), igual que
  # en el flujo original; se mantiene la relación muchos-a-muchos a propósito.
  left_join(park_attrs_tbl, by = c("ID", "CITY"), relationship = "many-to-many") %>%
  filter(!is.na(H), !is.na(GREENNESS_LEVEL), !is.na(ISMT_LEVEL)) %>%
  mutate(
    CITY       = factor(CITY, levels = city_levels),
    ISMT_LEVEL = factor(ISMT_LEVEL, levels = ismt_levels)
  )

timeline_greenness_tbl <- entropy_timeline_data %>%
  group_by(CITY, hour, GREENNESS_LEVEL) %>%
  summarise(mean_H = mean(H, na.rm = TRUE))

timeline_ismt_tbl <- entropy_timeline_data %>%
  group_by(CITY, hour, ISMT_LEVEL) %>%
  summarise(mean_H = mean(H, na.rm = TRUE))

save_table(timeline_greenness_tbl, "fig6_timeline_greenness_mean_entropy.csv")
save_table(timeline_ismt_tbl,      "fig6_timeline_ismt_mean_entropy.csv")

# ---- Figura principal: por greenness ----------------------------------------
fig6_timeline_greenness_all <- ggplot(
  timeline_greenness_tbl,
  aes(x = hour, y = mean_H, color = GREENNESS_LEVEL)
) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 1.5) +
  facet_wrap(~ CITY, ncol = 2) +
  scale_color_manual(
    values = c(
      "Low Greenness"    = "#AFBDAF",
      "Medium Greenness" = "#72AE72",
      "High Greenness"   = "#009900"
    )
  ) +
  labs(x = "Hour", y = "Mean entropy (H)", color = "Park greenness") +
  theme_minimal() +
  theme(legend.position = "bottom", panel.grid.minor = element_blank())

save_fig(fig6_timeline_greenness_all, "fig6_timeline_greenness_all_cities",
         width = 10, height = 7)

# ---- Versión por ISMT (complementaria; solo se guarda la tabla) ------------------
fig6_timeline_ismt_all <- ggplot(
  timeline_ismt_tbl,
  aes(x = hour, y = mean_H, color = ISMT_LEVEL)
) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 1.5) +
  facet_wrap(~ CITY, ncol = 2) +
  labs(x = "Hour", y = "Mean entropy (H)", color = "ISMT category") +
  theme_minimal() +
  theme(legend.position = "bottom", panel.grid.minor = element_blank())

# Para exportar también esta figura, descomentar:
# save_fig(fig6_timeline_ismt_all, "fig6_timeline_ismt_all_cities", width = 10, height = 7)

# NOTA: los timelines se reconstruyen desde las tablas oficiales. En
# Antofagasta y Puerto Montt el orden vertical de las categorías de greenness
# difiere de gráficos exploratorios previos, probablemente por diferencias
# entre las tablas finales y los objetos de trabajo originales por ciudad.
