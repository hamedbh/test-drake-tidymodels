create_xgb_pre_proc <- function(train) {
    set.seed(1616)
    recipe(outcome ~ .,
           data = train) %>%
        step_dummy(all_nominal(),
                   -all_outcomes(),
                   one_hot = TRUE)
}

define_xgb <- function(trees, learn_rate) {
    ntree <- enquo(trees)
    eta <- enquo(learn_rate)
    boost_tree(
        mtry = tune(),
        trees = !!ntree, 
        min_n = tune(), 
        tree_depth = tune(), 
        learn_rate = !!eta, 
        sample_size = tune()
    ) %>% 
        set_mode("classification") %>% 
        set_engine("xgboost")
}

create_xgb_wflow <- function(pre_proc, model_spec) {
    workflows::workflow() %>%
        add_model(spec = model_spec) %>%
        add_recipe(recipe = pre_proc)
}

create_xgb_params <- function(wflow,
                              pre_proc) {
    feat_count <- ncol(pre_proc %>%
                           prep() %>%
                           juice() %>%
                           select(-outcome))
    
    mtry_min <- floor(feat_count * 0.4)
    
    wflow %>%
        parameters() %>%
        update(mtry = mtry(range = c(mtry_min, feat_count)), 
               sample_size = sample_prop(c(0.5, 1)), 
               tree_depth = tree_depth(range = c(4L, 10L))
        )
}

create_xgb_grid <- function(params,
                            size,
                            RNG_seed) {
    set.seed(RNG_seed)
    params %>%
        grid_max_entropy(size = size) %>% 
        mutate(sample_size = as.double(sample_size))
}

tune_xgb_grid <- function(wflow,
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

tune_xgb_bayes <- function(wflow,
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
