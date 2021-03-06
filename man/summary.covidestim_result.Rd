% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/summary.R
\name{summary.covidestim_result}
\alias{summary.covidestim_result}
\title{Summarize a Covidestim run}
\usage{
\method{summary}{covidestim_result}(ccr, include.before = TRUE, index = FALSE)
}
\arguments{
\item{ccr}{A \code{covidestim_result} object}

\item{include.before}{A logical scalar. Include estimations that fall in the
period before the first day of input data? (This period is of length
\code{ndays_before} as passed to \code{covidestim}). If  \code{TRUE}, any
elements of variables which do not have values for this "before" period
will be represented as \code{NA}.}

\item{index}{A logical scalar. If \code{TRUE}, will include a variable
\code{index} in the output, with range \code{1:(ndays_before + ndays)}.}
}
\value{
A \code{data.frame} with the following variables:

  \itemize{
    \item \code{date}
    \item \code{cases.fitted}, \code{cases.fitted.lo},
      \code{cases.fitted.hi}: Median and 95\% interval around fitted case
      data.

    \item \code{cum.incidence}, \code{cum.incidence.lo},
      \code{cum.incidence.hi}: Median and 95\% interval around cumulative 
      incidence data.

    \item \code{deaths.fitted}, \code{deaths.fitted.lo},
      \code{deaths.fitted.hi}: Median and 95\% interval around fitted deaths
      data.

    \item \code{deaths}, \code{deaths.lo}, \code{deaths.hi}: Median and 95\%
      interval around estimated deaths/day, by date of death.

    \item \code{infections}, \code{infections.lo}, \code{infections.hi}:
      Median and 95\% interval around estimated infections/day, by date of
      infection.

    \item \code{severe}, \code{severe.lo}, \code{severe.hi}: Median and 95\%
       interval around the number of individuals who transitioned into the
       "severe" health state on a particular day. The "severe" state is
       defined as disease that would merit hospitalization.

    \item \code{symptomatic}, \code{symptomatic.lo}, \code{symptomatic.hi}:
       Median and 95\% interval around the estimate of the quantity of
       individuals who became symtomatic on a particular day.

    \item \code{data.available}: \code{TRUE/FALSE} for whether input data
      was available on that particular day.

    \item \code{Rt}, \code{Rt.lo}, \code{Rt.hi}: Estimate of the effective 
    reproductive number (Rt), with 95\% CIs.
    
    \item \code{sero.positive}, \code{sero.positive.lo}, 
    \code{sero.positive.hi}: Estimate of the number of seropositive
    individuals, with 95\% CIs.
    
    \item \code{pop.infectiousness}, \code{pop.infectiousness.lo}, 
    \code{pop.infectiousness.hi}: Estimate of the relative level of viral 
    shedding in the community, with 95\% CIs.
  }
}
\description{
Returns a \code{data.frame} summarizing a Covidestim model run. Note that if
\code{\link{runOptimizer.covidestim}} is used, all \code{*.(lo|hi)}
variables will be \code{NA}-valued, because BFGS does not generate
confidence intervals.
}
