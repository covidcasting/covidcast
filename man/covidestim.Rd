% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/covidestim.R
\name{covidestim}
\alias{covidestim}
\title{Configure a Covidestim run on a set of priors and input data}
\usage{
covidestim(
  ndays,
  ndays_before = 28,
  pop_size = 1e+12,
  chains = 3,
  iter = 1500,
  thin = 1,
  seed = 42,
  adapt_delta = 0.92,
  max_treedepth = 12,
  window.length = 7,
  region
)
}
\arguments{
\item{ndays}{A positive integer. The number of days of input data being
modeled. This should always be set to the number of days in your input
data.}

\item{ndays_before}{A positive integer. How many days before the first day
of model data should be modeled? A higher number will produce estimates
that go farther back in time, however, those estimates will contain more
and more uncertainty.}

\item{pop_size}{A positive integer What is the population in the geography
being modelled? This sets the max susceptible population and becomes
important as the population ever infected approaches the population size.}

\item{chains}{The number of chains to use during NUTS sampling, as passed to
\code{\link[rstan]{sampling}}.}

\item{iter}{The number of iterations to run during NUTS sampling, as passed
to \code{\link[rstan]{sampling}}.}

\item{thin}{A positive integer to specify period for saving samples, as
passed to \code{\link[rstan]{sampling}}. Modify this only if you intend
to inspect raw iterations data returned by \code{\link[rstan]{sampling}}.}

\item{seed}{A number. The random number generator seed for use in NUTS
sampling or in BFGS.}

\item{region}{A string. The FIPS code (for U.S. counties) or state name
(e.g. \code{New York}) being modeled. Required.}
}
\value{
An S3 object of type \code{covidestim}. This can be passed to
\code{\link{run.covidestim}} or \code{\link{runOptimizer.covidestim}} to execute the model, as
long as input data has been added (using the addition operator, see
example). This object can also be saved to disk using
\code{\link[base]{saveRDS}} to enable reproducibility across platforms or
sessions. However, note that Stan runs are only reproducible under very
specific conditions due to Stan's multi-language architecture. The
\code{print} method is overloaded to return to the user a summary of the
configuration, including prior values and the presence or absence of input
data.
}
\description{
\code{covidestim} returns a base configuration of the model with the default
set of priors, and no input data. This configuration, after adding input
data (see \code{\link{input_cases}}, \code{\link{input_deaths}},
\code{priors_*}), represents a valid model configuration that can be passed
to \code{\link{run.covidestim}} (for NUTS) or
\code{\link{runOptimizer.covidestim}} (for BFGS).
}
\examples{
# Note that this configuration is improper as it uses New York City
# case/death data, but uses Manhattan's FIPS code and population size.
# (for demonstration purposes only!)
covidestim(ndays = 120, seed = 42, region = '36061', pop_size = 1.63e6) +
  input_cases(example_nyc_data('cases')) +
  input_deaths(example_nyc_data('deaths'))

}
\seealso{
\url{https://mc-stan.org/docs/2_18/reference-manual/reproducibility-chapter.html}
}
