\name{raix_simulate}
\alias{raix_simulate}
\title{raix_simulate}
\description{
  AI-powered simulation engine. Describe the system and raix generates complete
  R simulation code with Monte Carlo, bootstrap, power analysis, and more.
}
\usage{
  raix_simulate(description, n_iterations = 1000, output = NULL, run = FALSE, seed = 42)
}
\arguments{
  \item{description}{What to simulate, in plain English.}
  \item{n_iterations}{Number of simulation iterations.}
  \item{output}{Optional file path for the simulation script.}
  \item{run}{If TRUE, executes the simulation and returns results.}
  \item{seed}{Random seed for reproducibility.}
}
\examples{
\dontrun{
  raix_simulate("Power analysis for a t-test with effect size 0.5")
  raix_simulate("Stock price random walk with drift, 252 trading days", run = TRUE)
}
}
\keyword{internal}
