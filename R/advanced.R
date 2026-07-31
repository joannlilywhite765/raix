# raix Advanced — Test, Refactor, Translate, SQL, Web, History
#
# Power tools for professional R developers.

#' Generate unit tests for an R function with AI
#'
#' Describe a function or paste its code, and raix generates complete
#' testthat unit tests covering edge cases, typical usage, and errors.
#'
#' @param func Function name (character) or function code
#' @param output Optional file path to write the test file
#' @return Generated test code (invisibly)
#' @export
raix_test <- function(func, output = NULL) {
  if (missing(func)) stop("Provide a function name or code to test")
  
  # Get function code
  if (is.character(func) && length(func) == 1 && exists(func, mode = "function")) {
    fn_name <- func
    code <- paste(deparse(get(func)), collapse = "\n")
  } else if (is.character(func)) {
    fn_name <- "the_function"
    code <- func
  } else {
    stop("func must be a function name (string) or function code (string)")
  }
  
  cli::cli_h2("raix Test Generator: {fn_name}")
  
  prompt <- if (raix_env$small_model) {
    paste0("Write testthat tests for this R function. Include: valid input, edge cases, errors.\n\n", code)
  } else {
    paste0("Write complete testthat unit tests for this R function:\n\n```r\n", code, "\n```\n\n",
           "Include tests for: (1) typical/valid inputs, (2) edge cases (empty, NA, NULL), ",
           "(3) expected errors. Use testthat 3e syntax. Output ONLY the test code.")
  }
  
  tests <- tryCatch(raix_send(prompt), error = function(e) NULL)
  if (is.null(tests)) {
    cli::cli_alert_danger("Test generation failed")
    return(invisible(NULL))
  }
  
  tests <- raix_extract_code(tests)
  cat("\n", cli::col_green("Generated tests:"), "\n")
  cat(tests, "\n\n")
  
  if (!is.null(output)) {
    writeLines(tests, output)
    cli::cli_alert_success("Tests written to {.file {output}}")
    if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
      rstudioapi::navigateToFile(output)
    }
  }
  
  invisible(tests)
}

#' Get AI refactoring suggestions for R code
#'
#' Paste code and raix suggests improvements: performance, readability,
#' best practices, modern R patterns.
#'
#' @param code R code to refactor (as string)
#' @param focus What to focus on: "all", "performance", "readability", "safety"
#' @param apply If TRUE, returns refactored code; if FALSE, returns suggestions
#' @return Refactored code or suggestions (invisibly)
#' @export
raix_refactor <- function(code, focus = c("all", "performance", "readability", "safety"), apply = FALSE) {
  if (missing(code) || !is.character(code) || nchar(trimws(code)) == 0) {
    stop("code must be a non-empty character string")
  }
  focus <- match.arg(focus)
  
  cli::cli_h2("raix Refactor")
  cli::cli_text("Focus: {focus}")
  
  focus_text <- switch(focus,
    all = "improve performance, readability, and safety",
    performance = "optimize for speed and memory efficiency",
    readability = "improve clarity, naming, and structure",
    safety = "add error handling, input validation, edge case protection"
  )
  
  prompt <- if (raix_env$small_model) {
    paste0("Refactor this R code to ", focus_text, ".\n\n", code, 
           if (apply) "\nOutput ONLY the refactored code." else "\nList 3-5 specific improvements.")
  } else {
    paste0("Review this R code and suggest ", focus_text, " improvements:\n\n```r\n", code, "\n```\n\n",
           if (apply) {
             "Rewrite the code with all improvements applied. Output ONLY the refactored R code."
           } else {
             "For each suggestion: (1) What to change, (2) Why, (3) Show the improved code snippet."
           })
  }
  
  result <- tryCatch(raix_send(prompt), error = function(e) NULL)
  if (is.null(result)) {
    cli::cli_alert_danger("Refactoring failed")
    return(invisible(NULL))
  }
  
  if (apply) result <- raix_extract_code(result)
  
  cat("\n", cli::col_green(if(apply) "Refactored code:" else "Suggestions:"), "\n")
  cat(result, "\n")
  
  invisible(result)
}

