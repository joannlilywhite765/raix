\name{raix_dashboard}
\alias{raix_dashboard}
\title{raix_dashboard}
\description{
  Launches a live web-based R + AI coding workspace with chat panel, code editor,
  syntax highlighting, and execution/output viewer.
}
\usage{
  raix_dashboard(port = NULL, host = "127.0.0.1", launch_browser = TRUE)
}
\arguments{
  \item{port}{Port to run on (default: random available).}
  \item{host}{Host address ("127.0.0.1" local, "0.0.0.0" network).}
  \item{launch_browser}{Open browser automatically.}
}
\examples{
\dontrun{
  raix_dashboard()
  raix_dashboard(port = 8080, host = "0.0.0.0")  # accessible on network
}
}
\keyword{internal}
