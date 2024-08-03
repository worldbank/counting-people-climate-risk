rm(list = ls()) # empty workspace
gc() # free-up unused memory

# load packages
library(terra)

#------------------------------------------------------------------------------#
# Deltares global coastal flood maps - MERITDEM 90m
# RPs 5,10,25,50,100
# max inundation depth (cm, max at 250cm)
# global tif files
#------------------------------------------------------------------------------#

for (rp in list("0005", "0010", "0025", "0050", "0100")) {
  f <- rast(paste0(
    "02.input/flood_fathom/",
    "GFM_global_MERITDEM90m_2018slr_rp", rp, "_masked.nc"
  ))

  f <- min(round(100 * f), 250) # round to nearest cm, max = 250cm

  rp <- as.numeric(rp)
  filename <- paste0("03.intermediate/Hazard/flood/Global", rp, "C.tif")
  writeRaster(f, filename,
    overwrite = TRUE, datatype = "INT1U",
    gdal = c("COMPRESS=ZSTD", "PREDICTOR=2", "ZSTDLEVEL=1")
  )
}

# interpolate RP20 coastal flood map from RP10 & RP25
f10 <- rast("03.intermediate/Hazard/flood/Global10C.tif")
f25 <- rast("03.intermediate/Hazard/flood/Global25C.tif")

intpl <- function(x, y) {
  x + 10 * (y - x) / 15
}
f20 <- intpl(f10, f25) # linear interpolation
f20 <- min(round(f20), 250) # round to nearest cm, max = 250cm

writeRaster(f20, "03.intermediate/Hazard/flood/Global20C.tif",
  overwrite = TRUE, datatype = "INT1U",
  gdal = c("COMPRESS=ZSTD", "PREDICTOR=2", "ZSTDLEVEL=1")
)
