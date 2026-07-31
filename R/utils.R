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
	        # Pre-warm model: send tiny prompt so first real call doesn't time out
	        if (detected$provider == "ollama") {
	          cli::cli_alert_info("Warming up {detected$model} (loading into RAM)...")
	          tryCatch(raix_send("hi"), error = function(e) NULL)
	          raix_env$first_call <- FALSE
	        }
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
    # Pre-warm Ollama models to avoid first-call timeout
    if (raix_env$provider == "ollama") {
      cli::cli_alert_info("Warming up {raix_env$model} (loading into RAM)...")
      tryCatch(raix_send("hi"), error = function(e) NULL)
      raix_env$first_call <- FALSE
    }
    cli::cli_alert_success("Connected! Type {.code raix_chat()} to start.")
  } else {
    cli::cli_alert_warning("Not reachable. Run {.code raix_setup()} to retry.")
  }
  
  cat("\n")
  cli::cli_text("Quick commands: {.code raix_chat()} | {.code raix_gui()} | {.code raix_help()}")
  invisible(raix_info())
}

# Windows-safe port check — avoids curl segfault by using socketConnection
# Returns TRUE if port is open and accepting connections
raix_port_open <- function(host = "localhost", port = 11434, timeout = 1) {
  con <- tryCatch({
    suppressWarnings(
      socketConnection(host = host, port = port, server = FALSE, 
                       blocking = TRUE, open = "r+", timeout = timeout)
    )
  }, error = function(e) NULL)
  if (!is.null(con)) {
    tryCatch(close(con), error = function(e) NULL)
    return(TRUE)
  }
  FALSE
}

