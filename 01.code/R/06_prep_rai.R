rm(list = ls()) # empty workspace
gc() # free-up unused memory

# load packages
library(terra)

#------------------------------------------------------------------------------#
# RAI Inaccessibility Gridded Data #
#------------------------------------------------------------------------------#

# SDSN RAI Inaccessibility Index - 2023 - 24arcsec ~800m - WGS84
rai <- rast("inputs/rai_sdsn/911RAI_InaccessibilityIndex2023.tif")

# Source: https://doi.org/10.3389/frsen.2024.1375476

# more than 2km from all-season road
rai_dep <- ifel(is.na(rai), 0, rai)
rai_dep <- (1 - rai_dep)

# resample to population grid
pop2020 <- rast("02.input/population_ghsl/GHS_POP_E2020_GLOBE_R2023A_4326_3ss_V1_0.tif")
rai_res <- resample(rai_dep, pop2020, method = "near", threads = TRUE)

# 2020 population more than 2km from all-season road
rai_pop2020 <- pop2020 * rai_res

# save
writeRaster(rai_pop2020,
  "03.intermediate/Hazard/GHS-POP2020_SDSN-RAI_3arcsec.tif",
  datatype = "FLT4S", overwrite = TRUE
)
