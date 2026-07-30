# AIR — AI for R: Core API Client
#
# Handles communication with 6 AI backends:
# OpenAI, Ollama, Anthropic Claude, DeepSeek, Kimi, Z.Ai

#' @keywords internal
"_PACKAGE"

# Global state ---------------------------------------------------------------
air_env <- new.env(parent = emptyenv())
air_env$backend <- "ollama"
air_env$model <- "llama3.2"
air_env$api_key <- NULL
air_env$base_url <- "http://localhost:11434"
air_env$system_prompt <- paste0(
  "You are AIR, an AI coding assistant for R. ",
  "You help users write, explain, debug, and document R code. ",
  "Always respond with valid R code when asked to generate code. ",
  "Keep explanations concise and R-focused. ",
  "When debugging, identify the root cause and suggest a fix."
)
air_env$temperature <- 0.2
air_env$max_tokens <- 2048
air_env$chat_history <- list()

#' Configure the AIR backend
#'
#' @param backend AI provider: "openai", "ollama", "claude", "deepseek", "kimi", "zai"
#' @param model Model name (e.g., "gpt-4o", "llama3.2", "claude-3-opus")
#' @param api_key API key (not needed for local Ollama)
#' @param base_url API base URL
#' @param system_prompt Custom system prompt
#' @param temperature Creativity (0-1). Lower = more deterministic.
#' @param max_tokens Maximum response tokens
#'
#' @return Invisibly returns the configuration list
#' @export
#'
#' @examples
#' \dontrun{
#' air_configure(backend = "openai", model = "gpt-4o", api_key = "sk-...")
#' air_configure(backend = "ollama", model = "llama3.2")
#' }
air_configure <- function(backend = c("openai", "ollama", "claude", "deepseek", "kimi", "zai"),
                          model = NULL,
                          api_key = NULL,
                          base_url = NULL,
                          system_prompt = NULL,
                          temperature = NULL,
                          max_tokens = NULL) {
  backend <- match.arg(backend)
  air_env$backend <- backend

  if (!is.null(model))        air_env$model <- model
  if (!is.null(api_key))      air_env$api_key <- api_key
  if (!is.null(base_url))     air_env$base_url <- base_url
  if (!is.null(system_prompt)) air_env$system_prompt <- system_prompt
  if (!is.null(temperature))  air_env$temperature <- temperature
  if (!is.null(max_tokens))   air_env$max_tokens <- max_tokens

  # Set default model per backend
  if (is.null(model)) {
    air_env$model <- switch(backend,
      openai = "gpt-4o", ollama = "llama3.2", claude = "claude-3-5-sonnet-20241022",
      deepseek = "deepseek-chat", kimi = "moonshot-v1-8k", zai = "zai-model"
    )
  }

  # Set default base URL per backend
  if (is.null(base_url)) {
    air_env$base_url <- switch(backend,
      openai = "https://api.openai.com/v1",
      ollama = "http://localhost:11434",
      claude = "https://api.anthropic.com/v1",
      deepseek = "https://api.deepseek.com/v1",
      kimi = "https://api.moonshot.cn/v1",
      zai = "https://api.z.ai/v1"
    )
  }

  cli::cli_alert_success("AIR configured: {backend} / {air_env$model}")
  invisible(as.list(air_env))
}

#' Send a message to the AI and get a response
#'
#' @param prompt The message to send
#' @param context Optional additional context (e.g., current R code)
#' @param stream Whether to stream the response (console-friendly)
#'
#' @return The AI's response as a character string
#' @export
air_send <- function(prompt, context = NULL, stream = FALSE) {
  if (!is.null(context)) {
    prompt <- paste0("Context:\n```r\n", context, "\n```\n\nUser: ", prompt)
  }

  messages <- list(
    list(role = "system", content = air_env$system_prompt),
    list(role = "user", content = prompt)
  )

  resp <- switch(air_env$backend,
    openai    = air_openai(messages, stream),
    ollama    = air_ollama(messages, stream),
    claude    = air_claude(messages, stream),
    deepseek  = air_deepseek(messages, stream),
    kimi      = air_kimi(messages, stream),
    zai       = air_zai(messages, stream),
    stop("Unknown backend: ", air_env$backend)
  )

  # Add to chat history
  air_env$chat_history <- c(air_env$chat_history,
    list(list(role = "user", content = prompt)),
    list(list(role = "assistant", content = resp))
  )

  resp
}

