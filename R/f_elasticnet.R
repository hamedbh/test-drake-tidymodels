create_elnet_pre_proc <- function(train) {
    set.seed(1400)
    recipe(outcome ~ .,
           data = train) %>%
        step_dummy(all_nominal(),
                   -all_outcomes(),
                   one_hot = TRUE) %>% 
        step_nzv(all_predictors()) %>% 
        step_normalize(all_predictors())
}

define_elnet <- function() {
    logistic_reg(
        penalty = tune(), 
        mixture = tune()
    ) %>% 
        set_mode("classification") %>% 
        set_engine("glmnet")
}
