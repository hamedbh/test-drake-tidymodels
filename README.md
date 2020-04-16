Testing `{drake}` and `{tidymodels}`
================

This is an example of predictive modelling using:

  - The [`{drake}`](https://docs.ropensci.org/drake/) package for
    dependency management;
  - The [`{tidymodels}`](https://github.com/tidymodels/tidymodels)
    family of packages for modelling.

This uses the [German Credit
dataset](http://archive.ics.uci.edu/ml/datasets/statlog+\(german+credit+data\)),
predicting a binary outcome of default (`bad`), or paying off the credit
in full (`good`).

# Exploratory Data Analysis

Some example EDA steps are here. We might start with
[skimr](https://github.com/ropensci/skimr) to get some summary stats on
the training data.

``` r
# Read in the training data from the drake cache with readd()
skim(readd(g_train))
```

|                                                  |                 |
| :----------------------------------------------- | :-------------- |
| Name                                             | readd(g\_train) |
| Number of rows                                   | 802             |
| Number of columns                                | 21              |
| \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_   |                 |
| Column type frequency:                           |                 |
| factor                                           | 14              |
| numeric                                          | 7               |
| \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_ |                 |
| Group variables                                  | None            |

Data summary

**Variable type: factor**

| skim\_variable           | n\_missing | complete\_rate | ordered | n\_unique | top\_counts                               |
| :----------------------- | ---------: | -------------: | :------ | --------: | :---------------------------------------- |
| acct\_status             |          0 |              1 | FALSE   |         4 | no\_: 319, ove: 217, bel: 211, ove: 55    |
| credit\_history          |          0 |              1 | FALSE   |         5 | all: 414, cri: 241, pas: 76, all: 38      |
| purpose                  |          0 |              1 | FALSE   |        10 | rad: 218, car: 191, fur: 151, car: 80     |
| savings\_acct            |          0 |              1 | FALSE   |         5 | to\_: 490, unk: 151, to\_: 78, to\_: 46   |
| present\_emp\_since      |          0 |              1 | FALSE   |         5 | to\_: 270, ove: 200, to\_: 144, to\_: 135 |
| other\_debtor\_guarantor |          0 |              1 | FALSE   |         3 | non: 722, gua: 42, co\_: 38               |
| property                 |          0 |              1 | FALSE   |         4 | car: 264, rea: 230, sav: 181, unk: 127    |
| other\_debts             |          0 |              1 | FALSE   |         3 | non: 650, ban: 115, sto: 37               |
| housing                  |          0 |              1 | FALSE   |         3 | own: 574, ren: 136, for: 92               |
| job                      |          0 |              1 | FALSE   |         4 | ski: 502, uns: 160, mgm: 120, une: 20     |
| telephone                |          0 |              1 | FALSE   |         2 | no: 471, yes: 331                         |
| foreign\_worker          |          0 |              1 | FALSE   |         2 | yes: 772, no: 30                          |
| gender                   |          0 |              1 | FALSE   |         2 | mal: 554, fem: 248                        |
| outcome                  |          0 |              1 | FALSE   |         2 | goo: 561, bad: 241                        |

**Variable type: numeric**

| skim\_variable          |   n\_missing | complete\_rate |    mean |      sd |  p0 |    p25 |    p50 |    p75 |  p100 | hist  |
| :---------------------- | -----------: | -------------: | ------: | ------: | --: | -----: | -----: | -----: | ----: | :---- |
| duration                |            0 |              1 |   20.96 |   12.28 |   4 |   12.0 |   18.0 |   24.0 |    72 | ▇▇▂▁▁ |
| amount                  |            0 |              1 | 3332.89 | 2908.21 | 250 | 1364.5 | 2321.5 | 4036.5 | 18424 | ▇▂▁▁▁ |
| pct\_of\_income         |            0 |              1 |    2.97 |    1.12 |   1 |    2.0 |    3.0 |    4.0 |     4 | ▂▃▁▂▇ |
| resident\_since         |            0 |              1 |    2.84 |    1.10 |   1 |    2.0 |    3.0 |    4.0 |     4 | ▂▆▁▃▇ |
| age                     |            0 |              1 |   35.55 |   11.50 |  19 |   27.0 |   33.0 |   42.0 |    75 | ▇▆▃▁▁ |
| num\_existing\_credits  |            0 |              1 |    1.42 |    0.58 |   1 |    1.0 |    1.0 |    2.0 |     4 | ▇▅▁▁▁ |
| num\_dependents         |            0 |              1 |    1.15 |    0.35 |   1 |    1.0 |    1.0 |    1.0 |     2 | ▇▁▁▁▂ |
| So there is no issue wi | th missing v |         alues. |         |         |     |        |        |        |       |       |

We can visualise the distributions for the variables, starting with the
categorical. Note that the plot objects were created in the drake plan,
and are included here using `readd()`.

``` r
readd(barplot_grid)
```

![](man/figures/factor%20barplots-1.png)<!-- -->

``` r
readd(density_plot_grid)
```

![](man/figures/density%20plot%20grid-1.png)<!-- -->

``` r
readd(integer_plot_grid)
```

![](man/figures/integer%20plot%20grid-1.png)<!-- -->

The distribution for `amount` is quite skewed, perhaps a log scale will
be more informative.

``` r
readd(log_plot_amount)
```

![](man/figures/log%20plot%20amount-1.png)<!-- -->

# Modelling

We will use five model types:

1.  Decision trees (using `{rpart}`);
2.  Random forest (`{ranger}`);
3.  Gradient-boosted decision trees (`{xgboost}`);
4.  Support vector machines with radial basis function (`{kernlab}`);
5.  Elastic-net regularised logistic regression (`{glmnet}`).

The approach for each is largely the same:

1.  Define a data pre-processing specification using
    [`{recipes}`](https://tidymodels.github.io/recipes/);
2.  Define the model specification using the unified model interface
    from [`{parsnip}`](https://tidymodels.github.io/parsnip/);
3.  Combine the model and pre-processing objects into a
    [`workflow()`](https://tidymodels.github.io/workflows/);
4.  Extract the parameters from the workflow object and create a tuning
    grid (either regular or a space-filling type);
5.  Tune the hyperparameters with
    [`{tune}`](https://tidymodels.github.io/tune/), using the tuning
    grid from 4;
6.  Use the results from the grid tuning as the initial results for
    Bayesian Optimisation. NB. skipped this step for elastic net as the
    submodel trick means we can test all combinations of 41 values for
    each of `penalty` (i.e. `lambda`) and `mixture` (`alpha`) for the
    cost of training only the 41 values of `mixture`. That gives
    \(41^2 = 1681\) hyperparameter combinations, which is ample.

We can examine the object created by tuning.

``` r
readd(xgb_reg_bayes_tune)
#> #  5-fold cross-validation using stratification 
#> # A tibble: 105 x 6
#>    splits          id    .metrics         .notes         .predictions        .iter
#>  * <list>          <chr> <list>           <list>         <list>              <dbl>
#>  1 <split [640/16… Fold1 <tibble [192 × … <tibble [0 × … <tibble [31,104 × …     0
#>  2 <split [642/16… Fold2 <tibble [192 × … <tibble [0 × … <tibble [30,720 × …     0
#>  3 <split [642/16… Fold3 <tibble [192 × … <tibble [0 × … <tibble [30,720 × …     0
#>  4 <split [642/16… Fold4 <tibble [192 × … <tibble [0 × … <tibble [30,720 × …     0
#>  5 <split [642/16… Fold5 <tibble [192 × … <tibble [0 × … <tibble [30,720 × …     0
#>  6 <split [640/16… Fold1 <tibble [1 × 7]> <tibble [0 × … <tibble [162 × 8]>      1
#>  7 <split [642/16… Fold2 <tibble [1 × 7]> <tibble [0 × … <tibble [160 × 8]>      1
#>  8 <split [642/16… Fold3 <tibble [1 × 7]> <tibble [0 × … <tibble [160 × 8]>      1
#>  9 <split [642/16… Fold4 <tibble [1 × 7]> <tibble [0 × … <tibble [160 × 8]>      1
#> 10 <split [642/16… Fold5 <tibble [1 × 7]> <tibble [0 × … <tibble [160 × 8]>      1
#> # … with 95 more rows
```

We will see how to use this in more detail in the [Model
evaluation](#model-evaluation) section. It has certain useful methods
available, including `autoplot()`. For brevity I have shown this for
just XGBoost.

``` r
readd(xgb_reg_bayes_tune) %>% 
    autoplot(type = "performance") + 
    # the autoplot() object is a ggplot, so we can modify it as needed
    labs(
        title = "Area under the ROC curve during Bayesian Optimisation"
    )
```

![](man/figures/bayesopt%20by%20iteration-1.png)<!-- -->

``` r
readd(xgb_reg_bayes_tune) %>% 
    autoplot(type = "parameters") + # this is the default type
    labs(
        title = "Parameter values used during Bayesian Optimisation"
    )
```

![](man/figures/bayesopt%20by%20parameter-1.png)<!-- -->

``` r
readd(xgb_reg_bayes_tune) %>% 
    autoplot(type = "marginals") + 
    labs(
        title = "Model performance by parameter value in Bayesian Optimisation"
    )
```

![](man/figures/bayesopt%20marginals-1.png)<!-- -->

# Model evaluation

The [`{yardstick}`](https://tidymodels.github.io/yardstick/) package
allows us to extract metrics in a tidy format.

``` r
readd(xgb_reg_bayes_tune) %>% 
    collect_metrics()
#> # A tibble: 212 x 10
#>     mtry min_n tree_depth sample_size .iter .metric .estimator  mean     n std_err
#>    <int> <int>      <int>       <dbl> <dbl> <chr>   <chr>      <dbl> <int>   <dbl>
#>  1    23     2          4        0.5      0 roc_auc binary     0.798     5  0.0255
#>  2    23     2          4        0.75     0 roc_auc binary     0.800     5  0.0221
#>  3    23     2          4        1        0 roc_auc binary     0.797     5  0.0232
#>  4    23     2          6        0.5      0 roc_auc binary     0.796     5  0.0242
#>  5    23     2          6        0.75     0 roc_auc binary     0.802     5  0.0240
#>  6    23     2          6        1        0 roc_auc binary     0.799     5  0.0227
#>  7    23     2          8        0.5      0 roc_auc binary     0.798     5  0.0254
#>  8    23     2          8        0.75     0 roc_auc binary     0.796     5  0.0226
#>  9    23     2          8        1        0 roc_auc binary     0.797     5  0.0219
#> 10    23     2         10        0.5      0 roc_auc binary     0.798     5  0.0249
#> # … with 202 more rows
```

That output is just a data frame, which we can manipulate as needed.

``` r
# Get the best-performing iterations
readd(xgb_reg_bayes_tune) %>% 
    collect_metrics() %>% 
    top_n(5, mean) %>% 
    arrange(desc(mean))
#> # A tibble: 5 x 10
#>    mtry min_n tree_depth sample_size .iter .metric .estimator  mean     n std_err
#>   <int> <int>      <int>       <dbl> <dbl> <chr>   <chr>      <dbl> <int>   <dbl>
#> 1    23     2          6        0.75     0 roc_auc binary     0.802     5  0.0240
#> 2    23     2          4        0.75     0 roc_auc binary     0.800     5  0.0221
#> 3    47     2          4        0.5      0 roc_auc binary     0.799     5  0.0253
#> 4    23     2          6        1        0 roc_auc binary     0.799     5  0.0227
#> 5    47     2          8        0.5      0 roc_auc binary     0.798     5  0.0253
```

That particular example can also be done with `show_best()`.

``` r
readd(xgb_reg_bayes_tune) %>% 
    show_best(metric = "roc_auc", 
              n = 5)
#> # A tibble: 5 x 10
#>    mtry min_n tree_depth sample_size .iter .metric .estimator  mean     n std_err
#>   <int> <int>      <int>       <dbl> <dbl> <chr>   <chr>      <dbl> <int>   <dbl>
#> 1    23     2          6        0.75     0 roc_auc binary     0.802     5  0.0240
#> 2    23     2          4        0.75     0 roc_auc binary     0.800     5  0.0221
#> 3    47     2          4        0.5      0 roc_auc binary     0.799     5  0.0253
#> 4    23     2          6        1        0 roc_auc binary     0.799     5  0.0227
#> 5    47     2          8        0.5      0 roc_auc binary     0.798     5  0.0253
```

We can consider the results across all the model types.

``` r
# The tune_results object is a list containing tuning results for all five 
# model types
loadd(tune_results)
```

``` r
map_dfr(tune_results, show_best, metric = "roc_auc", .id = "model") %>% 
    select(model, mean_auc = mean, .iter) %>% 
    arrange(desc(mean_auc)) %>% 
    # Elastic net didn't go through Bayesian Optimisation, so it doesn't have 
    # the .iter variable. Set to 0, i.e. the initial values from grid tuning
    replace_na(list(.iter = 0L))
#> # A tibble: 25 x 3
#>    model         mean_auc .iter
#>    <chr>            <dbl> <dbl>
#>  1 XGBoost          0.802     0
#>  2 XGBoost          0.800     0
#>  3 Random Forest    0.800     0
#>  4 Random Forest    0.799     0
#>  5 XGBoost          0.799     0
#>  6 Random Forest    0.799     0
#>  7 XGBoost          0.799     0
#>  8 XGBoost          0.798     0
#>  9 Random Forest    0.797     0
#> 10 Random Forest    0.797     1
#> # … with 15 more rows
```

XGBoost performs best, followed by Random Forest. The best values mostly
came from grid tuning (i.e. `.iter == 0`), suggesting that more
iterations of Bayesian Optimisation would have been needed to improve on
these.

The results are easy to visualise also.

``` r
map_dfr(tune_results, show_best, n = 10, metric = "roc_auc", .id = "model") %>% 
    replace_na(list(.iter = 0L)) %>% 
    mutate(model = factor(model)) %>% 
    ggplot(aes(x = model, y = mean, colour = model)) + 
    geom_point(alpha = 0.4) + 
    scale_colour_viridis_d(option = "B", 
                           end = 0.7) + 
    theme(legend.position = "none") + 
    labs(
        title = "Top 10 mean values of area under the ROC curve by model type", 
        y = NULL, 
        x = NULL
    )
```

![](man/figures/plot%20tuning%20results-1.png)<!-- --> We can select the
hyperparameters giving the best results with `select_best()`.

``` r
(best_xgb <- tune_results[["XGBoost"]] %>% 
     select_best(metric = "roc_auc"))
#> # A tibble: 1 x 4
#>    mtry min_n tree_depth sample_size
#>   <int> <int>      <int>       <dbl>
#> 1    23     2          6        0.75
```

Use `finalize_workflow()` to generate a workflow object with those
parameters.

``` r
(best_xgb_wfl <- finalize_workflow(
    # read in the XGBoost workflow
    readd(xgb_wfl), 
    parameters = best_xgb
))
#> ══ Workflow ══════════════════════════════════════════════════════════════════════
#> Preprocessor: Recipe
#> Model: boost_tree()
#> 
#> ── Preprocessor ──────────────────────────────────────────────────────────────────
#> 1 Recipe Step
#> 
#> ● step_dummy()
#> 
#> ── Model ─────────────────────────────────────────────────────────────────────────
#> Boosted Tree Model Specification (classification)
#> 
#> Main Arguments:
#>   mtry = 23
#>   trees = 500
#>   min_n = 2
#>   tree_depth = 6
#>   learn_rate = 0.01
#>   sample_size = 0.75
#> 
#> Computational engine: xgboost
```

And then generate a fitted model from that workflow.

``` r
best_xgb_wfl %>% 
    fit(
        # read in the training data
        data = readd(g_train)
    )
#> ══ Workflow [trained] ════════════════════════════════════════════════════════════
#> Preprocessor: Recipe
#> Model: boost_tree()
#> 
#> ── Preprocessor ──────────────────────────────────────────────────────────────────
#> 1 Recipe Step
#> 
#> ● step_dummy()
#> 
#> ── Model ─────────────────────────────────────────────────────────────────────────
#> ##### xgb.Booster
#> raw: 806.8 Kb 
#> call:
#>   xgboost::xgb.train(params = list(eta = 0.01, max_depth = 6L, 
#>     gamma = 0, colsample_bytree = 0.389830508474576, min_child_weight = 2L, 
#>     subsample = 0.75), data = x, nrounds = 500, verbose = 0, 
#>     objective = "binary:logistic", nthread = 1)
#> params (as set within xgb.train):
#>   eta = "0.01", max_depth = "6", gamma = "0", colsample_bytree = "0.389830508474576", min_child_weight = "2", subsample = "0.75", objective = "binary:logistic", nthread = "1", silent = "1"
#> xgb.attributes:
#>   niter
#> # of features: 59 
#> niter: 500
#> nfeatures : 59
```

This has been completed for all five models in the drake plan.

``` r
loadd(final_fits)
```

The [`{vip}`](https://koalaverse.github.io/vip/index.html) package helps
with variable importance plots.

``` r
final_fits[["XGBoost"]] %>% 
    pull_workflow_fit() %>% 
    vip(geom = "point", 
        num_features = 12L) + 
    labs(
        title = "12 most important variables for XGBoost model"
    )
```

![](man/figures/var%20imp%20plot%20XGBoost-1.png)<!-- -->

# Test set performance

XGBoost has performed best overall, so we can evaluate its performance
on the test set.

``` r
xgb_test_preds <- final_fits[["XGBoost"]] %>% 
    predict(new_data = readd(g_test), 
            type = "prob") %>% 
    bind_cols(readd(g_test) %>% 
                  select(outcome))
xgb_test_preds
#> # A tibble: 198 x 3
#>    .pred_bad .pred_good outcome
#>        <dbl>      <dbl> <fct>  
#>  1    0.0499      0.950 good   
#>  2    0.0335      0.967 good   
#>  3    0.662       0.338 bad    
#>  4    0.620       0.380 bad    
#>  5    0.150       0.850 good   
#>  6    0.204       0.796 good   
#>  7    0.0984      0.902 good   
#>  8    0.159       0.841 good   
#>  9    0.238       0.762 good   
#> 10    0.374       0.626 good   
#> # … with 188 more rows

# Generate the full ROC curve
xgb_roc_curve <- roc_curve(xgb_test_preds, truth = outcome, .pred_bad)
#> Warning: partial match of 'se' to 'sensitivities'
#> Warning: partial match of 'sp' to 'specificities'

# Get the AUC value and plot the curve
autoplot(xgb_roc_curve) + 
    labs(
        title = sprintf("AUC for XGBoost model on test set: %.2f", 
                        roc_auc(xgb_test_preds, truth = outcome, .pred_bad) %>% 
                            pull(.estimate))
    )
#> Warning: partial match of 'se' to 'sensitivities'

#> Warning: partial match of 'sp' to 'specificities'
```

![](man/figures/test%20AUC%20XGBoost-1.png)<!-- -->
