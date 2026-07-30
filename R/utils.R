# raix --- Beginner-Friendly Utilities
#
# raix_setup()    --- guided first-time setup wizard
# raix_search()   --- search CRAN packages
# raix_diagnose() --- diagnose R script/project issues
# raix_analyze()  --- guided data analysis assistant
# raix_google()   --- search Google from R console
# raix_rstudio()  --- RStudio integration helper
# raix_help()     --- beginner-friendly help menu

#' Guided first-time setup wizard
#'
#' Walks new users through backend selection, API key configuration,
#' connectivity testing, and a quick tutorial. Designed for complete beginners.
#'
#' @export
raix_setup <- function() {
  cli::cli_h1("Welcome to raix --- AI for R!")
  cli::cli_text("")
  cli::cli_text("This wizard helps you connect to ANY AI model in under 2 minutes.")
  cli::cli_text("")

  # Step 1: Choose provider
  cli::cli_h3("Step 1: Choose your AI provider")
  cli::cli_bullets(c(
    "*" = "Ollama --- FREE, local, private (recommended for beginners)",
    "*" = "OpenAI --- GPT-4o, most capable, requires API key",
    "*" = "Claude --- Anthropic, great for reasoning",
    "*" = "Groq --- Fast, free tier available",
    "*" = "Together AI --- Many open-source models",
    "*" = "Mistral --- European AI provider",
    "*" = "DeepSeek --- Affordable code generation",
    "*" = "LM Studio / vLLM --- Local OpenAI-compatible servers",
    "*" = "custom --- ANY OpenAI-compatible endpoint (bring your own URL)"
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
    raix_configure(provider = choice, model = model, base_url = url,
                  api_key = if (nchar(trimws(key)) > 0) key else NULL,
                  api_format = api_fmt)
  } else if (choice == "ollama") {
    cli::cli_h3("Step 2: Ollama setup")
    cli::cli_text("Ollama runs AI locally. Install from {.url https://ollama.com}")
    model <- readline(cli::col_blue("Model [llama3.2]: "))
    if (nchar(trimws(model)) == 0) model <- "llama3.2"
    raix_configure(provider = "ollama", model = model)
  } else {
    cli::cli_h3("Step 2: API key")
    cli::cli_text("Get an API key from {choice}.")
    key <- readline(cli::col_blue("API key: "))
    model <- readline(cli::col_blue("Model name (enter for default): "))
    if (nchar(trimws(model)) == 0) model <- NULL
    raix_configure(provider = choice, api_key = key, model = model)
  }

  # Step 3: Test connectivity
  cli::cli_h3("Step 3: Testing connection...")
  reachable <- tryCatch(raix_check(), error = function(e) FALSE)
  if (isTRUE(reachable)) {
    cli::cli_alert_success("Connected! You are ready to go.")
  } else {
    cli::cli_alert_warning("Could not reach the backend. You can still use raix --- just make sure your backend is running.")
  }

  # Step 4: Quick tutorial
  cli::cli_h3("Step 4: Quick tutorial --- try these commands!")
  cli::cli_bullets(c(
	    "*" = "{.code raix_explain(\"mean\")} --- Ask raix to explain R code",
    "*" = "{.code raix_generate(\"Create a bar chart\")} --- Generate R code from words",
    "*" = "{.code raix_debug()} --- Debug your last error",
    "*" = "{.code raix_chat()} --- Start an interactive chat",
    "*" = "{.code raix_search(\"ggplot2\")} --- Search CRAN packages",
    "*" = "{.code raix_analyze(mtcars)} --- Get help analyzing a dataset",
    "*" = "{.code raix_diagnose(\"my_script.R\")} --- Diagnose script issues",
    "*" = "{.code raix_google(\"R tutorial\")} --- Search Google from R",
    "*" = "{.code raix_help()} --- See all available commands"
  ))

  cli::cli_text("")
  cli::cli_alert_success("Setup complete! Happy coding!")
  invisible(raix_info())
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
raix_search <- function(topic, n = 10) {
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
            cli::cli_bullets(c("*" = "{.pkg {result$Package[i]}} --- {result$Title[i]}"))
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
    "Output format: package_name --- short description."
  )
  result <- tryCatch(raix_send(prompt), error = function(e) NULL)
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
raix_diagnose <- function(path = ".") {
  if (!file.exists(path)) stop("Path not found: ", path)

  cat("\n")
  cli::cli_h2("raix Project Diagnosis")
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
      cli::cli_alert_success("{.pkg {pkgs[i]}} --- installed")
    } else {
      cli::cli_alert_danger("{.pkg {pkgs[i]}} --- NOT installed. Run {.code install.packages('{pkgs[i]}')}")
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
      cli::cli_alert_danger("{.file {f}} --- syntax error: {parsed$message}")
      issues <- issues + 1
    }
  }
  if (issues == 0) cli::cli_alert_success("No syntax errors found!")

  # Check 3: Common anti-patterns
  cat("\n")
  cli::cli_h3("3. Common issues")
  patterns <- list(
    "setwd()" = "Avoid setwd() --- use RStudio projects or here::here()",
    "rm(list = ls())" = "Avoid rm(list=ls()) in shared scripts",
    "install.packages" = "Package installation in script --- move to setup section",
    "source\\(\"http" = "Sourcing from URLs --- security risk",
    "1:length\\(x\\)" = "Use seq_along(x) instead of 1:length(x)",
    "sapply\\(.*, \\[" = "Use vapply() for type-safe extraction",
    "options\\(stringsAsFactors" = "Deprecated since R 4.0",
    "attach\\(" = "Avoid attach() --- use with() or direct referencing"
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
    cli::cli_text("Run {.code raix_debug()} to get AI help fixing these issues.")
  }
  invisible(issues)
}

