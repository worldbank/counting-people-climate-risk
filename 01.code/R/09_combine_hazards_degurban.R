rm(list = ls()) # empty workspace
gc() # free-up unused memory

# load packages
library(terra)


#------------------------------------------------------------------------------#
# DEGURBA x HAZARDS #2020
#------------------------------------------------------------------------------#

degurban <- rast("03.intermediate/Hazard/GHSL_degurban2_2020_res3arcsec.tif")

haz4 <- rast("03.intermediate/Hazard/haz4_2020_3arcsec.tif")

dou_haz4 <- concats(degurban, haz4)

writeRaster(dou_haz4, "03.intermediate/Hazard/dou_haz4_2020_3arcsec.tif",
  datatype = "INT1U", overwrite = TRUE
)


#------------------------------------------------------------------------------#

#
sets <- data.frame(levels(dou_haz4[[1]])) %>% rename(hazard = urb_RP100.)
write.csv(sets, "03.intermediate/Hazard/dou_haz4_cats.csv", row.names = FALSE)

# degree of urbanization codes and levels
dou_cats <- data.frame(
  dou_code = c(10, 11, 12, 13, 21, 22, 23, 30),
  dou0 = c(
    "water",
    rep("rural", 3),
    rep("urban", 4)
  ),
  dou1 = c(
    "water",
    rep("rural", 3),
    rep("urban cluster", 3),
    "urban centre"
  ),
  dou2 = c(
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

write.csv(dou_cats, "03.intermediate/Hazard/dou_cats.csv", row.names = FALSE)
