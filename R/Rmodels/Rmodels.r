# **Topics**
#
# * Formula interface for model specification
# * Function methods for extracting quantities of interest from models
# * Contrasts to test specific hypotheses
# * Model comparisons
# * Predicted marginal effects

# ## Setup
#
# ### Class Structure
#
# * Informal --- Ask questions at any time. Really!
# * Collaboration is encouraged - please spend a minute introducing yourself to your neighbors!
#
# ### Prerequisites
#
# This is an intermediate R course:
#
# * Assumes working knowledge of R
# * Relatively fast-paced
# * This is not a statistics course! We will teach you *how* to fit models in R,
#   but we assume you know the theory behind the models.
#
# ### Goals
#
# We will learn about the R modeling ecosystem by fitting a variety of statistical models to
# different datasets. In particular, our goals are to learn about:
#
# 1. Modeling workflow
# 2. Visualizing and summarizing data before modeling
# 3. Modeling continuous outcomes
# 4. Modeling binary outcomes
# 5. Modeling clustered data
#
# We will not spend much time *interpreting* the models we fit, since this is not a statistics workshop.
# But, we will walk you through how model results are organized and orientate you to where you can find
# typical quantities of interest.
#
# ### Launch an R session
#
# Start RStudio and create a new project:
#
# * On Windows click the start button and search for RStudio. On Mac
#     RStudio will be in your applications folder.
# * In Rstudio go to `File -> New Project`.
# * Choose `Existing Directory` and browse to the workshop materials directory on your desktop.
# * Choose `File -> Open File` and select the file with the word "BLANK" in the name.
#
# ### Packages
#
# You should have already installed the `tidyverse` and `rmarkdown`
# packages onto your computer before the workshop
# --- see [R Installation](./Rinstall.html).
# Now let's load these packages into the search path of our R session.

library(tidyverse)
library(rmarkdown)

# Finally, lets install some packages that will help with modeling:

# install.packages("lme4")
library(lme4)  # for mixed models

# install.packages("emmeans")
library(emmeans)  # for marginal effects

# install.packages("effects")
library(effects)  # for predicted marginal means

# ## Modeling workflow
#
# Before we delve into the details of how to fit models in R, it's worth taking a step
# back and thinking more broadly about the components of the modeling process. These
# can roughly be divided into 3 stages:
#
# 1. Pre-estimation
# 2. Estimation
# 3. Post-estimaton
#
# At each stage, the goal is to complete a different task (e.g., to clean data, fit a model, test a hypothesis),
# but the process is sequential --- we move through the stages in order (though often many times in one project!)
#
# ![](R/Rmodels/images/R_model_pipeline.png)
#
# Throughout this workshop we will go through these stages several times as we fit different types of model.
#
# ## R modeling ecosystem
#
# There are literally hundreds of R packages that provide model fitting functionality.
# We're going to focus on just two during this workshop --- `stats`, from Base R, and
# `lme4`. It's a good idea to look at [CRAN Task Views](https://cran.r-project.org/web/views/) 
# when trying to find a modeling package for your needs, as they provide an extensive 
# curated list. But, here's a more digestable table showing some of the most popular
#  packages for particular types of model.
#
# | Models              | Packages                               |             
# |:--------------------|:---------------------------------------|
# | Generalized linear  | `stats`, `biglm`, `MASS`, `robustbase` | 
# | Mixed effects       | `lme4`, `nlme`, `glmmTMB`, `MASS`      |                                     
# | Econometric         | `pglm`, `VGAM`, `pscl`, `survival`     | 
# | Bayesian            | `brms`, `blme`, `MCMCglmm`, `rstan`    | 
# | Machine learning    | `mlr`, `caret`, `h2o`, `tensorflow`    | 

# ## Before fitting a model
#
# <div class="alert alert-info">
# **GOAL: To learn about the data by creating summaries and visualizations.**
# </div>
#
# One important part of the pre-estimation stage of model fitting, is gaining an understanding
# of the data we wish to model by creating plots and summaries. Let's do this now.
#
# ### Load the data
#
# List the data files we're going to work with:

list.files("dataSets")

# We're going to use the `states` data first, which originally appeared in *Statistics with Stata* by Lawrence C. Hamilton.

  # read the states data
  states_data <- read_rds("dataSets/states.rds")

  # look at the last few rows
  tail(states_data)

