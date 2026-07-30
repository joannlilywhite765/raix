# raix --- Beginner-Friendly Utilities
#
# raix_setup()    --- guided first-time setup wizard
# raix_search()   --- search CRAN packages
# raix_diagnose() --- diagnose R script/project issues
# raix_analyze()  --- guided data analysis assistant
# raix_google()   --- search Google from R console
# raix_rstudio()  --- RStudio integration helper
# raix_help()     --- beginner-friendly help menu

#' Single-command setup --- auto-detects and configures everything
#'
#' Auto-detects running AI backends (Ollama, LM Studio, vLLM), checks
#' environment variables for API keys (OPENAI_API_KEY, ANTHROPIC_API_KEY,
#' GROQ_API_KEY, etc.), and falls back to an interactive wizard if needed.
#' One command to get everything working.
#'
#' @param auto If TRUE (default), attempts auto-detection before asking.
#' @param provider Force a specific provider (skips auto-detection).
#' @param model Force a specific model.
#' @param api_key Force a specific API key.
#' @export
raix_setup <- function(auto = TRUE, provider = NULL, model = NULL, api_key = NULL) {
  cli::cli_h1("raix = R + AI + eXperiment")
  
  # Fast path: user provided everything
  if (!is.null(provider)) {
    raix_configure(provider = provider, model = model, api_key = api_key)
    if (isTRUE(raix_check_silent())) {
      cli::cli_alert_success("Connected! raix_chat() to start chatting.")
      return(invisible(raix_info()))
    }
  }
  
  # Auto-detection
  if (auto) {
    detected <- raix_autodetect()
    if (!is.null(detected)) {
      raix_configure(provider = detected$provider, model = detected$model,
                     api_key = detected$api_key)
      if (isTRUE(raix_check_silent())) {
        cli::cli_alert_success("{detected$provider} / {detected$model} --- ready!")
        cli::cli_text("")
        cli::cli_bullets(c(
          "*" = "{.code raix_chat()} --- Start chatting",
          "*" = "{.code raix_gui()} --- Open chat window",
          "*" = "{.code raix_help()} --- All commands"
        ))
        return(invisible(raix_info()))
      }
      cli::cli_alert_warning("{detected$provider} found but not responding.")
    }
  }
  
  # Interactive wizard fallback
  cat("\n")
  cli::cli_h3("Choose your AI provider")
  cli::cli_bullets(c(
    "*" = "Ollama --- FREE, local, private (recommended)",
    "*" = "OpenAI --- GPT-4o, most capable, needs API key",
    "*" = "Claude --- Anthropic, great for reasoning",
    "*" = "Groq --- Fast, free tier available",
    "*" = "Mistral / DeepSeek / Together / LM Studio / vLLM / custom"
  ))
  cat("\n")
  choice <- readline(cli::col_blue("Provider [ollama]: "))
  choice <- tolower(trimws(choice))
  if (nchar(choice) == 0) choice <- "ollama"

  if (choice == "custom") {
    cli::cli_h3("Custom endpoint")
    url <- readline(cli::col_blue("API base URL: "))
    model_name <- readline(cli::col_blue("Model name: "))
    key <- readline(cli::col_blue("API key (enter to skip): "))
    fmt <- readline(cli::col_blue("API format [openai]: "))
    if (nchar(trimws(fmt)) == 0) fmt <- "openai"
    raix_configure(provider = choice, model = model_name, base_url = url,
                   api_key = if (nchar(trimws(key)) > 0) key else NULL,
                   api_format = fmt)
	  } else if (choice == "ollama") {
	    cli::cli_h3("Ollama setup")
	    model_name <- readline(cli::col_blue("Model [llama3.2]: "))
	    if (nchar(trimws(model_name)) == 0 || tolower(trimws(model_name)) %in% c("yes", "y", "default", "ok", "yeah", "yep")) {
	      model_name <- "llama3.2"
	      cli::cli_alert_info("Using default: {model_name}")
	    }
	    raix_configure(provider = "ollama", model = model_name)
	  } else {
	    cli::cli_h3("API key")
	    key <- readline(cli::col_blue("API key: "))
	    model_name <- readline(cli::col_blue("Model (enter for default): "))
	    if (nchar(trimws(model_name)) == 0 || tolower(trimws(model_name)) %in% c("yes", "y", "default", "ok", "yeah", "yep")) {
	      model_name <- NULL
	      cli::cli_alert_info("Using provider default model")
	    }
    raix_configure(provider = choice, api_key = key, model = model_name)
  }
  
  # Test
  cli::cli_h3("Testing connection...")
  reachable <- tryCatch(raix_check(), error = function(e) FALSE)
  if (isTRUE(reachable)) {
    cli::cli_alert_success("Connected! Type {.code raix_chat()} to start.")
  } else {
    cli::cli_alert_warning("Not reachable. Run {.code raix_setup()} to retry.")
  }
  
  cat("\n")
  cli::cli_text("Quick commands: {.code raix_chat()} | {.code raix_gui()} | {.code raix_help()}")
  invisible(raix_info())
}

