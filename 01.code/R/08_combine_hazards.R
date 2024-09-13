rm(list = ls()) # empty workspace
gc() # free-up unused memory

# load packages
library(terra)

#------------------------------------------------------------------------------#
# MULTIHAZARD GLOBAL DATA - 2020 - for specific RPs / thresholds #
#------------------------------------------------------------------------------#
# define multihazard parameters
mod <- c("RP100*")

# rps
rp <- c("RP100")
rp_d <- c("RP40")

# intensity thresholds (from categories)
th_c <- c(2)
th_d <- c(1)
th_f <- c(3)
th_h <- c(4)

# create multi-hazard rasters
pop <- rast("02.input/population_ghsl/GHS_POP_E2020_GLOBE_R2023A_4326_3ss_V1_0.tif")
haz4 <- rast(pop[[1]])

for (m in 1:length(mod)) {
  print(mod[m])

  cyclone <- rast("03.intermediate/Hazard/cyclone_cat_res3arcsec.tif")[[rp[m]]]
  drought <- rast("03.intermediate/Hazard/drought_2020_cat_res3arcsec.tif")[[rp_d[m]]]
  flood <- rast("03.intermediate/Hazard/flood_cat_res3arcsec.tif")[[rp[m]]]
  heat <- rast("03.intermediate/Hazard/heat_cat_res3arcsec.tif")[[rp[m]]]

  haz <- c(
    cyclone >= th_c[m],
    drought >= th_d[m],
    flood >= th_f[m],
    heat >= th_h[m]
  )

  levels(haz[[1]]) <- data.frame(id = 0:1, hazard = c("0", "cyclone"))
  levels(haz[[2]]) <- data.frame(id = 0:1, hazard = c("0", "drought"))
  levels(haz[[3]]) <- data.frame(id = 0:1, hazard = c("0", "flood"))
  levels(haz[[4]]) <- data.frame(id = 0:1, hazard = c("0", "heat"))

  haz <- concats(concats(haz[[1]], haz[[2]]), concats(haz[[3]], haz[[4]]))
  sets <- data.frame(levels(haz))
  colnames(sets)[2] <- mod[m]
  levels(haz) <- sets

  haz4 <- c(haz4, haz)
}
writeRaster(haz4, "03.intermediate/Hazard/haz4_2020_3arcsec.tif",
  datatype = "INT1U", overwrite = TRUE
)
