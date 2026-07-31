#' Open raix Chat GUI
#'
#' Opens a chat window in RStudio Viewer.
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

#' Open raix Dashboard — Full R + AI Coding Workspace
#'
#' Launches a live web-based coding dashboard with:
#' - AI Chat panel (left) — ask questions, generate code
#' - R Code Editor (center) — write, edit, syntax highlighting
#' - Output/Plot viewer (bottom) — execute code and see results
#' - Natural language → R code generation
#' - One-click send AI-generated code to editor
#'
#' Perfect for data analysis, prototyping, learning R, and
#' rapid development with AI assistance.
#'
#' @param port Port to run the dashboard on (default: random available port)
#' @param host Host address (default: "127.0.0.1" for local, "0.0.0.0" for network)
#' @param launch_browser If TRUE, opens browser automatically
#'
#' @export
raix_dashboard <- function(port = NULL, host = "127.0.0.1", launch_browser = TRUE) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop("Package 'shiny' is required. Install with: install.packages('shiny')")
  }
  
  app_path <- system.file("shiny", "dashboard.R", package = "raix")
  if (app_path == "") stop("Dashboard app not found. Reinstall raix: remotes::install_github('twomathematicians-code/raix')")
  
  if (is.null(port)) {
    port <- if (requireNamespace("httpuv", quietly = TRUE)) {
      httpuv::randomPort()
    } else {
      4242
    }
  }
  
  if (launch_browser) {
    message(sprintf("\n🚀 raix Dashboard starting at http://%s:%s", host, port))
    message("   Press Ctrl+C or close the window to stop.\n")
  }
  
  shiny::runApp(app_path, port = port, host = host, launch.browser = launch_browser)
}
