#' Open raix Chat GUI in RStudio Viewer
#'
#' Opens a chat window in RStudio Viewer pane.
#' Configure models, switch providers, and chat without limitations.
#'
#' @export
raix_gui <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("Package 'shiny' is required. Install with: install.packages('shiny')")
  }
  app_path <- system.file("shiny", "app.R", package = "raix")
  if (app_path == "") stop("Shiny app not found in package installation")

  # Always open in RStudio Viewer, fall back to internal window
  viewer <- if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    rstudioapi::viewer
  } else {
    NULL
  }
  shiny::runApp(app_path, launch.browser = viewer, display.mode = "normal")
}

#' Open raix Dashboard — R + AI Coding Workspace
#'
#' Launches the full R + AI coding dashboard in RStudio Viewer.
#' Left panel: AI chat. Right panel: code editor + output viewer.
#' All results stay inside RStudio.
#'
#' @export
raix_dashboard <- function() {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("Package 'shiny' is required. Install with: install.packages('shiny')")
  }

  app_path <- system.file("shiny", "dashboard.R", package = "raix")
  if (app_path == "") stop("Dashboard app not found. Reinstall raix.")

  # Always use RStudio Viewer — keep everything inside RStudio
  viewer <- if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    rstudioapi::viewer
  } else {
    NULL
  }
  shiny::runApp(app_path, launch.browser = viewer, display.mode = "normal")
}
