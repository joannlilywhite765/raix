# AIR — Beginner-Friendly Utilities
#
# air_setup()    — guided first-time setup wizard
# air_search()   — search CRAN packages
# air_diagnose() — diagnose R script/project issues
# air_analyze()  — guided data analysis assistant
# air_google()   — search Google from R console
# air_rstudio()  — RStudio integration helper
# air_help()     — beginner-friendly help menu

#' Guided first-time setup wizard
#'
#' Walks new users through backend selection, API key configuration,
#' connectivity testing, and a quick tutorial. Designed for complete beginners.
#'
#' @export
air_setup <- function() {
  cli::cli_h1("Welcome to AIR — AI for R!")
  cli::cli_text("")
  cli::cli_text("This wizard helps you connect to ANY AI model in under 2 minutes.")
  cli::cli_text("")

  # Step 1: Choose provider
  cli::cli_h3("Step 1: Choose your AI provider")
  cli::cli_bullets(c(
    "*" = "Ollama — FREE, local, private (recommended for beginners)",
    "*" = "OpenAI — GPT-4o, most capable, requires API key",
    "*" = "Claude — Anthropic, great for reasoning",
    "*" = "Groq — Fast, free tier available",
    "*" = "Together AI — Many open-source models",
    "*" = "Mistral — European AI provider",
    "*" = "DeepSeek — Affordable code generation",
    "*" = "LM Studio / vLLM — Local OpenAI-compatible servers",
    "*" = "custom — ANY OpenAI-compatible endpoint (bring your own URL)"
  ))
  cat("\n")
  choice <- readline(cli::col_blue("Provider [ollama/openai/claude/groq/together/mistral/deepseek/lmstudio/vllm/custom]: "))
  choice <- tolower(trimws(choice))
  if (nchar(choice) == 0) choice <- "ollama"

  # Step 2: Configure
  if (choice == "custom") {
    cli::cli_h3("Step 2: Custom endpoint")
    url <- readline(cli::col_blue("API base URL (e.g., https://api.example.com/v1): "))
    model <- readline(cli::col_blue("Model name: "))
    key <- readline(cli::col_blue("API key (enter to skip): "))
    api_fmt <- readline(cli::col_blue("API format [openai/ollama/claude] (default: openai): "))
    if (nchar(trimws(api_fmt)) == 0) api_fmt <- "openai"
    air_configure(provider = choice, model = model, base_url = url,
                  api_key = if (nchar(trimws(key)) > 0) key else NULL,
                  api_format = api_fmt)
  } else if (choice == "ollama") {
    cli::cli_h3("Step 2: Ollama setup")
    cli::cli_text("Ollama runs AI locally. Install from {.url https://ollama.com}")
    model <- readline(cli::col_blue("Model [llama3.2]: "))
    if (nchar(trimws(model)) == 0) model <- "llama3.2"
    air_configure(provider = "ollama", model = model)
  } else {
    cli::cli_h3("Step 2: API key")
    cli::cli_text("Get an API key from {choice}.")
    key <- readline(cli::col_blue("API key: "))
    model <- readline(cli::col_blue("Model name (enter for default): "))
    if (nchar(trimws(model)) == 0) model <- NULL
    air_configure(provider = choice, api_key = key, model = model)
  }

  # Step 3: Test connectivity
  cli::cli_h3("Step 3: Testing connection...")
  reachable <- tryCatch(air_check(), error = function(e) FALSE)
  if (isTRUE(reachable)) {
    cli::cli_alert_success("Connected! You are ready to go.")
  } else {
    cli::cli_alert_warning("Could not reach the backend. You can still use AIR — just make sure your backend is running.")
  }

  # Step 4: Quick tutorial
  cli::cli_h3("Step 4: Quick tutorial — try these commands!")
  cli::cli_bullets(c(
    "*" = "{.code air_explain(\"mean\")} — Ask AIR to explain R code",
    "*" = "{.code air_generate(\"Create a bar chart\")} — Generate R code from words",
    "*" = "{.code air_debug()} — Debug your last error",
    "*" = "{.code air_chat()} — Start an interactive chat",
    "*" = "{.code air_search(\"ggplot2\")} — Search CRAN packages",
    "*" = "{.code air_analyze(mtcars)} — Get help analyzing a dataset",
    "*" = "{.code air_diagnose(\"my_script.R\")} — Diagnose script issues",
    "*" = "{.code air_google(\"R tutorial\")} — Search Google from R",
    "*" = "{.code air_help()} — See all available commands"
  ))

  cli::cli_text("")
  cli::cli_alert_success("Setup complete! Happy coding!")
  invisible(air_info())
}

