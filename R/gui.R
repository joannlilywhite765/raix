#' Open raix Chat GUI
#'
#' Opens a chat window in RStudio Viewer (like ZCode).
#' Configure models, switch providers, and chat without limitations.
#'
#' @export
raix_gui <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("Package 'shiny' is required. Install with: install.packages('shiny')")
  }
  app_path <- system.file("shiny", "app.R", package = "raix")
  if (app_path == "") stop("Shiny app not found in package installation")

  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    viewer <- rstudioapi::viewer
    shiny::runApp(app_path, launch.browser = viewer, display.mode = "normal")
  } else {
    shiny::runApp(app_path)
  }
}
