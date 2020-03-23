read_raw_data <- function(data_path) {
    # column names taken from the data dictionary, slightly changed to keep 
    # lengths reasonable
    column_names <- c("acct_status", "duration", "credit_history", 
                      "purpose", "amount", "savings_acct", 
                      "present_emp_since", "pct_of_income", "sex_status", 
                      "other_debtor_guarantor", "resident_since", "property", 
                      "age", "other_debts", "housing", 
                      "num_existing_credits", "job", "num_dependents", 
                      "telephone", "foreign_worker", "outcome")
    # set the column types manually to avoid any coercion errors
    column_types <- c("ciccicciccicicciciccc")
    
    readr::read_delim(data_path, 
                      delim = " ", 
                      col_names = column_names, 
                      col_types = column_types)
    
}

get_clean_data <- function(data_path) {
    read_raw_data(data_path) %>% 
        # details of the factors are taken from the data dictionary
        # Can ignore warnings, which are because there are no rows with the 
        # given Axx code. These manipulations use functions from the forcats 
        # package, which makes factors much easier
        mutate(
            acct_status = fct_recode(
                acct_status, 
                overdrawn = "A11",
                below_200DM = "A12",
                over_200DM = "A13",
                no_acct = "A14"
            ),
            credit_history = fct_recode(
                credit_history,
                none_taken_all_paid = "A30",
                all_paid_this_bank = "A31",
                all_paid_duly = "A32",
                past_delays = "A33",
                critical_acct = "A34"
            ),
            purpose = fct_recode(
                purpose,
                car_new = "A40",
                car_used = "A41",
                furniture_equipment = "A42",
                radio_tv = "A43",
                dom_appliance = "A44",
                repairs = "A45",
                education = "A46",
                retraining = "A48",
                business = "A49",
                others = "A410"
            ),
            savings_acct = fct_recode(
                savings_acct,
                to_100DM = "A61",
                to_500DM = "A62",
                to_1000DM = "A63",
                over_1000DM = "A64",
                unknwn_no_acct = "A65"
            ),
            present_emp_since = fct_recode(
                present_emp_since,
                unemployed = "A71",
                to_1_yr = "A72",
                to_4_yrs = "A73",
                to_7_yrs = "A74",
                over_7_yrs = "A75"
            ),
            sex_status = fct_recode(
                sex_status,
                male_divorced = "A91",
                female_married = "A92",
                male_single = "A93",
                male_married = "A94"
            ),
            other_debtor_guarantor = fct_recode(
                other_debtor_guarantor,
                none = "A101",
                co_applicant = "A102",
                guarantor = "A103"
            ),
            property = fct_recode(
                property,
                real_estate = "A121",
                savings_insurance = "A122",
                car_other = "A123",
                unknwn_none = "A124"
            ),
            other_debts = fct_recode(
                other_debts,
                bank = "A141",
                stores = "A142",
                none = "A143"
            ),
            housing = fct_recode(
                housing,
                rent = "A151",
                own = "A152",
                for_free = "A153"
            ),
            job = fct_recode(
                job,
                unemp_unskilled_nonres = "A171",
                unskilled_res = "A172",
                skilled_official = "A173",
                mgmt_highqual = "A174"
            ),
            telephone = fct_recode(telephone,
                                   no = "A191",
                                   yes = "A192"),
            foreign_worker = fct_recode(foreign_worker,
                                        yes = "A201",
                                        no = "A202"),
            outcome = fct_recode(outcome,
                                 good = "1",
                                 bad = "2") %>% 
                fct_relevel("bad")
        ) %>%
        # add another factor for gender, a simplification of sex_status, which can
        # then be compared during EDA
        mutate(
            gender = fct_collapse(
                sex_status,
                male = "male_divorced",
                male = "male_single",
                male = "male_married",
                female = "female_married"
            )
        ) %>%
        select(-outcome, everything()) %>%
        select(-sex_status)
}

partition_data <- function(d, p, RNG_seed) {
    set.seed(seed = RNG_seed)

    d %>%
        initial_split(data = d,
                      prop = p,
                      strata = outcome)
}

create_cv_folds <- function(dtrain, RNG_seed) {
    set.seed(RNG_seed)
    vfold_cv(dtrain,
             v = 3,
             repeats = 1,
             strata = outcome)
}

create_g_pre_proc <- function(dtrain) {
    set.seed(1118)
    recipe(outcome ~ .,
           data = dtrain) %>%
        step_dummy(all_nominal(),
                   -all_outcomes(),
                   one_hot = TRUE) %>%
        step_normalize(all_numeric()) %>%
        step_downsample(outcome)
}

