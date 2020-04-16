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
    integer_plot_grid = plot_integer_grid(g_train), 
    log_plot_amount = plot_log_amount(g_train), 
    
    # Decision trees with rpart
    tree_rec = create_tree_pre_proc(g_train), 
    tree_mod = define_tree_mod(), 
    tree_wfl = workflows::workflow() %>% 
        add_recipe(tree_rec) %>% 
        add_model(tree_mod),
    tree_params = parameters(tree_wfl), 
    tree_grid = create_tree_grid(tree_params, 
                                 size = 10L, 
                                 RNG_seed = 944), 
    tree_grid_tune = tune_tree_grid(
        wflow = tree_wfl,
        resamples = g_folds, 
        grid = tree_grid, 
        params = tree_params
    ), 
    tree_bayes_tune = tune_tree_bayes(
        wflow = tree_wfl,
        resamples = g_folds,
        iter = 20L, 
        params = tree_params,
        grid_results = tree_grid_tune, 
        RNG_seed = 946
    ), 
    
    # XGBoost 
    xgb_rec = create_xgb_pre_proc(g_train),
    xgb_mod = define_xgb(trees = 500, 
                         learn_rate = 0.01),
    xgb_wfl = workflows::workflow() %>% 
        add_recipe(xgb_rec) %>% 
        add_model(xgb_mod),
    xgb_params = create_xgb_params(xgb_wfl, xgb_rec),
    xgb_grid = create_xgb_grid(xgb_params, 10, 1645), 
    xgb_reg_grid = grid_regular(xgb_params, 
                                levels = c(4L, 4L, 4L, 3L)), 
    xgb_reg_grid_tune = tune_xgb_grid(
        wflow = xgb_wfl,
        resamples = g_folds,
        grid = xgb_reg_grid,
        params = xgb_params
    ),
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
        grid_results = xgb_grid_tune, 
        RNG_seed = 1699), 
    xgb_reg_bayes_tune = tune_xgb_bayes(
        wflow = xgb_wfl,
        resamples = g_folds,
        iter = 20L,
        params = xgb_params,
        grid_results = xgb_reg_grid_tune, 
        RNG_seed = 1600), 
    
    # Random Forest with ranger 
    
    # Can re-use the XGBoost pre-proc object, jump straight to model
    ranger_mod = define_ranger(725),
    ranger_wfl = workflows::workflow() %>% 
        add_recipe(xgb_rec) %>% 
        add_model(ranger_mod), 
    ranger_params = create_ranger_params(ranger_wfl, xgb_rec), 
    ranger_grid = grid_regular(ranger_params, levels = 3L),
    ranger_grid_tune = tune_ranger_grid(
        wflow = ranger_wfl,
        resamples = g_folds, 
        grid = ranger_grid, 
        params = ranger_params), 
    ranger_bayes_tune = tune_ranger_bayes(
        wflow = ranger_wfl,
        resamples = g_folds,
        iter = 20L, 
        params = ranger_params,
        grid_results = ranger_grid_tune, 
        RNG_seed = 1109), 
    
    # Support Vector Machine with Radial Basis Function
    svmrbf_rec = create_svmrbf_pre_proc(g_train), 
    svmrbf_mod = define_svmrbf(), 
    svmrbf_wfl = workflows::workflow() %>% 
        add_model(svmrbf_mod) %>% 
        add_recipe(svmrbf_rec), 
    # Can extract the parameters directly from workflow, no custom function 
    # required
    svmrbf_params = parameters(svmrbf_wfl), 
    svmrbf_grid = grid_max_entropy(svmrbf_params, 
                                   size = 10L),
    # reuse the ranger grid functions, all the same
    svmrbf_grid_tune = tune_ranger_grid(
        wflow = svmrbf_wfl,
        resamples = g_folds,
        grid = svmrbf_grid,
        params = svmrbf_params),
    svmrbf_bayes_tune = tune_ranger_bayes(
        wflow = svmrbf_wfl,
        resamples = g_folds,
        iter = 20L,
        params = svmrbf_params,
        grid_results = svmrbf_grid_tune,
        RNG_seed = 1155),
    
    # Elastic net, regularised logistic regression
    elnet_rec = create_elnet_pre_proc(g_train), 
    elnet_mod = define_elnet(), 
    elnet_wfl = workflows::workflow() %>% 
        add_model(elnet_mod) %>% 
        add_recipe(elnet_rec), 
    elnet_params = parameters(elnet_wfl) %>% 
        update(mixture = mixture(range = c(0, 1))), 
    elnet_grid = grid_regular(elnet_params, 
                              levels = 41), 
    elnet_grid_tune = tune_ranger_grid(
        wflow = elnet_wfl,
        resamples = g_folds,
        grid = elnet_grid,
        params = elnet_params), 
    
    # List of all the tuning results, for convenience. Could due this more 
    # compactly by using the map() and/or cross() transforms available in drake
    tune_results = list(
        CART = tree_bayes_tune, 
        "Random Forest" = ranger_bayes_tune, 
        XGBoost = xgb_reg_bayes_tune, 
        SVM = svmrbf_bayes_tune, 
        "Elastic Net" = elnet_grid_tune
    ), 
    # same for the workflows
    all_wfl = list(
        CART = tree_wfl, 
        "Random Forest" = ranger_wfl, 
        XGBoost = xgb_wfl, 
        SVM = svmrbf_wfl, 
        "Elastic Net" = elnet_wfl
    ), 
    final_fits = map2(
        all_wfl, 
        purrr::map(tune_results, 
                   select_best, 
                   "roc_auc"), 
        ~ finalize_workflow(.x, .y) %>% 
            fit(data = g_train)), 
    
    report = rmarkdown::render(
        knitr_in("report.Rmd"), 
        output_format = "github_document", 
        output_file = file_out("report.md"), 
        quiet = TRUE
    )
)
