source(here::here("R/packages.R"))

source(here::here("R/f_general.R"))
source(here::here("R/f_data_gathering.R"))
source(here::here("R/f_plotting.R"))
source(here::here("R/f_data_prep.R"))
source(here::here("R/f_ranger.R"))
source(here::here("R/f_mlp.R"))
source(here::here("R/f_xgboost.R"))

source(here::here("R/f_evaluate_models.R"))

source(here::here("R/plan.R"))

drake_config(
    g_plan, 
    verbose = 2
)