#' Search CRAN packages by topic
#'
#' Finds relevant R packages for a given purpose or keyword.
#'
#' @param topic What kind of package you need (e.g., "clustering", "plotting")
#' @param n Maximum number of results to show
#'
#' @return A data.frame of matching packages with titles
#' @export
air_search <- function(topic, n = 10) {
  if (missing(topic) || !is.character(topic) || nchar(trimws(topic)) == 0) {
    stop("topic must be a non-empty string (e.g., 'clustering', 'plotting')")
  }
  cli::cli_alert_info("Searching for R packages: '{topic}'...")

  # Try CRAN available.packages
  pkgs <- tryCatch(
    suppressWarnings(utils::available.packages(
      repos = "https://cran.rstudio.com/src/contrib", filters = list()
    )),
    error = function(e) NULL
  )

  if (!is.null(pkgs) && is.matrix(pkgs) && nrow(pkgs) > 0) {
    # Search in Package and Title columns
    scores <- tryCatch({
      apply(pkgs, 1, function(row) {
        text <- paste(tolower(row["Package"]), tolower(row["Title"]))
        sum(sapply(strsplit(tolower(topic), "\\s+")[[1]], function(w) grepl(w, text, fixed = TRUE)))
      })
    }, error = function(e) NULL)

    if (!is.null(scores) && length(scores) > 0) {
      top <- head(order(scores, decreasing = TRUE), min(n, length(scores)))
      if (length(top) > 0 && max(top) <= nrow(pkgs)) {
        result <- data.frame(
          Package = pkgs[top, "Package"],
          Title = substr(pkgs[top, "Title"], 1, 80),
          Version = pkgs[top, "Version"],
          row.names = NULL, stringsAsFactors = FALSE
        )
        if (sum(scores[top]) > 0) {
          cat("\n"); cli::cli_h3("CRAN packages matching '{topic}':")
          for (i in seq_len(nrow(result))) {
            cli::cli_bullets(c("*" = "{.pkg {result$Package[i]}} — {result$Title[i]}"))
          }
          return(invisible(result))
        }
      }
    }
  }

  # Fallback: AI-powered package suggestion
  cli::cli_alert_info("Using AI to suggest packages...")
  prompt <- paste0(
    "A user needs R packages for: ", topic, ". ",
    "Suggest the top 5 most popular CRAN packages. ",
    "Output format: package_name — short description."
  )
  result <- tryCatch(air_send(prompt), error = function(e) NULL)
  if (!is.null(result)) {
    cat("\n", cli::col_green("AI suggestions for '{topic}':"), "\n")
    cat(result, "\n")
    return(invisible(result))
  }
  cli::cli_alert_warning("Could not search packages. Check internet or AI backend.")
  invisible(NULL)
}

