define_ranger <- function(RNG_seed) {
    
    rand_forest(
        mode = "classification",
        trees = tune(),
        mtry = tune(), 
        min_n = tune()
    ) %>%
        set_engine("ranger", seed = RNG_seed)
}

create_ranger_params <- function(wflow,
                                 pre_proc) {
    wflow %>%
        parameters() %>% 
        update(trees = trees(c(100L, 2000L)), 
               mtry = mtry(range = c(10L, 
                                     pre_proc %>% 
                                         prep() %>% 
                                         juice() %>%
                                         select(-outcome) %>% 
                                         ncol())
               )
        )
    
}

tune_ranger_grid <- function(wflow,
                             resamples, 
                             grid, 
                             params) {
    tune_grid(
        wflow,
        resamples = resamples,
        grid = grid,
        param_info = params,
        metrics = metric_set(roc_auc),
        control = control_grid(
            verbose = TRUE,
            save_pred = TRUE
        )
    )
}

tune_ranger_bayes <- function(wflow,
                              resamples,
                              iter, 
                              params,
                              grid_results, 
                              RNG_seed) {
    set.seed(RNG_seed)
    tune_bayes(
        wflow,
        resamples = resamples,
        iter = iter,
        param_info = params,
        metrics = metric_set(roc_auc),
        initial = grid_results,
        control = control_bayes(
            verbose = TRUE,
            save_pred = TRUE
        )
    )
}
