rm(list = ls()) # empty workspace
gc() # free-up unused memory

# load packages
library(sf)
library(terra)
library(exactextractr)
library(data.table)

#------------------------------------------------------------------------------#
# import spatial data
#------------------------------------------------------------------------------#

# survey boundaries for aggregation
bounds <- read_sf("02.input/boundaries/VUL_AM24_2021.gpkg")

# GHSL population 2020
pop2020 <- rast(paste0(
  "02.input/population_ghsl/",
  "GHS_POP_E2020_GLOBE_R2023A_4326_3ss_V1_0.tif"
))
names(pop2020) <- "pop2020"

# population with low accessibility 2020 (RAI)
pop2020_rai <- rast("03.intermediate/RAI/GHS-POP2020_SDSN-RAI_3arcsec.tif")
names(pop2020_rai) <- "pop2020_rai"

# global DEGURBA-multihazard data (categorical, resampled)
haz4_dou <- rast("03.intermediate/Hazard/dou_haz4_2020_3arcsec.tif")
names(haz4_dou) <- "RP100*"

#check NA

#------------------------------------------------------------------------------#
# extract population exposed to hazards & with low accessibility (RAI)
#------------------------------------------------------------------------------#

# total population and population with low accessibility in each region
totalpop <- exact_extract(c(pop2020, pop2020_rai),
  bounds,
  fun = "sum", stack_apply = TRUE,
  append_cols = c("geo_code")
)

colnames(totalpop)[2:3] <- c("pop", "pop_rai")
setDT(totalpop, key = "geo_code")


# share of population by hazard exposure/DoU category in each region
bounds <- read_sf("02.input/boundaries/VUL_AM24_2021.gpkg") # Must reload bounds

exp_haz <- exact_extract(haz4_dou[["RP100*"]], bounds,
  fun = "weighted_frac",
  weights = pop2020,
  append_cols = c("geo_code"),
  stack_apply = TRUE,
  default_weight = 0
)

# reshape
exp_haz <- melt(setDT(exp_haz),
  value.name = "exp_sh",
  measure.vars = measure(
    value = as.integer,
    pattern = "weighted_frac_(.[0-9]*)"
  )
)
setDT(exp_haz, key = c("geo_code", "value"))

# share of population with low access by exposure/DoU category in each region
bounds <- read_sf("02.input/boundaries/VUL_AM24_2021.gpkg") # Must reload bounds

exp_rai <- exact_extract(haz4_dou, bounds,
  fun = "weighted_frac",
  weights = pop2020_rai,
  append_cols = c("geo_code"),
  stack_apply = TRUE,
  default_weight = 0
)

# reshape
exp_rai <- melt(setDT(exp_rai),
  value.name = "exp_sh_rai",
  measure.vars = measure(
    value = as.integer,
    pattern = "weighted_frac_(.[0-9]*)"
  )
)
setDT(exp_rai, key = c("geo_code", "value"))

# merge total population, exposure and RAI results, arrange, sort
exp <- exp_haz[exp_rai][totalpop][
  order(geo_code, value),
  .(geo_code,
    scenario = "RP100*", value, pop,
    exp_sh = ifelse(pop == 0, 0, exp_sh),
    pop_rai,
    exp_sh_rai = ifelse(pop_rai == 0, 0, exp_sh_rai)
  )
]

# check for NAs
na <- exp[is.na(exp$exp_sh) | is.na(exp$exp_sh_rai),]

# save raw exposure estimates
write.csv(exp,
  "03.intermediate/Exposure/2021/am24exp_raw.csv",
  row.names = FALSE
)