#' Get R help — explain what code does
#'
#' @param code R code to explain, or a function name
#'
#' @return Human-readable explanation
#' @export
air_explain <- function(code) {
  if (exists(code, mode = "function")) {
    code <- paste(deparse(get(code)), collapse = "\n")
  }
  prompt <- paste0("Explain this R code in simple terms:\n\n```r\n", code, "\n```")
  air_send(prompt)
}

#' Debug an R error
#'
#' @param error_msg The error message (or call without arguments to use last error)
#'
#' @return Root cause analysis and suggested fix
#' @export
air_debug <- function(error_msg = NULL) {
  if (is.null(error_msg)) {
    error_msg <- geterrmessage()
    if (error_msg == "") stop("No error to debug. Provide error_msg or run after an error.")
  }
  trace <- paste(capture.output(traceback()), collapse = "\n")
  prompt <- paste0(
    "I got this R error:\n\n", error_msg, "\n\n",
    "Traceback:\n", trace, "\n\n",
    "Explain the root cause and suggest a fix."
  )
  air_send(prompt)
}

#' Generate roxygen2 documentation for a function
#'
#' @param code R function code
#' @param func_name Optional function name
#'
#' @return roxygen2 documentation block
#' @export
air_document <- function(code, func_name = NULL) {
  prompt <- paste0(
    "Generate roxygen2 documentation for this R function. Include @param, @return, @examples, and @export if appropriate.\n\n",
    "```r\n", code, "\n```\n\n",
    "Output ONLY the roxygen block, no explanation."
  )
  air_send(prompt)
}

#' Generate R code from a natural language description
#'
#' @param description What you want the code to do
#' @param context Optional existing code for context
#'
#' @return Generated R code
#' @export
air_generate <- function(description, context = NULL) {
  prompt <- paste0(
    "Write R code to accomplish this task. Use best practices (error handling, type checking). ",
    "Output ONLY the R code, no explanation.\n\nTask: ", description
  )
  air_send(prompt, context = context)
}

#' Start an interactive chat session
#'
#' Opens a continuous chat in the R console. Type 'exit' or press ESC to quit.
#'
#' @export
air_chat <- function() {
  cli::cli_h1("AIR Chat Session")
  cli::cli_alert_info("Backend: {air_env$backend} | Model: {air_env$model}")
  cli::cli_text("Type 'exit' or press ESC to end the chat.")
  cli::cli_text("")

  while (TRUE) {
    user_input <- readline(cli::col_blue("\nYou> "))
    if (tolower(trimws(user_input)) %in% c("exit", "quit", "q")) {
      cli::cli_alert_success("Chat ended.")
      break
    }
    if (nchar(trimws(user_input)) == 0) next

    cat("\n")
    response <- air_send(user_input)
    cli::cli_text(cli::col_green("AIR> "), response)
    cat("\n")
  }
  invisible(NULL)
}

#' View current AIR configuration
#'
#' @export
air_info <- function() {
  cli::cli_h2("AIR Configuration")
  cli::cli_li("Backend: {air_env$backend}")
  cli::cli_li("Model: {air_env$model}")
  cli::cli_li("Base URL: {air_env$base_url}")
  cli::cli_li("Temperature: {air_env$temperature}")
  cli::cli_li("History length: {length(air_env$chat_history)}")
  invisible(NULL)
}
