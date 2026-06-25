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
- reconstruction of NDVI and ISMT metrics;
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
  - `UGS_cartography.gpkg`: Official supplementary cartographic package containing the `parks`, `ismt`, and `voronoi` layers used for spatial documentation and reproducibility.

## Sources

- Urban green space database – Public park and urban green space cartography used as the base layer for the study: https://storymaps.arcgis.com/stories/391dac6ee0c3438fbf186aed3ea1cff1
- Territorial Socio-Material Index (ISMT 2022) – Observatorio de Ciudades UC: https://ideocuc-ocuc.hub.arcgis.com/maps/c83a1ea2c31b4850b65a481b21e4919f/about
- 2017 Chilean Population and Housing Census – National Institute of Statistics (INE), Chile: https://www.ine.gob.cl/
- Landsat 8 satellite imagery – Google Earth Engine Data Catalog: https://earthengine.google.com/
- WorldClim Version 2 – Global climate data: https://www.worldclim.org/
- 2017 Chilean Population and Housing Census.
- Derived mobility and spatial datasets – Hourly park social entropy and Voronoi polygons derived from anonymized mobile phone records (XDR, MOVISTAR) are available in the repository under data/.

---

## Supporting Information

The repository reproduces the complete analytical workflow described in the manuscript, 
including the supplementary analyses (ANOVA, Tukey tests, dendrograms) and the generation of 
the supplementary spatial layers accompanying the publication.



---

## Workflow

The analysis is organized into six sections.

### 1. Data loading

Loads:

- official park inventory
- ISMT census data
- NDVI rasters
- WorldClim layers
- mobile phone mobility data
- official analytical tables

---

### 2. Data preparation

Includes reconstruction of:

- park attributes
- ISMT
- NDVI
- entropy
- analytical categories

Each reconstruction is validated against the original analytical tables used in the manuscript.

---

### 3. Results

Reproduces the analyses presented in the manuscript:

- NDVI distributions
- latitudinal gradient
- NDVI × ISMT
- Sankey diagrams
- entropy timelines
- hierarchical clustering

---

### 4. Table 1

Reconstructs the complete study-area summary table from the original datasets.

Unlike the original script, park descriptors are computed using unique park IDs rather than individual polygons, ensuring consistency with the unit of analysis adopted throughout the study.

---

### 5. Appendix

Includes the supplementary statistical analyses:

- ANOVA tables
- Tukey post-hoc tests
- dendrogram example

---

### 6. Supplementary material

Exports the supplementary spatial products accompanying the manuscript, including:

- GeoPackage containing:
    - parks
    - ISMT
    - Voronoi
- NDVI rasters
- supplementary README

---

# Data availability

Most datasets used in this repository are publicly available.

| Dataset | Included |
|----------|-----------|
| Parks (INE) | No |
| ISMT | No |
| NDVI rasters | Yes |
| WorldClim | No |
| Mobile phone XDR | No |
| Voronoi | No |
| Census-derived population table | Yes |

The excluded datasets cannot be redistributed because they are either distributed by third parties or subject to data-sharing agreements.

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
