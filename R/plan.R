g_plan <- drake_plan(
    source_data = download.file(
        "https://archive.ics.uci.edu/ml/machine-learning-databases/statlog/german/german.data", 
        file_out(here::here("data/raw/german.data"))
    ), 
    clean_df = get_clean_data(file_in(here::here("data/raw/german.data"))),
    training_split = partition_data(d = clean_df,
                                    p = 0.8,
                                    RNG_seed = 943),
    g_train = training(training_split),
    g_test = testing(training_split),
    g_folds = create_cv_folds(g_train, 1738), 
    
    # Plot objects
    barplot_grid = plot_barplot_grid(g_train),
    density_plot_grid = plot_density_grid(g_train),
    
    # XGBoost 
    xgb_rec = create_xgb_pre_proc(g_train),
    xgb_mod = define_xgb(trees = 100, 
                         learn_rate = 0.05),
    xgb_wfl = create_xgb_wflow(xgb_rec, xgb_mod),
    xgb_params = create_xgb_params(xgb_wfl, xgb_rec),
    xgb_grid = create_xgb_grid(xgb_params, 10, 1645), 
    xgb_grid_tune = tune_xgb_grid(
        wflow = xgb_wfl,
        resamples = g_folds,
        grid = xgb_grid,
        params = xgb_params
        ),
    xgb_bayes_tune = tune_xgb_bayes(
        wflow = xgb_wfl,
        resamples = g_folds,
        iter = 20L,
        params = xgb_params,
        grid_results = xgb_grid_tune)
    
    
    # ranger_spec = define_ranger(500, 725),
    # ranger_grid = create_ranger_grid(g_train, 5, 737),
    # ranger_CV = run_ranger_CV(ranger_spec, ranger_grid, cv_folds),
    # ranger_CV_metrics = get_CV_metrics(ranger_CV), 
    
    
)