#' Diagnose issues in an R script or project
#'
#' Analyzes an R file or project directory for common problems:
#' missing packages, syntax errors, inefficient patterns, and style issues.
#'
#' @param path Path to an R script or project directory
#'
#' @return Invisibly returns diagnosis results
#' @export
air_diagnose <- function(path = ".") {
  if (!file.exists(path)) stop("Path not found: ", path)

  cat("\n")
  cli::cli_h2("AIR Project Diagnosis")
  issues <- 0

  # Determine if path is a file or directory
  if (dir.exists(path)) {
    r_files <- list.files(path, pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
    rmd_files <- list.files(path, pattern = "\\.Rmd$", recursive = TRUE, full.names = TRUE)
    all_files <- c(r_files, rmd_files)
    cli::cli_alert_info("Scanning directory: {path}")
    cli::cli_text("Found {length(r_files)} R script(s) and {length(rmd_files)} Rmd file(s)")
  } else {
    all_files <- path
    cli::cli_alert_info("Scanning file: {path}")
  }

  if (length(all_files) == 0) {
    cli::cli_alert_warning("No R files found.")
    return(invisible(NULL))
  }

  # Check 1: Required packages
  cat("\n")
  cli::cli_h3("1. Package dependencies")
  all_code <- paste(sapply(all_files, function(f) paste(readLines(f, warn = FALSE), collapse = "\n")), collapse = "\n")
  lib_matches <- unique(unlist(regmatches(all_code, gregexpr("library\\(([^)]+)\\)|require\\(([^)]+)\\)", all_code))))
  pkgs <- unique(gsub("library\\(|require\\(|\\)", "", lib_matches))
  pkgs <- gsub("\"|'", "", pkgs)
  installed <- pkgs %in% rownames(installed.packages())
  for (i in seq_along(pkgs)) {
    if (installed[i]) {
      cli::cli_alert_success("{.pkg {pkgs[i]}} — installed")
    } else {
      cli::cli_alert_danger("{.pkg {pkgs[i]}} — NOT installed. Run {.code install.packages('{pkgs[i]}')}")
      issues <- issues + 1
    }
  }
  if (all(installed)) cli::cli_alert_success("All packages installed!")

  # Check 2: Syntax errors (quick parse check)
  cat("\n")
  cli::cli_h3("2. Syntax check")
  for (f in all_files) {
    parsed <- tryCatch(parse(file = f), error = function(e) e)
    if (inherits(parsed, "error")) {
      cli::cli_alert_danger("{.file {f}} — syntax error: {parsed$message}")
      issues <- issues + 1
    }
  }
  if (issues == 0) cli::cli_alert_success("No syntax errors found!")

  # Check 3: Common anti-patterns
  cat("\n")
  cli::cli_h3("3. Common issues")
  patterns <- list(
    "setwd()" = "Avoid setwd() — use RStudio projects or here::here()",
    "rm(list = ls())" = "Avoid rm(list=ls()) in shared scripts",
    "install.packages" = "Package installation in script — move to setup section",
    "source\\(\"http" = "Sourcing from URLs — security risk",
    "1:length\\(x\\)" = "Use seq_along(x) instead of 1:length(x)",
    "sapply\\(.*, \\[" = "Use vapply() for type-safe extraction",
    "options\\(stringsAsFactors" = "Deprecated since R 4.0",
    "attach\\(" = "Avoid attach() — use with() or direct referencing"
  )
  found_any <- FALSE
  for (pat in names(patterns)) {
    if (grepl(pat, all_code, perl = TRUE)) {
      cli::cli_alert_warning("{patterns[[pat]]}")
      found_any <- TRUE
      issues <- issues + 1
    }
  }
  if (!found_any) cli::cli_alert_success("No common anti-patterns detected!")

  # Summary
  cat("\n")
  cli::cli_h2("Diagnosis complete: {if (issues == 0) 'All clear!' else paste(issues, 'issue(s) found')}")
  if (issues > 0) {
    cli::cli_text("Run {.code air_debug()} to get AI help fixing these issues.")
  }
  invisible(issues)
}

#' Guided data analysis assistant
#'
#' Helps beginners explore and analyze a dataset step by step.
#'
#' @param data A data.frame to analyze
#' @export
air_analyze <- function(data) {
  if (missing(data) || !is.data.frame(data)) {
    stop("Please provide a data.frame (e.g., air_analyze(mtcars))")
  }
  nm <- deparse(substitute(data))

  cat("\n")
  cli::cli_h2("AIR Data Analysis: {nm}")
  cli::cli_text("{nrow(data)} rows × {ncol(data)} columns")
  cat("\n")

  # Show structure summary
  cli::cli_h3("Quick overview:")
  cli::cli_bullets(c(
    "*" = "Columns: {paste(names(data)[1:min(5, ncol(data))], collapse = ', ')}{if (ncol(data) > 5) '...'}",
    "*" = "Numeric columns: {sum(sapply(data, is.numeric))}",
    "*" = "Factor/character columns: {sum(sapply(data, function(x) is.factor(x) || is.character(x)))}",
    "*" = "Missing values: {sum(is.na(data))}"
  ))
  cat("\n")

  # Generate initial analysis with AI
  summary_str <- paste(capture.output(summary(data))[1:15], collapse = "\n")
  prompt <- paste0(
    "I have an R data.frame called '", nm, "' with this summary:\n\n",
    summary_str, "\n\n",
    "Suggest 3 interesting analyses I should try on this dataset. ",
    "For each, give: (1) a one-line description (2) the R code to run it. ",
    "Keep it beginner-friendly. Use tidyverse if helpful."
  )

  cli::cli_alert_info("Generating analysis suggestions...")
  result <- tryCatch(air_send(prompt), error = function(e) NULL)
  if (!is.null(result)) {
    cat("\n")
    cli::cli_text(cli::col_green("AI Suggestions:"))
    cat(result, "\n")
  } else {
    cli::cli_alert_warning("AI not available. Here's a basic summary:")
    print(summary(data))
  }
  invisible(data)
}

#' Search Google from the R console
#'
#' Opens a Google search in your browser, or returns search result
#' information directly in the console.
#'
#' @param query What to search for
#' @param open_browser Whether to open results in your browser (default: TRUE)
#'
#' @export
air_google <- function(query, open_browser = TRUE) {
  if (missing(query) || !is.character(query) || nchar(trimws(query)) == 0) {
    stop("query must be a non-empty search string")
  }
  encoded <- utils::URLencode(query)
  url <- paste0("https://www.google.com/search?q=", encoded)

  if (open_browser) {
    cli::cli_alert_info("Opening Google search in browser...")
    utils::browseURL(url)
  }

  # Also try AI-powered search summary
  prompt <- paste0(
    "The user searched for: ", query, ". ",
    "Provide a helpful, concise answer or explanation. ",
    "If this is an R-related question, include R code examples. ",
    "Keep it under 300 words."
  )
  result <- tryCatch(air_send(prompt), error = function(e) NULL)
  if (!is.null(result)) {
    cat("\n")
    cli::cli_text(cli::col_green("AIR summary for '{query}':"))
    cat(result, "\n")
  }
  cat("\n", cli::col_blue("Browser URL:"), url, "\n")
  invisible(url)
}

#' RStudio integration helper
#'
#' Opens AIR in various RStudio panes for easy access.
#'
#' @param mode "pane" (Viewer), "source" (Source editor), or "console"
#' @export
air_rstudio <- function(mode = c("pane", "source", "console")) {
  if (!requireNamespace("rstudioapi", quietly = TRUE)) {
    cli::cli_alert_warning("RStudio API not available — are you in RStudio?")
    return(invisible(NULL))
  }
  mode <- match.arg(mode)

  if (mode == "pane") {
    cli::cli_alert_info("Opening AIR cheat sheet in Viewer pane...")
    html <- paste0(
      "<h2>AIR — AI for R</h2>",
      "<table><tr><th>Task</th><th>Command</th></tr>",
      "<tr><td>Setup AI</td><td><code>air_setup()</code></td></tr>",
      "<tr><td>Chat with AI</td><td><code>air_chat()</code></td></tr>",
      "<tr><td>Explain code</td><td><code>air_explain()</code></td></tr>",
      "<tr><td>Debug error</td><td><code>air_debug()</code></td></tr>",
      "<tr><td>Generate code</td><td><code>air_generate()</code></td></tr>",
      "<tr><td>Document function</td><td><code>air_document()</code></td></tr>",
      "<tr><td>Search CRAN</td><td><code>air_search()</code></td></tr>",
      "<tr><td>Analyze data</td><td><code>air_analyze()</code></td></tr>",
      "<tr><td>Diagnose project</td><td><code>air_diagnose()</code></td></tr>",
      "<tr><td>Google search</td><td><code>air_google()</code></td></tr>",
      "<tr><td>Check connection</td><td><code>air_check()</code></td></tr>",
      "<tr><td>Configuration</td><td><code>air_info()</code></td></tr>",
      "</table>"
    )
    temp <- tempfile(fileext = ".html")
    writeLines(html, temp)
    rstudioapi::viewer(temp)
  } else if (mode == "source") {
    cli::cli_alert_info("Opening AIR setup script in Source editor...")
    rstudioapi::navigateToFile(system.file("R/air.R", package = "raix"))
  } else {
    cli::cli_alert_info("AIR is ready! Type {.code air_help()} to see all commands.")
  }
  invisible(NULL)
}

#' Beginner-friendly help menu
#'
#' Shows all AIR commands organized by task, with usage examples.
#'
#' @export
air_help <- function() {
  cat("\n")
  cli::cli_h1("AIR — AI for R")
  cli::cli_text("Your AI coding assistant for RStudio")
  cat("\n")

  cli::cli_h3("🚀 Getting Started")
  cli::cli_bullets(c(
    "*" = "{.code air_setup()} — Guided first-time setup (2 min)",
    "*" = "{.code air_info()} — Show current configuration",
    "*" = "{.code air_check()} — Test AI backend connectivity"
  ))

  cli::cli_h3("💬 AI Assistance")
  cli::cli_bullets(c(
    "*" = "{.code air_chat()} — Interactive chat with AI",
    "*" = "{.code air_send('question')} — Send one message to AI",
    "*" = "{.code air_google('topic')} — Search Google from R"
  ))

  cli::cli_h3("📝 Code Development")
  cli::cli_bullets(c(
    "*" = "{.code air_explain('code')} — Explain what R code does",
    "*" = "{.code air_generate('task')} — Generate R code from description",
    "*" = "{.code air_debug()} — Debug your last R error",
    "*" = "{.code air_document('fn')} — Generate roxygen2 documentation"
  ))

  cli::cli_h3("📊 Data & Project Tools")
  cli::cli_bullets(c(
    "*" = "{.code air_analyze(mtcars)} — Guided data analysis",
    "*" = "{.code air_search('topic')} — Find CRAN packages",
    "*" = "{.code air_diagnose('script.R')} — Diagnose script issues"
  ))

  cli::cli_h3("⚙️ Configuration")
  cli::cli_bullets(c(
    "*" = "{.code air_configure(backend = 'ollama')} — Switch AI backend",
    "*" = "Supported backends: ollama, openai, claude, deepseek, kimi, zai"
  ))

  cat("\n")
  cli::cli_text("Run {.code air_setup()} for a guided walkthrough!")
}