#' Guided data analysis assistant
#'
#' Helps beginners explore and analyze a dataset step by step.
#'
#' @param data A data.frame to analyze
#' @export
raix_analyze <- function(data) {
  if (missing(data) || !is.data.frame(data)) {
    stop("Please provide a data.frame (e.g., raix_analyze(mtcars))")
  }
  nm <- deparse(substitute(data))

  cat("\n")
  cli::cli_h2("raix Data Analysis: {nm}")
  cli::cli_text("{nrow(data)} rows x {ncol(data)} columns")
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
  result <- tryCatch(raix_send(prompt), error = function(e) NULL)
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
raix_google <- function(query, open_browser = TRUE) {
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
  result <- tryCatch(raix_send(prompt), error = function(e) NULL)
  if (!is.null(result)) {
    cat("\n")
    cli::cli_text(cli::col_green("raix summary for '{query}':"))
    cat(result, "\n")
  }
  cat("\n", cli::col_blue("Browser URL:"), url, "\n")
  invisible(url)
}

#' RStudio integration helper
#'
#' Opens raix in various RStudio panes for easy access.
#'
#' @param mode "pane" (Viewer), "source" (Source editor), or "console"
#' @export
raix_rstudio <- function(mode = c("pane", "source", "console")) {
  if (!requireNamespace("rstudioapi", quietly = TRUE)) {
	    cli::cli_alert_warning("RStudio API not available -- are you in RStudio?")
    return(invisible(NULL))
  }
  mode <- match.arg(mode)

  if (mode == "pane") {
    cli::cli_alert_info("Opening raix cheat sheet in Viewer pane...")
    html <- paste0(
      "<h2>raix --- AI for R</h2>",
      "<table><tr><th>Task</th><th>Command</th></tr>",
      "<tr><td>Setup AI</td><td><code>raix_setup()</code></td></tr>",
      "<tr><td>Chat with AI</td><td><code>raix_chat()</code></td></tr>",
      "<tr><td>Explain code</td><td><code>raix_explain()</code></td></tr>",
      "<tr><td>Debug error</td><td><code>raix_debug()</code></td></tr>",
      "<tr><td>Generate code</td><td><code>raix_generate()</code></td></tr>",
      "<tr><td>Document function</td><td><code>raix_document()</code></td></tr>",
      "<tr><td>Search CRAN</td><td><code>raix_search()</code></td></tr>",
      "<tr><td>Analyze data</td><td><code>raix_analyze()</code></td></tr>",
      "<tr><td>Diagnose project</td><td><code>raix_diagnose()</code></td></tr>",
      "<tr><td>Google search</td><td><code>raix_google()</code></td></tr>",
      "<tr><td>Check connection</td><td><code>raix_check()</code></td></tr>",
      "<tr><td>Configuration</td><td><code>raix_info()</code></td></tr>",
      "</table>"
    )
    temp <- tempfile(fileext = ".html")
    writeLines(html, temp)
    rstudioapi::viewer(temp)
  } else if (mode == "source") {
    cli::cli_alert_info("Opening raix setup script in Source editor...")
	    rstudioapi::navigateToFile(system.file("R/raix.R", package = "raix"))
  } else {
    cli::cli_alert_info("raix is ready! Type {.code raix_help()} to see all commands.")
  }
  invisible(NULL)
}

#' Beginner-friendly help menu
#'
#' Shows all raix commands organized by task, with usage examples.
#'
#' @export
raix_help <- function() {
  cat("\n")
  cli::cli_h1("raix --- AI for R")
  cli::cli_text("Your AI coding assistant for RStudio")
  cat("\n")

	  cli::cli_h3("[Setup] Getting Started")
	  cli::cli_bullets(c(
	    "*" = "{.code raix_setup()} --- Guided first-time setup (2 min)",
	    "*" = "{.code raix_info()} --- Show current configuration",
	    "*" = "{.code raix_check()} --- Test AI backend connectivity"
	  ))

	  cli::cli_h3("[Chat] AI Assistance")
	  cli::cli_bullets(c(
	    "*" = "{.code raix_chat()} --- Interactive chat with AI",
	    "*" = "{.code raix_send('question')} --- Send one message to AI",
	    "*" = "{.code raix_google('topic')} --- Search Google from R"
	  ))

	  cli::cli_h3("[Code] Code Development")
	  cli::cli_bullets(c(
	    "*" = "{.code raix_explain('code')} --- Explain what R code does",
	    "*" = "{.code raix_generate('task')} --- Generate R code from description",
	    "*" = "{.code raix_debug()} --- Debug your last R error",
	    "*" = "{.code raix_document('fn')} --- Generate roxygen2 documentation"
	  ))

	  cli::cli_h3("[Data] Data & Project Tools")
	  cli::cli_bullets(c(
	    "*" = "{.code raix_analyze(mtcars)} --- Guided data analysis",
	    "*" = "{.code raix_search('topic')} --- Find CRAN packages",
	    "*" = "{.code raix_diagnose('script.R')} --- Diagnose script issues"
	  ))

		  cli::cli_h3("[Config] Configuration")
		  cli::cli_bullets(c(
		    "*" = "{.code raix_configure(provider = 'ollama')} --- Switch AI provider",
		    "*" = "13+ providers: ollama, openai, claude, groq, mistral, deepseek, kimi, zai, perplexity, together, lmstudio, vllm, openrouter --- or any custom endpoint"
		  ))

  cat("\n")
  cli::cli_text("Run {.code raix_setup()} for a guided walkthrough!")
}
