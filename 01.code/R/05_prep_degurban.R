rm(list = ls()) # empty workspace
gc() # free-up unused memory

# load packages
library(terra)

#------------------------------------------------------------------------------#
# import data
#------------------------------------------------------------------------------#

# POPULATION - GHSL - 2020 - 3arcsec - WGS84 (GHS-POP-R2023A)

pop <- rast("02.input/population_ghsl/GHS_POP_E2020_GLOBE_R2023A_4326_3ss_V1_0.tif")

# Source: https://doi.org/10.2905/2FF68A52-5B5B-4A22-8F40-C41DA8332CFE

# DEGREE OF URBANISATION - GHSL - 1km - World Mollweide (GHS-SMOD-R2023A)

smod <- rast("02.input/degurban_ghsl/GHS_SMOD_E2020_GLOBE_R2023A_54009_1000_V1_0.tif")

# Source: https://doi.org/10.2905/A0DF7A6F-49DE-46EA-9BDE-563437A6E2BA

#------------------------------------------------------------------------------#
# preprocess degree of urbanisation
#------------------------------------------------------------------------------#

crs(smod) <- 'ESRI:54009' # Mollweide coordinate system (54009), 1000m grid

# degurban classification
levels(smod) <- data.frame(
  id = c(10, 11, 12, 13, 21, 22, 23, 30),
  urb = c(
    "water",
    "very low density rural",
    "low density rural",
    "rural cluster",
    "suburban or peri-urban",
    "semi-dense urban cluster",
    "dense urban cluster",
    "urban centre"
  )
)

# project and resample to population grid
smod_prj <- project(smod, crs(pop))
smod_res <- resample(smod_prj, pop, method = 'near', threads = TRUE)

# reclassify SMOD water cells with population
waterpop <- ifel(smod_res == 10, pop, NA)
waterpop <- subst(waterpop, 0, NA) # population on water cells

# reclassify populated water cells with to near non-water cells, otherwise rural
waterna <- subst(smod_res, 10, NA, raw = TRUE)
waternear <- focal(waterna, 11, "modal", na.policy = "only") # window size 11 ~ 1km
waternear <- subst(waternear, NA, 11) # 11 = vlow density rural
smod_resw <- ifel(is.na(waterpop), smod_res, waternear)
levels(smod_resw) <- levels(smod_res)

# save
writeRaster(smod_resw,
  "03.intermediate/Hazard/GHSL_degurban2_2020_res3arcsec.tif",
  datatype = "INT1U", overwrite = TRUE
)
