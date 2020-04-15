create_svmrbf_pre_proc <- function(train) {
    set.seed(1616)
    recipe(outcome ~ .,
           data = train) %>%
        step_dummy(all_nominal(),
                   -all_outcomes(),
                   one_hot = TRUE) %>% 
        step_nzv(all_predictors()) %>% 
        step_normalize(all_predictors())
}

define_svmrbf <- function() {
    svm_rbf(
        cost = tune(), 
        rbf_sigma = tune()
    ) %>% 
        set_mode("classification") %>% 
        set_engine("kernlab")
}
