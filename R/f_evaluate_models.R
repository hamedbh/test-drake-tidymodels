# get_preds <- function(model_grid, test_data) {
#     model_grid %>% 
#         mutate(preds = map(fit, 
#                            ~ predict(.x, 
#                                      new_data = test_data, 
#                                      type = "prob")))
# }
# 
# 
# add_auc <- function(preds_tbl, test_data) {
#     preds_tbl %>% 
#         mutate(auc = map_dbl(
#             preds, 
#             ~ .x %>% 
#                 select(.pred_bad) %>% 
#                 bind_cols(test_data %>% select(outcome)) %>% 
#                 roc_auc(truth = outcome, 
#                         .pred_bad) %>% 
#                 pull(.estimate)
#         ))
# }
# 
# get_CV_metrics <- function(CV_output) {
#     CV_output %>% 
#         group_by_at(.vars = vars(-starts_with("id"), 
#                                  -truth_tbl, 
#                                  -auc, 
#                                  -full_roc)) %>% 
#         summarise(all_auc = list(auc), 
#                   mean_auc = mean(auc), 
#                   var_auc = pop_var(auc)) %>% 
#         ungroup()
# }
# 
# boxplot_AUC <- function(CV_tbl, hyperparam) {
#     hyperparam <- enquo(hyperparam)
#     CV_tbl %>% 
#         unnest(all_auc) %>% 
#         mutate(!!hyperparam := factor(!!hyperparam)) %>% 
#         ggplot(aes(x = !!hyperparam, y = all_auc)) +
#         geom_boxplot() +
#         geom_point(aes(y = mean_auc), 
#                    CV_tbl %>% 
#                        unnest(all_auc) %>% 
#                        mutate(!!hyperparam := factor(!!hyperparam)) %>% 
#                        group_by(!!hyperparam) %>% 
#                        summarise(mean_auc = mean(all_auc)), 
#                    colour = "red") + 
#         theme_light() +
#         labs(
#             y = "AUC", 
#             title = paste("AUC scores for hyperparameter:", 
#                           rlang::as_label(hyperparam))
#         )
# }
# 
# scatterplot_AUC <- function(CV_tbl, hyperparam) {
#     hyperparam <- enquo(hyperparam)
#     CV_tbl %>% 
#         unnest(all_auc) %>% 
#         ggplot(aes(x = !!hyperparam, y = all_auc)) +
#         geom_point(alpha = 0.5) +
#         geom_point(aes(y = mean_auc), 
#                    CV_tbl %>% 
#                        unnest(all_auc) %>% 
#                        group_by(!!hyperparam) %>% 
#                        summarise(mean_auc = mean(all_auc)), 
#                    colour = "red") + 
#         theme_light() +
#         labs(
#             y = "AUC", 
#             title = paste("AUC scores for hyperparameter:", 
#                           rlang::as_label(hyperparam))
#         )
# }
