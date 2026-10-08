# =====================================================================
# 00_setup.R
# Configuración compartida: paquetes, opciones, rutas, constantes y
# funciones auxiliares. Todos los scripts de R/ empiezan con:
#
#   source(here::here("R", "00_setup.R"))
#
# Es idempotente: se puede cargar varias veces sin efectos secundarios.
# =====================================================================

if (!requireNamespace("here", quietly = TRUE)) {
  stop("Falta el paquete 'here'. Instalar con install.packages(\"here\")",
       call. = FALSE)
}

# ---------------------------------------------------------------------
# Paquetes
# ---------------------------------------------------------------------
# Cada script declara solo los paquetes que necesita con ugs_load().
# Si falta alguno, el error dice exactamente cuáles instalar.
ugs_load <- function(pkgs) {
  missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) > 0) {
    stop(
      "Faltan paquetes: ", paste(missing, collapse = ", "), "\n",
      "Instalar con: install.packages(c(",
      paste0('"', missing, '"', collapse = ", "), "))",
      call. = FALSE
    )
  }
  suppressPackageStartupMessages(
    invisible(lapply(pkgs, library, character.only = TRUE))
  )
}

# ---------------------------------------------------------------------
# Opciones globales
# ---------------------------------------------------------------------
options(
  scipen = 999,
  dplyr.summarise.inform = FALSE
)

# ---------------------------------------------------------------------
# Rutas (todas relativas a la raíz del proyecto, gracias a here)
# ---------------------------------------------------------------------
dir_data         <- here::here("data")
dir_outputs      <- here::here("outputs")
dir_figures      <- here::here("outputs", "figures")
dir_tables       <- here::here("outputs", "tables")
dir_intermediate <- here::here("outputs", "intermediate")  # objetos .rds entre etapas
dir_supplementary <- here::here("outputs", "supplementary")

invisible(lapply(
  c(dir_figures, dir_tables, dir_intermediate, dir_supplementary),
  dir.create, recursive = TRUE, showWarnings = FALSE
))

# ---------------------------------------------------------------------
# Constantes del estudio
# ---------------------------------------------------------------------
city_levels <- c(
  "Antofagasta", "La Serena", "Valparaíso",
  "Santiago", "Concepción", "Puerto Montt"
)

# Nombres de ciudad usados en las tablas oficiales -> nombres del manuscrito
city_recode <- c(
  "Coquimbo-La Serena" = "La Serena",
  "Gran Valparaíso"    = "Valparaíso",
  "Gran Santiago"      = "Santiago",
  "Gran Concepción"    = "Concepción"
)

ismt_levels <- c("Low", "Medium Low", "Medium High", "High")

greenness_levels <- c("Low Greenness", "Medium Greenness", "High Greenness")

city_colors <- c(
  "Antofagasta"  = "#66c2a5",
  "La Serena"    = "#fc8d62",
  "Valparaíso"   = "#8da0cb",
  "Concepción"   = "#a6d854",
  "Santiago"     = "#e78ac3",
  "Puerto Montt" = "#d8b60a"
)

# Proyección métrica usada para áreas y extracción de NDVI
crs_utm <- 32719

# ---------------------------------------------------------------------
# Funciones auxiliares
# ---------------------------------------------------------------------
as_city_factor <- function(x, ordered = TRUE) {
  factor(x, levels = city_levels, ordered = ordered)
}

as_ismt_factor <- function(x, ordered = TRUE) {
  factor(x, levels = ismt_levels, ordered = ordered)
}

# Slug sin tildes ni espacios, para nombres de archivo ("La Serena" -> "la_serena")
city_slug <- function(x) {
  gsub(" ", "_", chartr("áéíóúñ", "aeioun", tolower(x)), fixed = TRUE)
}

# Guarda un ggplot en PNG y PDF con el mismo nombre base.
save_fig <- function(plot, name, width, height, dpi = 300) {
  ggplot2::ggsave(
    file.path(dir_figures, paste0(name, ".png")),
    plot = plot, width = width, height = height, dpi = dpi,
    bg = "white"   # evita PNG con fondo transparente (theme_minimal)
  )
  grDevices::cairo_pdf(
    file.path(dir_figures, paste0(name, ".pdf")),
    width = width, height = height
  )
  print(plot)
  grDevices::dev.off()
  invisible(file.path(dir_figures, name))
}

# Escribe un CSV en outputs/tables y avisa dónde quedó.
save_table <- function(x, filename) {
  path <- file.path(dir_tables, filename)
  readr::write_csv(x, path)
  message("Tabla exportada: ", sub(paste0(here::here(), "/"), "", path, fixed = TRUE))
  invisible(path)
}

# ---------------------------------------------------------------------
# Tablas analíticas oficiales (parks + entropy), listas para usar
# ---------------------------------------------------------------------
# Las construye 01_analysis_tables.R y las guarda en outputs/intermediate/.
# Si todavía no existen, se generan automáticamente.
load_analysis_tables <- function() {
  f_parks   <- file.path(dir_intermediate, "parks_analysis_tbl.rds")
  f_entropy <- file.path(dir_intermediate, "entropy_analysis_tbl.rds")

  if (!file.exists(f_parks) || !file.exists(f_entropy)) {
    source(here::here("R", "01_analysis_tables.R"), local = TRUE)
  }

  list(
    parks   = readRDS(f_parks),
    entropy = readRDS(f_entropy)
  )
}
