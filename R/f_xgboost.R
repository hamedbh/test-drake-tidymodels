define_xgb <- function(trees, learn_rate) {
    ntree <- enquo(trees)
    eta <- enquo(learn_rate)
    boost_tree(
        mode = "classification", 
        mtry = varying(),
        trees = !!ntree, 
        min_n = varying(), 
        tree_depth = varying(), 
        learn_rate = !!eta, 
        loss_reduction = varying(), 
        sample_size = varying()
    ) %>% 
        set_engine("xgboost")
}

create_xgb_grid <- function(dtrain,
                            size,
                            RNG_seed) {
    set.seed(RNG_seed)
    g_preds <- dtrain %>% select(-outcome)
    param_set(
        list(
            mtry(),
            min_n(), 
            tree_depth(range = c(1L, 15L)), 
            loss_reduction(), 
            sample_size(range = c(0.5, 1))
        )
    ) %>%
        finalize(g_preds) %>% 
        grid_latin_hypercube(size = size)
}

run_xgb_CV <- function(spec, grid, folds) {
    grid %>% 
        mutate(CV_results = pmap(
            ., 
            function(mtry, 
                     min_n, 
                     tree_depth, 
                     loss_reduction, 
                     sample_size) {
                folds %>% 
                    mutate(main = map(splits, analysis), 
                           validate = map(splits, assessment)) %>% 
                    mutate(fit = map(main,
                                     ~ spec %>%
                                         set_args(
                                             mtry = mtry,
                                             min_n = min_n,
                                             tree_depth = tree_depth,
                                             loss_reduction = loss_reduction,
                                             sample_size = sample_size
                                         ) %>%
                                         fit(outcome ~ ., data = .x))) %>%
                    mutate(preds = map2(fit,
                                        validate,
                                        ~ predict(.x,
                                                  new_data = .y,
                                                  type = "prob"))) %>%
                    mutate(truth_tbl = map2(
                        preds,
                        validate,
                        ~ .x %>%
                            select(.pred_bad) %>%
                            bind_cols(.y %>%
                                          select(outcome)))) %>%
                    mutate(auc = map_dbl(
                        truth_tbl,
                        ~ .x %>%
                            roc_auc(truth = outcome,
                                    .pred_bad) %>%
                            pull(.estimate))) %>%
                    mutate(full_roc = map(
                        truth_tbl,
                        ~ .x %>%
                            roc_curve(truth = outcome,
                                      .pred_bad)
                    )) %>%
                    select(starts_with("id"),
                           truth_tbl,
                           auc,
                           full_roc)
            }
        )) %>% 
        unnest(CV_results) %>%
        add_column(model_name = "xgboost",
                   .before = 1L)
    
}