#' Translate code between R and Python
#'
#' Paste R code, get Python. Paste Python code, get R. AI handles
#' the translation including package equivalents and idioms.
#'
#' @param code Source code to translate
#' @param from Source language ("r" or "python") — auto-detected if not specified
#' @param to Target language ("r" or "python")
#' @return Translated code (invisibly)
#' @export
raix_translate <- function(code, from = c("auto", "r", "python"), to = c("python", "r")) {
  if (missing(code) || !is.character(code) || nchar(trimws(code)) == 0) {
    stop("code must be a non-empty character string")
  }
  from <- match.arg(from)
  to <- match.arg(to)
  
  # Auto-detect source language
  if (from == "auto") {
    r_indicators <- sum(grepl("<-|%>%|library\\(|c\\(|list\\(|function\\(|ggplot|dplyr", code))
    py_indicators <- sum(grepl("def |import |print\\(|\\[\\]|class |lambda|pandas|numpy", code))
    from <- if (r_indicators > py_indicators) "r" else "python"
  }
  
  cli::cli_h2("raix Translate: {toupper(from)} → {toupper(to)}")
  
  prompt <- if (raix_env$small_model) {
    paste0("Translate this ", from, " code to ", to, ":\n\n", code, "\nOutput ONLY the ", to, " code.")
  } else {
    paste0("Translate this ", from, " code to idiomatic ", to, ":\n\n```", from, "\n", code, "\n```\n\n",
           "Use the most natural/idiomatic ", to, " patterns. Map packages appropriately ",
           "(e.g., dplyr ↔ pandas, ggplot2 ↔ matplotlib/seaborn). Output ONLY the ", to, " code.")
  }
  
  result <- tryCatch(raix_send(prompt), error = function(e) NULL)
  if (is.null(result)) {
    cli::cli_alert_danger("Translation failed")
    return(invisible(NULL))
  }
  
  result <- raix_extract_code(result)
  
  cat("\n", cli::col_green(paste0(toupper(to), " code:")), "\n")
  cat(result, "\n")
  
  invisible(result)
}

#' Generate SQL from plain English
#'
#' Describe what data you want and raix generates the SQL query.
#' Supports SELECT, JOIN, GROUP BY, window functions, CTEs.
#'
#' @param description What data you need, in plain English
#' @param schema Optional: describe your table structure
#' @param dialect SQL dialect: "postgres", "mysql", "sqlite", "sqlserver"
#' @return SQL query (invisibly)
#' @export
raix_sql <- function(description, schema = NULL, dialect = c("postgres", "mysql", "sqlite", "sqlserver")) {
  if (missing(description) || !is.character(description) || nchar(trimws(description)) == 0) {
    stop("description must describe what data you want")
  }
  dialect <- match.arg(dialect)
  
  cli::cli_h2("raix SQL Generator")
  cli::cli_text("Dialect: {dialect}")
  
  context <- ""
  if (!is.null(schema)) {
    context <- paste0("Database schema:\n", schema, "\n\n")
  }
  
  prompt <- if (raix_env$small_model) {
    paste0("Write SQL (", dialect, ") for: ", description, "\n", context, "Output ONLY the SQL.")
  } else {
    paste0("Write a ", dialect, " SQL query for this request:\n\n", description, "\n\n",
           context,
           "Use proper ", dialect, " syntax. Include comments explaining each clause. ",
           "Output the SQL query ready to run.")
  }
  
  sql <- tryCatch(raix_send(prompt), error = function(e) NULL)
  if (is.null(sql)) {
    cli::cli_alert_danger("SQL generation failed")
    return(invisible(NULL))
  }
  
  sql <- raix_extract_code(sql)
  
  cat("\n", cli::col_green("SQL Query:"), "\n")
  cat(sql, "\n")
  
  invisible(sql)
}

