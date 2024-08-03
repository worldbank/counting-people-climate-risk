rm(list = ls()) # empty workspace
gc() # free-up unused memory

# load packages
library(sf)
library(dplyr)
library(wbstats)

#------------------------------------------------------------------------------#
# rescale population estimates using World Bank WDI population data
#------------------------------------------------------------------------------#

# import raw estimates
exp <- read.csv("03.intermediate/Exposure/2021/am24exp_raw.csv")

# get World Bank WDI population data for specific year
pop_year <- 2021
wdi_pop <- wb_data("SP.POP.TOTL", start_date = pop_year, end_date = pop_year)

# rescale gridded population estimates
exp2 <- mutate(exp, iso3c = substr(geo_code, 1, 3)) %>%
  left_join(wdi_pop[, c("iso3c", "SP.POP.TOTL")]) %>%
  rename(pop_wdi = SP.POP.TOTL, code = iso3c) %>%
  group_by(code, scenario, value) %>%
  mutate(
    pop_ghsl = sum(pop, na.rm = FALSE),
    pop = if_else(is.na(pop_wdi), pop, pop * pop_wdi / pop_ghsl),
    pop_rai = if_else(is.na(pop_wdi), pop_rai, pop_rai * pop_wdi / pop_ghsl),
    pop_year = pop_year
  )


#------------------------------------------------------------------------------#
# summarise estimates for merging with survey data
#------------------------------------------------------------------------------#

# survey boundaries
bounds <- read_sf("02.input/boundaries/VUL_AM24_2021.gpkg")

# exposure category and DoU labels
dou_haz4_cats <- read.csv("03.intermediate/Hazard/dou_haz4_cats.csv")
dou_cats <- read.csv("03.intermediate/Hazard/dou_cats.csv")

# add category labels, remove water DoU category
exp3 <- left_join(exp2, dou_haz4_cats) %>%
  mutate(
    dou2 = gsub("\\_.*", "", hazard),
    hazard = gsub("^[^_]*_", "", hazard)
  ) %>%
  left_join(dou_cats) %>%
  filter(dou_code != 10) %>% # remove water category
  mutate(hazard = gsub(
    "0", "below threshold",
    gsub("&0", "", gsub("0&", "", gsub("_", "&", hazard)))),
    haz_n = ifelse(hazard == "below threshold", 0,
    1 + lengths(regmatches(hazard, gregexpr("&", hazard)))
  )) %>%
  left_join(st_drop_geometry(bounds)) %>%
  select(c(8, 1, 24, 2, 3, 14:16, 13, 12, 17, 4:7, 9, 11)) %>%
  arrange(geo_code, scenario, value)

# get population by DoU category, restrict RAI to rural
exp4 <- group_by(exp3,geo_code,scenario,dou_code) %>%
  mutate(pop=sum(pop*exp_sh),
         exp_sh=if_else(exp_sh==0,0,exp_sh/sum(exp_sh)),
         pop_rai=if_else(dou_code > 20, 0, sum(pop_rai*exp_sh_rai)),
         exp_sh_rai=if_else(exp_sh_rai==0 | dou_code > 20 ,0, 
                            exp_sh_rai/sum(exp_sh_rai))) 

# summarise by hazard
exp_drought <- filter(exp4, grepl("drought", hazard)) %>%
  group_by(code, geo_code, dou_code, scenario, pop, pop_rai) %>%
  summarise(
    exp_drought = sum(pop * exp_sh, na.rm = TRUE),
    exp_drought_rai = sum(pop_rai * exp_sh_rai, na.rm = TRUE)
  )

exp_flood <- filter(exp4, grepl("flood", hazard)) %>%
  group_by(code, geo_code, dou_code, scenario, pop, pop_rai) %>%
  summarise(
    exp_flood = sum(pop * exp_sh, na.rm = TRUE),
    exp_flood_rai = sum(pop_rai * exp_sh_rai, na.rm = TRUE)
  )

exp_heat <- filter(exp4, grepl("heat", hazard)) %>%
  group_by(code, geo_code, dou_code, scenario, pop, pop_rai) %>%
  summarise(
    exp_heat = sum(pop * exp_sh, na.rm = TRUE),
    exp_heat_rai = sum(pop_rai * exp_sh_rai, na.rm = TRUE)
  )

exp_cyclone <- filter(exp4, grepl("cyclone", hazard)) %>%
  group_by(code, geo_code, dou_code, scenario, pop, pop_rai) %>%
  summarise(
    exp_cyclone = sum(pop * exp_sh, na.rm = TRUE),
    exp_cyclone_rai = sum(pop_rai * exp_sh_rai, na.rm = TRUE)
  )

# combine summary by hazard
exp_any <- filter(exp4, !grepl("below threshold", hazard)) %>%
  group_by(code, geo_code, dou_code, scenario, pop, pop_rai) %>%
  summarise(
    exp_any = sum(pop * exp_sh),
    exp_any_rai = sum(pop_rai * exp_sh_rai)
  )

exp_summary <- full_join(exp_drought, exp_flood) %>%
  full_join(exp_heat) %>%
  full_join(exp_cyclone) %>%
  full_join(exp_any) %>%
  left_join(dou_cats) %>%
  replace(is.na(.), 0) %>%
  rename(totalpop = pop, totalpop_rai = pop_rai) %>%
  select(c(1:3, 17:19, 4, 5, 7, 9, 11, 13, 15, 6, 8, 10, 12, 14, 16)) %>%
  arrange(geo_code, scenario, dou_code)

# save
write.csv(exp_summary,
  "03.intermediate/Exposure/2021/am24exp_clean.csv",
  row.names = FALSE
)
