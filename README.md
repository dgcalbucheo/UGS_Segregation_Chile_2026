Repository accompanying the manuscript:

# Socioeconomic Segregation and Park Greenness: Insights Across a Strong Latitudinal Gradient


Diego Calbucheo $^{a}$ & Horacio Samaniego $^{a,b,*}$

$^{a}$ Ecoinformatica lab, Universidad Austral de Chile, Valdivia, Chile; 

$^{b}$ Instituto de Sistemas Complejos de Valparaı́so, Subida Artillerı́a 470, Valparaı́so, 2360448, Chile.

$^{*}$ Corresponding author (horacio@ecoinformatica.cl)


## Abstract

Urban Green Spaces (UGS) provide critical ecosystem services including temperature regulation, pollution reduction, 
and mental health benefits. While their unequal distribution is globally documented, Latin American research typically 
relies on static accessibility metrics within single metropolitan areas. This overlooks the dynamic social usage of these 
spaces across varying climates. To address this gap, we integrated Landsat 8 remote sensing, census data, and massive 
mobile phone records (XDR) to analyze green space segregation across six Chilean conurbations. These cities span a 
latitudinal gradient from Antofagasta (23°S) to Puerto Montt (41°S). We quantified vegetation vigor 
using the Normalized Difference Vegetation Index (NDVI) and characterized neighborhood socioeconomic status (SES) using 
a multidimensional index. We also calculated social entropy from mobile records to dynamically measure daily social 
mixing within parks. Our results reveal a persistent ``green divide'' regardless of local climate. Parks in lower-SES 
neighborhoods are significantly less green and exhibit lower social mixing than those in affluent areas. Conversely, 
parks in affluent neighborhoods attract a more diverse user base throughout the day. These findings indicate that 
structural and administrative factors are the primary drivers of green inequality rather than climatic constraints. 
Equitable urban planning must evolve beyond simple provision targets to prioritize the quality and social integration 
capacity of urban green spaces.


## Repository overview

This repository contains the complete analytical workflow used to characterize socioeconomic inequalities in urban green spaces across six Chilean conurbations.

The pipeline reconstructs the methodology used in the manuscript, including:

- preparation of spatial datasets;
- reconstruction and validation of NDVI metrics;
- reconstruction and validation of ISMT metrics;
- reconstruction of entropy-based segregation analyses;
- statistical analyses (ANOVA and Tukey);
- generation of the main figures;
- generation of Table 1;
- supplementary analyses.

---

## Repository Structure

```
UGS_Segregation/
├── run_all.R                      # runs the whole analysis, start to finish
├── R/
│   ├── 00_setup.R                 # packages, paths, constants, helper functions
│   ├── 01_analysis_tables.R       # official tables -> parks/entropy analysis tables
│   ├── 02_fig2_fig3_ndvi.R        # Fig. 2, Fig. 3
│   ├── 03_fig4_anova_tukey.R      # Fig. 4, ANOVA, TukeyHSD (Table A.2, CSV/TXT)
│   ├── 04_fig5_sankey.R           # Fig. 5 (Sankey diagrams)
│   ├── 05_fig6_entropy_timelines.R# Fig. 6
│   ├── 06_fig7_clusters.R         # Fig. 7 / dendrograms
│   ├── 07_table1_study_area.R     # Table 1 components
│   ├── 08_appendix_tables.R       # Table A1 (ANOVA) and Tukey in LaTeX
│   └── optional_spatial_reconstruction.R  # heavy, optional: rebuilds ISMT/NDVI from raw spatial data and validates
├── reports/UGS_report.qmd         # light Quarto report that runs the scripts and shows results
├── data/                          # input datasets (see below)
├── outputs/                       # generated figures/tables (git-ignored)
└── Appendix.pdf
```

How to run: open `UGS_Segregation.Rproj` in RStudio and run `source("run_all.R")`.
Each script in `R/` can also be run on its own. To render the report:
`quarto render reports/UGS_report.qmd`.

- `data/`: Input datasets used throughout the analysis.
  - `ISMT_2022_actualizado/`: Territorial Socio-Material Index (ISMT).
  - `NDVI_rasters_2016/`: Landsat 8 NDVI rasters used in the study.
  - `worldclim/`: Climatic variables (temperature and precipitation).
  - `Table_parks.csv`: Official analytical park table.
  - `Table_entropy.csv`: Official analytical entropy table.
  - `UGS_cartography.gpkg`: Official supplementary cartographic package containing the park, ISMT, and Voronoi layers used throughout the manuscript.
  - `mobility_supplementary.zip`: Supplementary hourly park social entropy datasets derived from anonymized mobile phone records.