# | Variable | Description                                        |
# |:---------|:---------------------------------------------------|
# | csat     | Mean composite SAT score                           |
# | expense  | Per pupil expenditures                             |
# | percent  | % HS graduates taking SAT                          |
# | income   | Median household income, $1,000                    |
# | region   | Geographic region: West, N. East, South, Midwest   |
# | house    | House '91 environ. voting, %                       |
# | senate   | Senate '91 environ. voting, %                      |
# | energy   | Per capita energy consumed, Btu                    |
# | metro    | Metropolitan area population, %                    |
# | waste    | Per capita solid waste, tons                       |

# ### Examine the data
#
# Start by examining the data to check for problems.

  # summary of expense and csat columns, all rows
  sts_ex_sat <- 
      states_data %>% 
      select(expense, csat)
  
  summary(sts_ex_sat)

  # correlation between expense and csat
  cor(sts_ex_sat, use = "pairwise") 

# ### Plot the data
#
# Plot the data to look for multivariate outliers, non-linear relationships etc.

  # scatter plot of expense vs csat
  plot(sts_ex_sat)

# ![](R/Rmodels/images/statesCorr1.png)
#
# Obviously, in a real project, you would want to spend more time investigating the data,
# but we'll now move on to modeling.

# ## Models with continuous outcomes
#
# <div class="alert alert-info">
# **GOAL: To learn about the R modeling ecosystem by fitting ordinary least squares (OLS) models.** In particular:
#
# 1. Formula representation of a model specification
# 2. Model classes
# 3. Function methods
# 4. Model comparison
# </div>
#
# Once the data have been inspected and cleaned, we can start estimating models.
# The simplest models (but those with the most assumptions) are those for continuous and unbounded outcomes.
# Typically, for these outcomes, we'd use a model estimated using Ordinary Least Lquares (OLS),
# which in R can be fit with the `lm()` (linear model) function.
#
# To fit a model in R, we first have to convert our theoretical model into
# a `formula` --- a symbolic representation of the model in R syntax:

# formula for model specification
outcome ~ pred1 + pred2 + pred3

# NOTE the ~ is a tilde

# For example, the following model predicts SAT scores based on per-pupil expenditures:
#
# <div class="alert alert-secondary">
# $$
# csat_i = \beta_01 + \beta_1expense_i + \epsilon_i
# $$
# </div>
#
# We can use `lm()` to fit this model:

  # Fit our regression model
  sat_mod <- lm(csat ~ 1 + expense, # regression formula
                data = states_data) # data 
                
  # Summarize and print the results
  summary(sat_mod) %>% coef() # show regression coefficients table

# ### Why is the association between expense & SAT scores *negative*?
#
# Many people find it surprising that the per-capita expenditure on students is negatively related to SAT scores. The beauty of multiple regression is that we can try to pull these apart. What would the association between expense and SAT scores be if there were no difference among the states in the percentage of students taking the SAT?

  lm(csat ~ 1 + expense + percent, data = states_data) %>% 
  summary() 

# ### The `lm` class & methods
#
# Okay, we fitted our model. Now what? Typically, the main goal in the **post-estimation stage** of analysis
# is to extract **quantities of interest** from our fitted model. These quantities could be things like:
#
# 1. Testing whether one group is different on average from another group
# 2. Generating average response values from the model for interesting combinations of predictor values
# 3. Calculating interval estimates for particular coefficients
#
# But before we can do any of that, we need to know more about **what a fitted model actually is,**
# **what information it contains, and how we can extract from it information that we want to report**.
#
# Let's start by examining the model object:

  class(sat_mod)
  str(sat_mod)
  names(sat_mod)
  methods(class = class(sat_mod))

# We can use `function methods` to get more information about the fit:

  summary(sat_mod)
  summary(sat_mod) %>% coef()
  methods("summary")
  confint(sat_mod)

