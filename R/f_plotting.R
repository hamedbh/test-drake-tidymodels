plot_barplot_grid <- function(d) {
    d %>%
        dplyr::select(-outcome) %>%
        select_if(is.factor) %>%
        mutate_all(as.character) %>% # this is to avoid an error about factor
        # attributes being lost, but this step isn't
        # strictly necessary as gather() would coerce
        # to character anyway
        tidyr::gather(key = "feature") %>% # gather() turns a wide table to a long one
        ggplot(aes(x = value)) +
        geom_bar() +
        facet_wrap(~ feature, scales = "free_x") +
        theme_minimal() +
        theme(axis.text.x = element_blank()) + 
        labs(
            title = "Distribution of categorical variables", 
            x = NULL
        )
}

plot_density_grid <- function(d) {
    d %>%
        dplyr::select_if(is.integer) %>%
        dplyr::select(-c(num_dependents, 
                         num_existing_credits, 
                         pct_of_income, 
                         resident_since)) %>% 
        tidyr::gather(key = "predictor") %>%
        ggplot(aes(x = value)) +
        geom_density() +
        facet_wrap(~ predictor, scales = "free") +
        theme_minimal() + 
        theme(axis.text.y = element_blank()) + 
        labs(
            title = "Distribution of continuous variables", 
            x = NULL
        )
}

plot_log_amount <- function(d) {
    d %>% 
        ggplot(aes(x = amount)) + 
        geom_density() + 
        theme_minimal() + 
        scale_x_log10(labels = function(x) {
            scales::dollar(x,
                           accuracy = 1, 
                           prefix = "€")
        }) + 
        theme(axis.text.y = element_blank()) + 
        labs(
            title = expression(paste("Distribution of loan amount, ", 
                                     log[10], 
                                     " scale", 
                                     sep = "")), 
            x = NULL
        )
}

plot_integer_grid <- function(d) {
    d %>% 
        dplyr::select(c(num_dependents, 
                        num_existing_credits, 
                        pct_of_income, 
                        resident_since)) %>% 
        tidyr::gather(key = "predictor") %>%
        mutate_all(factor) %>% 
        ggplot(aes(x = value)) +
        geom_bar() +
        facet_wrap(~ predictor, scales = "free") +
        theme_minimal() + 
        labs(
            title = "Distribution of integer variables", 
            x = NULL
        )
}