# Auto-detect running AI backends, pick best code model
raix_autodetect <- function() {
  # 1. Check Ollama (localhost:11434)
  ollama_check <- try(httr::GET("http://localhost:11434/api/tags", httr::timeout(2)), silent = TRUE)
  if (!inherits(ollama_check, "try-error") && httr::status_code(ollama_check) < 400) {
    models <- tryCatch({
      parsed <- httr::content(ollama_check, "parsed", encoding = "UTF-8")
      if (!is.null(parsed$models) && length(parsed$models) > 0) {
        sapply(parsed$models, function(m) m$name)
      } else NULL
    }, error = function(e) NULL)
    
    if (!is.null(models) && length(models) > 0) {
      # Prioritize code-capable models: coder > gemma > qwen > phi > llama > mistral > first
      priority <- c("coder", "gemma", "qwen", "phi", "llama", "mistral", "deepseek")
      best <- NULL
      for (p in priority) {
        matches <- models[grepl(p, models, ignore.case = TRUE)]
        if (length(matches) > 0) { best <- matches[1]; break }
      }
      model <- if (!is.null(best)) best else models[1]
    } else {
      model <- "llama3.2"
    }
    return(list(provider = "ollama", model = model, api_key = NULL))
  }
  
  # 2. Check LM Studio (localhost:1234)
  lm_check <- try(httr::GET("http://localhost:1234/v1/models", httr::timeout(2)), silent = TRUE)
  if (!inherits(lm_check, "try-error") && httr::status_code(lm_check) < 400) {
    return(list(provider = "lmstudio", model = "local-model", api_key = NULL))
  }
  
  # 3. Check vLLM (localhost:8000)
  vllm_check <- try(httr::GET("http://localhost:8000/v1/models", httr::timeout(2)), silent = TRUE)
  if (!inherits(vllm_check, "try-error") && httr::status_code(vllm_check) < 400) {
    return(list(provider = "vllm", model = "default", api_key = NULL))
  }
  
  # 4. Check environment variables for API keys
  env_checks <- list(
    openai = "OPENAI_API_KEY",
    claude = "ANTHROPIC_API_KEY", 
    groq = "GROQ_API_KEY",
    deepseek = "DEEPSEEK_API_KEY",
    mistral = "MISTRAL_API_KEY",
    together = "TOGETHER_API_KEY"
  )
  for (p in names(env_checks)) {
    key <- Sys.getenv(env_checks[[p]])
    if (nchar(key) > 0) {
      preset <- PROVIDER_PRESETS[[p]]
      return(list(provider = p, model = NULL, api_key = key))
    }
  }
  
  NULL
}

# Silent connectivity check (no CLI output)
raix_check_silent <- function() {
  url <- if (raix_env$api_format == "ollama") paste0(raix_env$base_url, "/api/tags")
         else if (raix_env$api_format == "claude") paste0(raix_env$base_url, "/models")
         else paste0(raix_env$base_url, "/models")
  headers <- if (raix_env$api_format == "ollama") httr::add_headers(`Content-Type` = "application/json")
    else if (raix_env$api_format == "claude") httr::add_headers(`x-api-key` = raix_env$api_key %||% "", `anthropic-version` = "2023-06-01")
    else if (!is.null(raix_env$api_key) && nchar(raix_env$api_key) > 0)
      httr::add_headers(Authorization = paste("Bearer", raix_env$api_key))
    else httr::add_headers()
  resp <- try(httr::GET(url, headers, httr::timeout(3)), silent = TRUE)
  !inherits(resp, "try-error") && httr::status_code(resp) < 500
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
