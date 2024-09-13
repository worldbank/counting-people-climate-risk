rm(list = ls()) # empty workspace
gc() # free-up unused memory

# load packages
library(terra)
library(gtools)

#------------------------------------------------------------------------------#
# Fathom Global pluvial and fluvial (undefended)
# RPs 5,10,20,50,100
# max inundation depth (cm, max at 250cm)
# global tif files
#------------------------------------------------------------------------------#

# create global mosaics - separate for pluvial and fluvial
for (rp in list(5, 10, 20, 50, 100)) {
  for (type in list("P", "F")) {
    fn <- paste0(rp, type, ".tif$")
    flist <- list.files("03.intermediate/Hazard/flood", fn, full.names = TRUE)

    f <- sprc(lapply(flist, rast))
    f <- mosaic(f, fun = "max")

    filename <- paste0("03.intermediate/Hazard/flood/Global", rp, type, ".tif")
    writeRaster(f, filename,
      overwrite = TRUE, datatype = "INT1U",
      gdal = c("COMPRESS=ZSTD", "PREDICTOR=2", "ZSTDLEVEL=1")
    )
  }
}

# global mosaics - pluvial and fluvial combined max inundation depths (cm)
for (rp in list(5, 10, 20, 50, 100)) {
  plu <- rast(paste0("03.intermediate/Hazard/flood/Global", rp, "P.tif"))
  flu <- rast(paste0("03.intermediate/Hazard/flood/Global", rp, "F.tif"))
  plu <- extend(plu, flu)
  pluflu <- max(plu, flu, na.rm = TRUE)
  writeRaster(pluflu, paste0(
    "03.intermediate/Hazard/flood/Global",
    rp, "pluflu.tif"
  ),
  overwrite = TRUE, datatype = "INT1U",
  gdal = c("COMPRESS=ZSTD", "PREDICTOR=2", "ZSTDLEVEL=1")
  )
}

#------------------------------------------------------------------------------#
# Combined flood maps
# Fathom (pluvial, fluvial) + Deltares (coastal)
# RPs 5,10,20,50,100
# max inundation depth of any flood type (cm, max at 250cm)
# global tif files
#------------------------------------------------------------------------------#

for (rp in list(5, 10, 20, 50, 100)) {
  pluflu <- rast(paste0("03.intermediate/Hazard/flood/Global", rp, "pluflu.tif"))
  coastal <- rast(paste0("03.intermediate/Hazard/flood/Global", rp, "C.tif"))

  # extend or resample coastal
  coastal <- resample(coastal, pluflu, "bilinear", threads = TRUE)

  pfc <- max(pluflu, coastal, na.rm = TRUE)
  units(pfc) <- "cm"
  names(pfc) <- paste0("RP", rp)

  writeRaster(pfc, paste0(
    "03.intermediate/Hazard/flood/Global_RP",
    rp, "_PFUC.tif"
  ),
  overwrite = TRUE, datatype = "INT1U",
  gdal = c("COMPRESS=ZSTD", "PREDICTOR=2", "ZSTDLEVEL=1")
  )
}

#------------------------------------------------------------------------------#
# Global combined flood maps, combined RPs
# Fathom (pluvial, fluvial) + Deltares (coastal)
# max inundation depth of any flood type (cm, max at 250cm)
# global tif files
#------------------------------------------------------------------------------#

files <- list.files("03.intermediate/Hazard/flood", "Global.+PFUC.tif$",
  full.names = TRUE
)
flood <- rast(mixedsort(sort(files)))
names(flood) <- c("RP5", "RP10", "RP20", "RP50", "RP100")
units(flood) <- "cm"
flood

# resample to GHS-pop grid & save
pop <- rast("02.input/population_ghsl/GHS_POP_E2020_GLOBE_R2023A_4326_3ss_V1_0.tif")
flood_res <- resample(flood, pop, method = "bilinear", threads = TRUE)
writeRaster(flood_res, "03.intermediate/Hazard/flood_PFUC_res3arcsec.tif",
  datatype = "INT1U", gdal = c("COMPRESS=ZSTD", "PREDICTOR=2"),
  overwrite = TRUE
)
