# =====================================================================
# optional_spatial_reconstruction.R   (OPCIONAL, pesado)
#
# Reconstruye desde los datos espaciales crudos los atributos de los parques
# (ISMT ponderado por área, NDVI medio, entropía) y los VALIDA contra las
# tablas oficiales. Los resultados del manuscrito NO dependen de este script:
# salen de data/Table_parks.csv y data/Table_entropy.csv (ver 01_analysis_tables.R).
#
# Entradas : data/CALIDAD_pzpq_2019/*.shp          (no versionado, ver .gitignore)
#            data/ISMT_2022_actualizado/*.shp
#            data/NDVI_rasters_2016/*.tif
#            data/voronoi_chile/*.gpkg, hourly_entropy_*.csv  (no versionado)
#            data/Table_parks.csv  (para validar)
# Salidas  : outputs/intermediate/park_area_tbl.rds          (ID, AT)
#            outputs/intermediate/parks_reconstructed.rds    (ID, CITY, ISMT, ISMT_LEVEL, mean_ndvi)
#            outputs/tables/validation_ismt.csv, validation_ndvi.csv
#
# Requiere: sf, terra, raster, janitor, purrr
# Tarda varios minutos (intersecciones de ~14.000 polígonos).
# =====================================================================

source(here::here("R", "00_setup.R"))
ugs_load(c("dplyr", "tidyr", "readr", "purrr", "tibble", "sf", "raster", "janitor"))

sf::sf_use_s2(FALSE)

# ---------------------------------------------------------------------
# 1. Carga de datos espaciales crudos
# ---------------------------------------------------------------------
parks_raw_sf <- sf::st_read(
  file.path(dir_data, "CALIDAD_pzpq_2019", "CALIDAD_pzpq_2019.shp"), quiet = TRUE
) %>%
  sf::st_transform(crs_utm) %>%
  mutate(
    CITY = case_when(
      PROVINCIA == "ANTOFAGASTA" ~ "Antofagasta",
      COMUNA %in% c("LA SERENA", "COQUIMBO") ~ "La Serena",
      COMUNA %in% c("VALPARAÍSO", "VIÑA DEL MAR", "QUILPUÉ", "VILLA ALEMANA") ~ "Valparaíso",
      PROVINCIA == "SANTIAGO" |
        COMUNA %in% c("COLINA", "LAMPA", "PADRE HURTADO", "PEÑAFLOR",
                      "PIRQUE", "PUENTE ALTO", "SAN BERNARDO") ~ "Santiago",
      COMUNA %in% c("CONCEPCIÓN", "TALCAHUANO", "HUALPÉN", "PENCO",
                    "CORONEL", "SAN PEDRO DE LA PAZ") ~ "Concepción",
      COMUNA %in% c("PUERTO MONTT", "PUERTO VARAS") ~ "Puerto Montt",
      TRUE ~ NA_character_
    ),
    CITY = as_city_factor(CITY)
  ) %>%
  filter(!is.na(CITY))

ismt_raw_sf <- sf::st_read(
  file.path(dir_data, "ISMT_2022_actualizado", "ISMT_2022_actualizado.shp"), quiet = TRUE
) %>%
  sf::st_transform(crs_utm) %>%
  mutate(
    CITY = case_when(
      provincia == "ANTOFAGASTA" ~ "Antofagasta",
      provincia == "COQUIMBO" ~ "La Serena",
      comuna %in% c("VALPARAISO", "VINA_DEL_MAR", "QUILPUE", "VILLA_ALEMANA") ~ "Valparaíso",
      provincia == "SANTIAGO" |
        comuna %in% c("COLINA", "LAMPA", "PADRE_HURTADO", "PENAFLOR",
                      "PIRQUE", "PUENTE_ALTO", "SAN_BERNARDO") ~ "Santiago",
      comuna %in% c("CONCEPCION", "TALCAHUANO", "HUALPEN", "PENCO",
                    "CORONEL", "SAN_PEDRO_DE_LA_PAZ") ~ "Concepción",
      comuna %in% c("PUERTO_MONTT", "PUERTO_VARAS") ~ "Puerto Montt",
      TRUE ~ NA_character_
    ),
    CITY = as_city_factor(CITY)
  ) %>%
  filter(!is.na(CITY))

