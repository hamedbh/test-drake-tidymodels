create_tree_pre_proc <- function(train) {
    set.seed(930)
    recipe(outcome ~ .,
           data = train) %>%
        step_dummy(all_nominal(),
                   -all_outcomes(),
                   one_hot = TRUE) %>% 
        step_zv(all_predictors())
}

define_tree_mod <- function() {
    decision_tree(cost_complexity = tune(), 
                  min_n = tune()) %>% 
        set_engine("rpart") %>% 
        set_mode("classification")
}

create_tree_grid <- function(params,
                             size,
                             RNG_seed) {
    set.seed(RNG_seed)
    params %>%
        grid_max_entropy(size = size)
}

tune_tree_grid <- function(wflow,
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

tune_tree_bayes <- function(wflow,
                            resamples,
                            iter, 
                            params,
                            grid_results, 
                            RNG_seed) {
    no_improve <- iter
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
            save_pred = TRUE, 
            no_improve = no_improve
        )
    )
}
