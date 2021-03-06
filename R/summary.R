#' Summarize a Covidestim run
#'
#' Returns a \code{data.frame} summarizing a Covidestim model run. Note that if
#' \code{\link{runOptimizer.covidestim}} is used, all \code{*.(lo|hi)}
#' variables will be \code{NA}-valued, because BFGS does not generate
#' confidence intervals.
#'
#' @param ccr A \code{covidestim_result} object
#'
#' @param include.before A logical scalar. Include estimations that fall in the
#'   period before the first day of input data? (This period is of length
#'   \code{ndays_before} as passed to \code{covidestim}). If  \code{TRUE}, any
#'   elements of variables which do not have values for this "before" period
#'   will be represented as \code{NA}.
#'
#' @param index A logical scalar. If \code{TRUE}, will include a variable
#'   \code{index} in the output, with range \code{1:(ndays_before + ndays)}.
#'
#' @noMd
#' @return A \code{data.frame} with the following variables:
#'
#'   \itemize{
#'     \item \code{date}
#'     \item \code{cases.fitted}, \code{cases.fitted.lo},
#'       \code{cases.fitted.hi}: Median and 95\% interval around fitted case
#'       data.
#'
#'     \item \code{cum.incidence}, \code{cum.incidence.lo},
#'       \code{cum.incidence.hi}: Median and 95\% interval around cumulative 
#'       incidence data.
#'
#'     \item \code{deaths.fitted}, \code{deaths.fitted.lo},
#'       \code{deaths.fitted.hi}: Median and 95\% interval around fitted deaths
#'       data.
#'
#'     \item \code{deaths}, \code{deaths.lo}, \code{deaths.hi}: Median and 95\%
#'       interval around estimated deaths/day, by date of death.
#'
#'     \item \code{infections}, \code{infections.lo}, \code{infections.hi}:
#'       Median and 95\% interval around estimated infections/day, by date of
#'       infection.
#'
#'     \item \code{severe}, \code{severe.lo}, \code{severe.hi}: Median and 95\%
#'        interval around the number of individuals who transitioned into the
#'        "severe" health state on a particular day. The "severe" state is
#'        defined as disease that would merit hospitalization.
#'
#'     \item \code{symptomatic}, \code{symptomatic.lo}, \code{symptomatic.hi}:
#'        Median and 95\% interval around the estimate of the quantity of
#'        individuals who became symtomatic on a particular day.
#'
#'     \item \code{data.available}: \code{TRUE/FALSE} for whether input data
#'       was available on that particular day.
#'
#'     \item \code{Rt}, \code{Rt.lo}, \code{Rt.hi}: Estimate of the effective 
#'     reproductive number (Rt), with 95\% CIs.
#'     
#'     \item \code{sero.positive}, \code{sero.positive.lo}, 
#'     \code{sero.positive.hi}: Estimate of the number of seropositive
#'     individuals, with 95\% CIs.
#'     
#'     \item \code{pop.infectiousness}, \code{pop.infectiousness.lo}, 
#'     \code{pop.infectiousness.hi}: Estimate of the relative level of viral 
#'     shedding in the community, with 95\% CIs.
#'   }
#'
#' @export
#' @importFrom magrittr %>%
summary.covidestim_result <- function(ccr, include.before = TRUE, index = FALSE) {

  # Used for dealing with indices and dates
  ndays        <- ccr$config$N_days
  ndays_before <- ccr$config$N_days_before
  ndays_total  <- ndays_before + ndays
  start_date   <- as.Date(ccr$config$first_date, origin = '1970-01-01')

  # Dates an index and converts it to a date
  toDate <- function(idx) start_date + lubridate::days(idx - 1 - ndays_before)

  # Mappings between names in Stan and variable names in the output `df`
  c(
    "new_inf"              = "infections",
    "Rt"                   = "Rt",
    "occur_cas"            = "cases.fitted",
    "occur_die"            = "deaths.fitted",
    "cumulative_incidence" = "cum.incidence",
    "new_sym"              = "symptomatic",
    "new_sev"              = "severe",
    "new_die"              = "deaths",
    "new_die_dx"           = "deaths.diagnosed",
    "diag_cases"           = "symptomatic.diagnosed", 
    "diag_all"             = "diagnoses",
    "sero_positive"        = "sero.positive",
    "pop_infectiousness"   = "pop.infectiousness"
  ) -> params

  if ("optimizer" %in% ccr$flags)
    return(summaryOptimizer(ccr, toDate, params, start_date))

  # Used for renaming quantiles output by Stan
  quantile_names <- c("2.5%" = ".lo", "50%" = "", "97.5%" = ".hi")

  # This creates the list of `pars` that gets passed to `rstan::summary`
  # by enumerating all combs of varnames and indices
  purrr::cross2(names(params), as.character(1:ndays_total)) %>% 
  purrr::map_chr(
    function(item)
      glue("{par}[{idx}]", par = item[[1]], idx = item[[2]])
  ) -> pars

  rstan::summary(
    ccr$result,
    pars = pars,
    probs = c(0.025, 0.5, 0.975)
  )$summary %>% # Get rid of the per-chain summaries by indexing into `$summary`
    as.data.frame %>%
    tibble::as_tibble(rownames = "parname") -> melted

  # These are the variables that are going to be selected from the melted
  # representation created above
  vars_of_interest <- c("variable", "date", names(quantile_names))

  # Join the melted representation to the array indices that have been split
  # into their name:idx components
  stan_extracts <- dplyr::left_join(
    melted,
    split_array_indexing(melted$parname),
    by = "parname"
  ) %>%
    # Reformat the dates, and rename some of the variable names
    dplyr::mutate(date = toDate(index), variable = params[variable]) %>%
    # Eliminate things like R-hat that we don't care about right now
    dplyr::select_at(vars_of_interest) %>%
    # Melt things more to get down to three columns
    tidyr::gather(names(quantile_names), key = "quantile", value = "value") %>%
    # Create the finalized names for the quantiles, and delete the now-unneeded
    # quantile variable
    dplyr::mutate(
      variable = paste0(variable, quantile_names[quantile]),
      quantile = NULL,
      
    ) %>%
    # Cast everything back out
    tidyr::spread(key = "variable", value = "value") %>%
    dplyr::mutate(data.available = date >= start_date)

  d <- stan_extracts


  if (index == TRUE)
    d <- dplyr::bind_cols(d, list(index = 1:ndays_total))

  # Get rid of 'before period' data if not requested
  if (include.before == FALSE)
    d <- dplyr::filter(d, date >= start_date)

  d
}

