# =====================================================================
# 08_appendix_tables.R
# Apéndice:
#   Table A1 - ANOVA de una vía (NDVI ~ ISMT_LEVEL) por ciudad
#   Table A2 - Tukey post-hoc (emmeans) en formato LaTeX, para el manuscrito
#
# (La misma comparación de Tukey en CSV, vía TukeyHSD(), la genera
#  R/03_fig4_anova_tukey.R. Ambos métodos dan los mismos contrastes.)
#
# Entradas : outputs/intermediate/parks_analysis_tbl.rds
# Salidas  : outputs/tables/Table_A1_ANOVA_NDVI_ISMT.csv
#            outputs/tables/Table_A2_Tukey_emmeans_NDVI_ISMT.csv
#            outputs/tables/Table_A2_Tukey_NDVI_ISMT.tex
#
# Requiere: emmeans
# =====================================================================

source(here::here("R", "00_setup.R"))
ugs_load(c("dplyr", "tidyr", "tibble", "readr", "purrr", "emmeans"))

parks_analysis_tbl <- load_analysis_tables()$parks

appendix_data <- parks_analysis_tbl %>%
  filter(!is.na(CITY), !is.na(MEAN_NDVI), !is.na(ISMT_LEVEL)) %>%
  mutate(
    CITY       = factor(CITY, levels = city_levels),
    ISMT_LEVEL = factor(ISMT_LEVEL, levels = ismt_levels)
  )

# ---------------------------------------------------------------------
# Table A1: ANOVA por ciudad
# ---------------------------------------------------------------------
anova_ndvi_tbl <- appendix_data %>%
  group_by(CITY) %>%
  group_modify(~ {
    aov_tbl <- anova(lm(MEAN_NDVI ~ ISMT_LEVEL, data = droplevels(.x)))
    tibble(
      term    = rownames(aov_tbl),
      df      = aov_tbl$Df,
      sum_sq  = aov_tbl$`Sum Sq`,
      mean_sq = aov_tbl$`Mean Sq`,
      f_value = aov_tbl$`F value`,
      p_value = aov_tbl$`Pr(>F)`
    )
  }) %>%
  ungroup()

save_table(anova_ndvi_tbl, "Table_A1_ANOVA_NDVI_ISMT.csv")

# Versión formateada (se ve en el reporte .qmd)
anova_ndvi_tbl_formatted <- anova_ndvi_tbl %>%
  mutate(
    sum_sq  = round(sum_sq, 4),
    mean_sq = round(mean_sq, 4),
    f_value = round(f_value, 3),
    p_value = case_when(
      is.na(p_value)  ~ NA_character_,
      p_value < 0.001 ~ "<0.001",
      TRUE            ~ as.character(round(p_value, 4))
    )
  ) %>%
  rename(City = CITY, Term = term, Df = df, `Sum Sq` = sum_sq,
         `Mean Sq` = mean_sq, `F-value` = f_value, `p-value` = p_value)

# ---------------------------------------------------------------------
# Table A2: Tukey con emmeans
# ---------------------------------------------------------------------
tukey_latex_tbl <- appendix_data %>%
  group_by(CITY) %>%
  group_modify(~ {
    d <- droplevels(.x)
    if (nlevels(d$ISMT_LEVEL) < 2) return(tibble())

    m1 <- lm(MEAN_NDVI ~ ISMT_LEVEL, data = d)

    emmeans(m1, pairwise ~ ISMT_LEVEL, adjust = "tukey")$contrasts %>%
      summary(infer = c(TRUE, TRUE)) %>%
      as.data.frame() %>%
      tidyr::separate(contrast, into = c("I", "J"), sep = " - ", remove = FALSE) %>%
      transmute(I, J, diff = estimate, lower = lower.CL, upper = upper.CL, p_adj = p.value)
  }) %>%
  ungroup()

save_table(tukey_latex_tbl, "Table_A2_Tukey_emmeans_NDVI_ISMT.csv")

# ---- Formato LaTeX -----------------------------------------------------------
city_labels_tex <- c(
  "Antofagasta"  = "\\textbf{A} - Antofagasta",
  "La Serena"    = "\\textbf{B} - La Serena",
  "Valparaíso"   = "\\textbf{C} - Valparaíso",
  "Santiago"     = "\\textbf{D} - Santiago",
  "Concepción"   = "\\textbf{E} - Concepción",
  "Puerto Montt" = "\\textbf{F} - Puerto Montt"
)

fmt_num   <- function(x) sprintf("%.3f", x)
fmt_sig   <- function(diff, p) ifelse(p < 0.05, paste0("\\textbf{", fmt_num(diff), "$^*$}"), fmt_num(diff))
fmt_group <- function(x, p) ifelse(p < 0.05, paste0("\\textbf{", x, "}"), x)
fmt_ci    <- function(lower, upper, p) {
  ci <- paste0("(", fmt_num(lower), ", ", fmt_num(upper), ")")
  ifelse(p < 0.05, paste0("\\textbf{", ci, "}"), ci)
}

tukey_latex_lines <- tukey_latex_tbl %>%
  mutate(
    city_label = city_labels_tex[as.character(CITY)],
    I_fmt    = fmt_group(I, p_adj),
    J_fmt    = fmt_group(J, p_adj),
    diff_fmt = fmt_sig(diff, p_adj),
    ci_fmt   = fmt_ci(lower, upper, p_adj)
  ) %>%
  group_by(CITY) %>%
  group_split() %>%
  map_chr(function(df) {
    rows <- vapply(seq_len(nrow(df)), function(i) {
      city_cell <- if (i == 1) df$city_label[i] else ""
      i_cell    <- if (i == 1 || df$I[i] != df$I[i - 1]) df$I_fmt[i] else ""
      paste0(city_cell, " & ", i_cell, " & ", df$J_fmt[i], " & ",
             df$diff_fmt[i], " & ", df$ci_fmt[i], " \\\\")
    }, character(1))
    paste0(paste(rows, collapse = "\n"), "\n\\hline")
  })

tukey_latex <- paste0(
"\\begin{table}[!htb]
  \\caption{Tukey post-hoc analysis shows the mean NDVI differences between ISMT quartiles. Significant comparisons between groups I and J are highlighted and marked by an asterisk (\\ie $p < 0.05$).\\label{apxTable:TukeyTable}}
  \\footnotesize
  \\centering
  \\begin{tabularx}{\\linewidth}{l l l r r}
  \\\\[0.2mm]
  \\hline
  \\multirow{2}{*}{\\textbf{City}} & & & \\textbf{Mean difference} & 95\\% Confidence Interval \\\\
  & (I) ISMT Quartile & (J) ISMT Quartile & (I - J) $\\Delta$ NDVI & (lower, upper)\\\\
  \\hline
",
  paste(tukey_latex_lines, collapse = "\n\n"),
"
  \\hline
  \\end{tabularx}
\\end{table}
"
)

writeLines(tukey_latex, file.path(dir_tables, "Table_A2_Tukey_NDVI_ISMT.tex"), useBytes = TRUE)
message("Tabla exportada: outputs/tables/Table_A2_Tukey_NDVI_ISMT.tex")
