g_plan <- drake_plan(
    source_data = download.file(
        "https://archive.ics.uci.edu/ml/machine-learning-databases/statlog/german/german.data", 
        file_out(here::here("data/raw/german.data"))
    ), 
    clean_df = get_clean_data(file_in(here::here("data/raw/german.data"))), 
    barplot_grid = plot_barplot_grid(clean_df),
    density_plot_grid = plot_density_grid(clean_df), 
    training_split = partition_data(d = clean_df,
                                    p = 0.8,
                                    RNG_seed = 943),
    g_recipe = create_g_recipe(training_split),
    g_train = create_training(g_recipe),
    g_test = create_testing(g_recipe,
                            training_split),
    cv_folds = create_cv_folds(g_train, 1220), 
    ranger_spec = define_ranger(500, 725),
    ranger_grid = create_ranger_grid(g_train, 5, 737),
    ranger_CV = run_ranger_CV(ranger_spec, ranger_grid, cv_folds),
    ranger_CV_metrics = get_CV_metrics(ranger_CV), 
    mlp_spec = define_mlp(),
    mlp_grid = create_mlp_grid(g_train, c(2L, 3L, 2L), 1802),
    mlp_CV = run_mlp_CV(mlp_spec, mlp_grid, cv_folds),
    mlp_CV_metrics = get_CV_metrics(mlp_CV), 
    xgb_spec = define_xgb(1000, 0.01),
    xgb_grid = create_xgb_grid(g_train, 15, 1031),
    xgb_CV = run_xgb_CV(xgb_spec, xgb_grid, cv_folds),
    xgb_CV_metrics = get_CV_metrics(xgb_CV)
)