# Auto-detect running AI backends, pick best code model
raix_autodetect <- function() {
  # 1. Check Ollama (localhost:11434) — TCP check first to avoid curl segfault
  if (raix_port_open("localhost", 11434)) {
    ollama_check <- try(httr::GET("http://localhost:11434/api/tags", httr::timeout(3)), silent = TRUE)
    if (!inherits(ollama_check, "try-error") && httr::status_code(ollama_check) < 400) {
      models <- tryCatch({
        parsed <- httr::content(ollama_check, "parsed", encoding = "UTF-8")
        if (!is.null(parsed$models) && length(parsed$models) > 0) {
          sapply(parsed$models, function(m) m$name)
        } else NULL
      }, error = function(e) NULL)
      
      if (!is.null(models) && length(models) > 0) {
        # Prioritize code-capable: coder > gemma > qwen > phi > llama > mistral > deepseek > first
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
  }
  
  # 2. Check LM Studio (localhost:1234)
  if (raix_port_open("localhost", 1234)) {
    lm_check <- try(httr::GET("http://localhost:1234/v1/models", httr::timeout(2)), silent = TRUE)
    if (!inherits(lm_check, "try-error") && httr::status_code(lm_check) < 400) {
      return(list(provider = "lmstudio", model = "local-model", api_key = NULL))
    }
  }
  
  # 3. Check vLLM (localhost:8000)
  if (raix_port_open("localhost", 8000)) {
    vllm_check <- try(httr::GET("http://localhost:8000/v1/models", httr::timeout(2)), silent = TRUE)
    if (!inherits(vllm_check, "try-error") && httr::status_code(vllm_check) < 400) {
      return(list(provider = "vllm", model = "default", api_key = NULL))
    }
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
      return(list(provider = p, model = NULL, api_key = key))
    }
  }
  
  NULL
}

# Silent connectivity check — TCP-first to avoid Windows curl crash
raix_check_silent <- function() {
  # Extract host/port from base_url
  url_parts <- raix_env$base_url
  host <- "localhost"
  port <- if (raix_env$api_format == "ollama") 11434 
          else if (grepl(":1234", url_parts)) 1234
          else if (grepl(":8000", url_parts)) 8000
          else NULL
  
  # TCP check first
  if (!is.null(port) && !raix_port_open(host, port)) return(FALSE)
  
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

  cli::cli_h3("[Dev] Developer Agent")
  cli::cli_bullets(c(
    "*" = "{.code raix_solve('problem')} --- Full solution from description",
    "*" = "{.code raix_script('problem', 'out.R')} --- Generate .R script",
    "*" = "{.code raix_notebook('problem', 'out.Rmd')} --- Generate .Rmd notebook",
    "*" = "{.code raix_project('.')} --- Scan project for AI context",
    "*" = "{.code raix_package('task')} --- Find best package for task",
    "*" = "{.code raix_read('file.R')} --- Read file with AI summary",
    "*" = "{.code raix_write('desc', 'out.R')} --- Write AI content to file"
  ))

  cli::cli_h3("[Compute] Terminal, Python, Compile, Pipeline")
  cli::cli_bullets(c(
    "*" = "{.code raix_terminal('ls -la')} --- Run shell commands + AI analysis",
    "*" = "{.code raix_python('task')} --- Generate and run Python from R",
    "*" = "{.code raix_compile('task')} --- Generate C++ with Rcpp, compile, return function",
    "*" = "{.code raix_pipeline(steps)} --- Multi-step cross-language workflow",
    "*" = "{.code raix_benchmark(expr)} --- Time code, get AI optimization tips",
    "*" = "{.code raix_parallel('task')} --- AI rewrites code for multi-core",
    "*" = "{.code raix_sysinfo()} --- Show CPU/RAM/GPU/Python info for AI context",
    "*" = "{.code raix_run('script.py')} --- Run any script (R, Python, shell, JS)"
  ))

  cli::cli_h3("[Config] Configuration")
		  cli::cli_bullets(c(
		    "*" = "{.code raix_configure(provider = 'ollama')} --- Switch AI provider",
		    "*" = "13+ providers: ollama, openai, claude, groq, mistral, deepseek, kimi, zai, perplexity, together, lmstudio, vllm, openrouter --- or any custom endpoint"
		  ))

  cat("\n")
  cli::cli_text("Run {.code raix_setup()} for a guided walkthrough!")
}

# ── Developer Agent Utilities ─────────────────────────────────────────────

#' Solve a data problem end-to-end with AI
#'
#' Describe your problem in plain English and get a complete, runnable
#' R solution. raix automatically selects the best packages, plans the
#' approach, and generates production-ready code.
#'
#' @param problem Description of the data problem to solve
#' @param data Optional data.frame or path to data file for context
#' @param output Optional file path to write the solution (.R or .Rmd)
#' @param execute If TRUE, runs the generated code and returns results
#'
#' @return The generated solution (invisibly)
#' @export
raix_solve <- function(problem, data = NULL, output = NULL, execute = FALSE) {
  if (missing(problem) || !is.character(problem) || nchar(trimws(problem)) == 0) {
    stop("problem must be a non-empty description of what you want to solve")
  }
  
  cli::cli_h1("raix Solver")
  cli::cli_text("Problem: {problem}")
  
  # Build context
  context <- raix_build_context(data)
  
  # Step 1: Plan
  cli::cli_h3("Step 1: Planning solution...")
  plan_prompt <- if (raix_env$small_model) {
    paste0("Task: ", problem, "\n",
           context, "\n",
           "List: 1) Best R packages 2) Approach steps (3-4 max)")
  } else {
    paste0("I need to solve this data problem in R:\n\n", problem, "\n\n",
           context, "\n\n",
           "First, tell me: 1) Which R packages should I use and why? ",
           "2) What's the step-by-step approach? Keep it concise.")
  }
  plan <- tryCatch(raix_send(plan_prompt), error = function(e) NULL)
  if (!is.null(plan)) {
    cat("\n", cli::col_blue("Plan:"), "\n", plan, "\n\n")
  }
  
  # Step 2: Generate code
  cli::cli_h3("Step 2: Generating R code...")
  code_prompt <- if (raix_env$small_model) {
    paste0("Write complete R code for: ", problem, "\n",
           context, "\n",
           if (!is.null(plan)) paste0("Plan: ", plan, "\n") else "",
           "Output ONLY the R code. Include library() calls. Use base R when possible.")
  } else {
    paste0("Write a complete, runnable R script for this problem:\n\n", problem, "\n\n",
           context, "\n\n",
           if (!is.null(plan)) paste0("Follow this plan:\n", plan, "\n\n") else "",
           "Include: library() calls, data loading, analysis, visualization, and comments. ",
           "Output ONLY the R code, ready to source().")
  }
  
  solution <- tryCatch(raix_send(code_prompt), error = function(e) NULL)
  if (is.null(solution)) {
    cli::cli_alert_danger("Failed to generate solution. Check your AI backend.")
    return(invisible(NULL))
  }
  
  # Extract code from markdown if needed
  solution <- raix_extract_code(solution)
  
  cat("\n")
  cli::cli_text(cli::col_green("Solution:"))
  cat(solution, "\n")
  
  # Write to file
  if (!is.null(output)) {
    writeLines(solution, output)
    cli::cli_alert_success("Solution written to {.file {output}}")
  }
  
  # Execute
  if (execute) {
    cli::cli_h3("Step 3: Executing...")
    result <- tryCatch(eval(parse(text = solution)), error = function(e) {
      cli::cli_alert_danger("Execution error: {conditionMessage(e)}")
      NULL
    })
    if (!is.null(result)) {
      cli::cli_alert_success("Code executed successfully!")
      return(invisible(list(code = solution, result = result)))
    }
  }
  
  invisible(solution)
}

#' Generate a complete R script from a problem description
#'
#' Creates a .R file with the full solution. Like raix_solve() but
#' always writes to a file and returns the path.
#'
#' @param problem Problem description
#' @param output Path for the .R file (default: auto-generated name)
#' @param data Optional data for context
#' @return Path to the generated script (invisibly)
#' @export
raix_script <- function(problem, output = NULL, data = NULL) {
  if (is.null(output)) {
    output <- paste0("raix_solution_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".R")
  }
  raix_solve(problem = problem, data = data, output = output, execute = FALSE)
  if (file.exists(output)) {
    cli::cli_alert_success("Script created: {.file {output}}")
    if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
      rstudioapi::navigateToFile(output)
    }
  }
  invisible(output)
}

#' Generate a complete R Markdown notebook from a problem description
#'
#' Creates a polished .Rmd file with markdown explanations, code chunks,
#' and visualizations. Ready to knit to HTML/PDF.
#'
#' @param problem Problem description
#' @param output Path for the .Rmd file (default: auto-generated name)
#' @param data Optional data.frame or file path for context
#' @param title Title for the notebook
#' @return Path to the generated notebook (invisibly)
#' @export
raix_notebook <- function(problem, output = NULL, data = NULL, title = NULL) {
  if (is.null(output)) {
    output <- paste0("raix_notebook_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".Rmd")
  }
  if (is.null(title)) title <- problem
  
  context <- raix_build_context(data)
  
  cli::cli_h1("raix Notebook Generator")
  
  prompt <- if (raix_env$small_model) {
    paste0("Create R Markdown notebook for: ", problem, "\n",
           context, "\n",
           "Title: ", title, "\n",
           "Include: setup chunk, code chunks, brief text. Output complete .Rmd.")
  } else {
    paste0("Create a complete R Markdown (.Rmd) notebook for this task:\n\n", problem, "\n\n",
           context, "\n\n",
           "The notebook title is: ", title, "\n\n",
           "Include: YAML header (html_document), setup chunk with library() calls, ",
           "multiple labeled code chunks with explanations in markdown between them, ",
           "and a summary section at the end. Make it professional and ready to knit.",
           "\n\nOutput the COMPLETE .Rmd file content.")
  }
  
  notebook <- tryCatch(raix_send(prompt), error = function(e) NULL)
  if (is.null(notebook)) {
    cli::cli_alert_danger("Failed to generate notebook.")
    return(invisible(NULL))
  }
  
  notebook <- raix_extract_code(notebook)
  writeLines(notebook, output)
  cli::cli_alert_success("Notebook created: {.file {output}}")
  
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    rstudioapi::navigateToFile(output)
  }
  invisible(output)
}

#' Scan a project directory and build context for AI
#'
#' Reads R scripts, Rmd files, data files, and project structure
#' to give the AI full context about your project.
#'
#' @param path Project directory path (default: current directory)
#' @return A list with project context (invisibly)
#' @export
raix_project <- function(path = ".") {
  if (!dir.exists(path)) stop("Directory not found: ", path)
  
  cli::cli_h1("raix Project Scan")
  cli::cli_text("Scanning: {normalizePath(path)}")
  
  # File inventory
  all_files <- list.files(path, recursive = TRUE, full.names = TRUE)
  r_files <- list.files(path, pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
  rmd_files <- list.files(path, pattern = "\\.[Rr]md$", recursive = TRUE, full.names = TRUE)
  data_files <- list.files(path, pattern = "\\.(csv|tsv|xlsx|rds|rda)$", recursive = TRUE, full.names = TRUE)
  
  cli::cli_bullets(c(
    "*" = "R scripts: {length(r_files)}",
    "*" = "R Markdown: {length(rmd_files)}",
    "*" = "Data files: {length(data_files)}",
    "*" = "Total files: {length(all_files)}"
  ))
  
  # Build context
  context_lines <- c(
    paste0("Project path: ", normalizePath(path)),
    paste0("R version: ", R.version.string),
    paste0("Installed packages: ", paste(head(rownames(installed.packages()), 30), collapse = ", "), "..."),
    "",
    "=== R Scripts ==="
  )
  
  for (f in head(r_files, 5)) {
    content <- tryCatch(paste(readLines(f, warn = FALSE), collapse = "\n"), error = function(e) "(unreadable)")
    context_lines <- c(context_lines, paste0("--- ", basename(f), " ---"), substr(content, 1, 2000))
  }
  
  if (length(rmd_files) > 0) {
    context_lines <- c(context_lines, "", "=== R Markdown Files ===")
    for (f in head(rmd_files, 3)) {
      content <- tryCatch(paste(readLines(f, warn = FALSE), collapse = "\n"), error = function(e) "(unreadable)")
      context_lines <- c(context_lines, paste0("--- ", basename(f), " ---"), substr(content, 1, 2000))
    }
  }
  
  if (length(data_files) > 0) {
    context_lines <- c(context_lines, "", paste0("Data files: ", paste(basename(data_files), collapse = ", ")))
  }
  
  context <- paste(context_lines, collapse = "\n")
  
  # Store for later use
  raix_env$project_context <- context
  raix_env$project_path <- normalizePath(path)
  
  cli::cli_alert_success("Project context loaded ({nchar(context)} chars)")
  cli::cli_text("Use {.code raix_solve()} with full project awareness.")
  
  invisible(list(path = normalizePath(path), files = all_files, context = context))
}

#' Find the best R package for a specific task
#'
#' Searches CRAN and uses AI to recommend the most suitable, well-maintained
#' R package for any data task.
#'
#' @param task Description of what you want to do (e.g., "survival analysis", "text mining")
#' @return Recommended packages with install commands (invisibly)
#' @export
raix_package <- function(task) {
  if (missing(task) || !is.character(task) || nchar(trimws(task)) == 0) {
    stop("task must describe what you want to do (e.g., 'deep learning', 'geo mapping')")
  }
  
  cli::cli_h2("Finding best packages for: {task}")
  
  # First try CRAN search
  pkgs <- tryCatch(raix_search(task, n = 5), error = function(e) NULL)
  
  # Then get AI recommendation with comparison
  prompt <- if (raix_env$small_model) {
    paste0("Best R package for: ", task, ". Name top 2. 1 line each why.")
  } else {
    paste0("What is the single best R package for: ", task, "? ",
           "Consider: popularity, maintenance, ease of use, performance. ",
           "If there are multiple good options, compare them briefly. ",
           "Output: package_name --- reason")
  }
  
  suggestion <- tryCatch(raix_send(prompt), error = function(e) NULL)
  if (!is.null(suggestion)) {
    cat("\n", cli::col_green("AI Recommendation:"), "\n")
    cat(suggestion, "\n\n")
  }
  
  invisible(suggestion)
}

#' Read a file with AI-powered summarization
#'
#' Reads any text file and optionally summarizes or explains it with AI.
#'
#' @param file Path to the file
#' @param summarize If TRUE, AI summarizes the content
#' @return File content (invisibly)
#' @export
raix_read <- function(file, summarize = FALSE) {
  if (!file.exists(file)) stop("File not found: ", file)
  
  ext <- tolower(tools::file_ext(file))
  is_binary <- ext %in% c("rds", "rda", "rdata", "xlsx", "xls", "png", "jpg", "pdf")
  
  if (is_binary) {
    info <- file.info(file)
    cli::cli_bullets(c(
      "*" = "File: {basename(file)}",
      "*" = "Type: {ext} (binary)",
      "*" = "Size: {utils:::format.object_size(info$size, 'auto')}"
    ))
    return(invisible(list(path = file, type = ext, size = info$size)))
  }
  
  content <- tryCatch(paste(readLines(file, warn = FALSE), collapse = "\n"), 
                      error = function(e) stop("Cannot read file: ", conditionMessage(e)))
  
  cli::cli_h2("Reading: {basename(file)}")
  cli::cli_text("{nchar(content)} chars | {length(strsplit(content, '\\n')[[1]])} lines")
  
  if (summarize && nchar(content) > 100) {
    prompt <- paste0("Summarize this file in 2-3 bullet points:\n\n", 
                     substr(content, 1, 3000))
    summary <- tryCatch(raix_send(prompt), error = function(e) NULL)
    if (!is.null(summary)) {
      cat("\n", cli::col_green("Summary:"), "\n", summary, "\n")
    }
  } else if (!summarize) {
    cat("\n", substr(content, 1, 2000), 
        if (nchar(content) > 2000) "\n... (truncated)" else "", "\n")
  }
  
  invisible(content)
}

#' Write AI-generated content to a file
#'
#' Sends a description to the AI, gets the generated content,
#' and writes it directly to a file.
#'
#' @param description What to generate
#' @param file Output file path
#' @param type "code" for R code, "text" for prose, "rmd" for R Markdown
#' @return Path to the created file (invisibly)
#' @export
raix_write <- function(description, file, type = c("code", "text", "rmd")) {
  if (missing(description) || !is.character(description)) {
    stop("description must be a non-empty character string")
  }
  type <- match.arg(type)
  
  cli::cli_h2("Generating {type} file: {.file {file}}")
  
  prompt <- switch(type,
    code = if (raix_env$small_model) {
      paste0("Write R code. Output ONLY code.\n", description)
    } else {
      paste0("Write a complete R script for:\n\n", description, "\n\nOutput ONLY the R code.")
    },
    text = paste0("Write content for: ", description),
    rmd = if (raix_env$small_model) {
      paste0("Create Rmd for: ", description, "\nInclude: YAML, code chunks, text.")
    } else {
      paste0("Create a complete R Markdown notebook for:\n\n", description,
             "\n\nInclude YAML header, code chunks, and markdown text. Output the full .Rmd.")
    }
  )
  
  content <- tryCatch(raix_send(prompt), error = function(e) {
    cli::cli_alert_danger("Generation failed: {conditionMessage(e)}")
    NULL
  })
  
  if (is.null(content)) return(invisible(NULL))
  
  content <- raix_extract_code(content)
  writeLines(content, file)
  cli::cli_alert_success("Written {nchar(content)} chars to {.file {file}}")
  
  # Open in RStudio if available
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    rstudioapi::navigateToFile(file)
  }
  
  invisible(file)
}

# ── Internal Helpers ───────────────────────────────────────────────────────

# Build context string from optional data parameter
raix_build_context <- function(data = NULL) {
  lines <- c()
  
  # R environment info
  lines <- c(lines, paste0("R version: ", R.version.string))
  lines <- c(lines, paste0("Working directory: ", getwd()))
  
  # Data info
  if (!is.null(data)) {
    if (is.data.frame(data)) {
      nm <- deparse(substitute(data))
      lines <- c(lines, paste0("Data: ", nm, " (", nrow(data), " rows x ", ncol(data), " cols)"))
      lines <- c(lines, paste0("Columns: ", paste(head(names(data), 20), collapse = ", ")))
      # Sample
      capture <- utils::capture.output(str(data, give.attr = FALSE, list.len = 5))
      lines <- c(lines, paste(capture, collapse = "\n"))
    } else if (is.character(data) && file.exists(data)) {
      lines <- c(lines, paste0("Data file: ", data))
      if (grepl("\\.csv$", data, ignore.case = TRUE)) {
        preview <- tryCatch(readLines(data, n = 3), error = function(e) NULL)
        if (!is.null(preview)) lines <- c(lines, "Preview:", preview)
      }
    }
  }
  
  # Project context if available
  if (!is.null(raix_env$project_context)) {
    lines <- c(lines, "", "=== Project Context ===", 
               substr(raix_env$project_context, 1, 2000))
  }
  
  # Installed packages
  pkgs <- head(rownames(installed.packages()), 40)
  lines <- c(lines, "", paste0("Key installed packages: ", paste(pkgs, collapse = ", ")))
  
  paste(lines, collapse = "\n")
}

# Extract code from markdown code blocks
raix_extract_code <- function(text) {
  if (is.null(text)) return("")
  # If there are ``` blocks, extract content from the first complete one
  if (grepl("```", text)) {
    # Try to find R code blocks first
    blocks <- regmatches(text, gregexpr("```\\{?r?\\}?\\s*\\n([\\s\\S]*?)```", text, perl = TRUE))[[1]]
    if (length(blocks) > 0) {
      # Extract content between ```
      content <- gsub("```\\{?r?\\}?\\s*\\n?", "", blocks)
      content <- gsub("```\\s*$", "", content)
      return(paste(content, collapse = "\n\n"))
    }
    # Generic code blocks
    blocks <- regmatches(text, gregexpr("```\\w*\\s*\\n([\\s\\S]*?)```", text, perl = TRUE))[[1]]
    if (length(blocks) > 0) {
      content <- gsub("```\\w*\\s*\\n", "", blocks)
      content <- gsub("```\\s*$", "", content)
      return(paste(content, collapse = "\n\n"))
    }
    # Just strip all ``` markers
    text <- gsub("```\\w*\\s*\\n?", "", text)
    text <- gsub("```", "", text)
  }
  trimws(text)
}