# How does R know which method to call for a given object? 
# R uses `generic functions`, which provide access to `methods`. 
# Method dispatch takes place based on the `class` of the
# first argument to the generic function. For example, for the generic 
# function `summary()` and an object of class `lm`, the method 
# dispatched will be `summary.lm()`. Function methods always take 
# the form `generic.method()`:
#
# ![](R/Rmodels/images/methods.png)
#
# It's always worth examining what function methods are available for the class of model you're fitting.
# Here's a summary table of some of the most often used methods. These are post-estimation tools you
# will want in your toolbox:
#
# | Function      | Package        | Output                                                  |
# |:--------------|:---------------|:--------------------------------------------------------|
# | `summary()`   | `stats` base R | standard errors, test statistics, p-values, GOF stats   |
# | `confint()`   | `stats` base R | confidence intervals                                    |
# | `anova()`     | `stats` base R | anova table (one model), model comparison (> one model) |
# | `coef()`      | `stats` base R | point estimates                                         |
# | `drop1()`     | `stats` base R | model comparison                                        |
# | `predict()`   | `stats` base R | predicted response values                               |
# | `fitted()`    | `stats` base R | predicted response values (for observed data)           |
# | `residuals()` | `stats` base R | residuals                                               |
# | `fixef()`     | `lme4`         | fixed effect point estimates (mixed models only)        |
# | `ranef()`     | `lme4`         | random effect point estimates (mixed models only)       |
# | `coef()`      | `lme4`         | empirical Bayes estimates (mixed models only)           |
# | `allEffects()`| `effects`      | predicted marginal means                                |
# | `emmeans()`   | `emmeans`      | predicted marginal means & marginal effects             |
# | `margins()`   | `margins`      | predicted marginal means & marginal effects             |

# ### OLS regression assumptions
#
# OLS regression relies on several assumptions, including:
#
# 1. The model includes all relevant variables (i.e., no omitted variable bias).
# 2. The model is linear in the parameters (i.e., the coefficients and error term).
# 3. The error term has an expected value of zero.
# 4. All right-hand-side variables are uncorrelated with the error term.
# 5. No right-hand-side variables are a perfect linear function of other RHS variables.
# 6. Observations of the error term are uncorrelated with each other.
# 7. The error term has constant variance (i.e., homoscedasticity).
# 8. (Optional - only needed for inference). The error term is normally distributed.
#
# Investigate assumptions #7 and #8 visually by plotting your model:

  par(mfrow = c(2, 2)) # splits the plotting window into 4 panels
  plot(sat_mod)

# ### Comparing models
#
# Do congressional voting patterns predict SAT scores over and above expense? Fit two models and compare them:

  # fit another model, adding house and senate as predictors
  sat_voting_mod <- lm(csat ~ 1 + expense + house + senate,
                        data = na.omit(states_data))

  summary(sat_voting_mod) %>% coef()

# Why are we using `na.omit()`? Let's see what `na.omit()` does.

# fake data
dat <- data.frame(
  x = 1:5,
  y = c(3, 2, 1, NA, 5),
  z = c(6, NA, 2, 7, 3))
dat

na.omit(dat) # listwise deletion of observations

# also see
# ?complete.cases
dat[with(dat, complete.cases(x, y, z)), ]

# To compare models, we must fit them to the same data. This is why we need `na.omit()`.
# Now let's update our first model using `na.omit()`:

  sat_mod <- update(sat_mod, data = na.omit(states_data))

  # compare using an F-test with the anova() function
  anova(sat_mod, sat_voting_mod)

# ### Exercise 0
#
# **Ordinary least squares regression**
#
# Use the *states.rds* data set. Fit a model predicting energy consumed per capita (energy) from the percentage of residents living in metropolitan areas (`metro`). Be sure to
#
# 1.  Examine/plot the data before fitting the model
## 

# 2.  Print and interpret the model `summary()`
## 

# 3.  `plot()` the model to look for deviations from modeling assumptions
## 

# 4. Select one or more additional predictors to add to your model and repeat steps 1-3. Is this model significantly better than the model with `metro` as the only predictor?
## 


# ## Interactions & factors
#
# <div class="alert alert-info">
# **GOAL: To learn how to specify interaction effects and fit models with categorical predictors.** In particular:
#
# 1. Formula syntax for interaction effects
# 2. Factor levels and labels
# 3. Contrasts and pairwise comparisons
# </div>
#
# ### Modeling interactions
#
# Interactions allow us assess the extent to which the association between one predictor and the outcome depends on a second predictor. For example: Does the association between expense and SAT scores depend on the median income in the state?

  # Add the interaction to the model
  sat_expense_by_percent <- lm(csat ~ 1 + expense + income + expense : income, data = states_data)

  # same as above, but shorter syntax
  sat_expense_by_percent <- lm(csat ~ 1 + expense * income, data = states_data) 

  # Show the regression coefficients table
  summary(sat_expense_by_percent) %>% coef() 

