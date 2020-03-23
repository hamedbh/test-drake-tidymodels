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
        theme(axis.text.x = element_blank())
}


plot_density_grid <- function(d) {
    # then histograms for integers
    d %>%
        dplyr::select_if(is.integer) %>%
        tidyr::gather(key = "predictor") %>%
        ggplot(aes(x = value)) +
        geom_density() +
        facet_wrap(~ predictor, scales = "free") +
        theme_minimal()
}
