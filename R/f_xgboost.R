define_xgb <- function(trees, learn_rate) {
    ntree <- enquo(trees)
    eta <- enquo(learn_rate)
    boost_tree(
        mtry = tune(),
        trees = !!ntree, 
        min_n = tune(), 
        tree_depth = tune(), 
        learn_rate = !!eta, 
        loss_reduction = tune(), 
        sample_size = tune()
    ) %>% 
        set_mode("classification") %>% 
        set_engine("xgboost")
}

# create_xgb_wflow <- function(pre_proc, model_spec) {
#     workflow() %>% 
#         add_model(spec = model_spec) %>% 
#         add_recipe(recipe = pre_proc)
# }
# 
# create_xgb_params <- function(wflow, 
#                               dtrain) {
#     wflow %>% 
#         parameters() %>% 
#         finalize(dtrain)
# }
# 
# create_xgb_grid <- function(params, 
#                             size, 
#                             RNG_seed) {
#     set.seed(RNG_seed)
#     params %>% 
#         grid_latin_hypercube(size = size)
# }
# 
# tune_xgb_grid <- function(wflow, 
#                           resamples, 
#                           params, 
#                           grid) {
#     tune_grid(
#         wflow, 
#         resamples = resamples, 
#         param_info = params, 
#         grid = grid, 
#         metrics = metric_set(roc_auc), 
#         control = control_grid(
#             verbose = TRUE, 
#             allow_par = TRUE, 
#             save_pred = TRUE
#         )
#     )
# }
# 
# tune_xgb_bayes <- function(wflow, 
#                            resamples, 
#                            params, 
#                            grid_results, 
#                            iter, 
#                            RNG_seed) {
#     tune_bayes(
#         wflow, 
#         resamples = resamples, 
#         iter = iter, 
#         param_info = params, 
#         metrics = metric_set(roc_auc), 
#         initial = grid_results, 
#         control = control_bayes(
#             verbose = TRUE, 
#             seed = RNG_seed, 
#             save_pred = TRUE
#         )
#     )
# }
