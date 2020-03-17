define_mlp <- function() {
    mlp(
        mode = "classification", 
        hidden_units = varying(),
        penalty = varying(), 
        epochs = varying()
    ) %>% 
        set_engine("nnet")
}

create_mlp_grid <- function(dtrain,
                            levels,
                            RNG_seed) {
    set.seed(RNG_seed)
    num_preds <- ncol(dtrain) - 1L
    param_set(
        list(
            hidden_units(range = c(3L, 4L), 
                         trans = log2_trans()), 
            penalty(), 
            epochs(range = c(20L, 30L))
        )
    ) %>%
        grid_regular(levels = levels)
}

run_mlp_CV <- function(spec, grid, folds) {
    grid %>% 
        mutate(CV_results = pmap(
            ., 
            function(hidden_units, 
                     penalty, 
                     epochs) {
                folds %>% 
                    mutate(main = map(splits, analysis), 
                           validate = map(splits, assessment)) %>% 
                    mutate(fit = map(main, 
                                     ~ spec %>% 
                                         set_args(
                                             hidden_units = hidden_units, 
                                             penalty = penalty, 
                                             epochs = epochs
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
        add_column(model_name = "mlp", 
                   .before = 1L)
    
}
