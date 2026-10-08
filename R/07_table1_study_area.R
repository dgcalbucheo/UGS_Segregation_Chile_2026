# =====================================================================
# 07_table1_study_area.R
# Table 1: descriptores del área de estudio. Cada bloque calcula una parte
# de la tabla; al final se exportan todas las piezas a outputs/tables/.
# (La tabla del manuscrito se terminó de armar y formatear a mano.)
#
#   A. Densidad poblacional por ciudad   <- data/poblaciones.xlsx
#   B. Polígonos urbanos / población 2017 <- data/Mapa_Ciudades_2017
#   C. Clima (WorldClim)                  <- data/worldclim/{tavg,prec}
#   D. Antenas (Voronoi)                  <- data/voronoi_chile/voronoi_ismt_chile.gpkg
#   E. NDVI de los parques                <- parks_analysis_tbl
#   F. ISMT por ciudad                    <- data/UGS_cartography.gpkg (capa "ismt")
#   G. Área de parques                    <- Table_parks.csv (AREA) *
#
# * En el .qmd original esta parte usaba la geometría de los parques
#   (parks_sf$AT); requiere R/optional_spatial_reconstruction.R. Si existe
#   outputs/intermediate/park_area_tbl.rds se usa; si no, se usa AREA.
#
# Requiere: sf, terra, readxl
# =====================================================================

source(here::here("R", "00_setup.R"))
ugs_load(c("dplyr", "tidyr", "readr", "readxl", "sf", "terra"))

sf::sf_use_s2(FALSE)

tables <- load_analysis_tables()
parks_analysis_tbl <- tables$parks

city_order <- function(x) arrange(x, factor(.data[[names(x)[1]]], levels = city_levels))

# ---------------------------------------------------------------------
# A. Densidad poblacional (población total y área comunal)
# ---------------------------------------------------------------------
density_raw <- readxl::read_excel(file.path(dir_data, "poblaciones.xlsx"))
names(density_raw) <- gsub("[^a-z0-9]+", "_", tolower(names(density_raw)))  # = janitor::clean_names()

density_tbl <- density_raw %>%
  mutate(
    area_km2 = poblacion / densidad_reportada,
    city = case_when(
      comuna == "antofagasta" ~ "Antofagasta",
      comuna %in% c("la serena", "coquimbo") ~ "La Serena",
      comuna %in% c("valparaiso", "viña del mar", "quilpue", "villa alemana") ~ "Valparaíso",
      comuna %in% c("santiago (provincia)", "colina", "lampa", "padre hurtado",
                    "peñaflor", "pirque", "puente alto", "san bernardo") ~ "Santiago",
      comuna %in% c("concepcion", "talcahuano", "hualpen", "penco",
                    "coronel", "san pedro de la paz") ~ "Concepción",
      comuna %in% c("puerto montt", "puerto varas") ~ "Puerto Montt",
      TRUE ~ NA_character_
    )
  )

stopifnot(!anyNA(density_tbl$city))   # todas las comunas deben asignarse

city_density <- density_tbl %>%
  group_by(city) %>%
  summarise(
    population = sum(poblacion, na.rm = TRUE),
    area_km2   = sum(area_km2, na.rm = TRUE),
    population_density = population / area_km2
  ) %>%
  city_order()

# ---------------------------------------------------------------------
# B. Polígonos urbanos del Censo 2017
# ---------------------------------------------------------------------
ciudades <- sf::st_read(
  file.path(dir_data, "Mapa_Ciudades_2017", "Ciudades_2017.shp"),
  quiet = TRUE
)

# El .qmd original escribía "QULICURA" (la comuna es QUILICURA), así que Quilicura
# (209,676 hab.) quedaba fuera del polígono urbano de Santiago. Se corrige por
# defecto: los valores de clima de la Tabla 1 (15.0 °C, [8.5, 21.6] °C, 434 mm
# para Santiago) no cambian a la precisión publicada. Poner fix_quilicura <- FALSE
# (antes de correr) para reproducir exactamente el comportamiento original.
if (!exists("fix_quilicura")) fix_quilicura <- TRUE
quilicura_name <- if (fix_quilicura) "QUILICURA" else "QULICURA"

