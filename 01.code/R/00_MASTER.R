#------------------------------------------------------------------------------#
#           Population at high-risk from climate related hazards               #
#                             R master script                                  #
#------------------------------------------------------------------------------#

# install packages using renv
renv::restore()

# set directory to root replication folder
setwd("../../")

# run from intermediate data?
from_intermediate = TRUE

# !!! Running the MASTER R script from source data is not recommended !!! #
# !!!          (~1 TB storage required, > 14 days run time)           !!! #

# run scripts   
if (from_intermediate) {
  source("01.code/R/10_extract_exposed_pop.R")
  source("01.code/R/11_clean_exposed_pop.R")
} else {
  script_list <- list.files("01.code/R", ".R$", full.names = TRUE)
  for (code in setdiff(script_list, "01.code/R/00_MASTER.R")) {
    source(code)
  }
}