\name{raix_small_mode}
\alias{raix_small_mode}
\title{raix_small_mode}
\description{
  Toggle small-model optimization mode. Small mode uses shorter, more directive
  prompts optimized for local 7B-9B parameter models (qwen2.5-coder, phi3.5, gemma2, llama3.2).
}
\usage{
  raix_small_mode(enable = NULL)
}
\arguments{
  \item{enable}{TRUE to force small mode, FALSE for standard, NULL to auto-detect.}
}
\examples{
\dontrun{
  raix_small_mode(TRUE)
  raix_small_mode()
}
}
\keyword{internal}