# ---------------------------------------------------------------------
# 2.1 Geometrías de parques: AP (área del polígono) y AT (área total por ID)
# ---------------------------------------------------------------------
parks_sf <- parks_raw_sf %>%
  mutate(ID = as.character(ID_TEXT), CITY = as.character(CITY),
         AP = as.numeric(st_area(.))) %>%
  group_by(ID) %>%
  mutate(AT = sum(AP, na.rm = TRUE)) %>%
  ungroup()

saveRDS(
  parks_sf %>% st_drop_geometry() %>% group_by(ID) %>% summarise(AT = max(AT)),
  file.path(dir_intermediate, "park_area_tbl.rds")
)

# ---------------------------------------------------------------------
# 2.2 ISMT ponderado por área
# ---------------------------------------------------------------------
parks_ismt_tbl <- st_intersection(parks_sf, ismt_raw_sf) %>%
  mutate(area_weight = as.numeric(st_area(.)) / AT,
         ismt_weighted = ismtpn * area_weight) %>%
  st_drop_geometry() %>%
  group_by(ID) %>%
  summarise(ISMT = sum(ismt_weighted, na.rm = TRUE))

parks_sf <- parks_sf %>% select(-any_of("ISMT")) %>% left_join(parks_ismt_tbl, by = "ID")

# 2.2.1 Categorías ISMT: umbrales por ciudad del análisis original (NO se
# derivan de la distribución reconstruida; se reproducen tal cual).
ismt_breaks <- list(
  "Antofagasta"  = c(0, 0.166461, 0.527227, 0.630018, 1),
  "La Serena"    = c(0, 0.544723, 0.592560, 0.663751, 1),
  "Valparaíso"   = c(0, 0.547882, 0.609700, 0.675941, 1),
  "Santiago"     = c(0, 0.535257, 0.618865, 0.733090, 1),
  "Concepción"   = c(0, 0.544723, 0.592560, 0.663751, 1),
  "Puerto Montt" = c(0, 0.521255, 0.559032, 0.648573, 1)
)

parks_sf$ISMT_LEVEL <- NA_character_
for (city in names(ismt_breaks)) {
  i <- parks_sf$CITY == city
  parks_sf$ISMT_LEVEL[i] <- as.character(cut(
    parks_sf$ISMT[i], breaks = ismt_breaks[[city]],
    labels = ismt_levels, include.lowest = TRUE
  ))
}
parks_sf$ISMT_LEVEL <- as_ismt_factor(parks_sf$ISMT_LEVEL)

# ---------------------------------------------------------------------
# 2.3 NDVI medio por parque (rasters reproyectados a UTM 19S)
# ---------------------------------------------------------------------
ndvi_files <- c(
  "Antofagasta"  = "ndvi_antofa_feb2016.tif",
  "La Serena"    = "ndvi_laserena_feb2016.tif",
  "Valparaíso"   = "ndvi_valparaiso_feb2016.tif",
  "Santiago"     = "ndvi_santiago_mar2016.tif",
  "Concepción"   = "ndvi_conce_feb2016.tif",
  "Puerto Montt" = "ndvi_ptomontt_mar2016.tif"
)

parks_sf$mean_ndvi <- NA_real_

for (city in names(ndvi_files)) {
  r <- raster::raster(file.path(dir_data, "NDVI_rasters_2016", ndvi_files[[city]]))
  r[r < 0] <- NA
  r <- raster::projectRaster(r, crs = sf::st_crs(parks_sf)$wkt)
  r[r < 0] <- NA

  parks_city <- parks_sf %>% filter(CITY == city)
  parks_sf$mean_ndvi[parks_sf$CITY == city] <-
    raster::extract(r, as(parks_city, "Spatial"), fun = mean, na.rm = TRUE)
}

saveRDS(
  parks_sf %>% st_drop_geometry() %>% select(ID, CITY, ISMT, ISMT_LEVEL, mean_ndvi),
  file.path(dir_intermediate, "parks_reconstructed.rds")
)

