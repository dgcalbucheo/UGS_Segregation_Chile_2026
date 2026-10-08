# =====================================================================
# run_all.R  -  Ejecuta todo el análisis, de principio a fin
#
# Uso (desde RStudio, con el proyecto UGS_Segregation.Rproj abierto):
#   source("run_all.R")
#
# o desde la terminal, en la carpeta del proyecto:
#   Rscript run_all.R
#
# Cada etapa es un script independiente en R/ y puede ejecutarse sola.
# Si una etapa falla, las demás se siguen ejecutando y al final se muestra
# un resumen con el error.
# =====================================================================

source(here::here("R", "00_setup.R"))

# Etapa pesada y opcional (necesita los shapefiles crudos, tarda varios minutos)
run_spatial_reconstruction <- FALSE

stages <- c(
  "01_analysis_tables.R",        # tablas analíticas oficiales
  "02_fig2_fig3_ndvi.R",         # Fig. 2 y 3
  "03_fig4_anova_tukey.R",       # Fig. 4, ANOVA y TukeyHSD (Table A.2, CSV)
  "04_fig5_sankey.R",            # Fig. 5 (Sankey, requiere networkD3)
  "05_fig6_entropy_timelines.R", # Fig. 6
  "06_fig7_clusters.R",          # Fig. 7 / dendrogramas
  "07_table1_study_area.R",      # Table 1 (requiere sf, terra)
  "08_appendix_tables.R"         # Table A1 y Tukey en LaTeX
)

if (run_spatial_reconstruction) {
  stages <- c("optional_spatial_reconstruction.R", stages)
}

results <- lapply(stages, function(stage) {
  message("\n>>> ", stage)
  t0 <- Sys.time()
  err <- tryCatch(
    { source(here::here("R", stage), local = new.env()); NULL },
    error = function(e) conditionMessage(e)
  )
  data.frame(
    stage   = stage,
    status  = if (is.null(err)) "OK" else "ERROR",
    seconds = round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1),
    detail  = if (is.null(err)) "" else err
  )
})

summary_tbl <- do.call(rbind, results)
message("\n================ Resumen ================")
print(summary_tbl, row.names = FALSE)

if (any(summary_tbl$status == "ERROR")) {
  warning("Alguna etapa falló; revisar la columna 'detail'.", call. = FALSE)
}
