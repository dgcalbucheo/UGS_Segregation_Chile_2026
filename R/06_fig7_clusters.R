# =====================================================================
# 06_fig7_clusters.R
# Fig. 7 / Apéndice 5.4: clustering jerárquico de los perfiles horarios de
# entropía de los parques (> 5000 m2), y comparación de los grupos según
# calidad (QUALITY_INDEX), NDVI e ISMT.
#
# Entradas : outputs/intermediate/{parks,entropy}_analysis_tbl.rds
#            (opcional) outputs/intermediate/park_area_tbl.rds, generado por
#            R/optional_spatial_reconstruction.R; si no existe se usa la
#            columna AREA de Table_parks.csv.
# Salidas  : outputs/figures/fig7_dendrogram_<ciudad>.pdf
#            outputs/figures/fig7_cluster_boxplots_<ciudad>.pdf
#
# Por defecto procesa solo Antofagasta (como el original). Para todas las
# ciudades: cluster_cities <- city_levels antes de ejecutar el script.
# =====================================================================

source(here::here("R", "00_setup.R"))
ugs_load(c("dplyr", "tidyr", "tibble", "ggplot2", "dendextend"))

if (!exists("cluster_cities")) cluster_cities <- "Antofagasta"
n_groups <- 4
min_area_m2 <- 5000

tables <- load_analysis_tables()
parks_analysis_tbl   <- tables$parks
entropy_analysis_tbl <- tables$entropy

# ---- Área total del parque (AT) ------------------------------------------------
f_area <- file.path(dir_intermediate, "park_area_tbl.rds")
if (file.exists(f_area)) {
  park_area_tbl <- readRDS(f_area)                       # ID, AT (desde geometrías)
} else {
  message("park_area_tbl.rds no existe: se usa AREA de Table_parks.csv como AT.")
  park_area_tbl <- parks_analysis_tbl %>%
    group_by(ID) %>%
    summarise(AT = sum(AREA, na.rm = TRUE))
}

parks_cluster_tbl <- parks_analysis_tbl %>%
  left_join(select(park_area_tbl, ID, AT), by = "ID")

entropy_cluster_tbl <- entropy_analysis_tbl %>%
  left_join(
    parks_cluster_tbl %>%
      select(ID, CITY, AT, QUALITY_INDEX, MEAN_NDVI, ISMT) %>%
      distinct(ID, CITY, .keep_all = TRUE),
    by = c("ID", "CITY")
  ) %>%
  filter(AT > min_area_m2)

# ---- Un dendrograma + boxplots por ciudad -----------------------------------------
for (city_i in cluster_cities) {

  dend_tbl <- entropy_cluster_tbl %>%
    filter(CITY == city_i) %>%
    select(ID, `0`:`23`) %>%
    distinct(ID, .keep_all = TRUE) %>%
    drop_na()

  dend_mat <- dend_tbl %>%
    column_to_rownames("ID") %>%
    as.matrix()

  dendro <- as.dendrogram(hclust(dist(dend_mat)))
  dendro_col <- color_branches(dendro, n_groups)
  dendro_col <- set(dendro_col, "branches_lwd", 2)

  pdf(file.path(dir_figures, paste0("fig7_dendrogram_", city_slug(city_i), ".pdf")),
      width = 7, height = 8)
  plot(dendro_col, horiz = TRUE, leaflab = "none", main = city_i)
  dev.off()

  groups_tbl <- tibble(
    ID = names(cutree(dendro, n_groups)),
    dend_group = factor(cutree(dendro, n_groups))
  ) %>%
    left_join(
      parks_cluster_tbl %>%
        filter(CITY == city_i) %>%
        select(ID, CITY, AT, QUALITY_INDEX, MEAN_NDVI, ISMT) %>%
        distinct(ID, .keep_all = TRUE),
      by = "ID"
    ) %>%
    filter(QUALITY_INDEX > 0)

  box_long <- groups_tbl %>%
    pivot_longer(c(QUALITY_INDEX, MEAN_NDVI, ISMT),
                 names_to = "variable", values_to = "value")

  p_box <- ggplot(box_long, aes(x = dend_group, y = value)) +
    geom_boxplot() +
    facet_wrap(~ variable, scales = "free_y", nrow = 1) +
    labs(title = city_i, x = "Entropy cluster", y = NULL) +
    theme_minimal()

  ggsave(
    file.path(dir_figures, paste0("fig7_cluster_boxplots_", city_slug(city_i), ".pdf")),
    plot = p_box, width = 9, height = 3.5
  )

  message("Clustering listo: ", city_i, " (", nrow(dend_mat), " parques)")
}
