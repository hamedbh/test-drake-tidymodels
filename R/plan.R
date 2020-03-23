g_plan <- drake_plan(
    source_data = download.file(
        "https://archive.ics.uci.edu/ml/machine-learning-databases/statlog/german/german.data", 
        file_out(here::here("data/raw/german.data"))
    ), 
    clean_df = get_clean_data(file_in(here::here("data/raw/german.data"))),
    training_split = partition_data(d = clean_df,
                                    p = 0.8,
                                    RNG_seed = 943),
    barplot_grid = plot_barplot_grid(training_split %>% training()),
    density_plot_grid = plot_density_grid(training_split %>% training()),
    g_train = training(training_split),
    g_test = testing(training_split),
    g_folds = create_cv_folds(g_train, 1738), 
    g_recipe = create_g_pre_proc(g_train),
    # ranger_spec = define_ranger(500, 725),
    # ranger_grid = create_ranger_grid(g_train, 5, 737),
    # ranger_CV = run_ranger_CV(ranger_spec, ranger_grid, cv_folds),
    # ranger_CV_metrics = get_CV_metrics(ranger_CV), 
    xgb_mod = define_xgb(10, 0.3),
    # xgb_wflow = create_xgb_wflow(g_recipe, xgb_mod), 
    # xgb_params = create_xgb_params(xgb_wflow,
    #                                training(training_split)),
    # xgb_grid = create_xgb_grid(params = xgb_params,
    #                            size = 10,
    #                            RNG_seed = 2057),
    # xgb_grid_tune = tune_xgb_grid(
    #     wflow = xgb_wflow,
    #     resamples = boots,
    #     params = xgb_params,
    #     grid = xgb_grid),
    # xgb_bayes_tune = tune_xgb_bayes(
    #     wflow = xgb_wflow,
    #     resamples = boots,
    #     params = xgb_params,
    #     grid_results = xgb_grid_tune,
    #     iter = 1L,
    #     RNG_seed = 700)
)
