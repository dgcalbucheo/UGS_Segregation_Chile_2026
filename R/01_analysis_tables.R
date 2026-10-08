# =====================================================================
# 01_analysis_tables.R
# Construye las tablas analíticas que alimentan todos los resultados
# (Fig. 2-7, Table A1/A2, Table 1) a partir de los datos oficiales:
#
#   data/Table_parks.csv    -> parks_analysis_tbl
#   data/Table_entropy.csv  -> entropy_analysis_tbl
#
# Entradas : data/Table_parks.csv, data/Table_entropy.csv
# Salidas  : outputs/intermediate/parks_analysis_tbl.rds
#            outputs/intermediate/entropy_analysis_tbl.rds
#
# No requiere paquetes espaciales (sf / terra / raster).
# =====================================================================

source(here::here("R", "00_setup.R"))
ugs_load(c("dplyr", "readr"))

# ---- Carga -----------------------------------------------------------
parks_official_tbl <- readr::read_csv(
  file.path(dir_data, "Table_parks.csv"),
  show_col_types = FALSE
)

entropy_official_tbl <- readr::read_csv(
  file.path(dir_data, "Table_entropy.csv"),
  show_col_types = FALSE
)

# ---- Parques: nombres de ciudad + categorías de "greenness" ------------
# GREENNESS_LEVEL: terciles de NDVI medio dentro de cada ciudad.
parks_analysis_tbl <- parks_official_tbl %>%
  mutate(
    ID   = as.character(ID),
    CITY = recode(CITY, !!!city_recode)
  ) %>%
  group_by(CITY) %>%
  mutate(
    GREENNESS_LEVEL = cut(
      MEAN_NDVI,
      breaks = quantile(MEAN_NDVI, probs = seq(0, 1, 1 / 3), na.rm = TRUE),
      labels = greenness_levels,
      include.lowest = TRUE
    )
  ) %>%
  ungroup()

# ---- Entropía: mismos nombres de ciudad ---------------------------------
entropy_analysis_tbl <- entropy_official_tbl %>%
  mutate(
    ID   = as.character(ID),
    CITY = recode(CITY, !!!city_recode)
  )

# ---- Chequeos rápidos -----------------------------------------------------
stopifnot(
  all(parks_analysis_tbl$CITY %in% city_levels),
  all(entropy_analysis_tbl$CITY %in% city_levels)
)

message("parks_analysis_tbl:   ", nrow(parks_analysis_tbl), " filas")
message("entropy_analysis_tbl: ", nrow(entropy_analysis_tbl), " filas")

# ---- Guardar ---------------------------------------------------------------
saveRDS(parks_analysis_tbl,   file.path(dir_intermediate, "parks_analysis_tbl.rds"))
saveRDS(entropy_analysis_tbl, file.path(dir_intermediate, "entropy_analysis_tbl.rds"))
