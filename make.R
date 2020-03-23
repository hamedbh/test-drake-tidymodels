source(here::here("R/packages.R"))

list.files(here::here("R"), 
           pattern = "^f", 
           full.names = TRUE) %>% 
    walk(source)

source(here::here("R/plan.R"))

make(
    g_plan, 
    verbose = 1
)