# ### Regression with categorical predictors
#
# Let's try to predict SAT scores from region, a categorical variable. 
# Note that you must make sure R does not think your categorical variable is numeric.

  # make sure R knows region is categorical
  str(states_data$region)
  states_data$region <- factor(states_data$region)

  # arguments to the factor() function
  # factor(x, levels, labels)

  levels(states_data$region)

  # Add region to the model
  sat_region <- lm(csat ~ 1 + region, data = states_data) 

  # Show the results
  summary(sat_region) %>% coef() # show the regression coefficients table
  anova(sat_region) # show ANOVA table

# So, make sure to tell R which variables are categorical by converting them to factors!

# ### Setting factor reference groups & contrasts
#
# **Contrasts** is the umbrella term used to describe the process of testing linear combinations of parameters from regression models.
# All statistical sofware use contrasts, but each sofware has different defaults and their own way of overriding these.
#
# The default contrasts in R are "treatment" contrasts (aka "dummy coding"), where each level within a factor
# is identified within a matrix of binary `0` / `1` variables, with the first level chosen as the reference category.
# They're called "treatment" contrasts, because of the typical use case where there is one control group (the reference group)
# and one or more treatment groups that are to be compared to the controls. It is easy to change the default contrasts to something
# other than treatment contrasts, though this is rarely needed. More often, we may want to change the reference group in
# treatment contrasts or get all sets of pairwise contrasts between factor levels.

  # change the reference group
  states_data$region <- relevel(states_data$region, ref = "Midwest")
  m1 <- lm(csat ~ 1 + region, data = states_data)
  summary(m1) %>% coef()

  # get all pairwise contrasts between means
  means <- emmeans(m1, specs = ~ region)
  means
  contrast(means, method = "pairwise")


# ### Exercise 1
#
# **Interactions & factors**
#
# Use the `states` data set.
#
# 1.  Add on to the regression equation that you created in Exercise 1 by generating an interaction term and testing the interaction.
## 

# 2.  Try adding region to the model. Are there significant differences across the four regions?
## 


# ## Models with binary outcomes
#
# <div class="alert alert-info">
# **GOAL: To learn how to use the `glm()` function to model binary outcomes.** In particular:
#
# 1. The `family` and `link` components of the `glm()` function call
# 2. Transforming model coefficients into odds ratios
# 3. Transforming model coefficients into predicted marginal means
# </div>
#
# ### Logistic regression
#
# This far we have used the `lm()` function to fit our regression models. `lm()` is great, but limited --- in particular it only fits models for continuous dependent variables. For categorical dependent variables we can use the `glm()` function.
#
# For these models we will use a different dataset, drawn from the National Health Interview Survey. From the [CDC website](http://www.cdc.gov/nchs/nhis.htm):
#
# > The National Health Interview Survey (NHIS) has monitored the health of the nation since 1957. NHIS data on a broad range of health topics are collected through personal household interviews. For over 50 years, the U.S. Census Bureau has been the data collection agent for the National Health Interview Survey. Survey results have been instrumental in providing data to track health status, health care access, and progress toward achieving national health objectives.
#
# Load the National Health Interview Survey data:

  NH11 <- read_rds("dataSets/NatHealth2011.rds")

# ### Logistic regression example
#
# Motivation for a logistic regression model --- with a binary response:
#
# 1. Errors will not be normally distributed
# 2. Variance will not be homoskedastic
# 3. Predictions should be constrained to be on the interval [0, 1]
#
# ![](R/Rmodels/images/logistic.png)

# Anatomy of a generalized linear model:

  # OLS model using lm()
  lm(outcome ~ 1 + pred1 + pred2, 
     data = mydata)

  # OLS model using glm()
  glm(outcome ~ 1 + pred1 + pred2, 
      data = mydata, 
      family = gaussian(link = "identity"))
 
  # logistic model using glm()
  glm(outcome ~ 1 + pred1 + pred2, 
      data = mydata, 
      family = binomial(link = "logit"))

