# =====================================================================
# 04_fig5_sankey.R
# Fig. 5: diagramas de Sankey greenness (NDVI) -> categoría ISMT, por ciudad
#
# Entradas : outputs/intermediate/parks_analysis_tbl.rds
# Salidas  : outputs/tables/sankey_greenness_ismt_links.csv
#            outputs/figures/fig5_sankey_greenness_ismt_<ciudad>.html  (6 archivos)
#
# Requiere: networkD3, htmlwidgets
# =====================================================================

source(here::here("R", "00_setup.R"))
ugs_load(c("dplyr", "readr", "networkD3", "htmlwidgets"))

parks_analysis_tbl <- load_analysis_tables()$parks

# ---- Flujos para todas las ciudades --------------------------------------
sankey_greenness_ismt_links <- parks_analysis_tbl %>%
  filter(!is.na(CITY), !is.na(GREENNESS_LEVEL), !is.na(ISMT_LEVEL)) %>%
  count(CITY, source = GREENNESS_LEVEL, target = ISMT_LEVEL, name = "value")

save_table(sankey_greenness_ismt_links, "sankey_greenness_ismt_links.csv")

# ---- Constructor del diagrama (una ciudad) ----------------------------------
make_sankey_greenness_ismt <- function(data, city_name) {
  links <- data %>%
    filter(CITY == city_name,
           !is.na(GREENNESS_LEVEL), !is.na(ISMT_LEVEL)) %>%
    count(source = as.character(GREENNESS_LEVEL),
          target = as.character(ISMT_LEVEL),
          name = "value")

  # Nodos: primero las categorías de greenness y luego las de ISMT,
  # solo las presentes en esta ciudad.
  node_names <- c(greenness_levels, ismt_levels)
  node_names <- node_names[node_names %in% c(links$source, links$target)]
  nodes <- data.frame(name = node_names)

  # networkD3 pide índices base 0
  links <- links %>%
    mutate(
      source = match(source, node_names) - 1L,
      target = match(target, node_names) - 1L
    ) %>%
    as.data.frame()

  networkD3::sankeyNetwork(
    Links = links, Nodes = nodes,
    Source = "source", Target = "target", Value = "value",
    NodeID = "name", fontSize = 12, nodeWidth = 30
  )
}

# ---- Exportar un HTML por ciudad -----------------------------------------------
for (city in city_levels) {
  widget <- make_sankey_greenness_ismt(parks_analysis_tbl, city)

  htmlwidgets::saveWidget(
    widget,
    file = file.path(dir_figures,
                     paste0("fig5_sankey_greenness_ismt_", city_slug(city), ".html")),
    selfcontained = FALSE
  )
}

message("Sankeys exportados en outputs/figures/")
