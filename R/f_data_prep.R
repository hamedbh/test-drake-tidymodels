partition_data <- function(d, p, RNG_seed) {
    set.seed(seed = RNG_seed)
    
    d %>% 
        initial_split(data = d, 
                      prop = p, 
                      strata = outcome)
}

create_cv_folds <- function(dtrain, RNG_seed) {
    set.seed(RNG_seed)
    vfold_cv(dtrain, 
             v = 5, 
             repeats = 5, 
             strata = outcome)
}

create_g_recipe <- function(splits) {
    set.seed(1118)
    training(splits) %>% 
        recipe(outcome ~ .) %>% 
        step_bagimpute(all_predictors(), 
                       seed_val = 956) %>% 
        step_dummy(all_nominal(), 
                   -all_outcomes(), 
                   one_hot = TRUE) %>% 
        step_normalize(all_numeric()) %>% 
        step_downsample(outcome, under_ratio = 1.2)
    
}

create_training <- function(rec) { 
    rec %>% 
        prep() %>% 
        juice()
}

create_testing <- function(rec, splits) {
    rec %>% 
        prep() %>% 
        bake(new_data = splits %>% 
                 testing())
}