# The `family` argument sets the error distribution for the model, while the `link` function
# argument relates the predictors to the expected value of the outcome.
#
# Let's predict the probability of being diagnosed with hypertension based on `age`, `sex`, `sleep`, and `bmi`.
# Here's the model:
#
# <div class="alert alert-secondary">
# $$
# logit(hypev_i) = \beta_01 + \beta_1agep_i + \beta_2sex_i + \beta_3sleep_i + \beta_4bmi_i + \epsilon_i 
# $$
# </div>
#
# where $logit(\cdot)$ is the link function, which is equivalent to the log odds of `hypev`:
#
# <div class="alert alert-secondary">
# $$
# logit(hypev_i) = ln \frac{p(hypev_i = 1)}{p(hypev_i = 0)}
# $$
# </div>
#
# And here's how we fit this in R. First, let's clean up the hypertension outcome by making it binary:

  str(NH11$hypev) # check stucture of hypev
  levels(NH11$hypev) # check levels of hypev

  # collapse all missing values to NA
  NH11$hypev <- factor(NH11$hypev, levels=c("2 No", "1 Yes"))

# Now let's use `glm()` to estimate the model:

  # run our regression model
  hyp_out <- glm(hypev ~ 1 + age_p + sex + sleep + bmi,
                 data = NH11, 
                 family = binomial(link = "logit"))

  summary(hyp_out) %>% coef()

# ### Odds ratios
#
# Generalized linear models use link functions to relate the average value of the response to the predictors,
# so raw coefficients are difficult to interpret. For example, the `age` coefficient of .06 in the previous
# model tells us that for every one unit increase in `age`, the log odds of hypertension diagnosis increases
# by 0.06. Since most of us are not used to thinking in log odds this is not too helpful!
#
# One solution is to transform the coefficients to make them easier to interpret.
# Here we transform them into odds ratios by exponentiating:

  # point estimates
  coef(hyp_out) %>% exp()
  
  # confidence intervals
  confint(hyp_out) %>% exp()

# ### Predicted marginal means
#
# Instead of reporting odds ratios, we may want to calculate predicted marginal means (sometimes called "least squares means").
# These are average values of the outcome at particular levels of the predictors. For ease of interpretation, we want these
# marginal means to be on the response scale (i.e., the probability scale). We can use the `effects` package to compute
# these quantities of interest for us (by default, the numerical output will be on the response scale).

  eff <- allEffects(hyp_out)
  plot(eff, type = "response") # "response" refers to the probability scale

  # generate a sequence at which to get predictions of the outcome
  seq(20, 80, by = 5)

  # override defaults
  eff <- allEffects(hyp_out, xlevels = list(age_p = seq(20, 80, by = 5)))
  eff_df <- as.data.frame(eff) # confidence intervals
  eff_df

# ![](R/Rmodels/images/effects1.png)

# ### Exercise 2 
#
# **Logistic regression**
#
# Use the `NH11` data set that we loaded earlier.
#
# 1.  Use `glm()` to conduct a logistic regression to predict ever worked (`everwrk`) using age (`age_p`) and marital status (`r_maritl`). Make sure you only keep the following two levels for `everwrk` (`1 Yes` and `2 No`). Hint: use the `factor()` function. Also, make sure to drop any `r_maritl` levels that do not contain observations. Hint: see `?droplevels`.
## 

# 2.  Predict the probability of working for each level of marital status. Hint: use `allEffects()`
## 

# Note that the data are not perfectly clean and ready to be modeled. You will need to clean up at least some of the variables before fitting the model.

# ## Multilevel modeling
#
# <div class="alert alert-info">
# **GOAL: To learn about how to use the `lmer()` function to model clustered data.** In particular:
#
# 1. The formula syntax for incorporating random effects into a model
# 2. Calculating the intraclass correlation (ICC)
# 3. Model comparison for fixed and random effects
# </div>
#
# ### Multilevel modeling overview
#
# * Multi-level (AKA hierarchical) models are a type of **mixed-effects** model
# * They are used to model data that are clustered (i.e., non-independent)
# * Mixed-effecs models include two types of predictors: **fixed-effects** and **random effects**
#   + **Fixed-effects** -- observed levels are of direct interest (.e.g, sex, political party...)
#   + **Random-effects** -- observed levels not of direct interest: goal is to make inferences to a population represented by observed levels
#   + In R, the `lme4` package is the most popular for mixed effects models
#   + Use the `lmer()` function for liner mixed models, `glmer()` for generalized linear mixed models

