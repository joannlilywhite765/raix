\name{raix_solve}
\alias{raix_solve}
\title{raix_solve}
\description{
  Describe a data problem in plain English and get a complete, runnable R solution.
  Automatically selects the best packages, plans the approach, and generates code.
}
\usage{
  raix_solve(problem, data = NULL, output = NULL, execute = FALSE)
}
\arguments{
  \item{problem}{Description of the data problem to solve.}
  \item{data}{Optional data.frame or path to data file for context.}
  \item{output}{Optional file path to write the solution (.R or .Rmd).}
  \item{execute}{If TRUE, runs the generated code and returns results.}
}
\examples{
\dontrun{
  raix_solve("Predict customer churn from this dataset", data = customers)
  raix_solve("Create a Shiny dashboard for sales data", output = "dashboard.R")
}
}
\keyword{internal}
