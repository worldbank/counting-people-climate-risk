rm(list = ls()) # empty workspace
gc() # free-up unused memory

# load packages
library(terra)

#------------------------------------------------------------------------------#
# HAZARD CLASSIFICATION MATRIX #
#------------------------------------------------------------------------------#

# hazard category breaks and labels
cyclone_c <- c(0, 29.0, 37.6, 43.4, 51.1, 61.6, Inf) # wind speed (m/s, 10 min)
cyclone_l <- c("<Cat-1", "Cat-1", "Cat-2", "Cat-3", "Cat-4", "Cat-5")
cyclone_th <- c("≥Cat-1", "≥Cat-2", "≥Cat-3", "≥Cat-4", "≥Cat-5")

drought_l <- c("<30% land affected", "30-50% land affected", ">50% land affected")
drought_th <- c(">30% land affected", ">50% land affected")

flood_c <- c(0, 0, 15, 50, 100, 150, Inf) # max inundation depth (cm)
flood_l <- c("No flood", "0-0.15 m", "0.15-0.5 m", "0.5-1 m", "1-1.5 m", ">1.5 m")
flood_th <- c(">0 m", ">0.15 m", ">0.5 m", ">1.0 m", ">1.5 m")

heat_c <- c(-Inf, 28, 30, 32, 33, 34, 35, Inf) # 3-day max simplified WBGT (°C)
heat_l <- c("<28C", "28-30C", "30-32C", "32-33C", "33-34C", "34-35C", ">35C")
heat_th <- c(">28C", ">30C", ">32C", ">33C", ">34C", ">35C")

# hazard intensity classification matrix
class <- data.frame(
  "hazard" = c(
    rep("cyclone", length(cyclone_c)),
    rep("flood", length(flood_c)),
    rep("heat", length(heat_c))
  ),
  "breaks" = c(cyclone_c, flood_c, heat_c)
)

write.csv(class, "03.intermediate/Hazard/haz_classify.csv", row.names = FALSE)

# category labels
cat_labs <- data.frame(
  "hazard" = c(
    rep("cyclone", length(cyclone_l)),
    rep("drought", length(drought_l)),
    rep("flood", length(flood_l)),
    rep("heat", length(heat_l))
  ),
  "value" = c(
    seq(cyclone_l), seq(drought_l),
    seq(flood_l), seq(heat_l)
  ) - 1,
  "label" = c(
    cyclone_l, drought_l,
    flood_l, heat_l
  )
)

write.csv(cat_labs, "03.intermediate/Hazard/haz_catlabels.csv", row.names = FALSE)

# above threshold labels
th_labs <- data.frame(
  "hazard" = c(
    rep("cyclone", length(cyclone_th)),
    rep("drought", length(drought_th)),
    rep("flood", length(flood_th)),
    rep("heat", length(heat_th))
  ),
  "value" = c(
    seq(cyclone_th), seq(drought_th),
    seq(flood_th), seq(heat_th)
  ),
  "label" = c(
    cyclone_th, drought_th,
    flood_th, heat_th
  )
)

write.csv(th_labs, "03.intermediate/Hazard/haz_thlabels.csv", row.names = FALSE)


#------------------------------------------------------------------------------#
# CLASSIFY & RESAMPLE HAZARD DATA TO POPULATION GRID #
#------------------------------------------------------------------------------#

# population data - used to crop/extend and resample hazard data
pop <- rast("02.input/population_ghsl/GHS_POP_E2020_GLOBE_R2023A_4326_3ss_V1_0.tif")

# hazard data (native resolution, return period stacks)
haz_list <- c(
  "cyclone_wind_6arcmin.tif",
  "drought_asi_1km.tif",
  "flood_PFUC_res3arcsec.tif",
  "heat_max5dESI_15arcmin.tif"
)

# loop over hazards
for (h in haz_list) {
  # import data
  haz <- rast(paste0("03.intermediate/Hazard/", h))
  hazard <- gsub("\\_.*", "", h) # hazard name (before 1st "_")
  print(hazard)

  # crop/extend to the extent of population grid
  haz <- crop(haz, pop, snap = "out", extend = TRUE)

  # classify
  if (!hazard %in% c("drought")) { # data already categorical

    haz <- classify(haz, class[class$hazard == hazard, "breaks"], include.lowest = TRUE)
  }

  # !assign lowest intensity category to cells with no data
  haz <- ifel(is.na(haz), 0, haz)

  # resample to population grid
  if (!hazard %in% c("flood")) { # flood data already resampled (bilinear)

    haz <- resample(haz, pop, method = "near", threads = T)
  }

  # restrict drought to rural areas (DEGURBA)
  if (hazard %in% c("drought")) {
    degurban <- rast("03.intermediate/Hazard/GHSL_degurban2_2020_res3arcsec.tif")
    haz <- mask(haz, degurban, maskvalues = c(30, 23, 22, 21), updatevalue = 0)

    writeRaster(haz, "03.intermediate/Hazard/drought_2020_cat_res3arcsec.tif",
      datatype = "INT1U", overwrite = TRUE,
      gdal = c("COMPRESS=ZSTD", "PREDICTOR=2")
    )
  } else {
    # save categorical resampled data (compressed)
    writeRaster(haz, paste0(
      "03.intermediate/Hazard/", hazard,
      "_cat_res3arcsec.tif"
    ),
    datatype = "INT1U", overwrite = TRUE,
    gdal = c("COMPRESS=ZSTD", "PREDICTOR=2")
    )
  }

  rm(haz)
  tmpFiles(current = TRUE, orphan = TRUE, remove = TRUE)
}