# ### The Exam data
#
# The Exam data set contans exam scores of 4,059 students from 65 schools in Inner London. The variable names are as follows:
#
# | Variable | Description                             |
# |:---------|:----------------------------------------|
# | school   | School ID - a factor.                   |
# | normexam | Normalized exam score.                  |
# | standLRT | Standardised LR test score.             |
# | student  | Student id (within school) - a factor   |

  Exam <- read_rds("dataSets/Exam.rds")


# ### The null model & ICC
#
# As a preliminary step it is often useful to partition the variance in the dependent variable into the various levels. This can be accomplished by running a null model (i.e., a model with a random effects grouping structure, but no fixed-effects predictors).

  # anatomy of lmer() function
  lmer(outcome ~ 1 + pred1 + pred2 + (1 | grouping_variable), 
       data = mydata, 
       REML = FALSE)

  # null model, grouping by school but not fixed effects.
  Norm1 <-lmer(normexam ~ 1 + (1 | school), 
              data = na.omit(Exam), REML = FALSE)
  summary(Norm1)

# The is .161/(.161 + .852) = .159 = 16% of the variance is at the school level. 
#
# There is no consensus on how to calculate p-values for MLMs; hence why they are omitted from the `lme4` output. 
# But, if you really need p-values, the `lmerTest` package will calculate p-values for you (using the Satterthwaite 
# approximation).

# ### Adding fixed-effects predictors
#
# Here's a model that predicts exam scores from student's standardized tests scores:
#
# <div class="alert alert-secondary">
# $$
# normexam_{ij} = \mu + \beta_1standLRT_{ij} + U_{0j} + \epsilon_{ij}
# $$
# </div>
#
# where $U_{0j}$ is the random intercept for `school`. Let's implement this in R using `lmer()`:

  Norm2 <-lmer(normexam ~ 1 + standLRT + (1 | school),
               data = na.omit(Exam), REML = FALSE) 
  summary(Norm2) 

# ### Multiple degree of freedom comparisons
#
# As with `lm()` and `glm()` models, you can compare the two `lmer()` models using a likelihood ratio test with the `anova()` function.

  anova(Norm1, Norm2)

# ### Random slopes
#
# Add a random effect of students' standardized test scores as well. Now in addition to estimating the distribution of intercepts across schools, we also estimate the distribution of the slope of exam on standardized test.

  Norm3 <- lmer(normexam ~ 1 + standLRT + (1 + standLRT | school), 
                data = na.omit(Exam), REML = FALSE) 
  summary(Norm3) 

# ### Test the significance of the random slope
#
# To test the significance of a random slope just compare models with and without the random slope term using a likelihood ratio test:

  anova(Norm2, Norm3) 

# ### Exercise 3
#
# **Multilevel modeling**
#
# Use the `bh1996` dataset: 

## install.packages("multilevel")
data(bh1996, package="multilevel")

# From the data documentation:
#
# > Variables are Leadership Climate (`LEAD`), Well-Being (`WBEING`), and Work Hours (`HRS`). The group identifier is named `GRP`.
#
# 1.  Create a null model predicting wellbeing (`WBEING`)
## 

# 2.  Calculate the ICC for your null model
## 

# 3.  Run a second multi-level model that adds two individual-level predictors, average number of hours worked (`HRS`) and leadership skills (`LEAD`) to the model and interpret your output.
## 

# 4.  Now, add a random effect of average number of hours worked (`HRS`) to the model and interpret your output. Test the significance of this random term.
## 


# ## Exercise solutions
#
# ### Ex 0: prototype
#
# Use the *states.rds* data set.

  states <- read_rds("dataSets/states.rds")

# Fit a model predicting energy consumed per capita (energy) from the percentage of residents living in metropolitan areas (metro). Be sure to:
#
# 1.  Examine/plot the data before fitting the model.

  states_en_met <- subset(states, select = c("metro", "energy"))
  summary(states_en_met)
  plot(states_en_met)
  cor(states_en_met, use = "pairwise")

