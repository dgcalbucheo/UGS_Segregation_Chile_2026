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

- `UGS_pipeline.qmd`: Complete reproducible workflow used in the manuscript, including data loading, data preparation, statistical analyses, figures, tables, and supplementary material.

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
- Landsat 8 satellite imagery – Google Earth Engine Data Catalog: [https://earthengine.google.com/](https://developers.google.com/earth-engine/datasets/catalog/LANDSAT_LC08_C02_T1_L2?hl=es-419)
- WorldClim Version 2 – Global climate data: https://www.worldclim.org/
- Derived mobility and spatial datasets – Hourly park social entropy and the associated Voronoi polygons derived from anonymized mobile phone records (XDR, MOVISTAR) are available in [`mobility_supplementary.zip`](data/mobility_supplementary.zip).
---

## Supporting Information

including the supplementary analyses (ANOVA, Tukey tests, dendrograms) and the supplementary cartographic material accompanying the publication.

---

## Workflow

The analytical workflow is organized into six sections:

1. **Data loading** – Imports all spatial, environmental, mobility, and analytical datasets.

2. **Data preparation** – Reconstructs and validates park attributes, ISMT, NDVI, entropy, and analytical classifications.

3. **Results** – Reproduces all statistical analyses and figures presented in the manuscript.

4. **Table 1** – Reconstructs the study-area summary table from the original datasets.

5. **Appendix** – Generates the supplementary statistical analyses (ANOVA, Tukey tests, and dendrograms).

6. **Supplementary material** – Includes the official cartographic products and supplementary datasets accompanying the manuscript.

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


Original mobile phone XDR records and the original public park database are not redistributed because they are subject to third-party licensing and data-sharing agreements. This repository instead provides the processed datasets required to reproduce the analyses presented in the manuscript.

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
