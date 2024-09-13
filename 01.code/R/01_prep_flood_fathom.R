rm(list = ls()) # empty workspace
gc() # free-up unused memory

# load packages
library(terra)

#------------------------------------------------------------------------------#
# Fathom Global pluvial and fluvial (undefended)
# RPs 5,10,20,50,100
# max inundation depth (cm, max at 250cm)
# generates country level maps
#------------------------------------------------------------------------------#

dir <- "02.input/flood_fathom"

dir.create("03.intermediate/Hazard/flood/")
out <- "03.intermediate/Hazard/flood/"

files <- list.files(dir, ".zip$")
codes <- substr(files, 1, nchar(files) - 4)
codes
codes <- codes[c(222)]

for (i in codes) { # loop over countries
  path <- paste0(dir, "/", i, ".zip")

  for (rp in list(5, 10, 20, 50, 100)) {
    for (type in list("P", "FU")) {
      flag <- 0

      fn <- paste0(type, "_1in", rp, ".tif$")
      flist <- grep(fn, unzip(path, list = TRUE)$Name, 
                    ignore.case = TRUE, value = TRUE)

      if (length(flist) > 1) { # case with many files (Alaska, Fiji, Kiribati)
        for (n in 1:length(flist)) {
          f <- rast(unzip(path, flist[n]))

          f <- subst(f, -9999, NA) # No data pixels --> NA
          f <- subst(f, 999, NA) # perm. water bodies --> NA
          f <- min(round(100 * f), 250) # round to nearest cm, max = 250cm

          filename <- paste0(out, i, rp, type, "_", n, ".tif")
          writeRaster(f, filename,
            overwrite = TRUE, datatype = "INT1U",
            gdal = c("COMPRESS=ZSTD", "PREDICTOR=2", "ZSTDLEVEL=1")
          )
        }
      } else {
        if (length(flist) == 1) { # case with single file
          f <- rast(unzip(path, flist))
        } else if (length(flist) == 0) { # case with multiple tiles, different names
          fn <- paste0(type, "_1in", rp, "_tile.+.tif$")
          flist <- grep(fn, unzip(path, list = TRUE)$Name, 
                        ignore.case = TRUE, value = TRUE)

          if (length(flist) > 1) {
            f <- sprc(lapply(unzip(path, flist), rast))
            f <- merge(f)
          } else {
            flag <- 1
            print(paste0("No flood map found for ", i, ", RP", rp, ", flood type: ", type))
          }
        }
        if (flag == 0) {
          f <- subst(f, -9999, NA) # No data pixels --> NA
          f <- subst(f, 999, NA) # perm. water bodies --> NA
          f <- min(round(100 * f), 250) # round to nearest cm, max = 250cm

          filename <- paste0(out, i, rp, type, ".tif")
          writeRaster(f, filename,
            overwrite = TRUE, datatype = "INT1U",
            gdal = c("COMPRESS=ZSTD", "PREDICTOR=2", "ZSTDLEVEL=1")
          )
        }
      }
    }
  }
  print(i)
}

# get fluvial defended for USA because undefended does not exist
path <- paste0(dir, "/USA.zip")
for (rp in list(5, 10, 20, 50, 100)) {
  fn <- paste0("FD_1in", rp, "_tile.+.tif$")
  flist <- grep(fn, unzip(path, list = TRUE)$Name, 
                ignore.case = TRUE, value = TRUE)
  f <- sprc(lapply(unzip(path, flist), rast))
  f <- merge(f)

  f <- subst(f, -9999, NA) # No data pixels --> NA
  f <- subst(f, 999, NA) # perm. water bodies --> NA
  f <- min(round(100 * f), 250) # round to nearest cm, max = 250cm

  filename <- paste0(out, "USA", rp, "FD.tif")
  writeRaster(f, filename,
    overwrite = TRUE, datatype = "INT1U",
    gdal = c("COMPRESS=ZSTD", "PREDICTOR=2", "ZSTDLEVEL=1")
  )
}

# São Tomé and Príncipe (code above misses due to invalid characters in path)
path <- paste0(dir, "/São Tomé and Príncipe.zip")
for (rp in list(5, 10, 20, 50, 100)) {
  for (type in list("P", "FU")) {
    fn <- paste0(type, "_1in", rp, ".tif$")
    flist <- grep(fn, unzip(path, list = TRUE)$Name, 
                  ignore.case = TRUE, value = TRUE)
    f <- rast(unzip(path, flist))
    f <- subst(f, -9999, NA) # No data pixels --> NA
    f <- subst(f, 999, NA) # perm. water bodies --> NA
    f <- min(round(100 * f), 250) # round to nearest cm, max = 250cm

    filename <- paste0(out, "São Tomé and Príncipe", rp, type, ".tif")
    writeRaster(f, filename,
      overwrite = TRUE, datatype = "INT1U",
      gdal = c("COMPRESS=ZSTD", "PREDICTOR=2", "ZSTDLEVEL=1")
    )
  }
}

# Note Alaska, Fiji and Kiribati split into two files (East and West of 0 line)