# 2.  Print and interpret the model `summary()`.

  mod_en_met <- lm(energy ~ metro, data = states)
  summary(mod_en_met)

# 3.  `plot()` the model to look for deviations from modeling assumptions.

  plot(mod_en_met)

# 4. Select one or more additional predictors to add to your model and repeat steps 1-3. Is this model significantly better than the model with *metro* as the only predictor?

  states_en_met_pop_wst <- subset(states, select = c("energy", "metro", "pop", "waste"))
  summary(states_en_met_pop_wst)
  plot(states_en_met_pop_wst)
  cor(states_en_met_pop_wst, use = "pairwise")

  mod_en_met_pop_waste <- lm(energy ~ 1 + metro + pop + waste, data = states)
  summary(mod_en_met_pop_waste)
  anova(mod_en_met, mod_en_met_pop_waste)

# ### Ex 1: prototype
#
# Use the states data set.
#
# 1.  Add on to the regression equation that you created in exercise 1 by generating an interaction term and testing the interaction.

  mod_en_metro_by_waste <- lm(energy ~ 1 + metro * waste, data = states)

# 2.  Try adding a region to the model. Are there significant differences across the four regions?

  mod_en_region <- lm(energy ~ 1 + metro * waste + region, data = states)
  anova(mod_en_region)

# ### Ex 2: prototype
#
# Use the NH11 data set that we loaded earlier. Note that the data is not perfectly clean and ready to be modeled. You will need to clean up at least some of the variables before fitting the model.
#
# 1.  Use `glm()` to conduct a logistic regression to predict ever worked (`everwrk`) using age (`age_p`) and marital status (`r_maritl`). Make sure you only keep the following two levels for `everwrk` (`1 Yes` and `2 No`). Hint: use the `factor()` function. Also, make sure to drop any `r_maritl` levels that do not contain observations. Hint: see `?droplevels`.

  NH11 <- mutate(NH11,
                     everwrk = factor(everwrk, levels = c("1 Yes", "2 No")),
                     r_maritl = droplevels(r_maritl))

  mod_wk_age_mar <- glm(everwrk ~ 1 + age_p + r_maritl, 
                        data = NH11,
                        family = binomial(link = "logit"))

  summary(mod_wk_age_mar)

# 2.  Predict the probability of working for each level of marital status. Hint: use `allEffects()`.

  eff <- allEffects(mod_wk_age_mar)
  as.data.frame(eff)

# ### Ex 3: prototype
#
# Use the dataset, bh1996:

  data(bh1996, package="multilevel")

# From the data documentation:
#
# > Variables are Leadership Climate (`LEAD`), Well-Being (`WBEING`), and Work Hours (`HRS`). The group identifier is named `GRP`.
#
# 1.  Create a null model predicting wellbeing (`WBEING`).

  mod_grp0 <- lmer(WBEING ~ 1 + (1 | GRP), data = bh1996)
  summary(mod_grp0)

# 3.  Run a second multi-level model that adds two individual-level predictors, average number of hours worked (`HRS`) and leadership skills (`LEAD`) to the model and interpret your output.

  mod_grp1 <- lmer(WBEING ~ 1 + HRS + LEAD + (1 | GRP), data = bh1996)
  summary(mod_grp1)

# 3.  Now, add a random effect of average number of hours worked (`HRS`) to the model and interpret your output. Test the significance of this random term.

  mod_grp2 <- lmer(WBEING ~ 1 + HRS + LEAD + (1 + HRS | GRP), data = bh1996)
  anova(mod_grp1, mod_grp2)


# ## Wrap-up
#
# ### Feedback
#
# These workshops are a work in progress, please provide any feedback to: help@iq.harvard.edu
#
# ### Resources
#
# * IQSS 
#     + Workshops: <https://dss.iq.harvard.edu/workshop-materials>
#     + Data Science Services: <https://dss.iq.harvard.edu/>
#     + Research Computing Environment: <https://iqss.github.io/dss-rce/>
#
# * HBS
#     + Research Computing Services workshops: <https://training.rcs.hbs.org/workshops>
#     + Other HBS RCS resources: <https://training.rcs.hbs.org/workshop-materials>
#     + RCS consulting email: <mailto:research@hbs.edu>