- `Appendix.pdf`: Supplementary appendix corresponding to the manuscript.

## Data and Sources

- Urban green space database – Public park and urban green space cartography used as the base layer for the study: https://storymaps.arcgis.com/stories/391dac6ee0c3438fbf186aed3ea1cff1
- Territorial Socio-Material Index (ISMT 2022) – Observatorio de Ciudades UC: https://ideocuc-ocuc.hub.arcgis.com/maps/c83a1ea2c31b4850b65a481b21e4919f/about
- 2017 Chilean Population and Housing Census – National Institute of Statistics (INE), Chile: https://www.ine.gob.cl/
- Landsat 8 satellite imagery – Google Earth Engine Data Catalog: https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_LC08_C02_T1_L2?hl=es-419
- WorldClim Version 2 – Global climate data: https://www.worldclim.org/
- Derived mobility and spatial datasets – Hourly park social entropy and the associated Voronoi polygons derived from anonymized mobile phone records (XDR, MOVISTAR) are available in [`mobility_supplementary.zip`](data/mobility_supplementary.zip).
---

## Supporting Information

The supporting information (`Appendix.pdf`) includes the supplementary analyses (ANOVA, Tukey tests, dendrograms) and the supplementary cartographic material accompanying the publication.

---

## Workflow

The manuscript results are computed from the official analytical tables (`Table_parks.csv`, `Table_entropy.csv`), so the main analysis is light and fast. The scripts in `R/` run in order:

1. **Setup and analysis tables** (`00`, `01`) – shared configuration and the analytical tables.
2. **Results** (`02`-`06`) – Figs. 2-7, ANOVA and Tukey tests.
3. **Table 1** (`07`) – study-area descriptors.
4. **Appendix** (`08`) – ANOVA and Tukey tables.
5. **Optional spatial reconstruction** – rebuilds ISMT, NDVI and entropy from raw spatial data and validates them against the official tables.

## Reproducibility notes

The pipeline reproduces the manuscript's ANOVA, Tukey tests (Table A.2), Fig. 3
and Table 1 from the official analytical tables. The following points are
documented for transparency:

- **Fig. 5 (Sankey).** The published figure was assembled and styled manually
  and is not regenerated by this pipeline. `R/04_fig5_sankey.R` produces
  interactive Sankey diagrams from `data/Table_parks.csv`. For Santiago, the
  link counts differ from the published figure: Low SES 1629/1200/514 (total
  3343) in the figure vs. 1671/1291/551 (3513) in the repository; High SES
  121/172/1183 (1476) vs. 121/174/1225 (1520). The repository values are those
  used in the ANOVA.
- **Table 1, population.** Population values (x10^3) are fixed values carried
  over from an earlier version of the analysis; they are not recomputed here.
  Population density is computed from `data/poblaciones.xlsx`.
- **Table 1, users by SES.** These rows are not recomputed by this pipeline.
- **Commune name.** The original script misspelled "QUILICURA" as "QULICURA",
  which left that commune out of the Santiago urban polygon used for the
  climate values. The pipeline corrects it (`fix_quilicura <- TRUE`); the
  climate values of Table 1 are unchanged at the published precision. Set
  `fix_quilicura <- FALSE` to reproduce the original behavior.

---

# Data availability

Most datasets required to reproduce the analyses are included in this repository or are publicly available from their original sources.

| Dataset                         | Included |
| ------------------------------- | -------- |
| Original public park database   | No       |
| ISMT 2022                       | Yes      |
| NDVI rasters                    | Yes      |
| WorldClim                       | Yes      |
| Original mobile phone XDR       | No       |
| Derived hourly entropy          | Yes      |
| Supplementary cartography       | Yes      |
| Census-derived population table | Yes      |


Original mobile phone XDR records cannot be redistributed because they are subject to third-party licensing and data-sharing agreements. The original public park database can be obtained from the source referenced above but is not included in this repository to reduce repository size. Processed datasets required to reproduce the analyses are provided instead.

---

# Citation

If you use this repository, please cite:

Calbucheo D. & Samaniego, H.

Socioeconomic Segregation and Park Greenness:
Insights Across a Strong Latitudinal Gradient.

*(to be updated upon publication)*

---

# Funding Information

- ANID/FONDECYT/1211490 -- Horacio Samaniego