split_array_indexing <- function(elnames) {

  # Matches a valid indexed variable in Stan, capturing it into two groups
  regex <- '^([A-Za-z_][A-Za-z_0-9]+)\\[([0-9]+)\\]$'

  # Match everything into a data.frame
  captured <- stringr::str_match(elnames, regex)
  captured <- as.data.frame(captured, stringsAsFactors = FALSE)

  # Rename cols, coerce the index to a number
  colnames(captured) <- c("parname", "variable", "index")
  captured$index <- as.numeric(captured$index)

  captured
}

#' Summarize internal parameters of a Covidestim run
#'
#' Returns a \code{data.frame} with a information on the posterior of a few
#' key Stan parameters.
#'
#' @param ccr A \code{covidestim_result} object
#'
#' @return A \code{data.frame} with the following variables:
#'
#'   \itemize{
#'     \item \code{par}: Name of the Stan parameter
#'
#'     \item \code{2.5\%}, \code{50\%}, \code{97.5\%}: Quantiles for the posterior
#'       distribution of \code{par}.
#'   }
#'
#' @export
#' @importFrom magrittr %>%
summaryEpi <- function(ccr) {
  
  c(
    "p_sym_if_inf",
    "p_sev_if_sym",
    "p_die_if_sev",
    "p_die_if_sym",
    "p_diag_if_sym",
    "p_diag_if_sev"
  ) -> pars_of_interest

  # Used for renaming quantiles output by Stan
  quantile_names <- c("2.5%" = ".lo", "50%" = "median", "97.5%" = ".hi")

  rstan::summary(
    ccr$result,
    pars = pars_of_interest,
    probs = c(0.025, 0.5, 0.975)
  )$summary %>% # Get rid of the per-chain summaries by indexing into `$summary`
    as.data.frame %>%
    tibble::as_tibble(rownames = "par") -> melted

  # These are the variables that are going to be selected from the melted
  # representation created above
  vars_of_interest <- c("par", names(quantile_names))

  result <- dplyr::select_at(melted, vars_of_interest)

  result
}

summaryOptimizer <- function(ccr, toDate, params, start_date) {

  # Optimizer results don't have confidence intervals - however, to maintain
  # parity with the "default" version of the summary function (where the
  # sampler produces the results that are being processed), we need to have
  # NA-valued confidence intervals. This also makes sharing a DB table with
  # sampler-generated results much easier. The next few lines create the
  # neccessary "*.lo" and "*.hi" NA-valued columns
  params.lo <- paste0(params, ".lo")
  params.hi <- paste0(params, ".hi")

  nullParams <- as.list(rep(NA, 2*length(params))) %>%
    stats::setNames(c(params.lo, params.hi))

  # ccr$result is a list keyed on Stan param name, each value is a numeric
  # vector of equal length.
  tibble::as_tibble(ccr$result) %>%
    # Convert to result naming-scheme provided by `summary()`
    dplyr::rename_with(~params[.]) %>%
    # Add empty conf. interval variables
    dplyr::bind_cols(nullParams) %>%
    # Sort result columns in alphabetical order to maintain parity with
    # original `summary` implementation
    dplyr::select(order(colnames(.))) %>%
    # Add dates and data.available column
    dplyr::mutate(
      date = toDate(1:dplyr::n()),
      data.available = date >= start_date
    ) %>%
    # Maintain parity with order in original `summary` implementation
    dplyr::select(date, everything(), data.available)
}