#' Fetch and summarize a web page with AI
#'
#' Downloads a URL, extracts text, and uses AI to summarize or
#' answer questions about the content.
#'
#' @param url Web page URL to fetch
#' @param question Optional: specific question about the page content
#' @return Page summary or answer (invisibly)
#' @export
raix_web <- function(url, question = NULL) {
  if (missing(url) || !is.character(url) || nchar(trimws(url)) == 0) {
    stop("url must be a valid web address")
  }
  
  cli::cli_h2("raix Web")
  cli::cli_text("Fetching: {url}")
  
  # Fetch page content
  content <- tryCatch({
    resp <- httr::GET(url, httr::timeout(15))
    if (httr::http_error(resp)) stop("HTTP ", httr::status_code(resp))
    text <- httr::content(resp, "text", encoding = "UTF-8")
    # Strip HTML tags
    text <- gsub("<[^>]+>", " ", text)
    text <- gsub("\\s+", " ", text)
    substr(trimws(text), 1, 8000)
  }, error = function(e) {
    cli::cli_alert_danger("Failed to fetch: {conditionMessage(e)}")
    NULL
  })
  
  if (is.null(content)) return(invisible(NULL))
  
  cli::cli_text("Fetched {nchar(content)} chars")
  
  # Summarize or answer
  if (!is.null(question)) {
    prompt <- paste0("Based on this web page content, answer the question.\n\n",
                     "Question: ", question, "\n\n",
                     "Page content:\n", content)
  } else {
    prompt <- paste0("Summarize this web page in 3-5 bullet points:\n\n", content)
  }
  
  result <- tryCatch(raix_send(prompt), error = function(e) NULL)
  if (!is.null(result)) {
    cat("\n", cli::col_green(if(!is.null(question)) "Answer:" else "Summary:"), "\n")
    cat(result, "\n")
  }
  
  invisible(result)
}

#' View and search raix chat history
#'
#' Displays recent conversations with the AI. Can search for specific
#' topics, export to file, or clear history.
#'
#' @param search Optional text to search for in history
#' @param n Number of recent messages to show (default: 20)
#' @param clear If TRUE, clears all chat history
#' @export
raix_history <- function(search = NULL, n = 20, clear = FALSE) {
  if (clear) {
    raix_env$chat_history <- list()
    cli::cli_alert_success("Chat history cleared")
    return(invisible(NULL))
  }
  
  history <- raix_env$chat_history
  if (length(history) == 0) {
    cli::cli_alert_info("No chat history yet. Start with raix_chat()!")
    return(invisible(NULL))
  }
  
  cli::cli_h2("raix Chat History: {length(history)/2} exchanges")
  
  # Filter by search
  if (!is.null(search)) {
    matches <- sapply(history, function(m) grepl(search, m$content, ignore.case = TRUE))
    history <- history[matches]
    cli::cli_text("Filtered by '{search}': {length(history)} messages")
  }
  
  # Show last N
  history <- tail(history, n * 2)
  
  for (i in seq(1, length(history), by = 2)) {
    user_msg <- history[[i]]
    ai_msg <- if (i+1 <= length(history)) history[[i+1]] else NULL
    
    cat("\n")
    cli::cli_text(cli::col_blue("You> "), substr(user_msg$content, 1, 100),
                  if (nchar(user_msg$content) > 100) "..." else "")
    if (!is.null(ai_msg)) {
      cli::cli_text(cli::col_green("raix> "), substr(ai_msg$content, 1, 150),
                    if (nchar(ai_msg$content) > 150) "..." else "")
    }
  }
  
  cat("\n")
  cli::cli_text("Total: {length(raix_env$chat_history)/2} exchanges | Clear: {.code raix_history(clear = TRUE)}")
  
  invisible(history)
}