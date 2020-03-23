# define_ranger <- function(trees, RNG_seed) {
#     trees <- enquo(trees)
#     
#     rand_forest(
#         mode = "classification", 
#         trees = !!trees, 
#         mtry = varying()
#     ) %>% 
#         set_engine("ranger", seed = RNG_seed)
# }
# 
# create_ranger_grid <- function(dtrain,
#                                grid_size,
#                                RNG_seed) {
#     set.seed(RNG_seed)
#     num_preds <- ncol(dtrain) - 1L
#     param_set(
#         list(
#             mtry(range = c(1L, num_preds))
#         )
#     ) %>%
#         grid_regular(levels = grid_size)
# }
# 
# run_ranger_CV <- function(spec, grid, folds) {
#     grid %>% 
#         mutate(CV_results = map(
#             mtry, 
#             function(mtry) {
#                 folds %>% 
#                     mutate(main = map(splits, analysis), 
#                            validate = map(splits, assessment)) %>% 
#                     mutate(fit = map(main, 
#                                      ~ spec %>% 
#                                          set_args(mtry = mtry) %>% 
#                                          fit(outcome ~ ., data = .x))) %>% 
#                     mutate(preds = map2(fit,
#                                         validate, 
#                                         ~ predict(.x, 
#                                                   new_data = .y, 
#                                                   type = "prob"))) %>% 
#                     mutate(truth_tbl = map2(
#                         preds, 
#                         validate, 
#                         ~ .x %>% 
#                             select(.pred_bad) %>% 
#                             bind_cols(.y %>% 
#                                           select(outcome)))) %>% 
#                     mutate(auc = map_dbl(
#                         truth_tbl,
#                         ~ .x %>%
#                             roc_auc(truth = outcome,
#                                     .pred_bad) %>%
#                             pull(.estimate))) %>%
#                     # pull(auc)
#                     # pull(truth_tbl)
#                     mutate(full_roc = map(
#                         truth_tbl, 
#                         ~ .x %>% 
#                             roc_curve(truth = outcome, 
#                                       .pred_bad)
#                     )) %>% 
#                     select(starts_with("id"), 
#                            truth_tbl, 
#                            auc, 
#                            full_roc)
#             }
#         )) %>% 
#         unnest(CV_results) %>% 
#         add_column(model_name = "ranger", 
#                    .before = 1L)
#     
# }