# ---------------------------------------------------------------------
# 3. Validación contra Table_parks.csv
# ---------------------------------------------------------------------
parks_official_tbl <- readr::read_csv(file.path(dir_data, "Table_parks.csv"),
                                      show_col_types = FALSE) %>%
  mutate(ID = as.character(ID)) %>%
  group_by(ID) %>%
  summarise(ISMT_old = first(na.omit(ISMT)), ndvi_old = first(na.omit(MEAN_NDVI)))

check <- parks_sf %>%
  st_drop_geometry() %>%
  group_by(ID) %>%
  summarise(ISMT_new = first(na.omit(ISMT)), ndvi_new = first(na.omit(mean_ndvi))) %>%
  inner_join(parks_official_tbl, by = "ID") %>%
  mutate(diff_ismt = abs(ISMT_new - ISMT_old), diff_ndvi = abs(ndvi_new - ndvi_old))

message("Parques comparados: ", nrow(check))
message("Correlación ISMT: ", round(cor(check$ISMT_new, check$ISMT_old, use = "complete.obs"), 4),
        " | dif. media abs.: ", signif(mean(check$diff_ismt, na.rm = TRUE), 3))
message("Correlación NDVI: ", round(cor(check$ndvi_new, check$ndvi_old, use = "complete.obs"), 4),
        " | dif. media abs.: ", signif(mean(check$diff_ndvi, na.rm = TRUE), 3))
# Referencia (corrida original): ISMT r ~ 0.9994, dif. 0.00012; NDVI r = 0.9837, dif. 0.0028

save_table(check %>% arrange(desc(diff_ismt)), "validation_ismt.csv")
save_table(check %>% arrange(desc(diff_ndvi)), "validation_ndvi.csv")

# ---------------------------------------------------------------------
# 4. Entropía (documentación metodológica; NO reproduce exactamente la oficial)
# ---------------------------------------------------------------------
# La reconstrucción de entropía dio r = 0.851 contra Table_entropy.csv
# (Antofagasta exacta; el resto con desviaciones moderadas). Los resultados
# publicados usan Table_entropy.csv. Se conserva solo como documentación y
# está desactivada por defecto.
run_entropy_reconstruction <- FALSE

if (run_entropy_reconstruction) {
  voronoi_raw_sf <- sf::st_read(
    file.path(dir_data, "voronoi_chile", "voronoi_ismt_chile.gpkg"), quiet = TRUE
  ) %>% sf::st_transform(crs_utm)

  # Archivos horarios por ciudad (columnas esperadas: antena, hour, h, n)
  entropy_files <- c(
    "Antofagasta"  = "hourly_entropy_antofagasta.csv",
    "La Serena"    = "hourly_entropy_laserena.csv",
    "Valparaíso"   = "hourly_entropy_valparaiso.csv",
    "Santiago"     = "hourly_entropy_santiago.csv",
    "Concepción"   = "hourly_entropy_concepcion.csv",
    "Puerto Montt" = "hourly_entropy_puertomontt.csv"
  )

  entropy_raw_tbl <- purrr::imap_dfr(entropy_files, ~ {
    readr::read_csv(file.path(dir_data, "voronoi_chile", .x), show_col_types = FALSE) %>%
      janitor::clean_names() %>%
      mutate(CITY = .y)
  })

  entropy_reconstructed_tbl <- st_intersection(voronoi_raw_sf, parks_sf) %>%
    mutate(area_weight_voronoi = as.numeric(st_area(.)) / AT) %>%
    st_drop_geometry() %>%
    left_join(entropy_raw_tbl, by = c("ID_OLD" = "antena")) %>%
    filter(!is.na(h)) %>%
    group_by(ID = ID.1, CITY = CITY.x, hour) %>%
    summarise(H = sum(h * area_weight_voronoi, na.rm = TRUE),
              N = sum(n * area_weight_voronoi, na.rm = TRUE))

  saveRDS(entropy_reconstructed_tbl,
          file.path(dir_intermediate, "entropy_reconstructed_tbl.rds"))
}
