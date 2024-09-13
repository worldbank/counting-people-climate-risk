rm(list = ls()) # empty workspace
gc() # free-up unused memory

# load packages
library(terra)
library(gtools)

#------------------------------------------------------------------------------#
# TROPICAL CYCLONE - STORM (MODELLED)
#------------------------------------------------------------------------------#

# STORM tropical cyclone max wind speeds (m/s, 10min) - present day baseline climate

files <- list.files("02.input/cyclone_storm", "constant_.+.tif$", full.names = TRUE)
cyclone <- rast(mixedsort(sort(files))[c(1, 2, 5, 10, 11, 14, 19)])
names(cyclone) <- c("RP10", "RP20", "RP50", "RP100", "RP200", "RP500", "RP1000")

# save return period stack with max wind speeds
writeRaster(cyclone, "03.intermediate/Hazard/cyclone_wind_6arcmin.tif",
  datatype = "FLT4S", overwrite = TRUE
)

# Source: https://zenodo.org/doi/10.5281/zenodo.7438144
# Paper: https://doi.org/10.1038/s41597-020-00720-x

#------------------------------------------------------------------------------#
# AGRICULTURAL DROUGHT - FAO ASI (HISTORICAL FREQUENCY)
#------------------------------------------------------------------------------#

# Historic agricultural drought frequency - FAO ASI - 30/50% affected
hdf30 <- rast(list.files("02.input/drought_fao", "LA30.tif$", full.names = TRUE))
hdf50 <- rast(list.files("02.input/drought_fao", "LA50.tif$", full.names = TRUE))

# flags: 252: no data; 253: no season; 254: no cropland/grassland
# get maximum frequency of drought in either season, cropland or grassland
hdf30 <- max(subst(hdf30, 252:254, NA), na.rm = TRUE)
hdf50 <- max(subst(hdf50, 252:254, NA), na.rm = TRUE)

drought <- c(hdf30, hdf50)
names(drought) <- c("hdf30", "hdf50")

# historic frequencies in drought data
hdf <- freq(drought, bylayer = F)
colnames(hdf) <- c("freq", "count")

# convert historic freq (39 yr record) into return periods
m <- data.frame("freq" = round(c(1:39) / 39 * 100), "yrs" = c(1:39), "rp" = 39 / c(1:39))
hdf <- merge(hdf, m, all.x = TRUE)
hdf$rp <- ifelse(is.na(hdf$rp), 39 / (hdf$freq / 100 * 39), hdf$rp) # rps if no match
hdf$rp <- ceiling(hdf$rp / 5) * 5 # round up to nearest 5 yr RP
m <- hdf[, c(1, 4)]

# classify historic drought frequency data using 5 yr return periods
drought_rp <- classify(drought, m)

# construct rp stack with two drought intensity levels (land area affected)
for (rp in c(5, 10, 15, 20, 40)) {
  drought_rp$n <- ifel(drought_rp$hdf30 <= rp, 1, 0)
  drought_rp$n <- ifel(drought_rp$hdf50 <= rp, 2, drought_rp$n)
  names(drought_rp[[nlyr(drought_rp)]]) <- paste0("RP", rp)
}

drought_5rp <- subset(drought_rp, 3:7)

# save return period stack with drought categories
writeRaster(drought_5rp, "03.intermediate/Hazard/drought_asi_1km.tif",
  datatype = "INT1U", overwrite = TRUE
)

# Source: https://data.apps.fao.org/catalog/iso/f8568e67-46e7-425d-b779-a8504971389b

#------------------------------------------------------------------------------#
# EXTREME HEAT EVENTS - CCKP ESI
#------------------------------------------------------------------------------#

# CCKP 5-day maximum daily Environmental Stress Index (ESI)

files <- list.files("02.input/heatwave_cckp", "returnlevel.*median.*.nc$",
  full.names = TRUE
)
heat <- rast(mixedsort(sort(files)))
names(heat) <- c("RP5", "RP10", "RP20", "RP50", "RP100")

# save return period stack with 3-day max wbgt
writeRaster(heat, "03.intermediate/Hazard/heat_max5dESI_15arcmin.tif",
  datatype = "FLT4S", overwrite = TRUE
)

# Source: CCKP using ERA-5 data for 1950-2022