santiago_comunas <- c(
  "CERRILLOS", "CERRO NAVIA", "CONCHALÍ", "EL BOSQUE", "ESTACIÓN CENTRAL",
  "HUECHURABA", "INDEPENDENCIA", "LA CISTERNA", "LA FLORIDA", "LA GRANJA",
  "LA PINTANA", "LA REINA", "LAS CONDES", "LO BARNECHEA", "LO ESPEJO",
  "LO PRADO", "MACUL", "MAIPÚ", "ÑUÑOA", "PEDRO AGUIRRE CERDA", "PEÑALOLÉN",
  "PROVIDENCIA", "PUDAHUEL",
  quilicura_name,   # "QUILICURA"; con fix_quilicura <- FALSE: "QULICURA" (typo original)
  "QUINTA NORMAL", "RECOLETA", "RENCA", "SAN JOAQUÍN", "SAN MIGUEL",
  "SAN RAMÓN", "SANTIAGO", "VITACURA",
  "COLINA", "LAMPA", "PADRE HURTADO", "PEÑAFLOR", "PIRQUE", "PUENTE ALTO",
  "SAN BERNARDO"
)

ciudades_study <- ciudades %>%
  mutate(
    CITY = case_when(
      NOM_COMUNA == "ANTOFAGASTA" ~ "Antofagasta",
      NOM_COMUNA %in% c("LA SERENA", "COQUIMBO") ~ "La Serena",
      NOM_COMUNA %in% c("VALPARAÍSO", "VIÑA DEL MAR", "QUILPUÉ", "VILLA ALEMANA") ~ "Valparaíso",
      NOM_COMUNA %in% santiago_comunas ~ "Santiago",
      NOM_COMUNA %in% c("CONCEPCIÓN", "TALCAHUANO", "HUALPÉN", "PENCO",
                        "CORONEL", "SAN PEDRO DE LA PAZ") ~ "Concepción",
      NOM_COMUNA %in% c("PUERTO MONTT", "PUERTO VARAS") ~ "Puerto Montt",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(CITY))

# Aviso: comunas de la lista que no aparecen en el shapefile (p. ej. por typos)
missing_communes <- setdiff(santiago_comunas, ciudades$NOM_COMUNA)
if (length(missing_communes) > 0) {
  warning("Comunas de Santiago no encontradas en Ciudades_2017.shp: ",
          paste(missing_communes, collapse = ", "), call. = FALSE)
}

ciudades_ugs <- ciudades_study %>%
  group_by(CITY) %>%
  summarise(
    population_urban_2017 = sum(TOT_PERSON, na.rm = TRUE),
    urban_area_m2 = sum(as.numeric(st_area(geometry)), na.rm = TRUE)
  ) %>%
  mutate(
    urban_area_km2    = urban_area_m2 / 1e6,
    urban_density_km2 = population_urban_2017 / urban_area_km2
  )

urban_summary <- ciudades_ugs %>% st_drop_geometry() %>% city_order()

# ---------------------------------------------------------------------
# C. Clima (WorldClim, extraído sobre los polígonos urbanos)
# ---------------------------------------------------------------------
tavg <- terra::rast(list.files(file.path(dir_data, "worldclim", "tavg"),
                               pattern = "\\.tif$", full.names = TRUE))
prec <- terra::rast(list.files(file.path(dir_data, "worldclim", "prec"),
                               pattern = "\\.tif$", full.names = TRUE))

tavg_annual <- terra::mean(tavg)   # temperatura media anual
prec_annual <- sum(prec)           # precipitación total anual

ciudades_ugs_wgs84 <- sf::st_transform(ciudades_ugs, 4326)
urban_vect <- terra::vect(ciudades_ugs_wgs84)

extract_mean <- function(r) terra::extract(r, urban_vect, fun = mean, na.rm = TRUE)[, 2]
extract_monthly <- function(r) {
  sapply(seq_len(terra::nlyr(r)), function(i) extract_mean(r[[i]]))
}

temp_monthly <- extract_monthly(tavg)
prec_monthly <- extract_monthly(prec)
if (is.null(dim(temp_monthly))) temp_monthly <- matrix(temp_monthly, ncol = terra::nlyr(tavg))
if (is.null(dim(prec_monthly))) prec_monthly <- matrix(prec_monthly, ncol = terra::nlyr(prec))

climate_city <- tibble(
  CITY = ciudades_ugs_wgs84$CITY,
  mean_annual_temperature   = extract_mean(tavg_annual),
  min_monthly_temperature   = apply(temp_monthly, 1, min, na.rm = TRUE),
  max_monthly_temperature   = apply(temp_monthly, 1, max, na.rm = TRUE),
  annual_precipitation      = extract_mean(prec_annual),
  min_monthly_precipitation = apply(prec_monthly, 1, min, na.rm = TRUE),
  max_monthly_precipitation = apply(prec_monthly, 1, max, na.rm = TRUE)
) %>%
  city_order()

# ---------------------------------------------------------------------
# D. Antenas (polígonos Voronoi del dataset de movilidad)
# ---------------------------------------------------------------------
f_voronoi <- file.path(dir_data, "voronoi_chile", "voronoi_ismt_chile.gpkg")
antennas_city <- NULL
if (file.exists(f_voronoi)) {
  voronoi_raw_sf <- sf::st_read(f_voronoi, quiet = TRUE)
  # La columna City viene por conurbación ("gran santiago", "antofagasta", ...)
  antennas_city <- voronoi_raw_sf %>%
    st_drop_geometry() %>%
    mutate(CITY = recode(
      City,
      "antofagasta"       = "Antofagasta",
      "gran la serena"    = "La Serena",
      "gran valparaiso"   = "Valparaíso",
      "gran santiago"     = "Santiago",
      "gran concepcion"   = "Concepción",
      "gran puerto montt" = "Puerto Montt",
      .default = NA_character_
    )) %>%
    filter(!is.na(CITY)) %>%
    distinct(ID, CITY) %>%
    count(CITY, name = "antennas") %>%
    city_order()
} else {
  message("D. Antenas: no se encontró ", f_voronoi, " (datos de movilidad, no versionados).")
}

# ---------------------------------------------------------------------
# E. NDVI de los parques
# ---------------------------------------------------------------------
table_1_ndvi_tbl <- parks_analysis_tbl %>%
  group_by(CITY) %>%
  summarise(
    mean_ndvi = mean(MEAN_NDVI, na.rm = TRUE),
    min_ndvi  = min(MEAN_NDVI, na.rm = TRUE),
    max_ndvi  = max(MEAN_NDVI, na.rm = TRUE)
  ) %>%
  city_order()

# ---------------------------------------------------------------------
# F. ISMT por ciudad (media ponderada por población de las zonas)
# ---------------------------------------------------------------------
ismt_official_sf <- sf::st_read(file.path(dir_data, "UGS_cartography.gpkg"),
                                layer = "ismt", quiet = TRUE)

ismt_city <- ismt_official_sf %>%
  st_drop_geometry() %>%
  mutate(population = Q1 + Q2 + Q3 + Q4 + Q5) %>%
  group_by(city) %>%
  summarise(
    mean_ismt = weighted.mean(ismtpn, w = population, na.rm = TRUE),
    min_ismt  = min(ismtpn, na.rm = TRUE),
    max_ismt  = max(ismtpn, na.rm = TRUE),
    total_population = sum(population),
    n_zones = n()
  ) %>%
  city_order()

# ---------------------------------------------------------------------
# G. Área de parques
# ---------------------------------------------------------------------
f_area <- file.path(dir_intermediate, "park_area_tbl.rds")
park_area_src <- if (file.exists(f_area)) {
  readRDS(f_area) %>% rename(park_area_m2 = AT) %>%
    left_join(distinct(parks_analysis_tbl, ID, CITY), by = "ID")
} else {
  # Sin reconstrucción espacial: se calcula desde la capa "parks" de
  # UGS_cartography.gpkg, igual que el .qmd original (AP = st_area de cada
  # polígono; AT = suma de AP por ID). Reproduce el nº de parques de la
  # Tabla 1 y sus áreas con diferencias <= 0.3 %.
  message("G. park_area_tbl.rds no existe: se calcula el área desde la capa 'parks' del gpkg.")
  parks_gpkg <- sf::st_read(file.path(dir_data, "UGS_cartography.gpkg"),
                            layer = "parks", quiet = TRUE)
  ap <- tryCatch(
    as.numeric(sf::st_area(parks_gpkg)),
    error = function(e) {            # s2 apagado necesita lwgeom; si falta, usar s2
      sf::sf_use_s2(TRUE)
      as.numeric(sf::st_area(parks_gpkg))
    }
  )
  parks_gpkg %>%
    sf::st_drop_geometry() %>%
    mutate(ID = as.character(ID_TEXT), CITY = as.character(city), AP = ap) %>%
    group_by(CITY, ID) %>%
    summarise(park_area_m2 = sum(AP, na.rm = TRUE), .groups = "drop")
}

table_1_parks_tbl <- park_area_src %>%
  group_by(CITY) %>%
  summarise(
    parks = n_distinct(ID),
    total_park_area_ha = sum(park_area_m2, na.rm = TRUE) / 10000,
    mean_park_area_ha  = mean(park_area_m2, na.rm = TRUE) / 10000
  ) %>%
  city_order()

# ---------------------------------------------------------------------
# Exportar
# ---------------------------------------------------------------------
save_table(city_density,      "table1_a_population_density.csv")
save_table(urban_summary,     "table1_b_urban_polygons.csv")
save_table(climate_city,      "table1_c_climate.csv")
if (!is.null(antennas_city)) save_table(antennas_city, "table1_d_antennas.csv")
save_table(table_1_ndvi_tbl,  "table1_e_ndvi.csv")
save_table(ismt_city,         "table1_f_ismt.csv")
save_table(table_1_parks_tbl, "table1_g_park_area.csv")

print(climate_city)
print(ismt_city)
