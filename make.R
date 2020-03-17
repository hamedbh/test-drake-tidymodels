source(here::here("R/packages.R"))

source(here::here("R/f_general.R"))
source(here::here("R/f_data_gathering.R"))

source(here::here("R/plan.R"))

make(
    g_plan, 
    verbose = 2
)
