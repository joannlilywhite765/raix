# AIR — AI for R: Core API Client
#
# Model-agnostic: works with ANY OpenAI-compatible, Ollama, or Claude API.
# No hardcoded provider list — bring your own model, your own endpoint.

#' @keywords internal
"_PACKAGE"

# Global state ---------------------------------------------------------------
air_env <- new.env(parent = emptyenv())
air_env$provider   <- "ollama"       # Display name (any string)
air_env$model      <- "llama3.2"     # Any model name
air_env$api_key    <- NULL
air_env$base_url   <- "http://localhost:11434"
air_env$api_format <- "ollama"       # "openai", "ollama", or "claude"
air_env$system_prompt <- paste0(
  "You are AIR, an AI coding assistant for R. ",
  "You help users write, explain, debug, and document R code. ",
  "Always respond with valid R code when asked to generate code. ",
  "Keep explanations concise and R-focused."
)
air_env$temperature  <- 0.2
air_env$max_tokens   <- 2048
air_env$chat_history <- list()

# Known provider presets (for convenience, not a hardcoded list) -------------
PROVIDER_PRESETS <- list(
  ollama   = list(base_url = "http://localhost:11434", api_format = "ollama"),
  openai   = list(base_url = "https://api.openai.com/v1", api_format = "openai"),
  claude   = list(base_url = "https://api.anthropic.com/v1", api_format = "claude"),
  deepseek = list(base_url = "https://api.deepseek.com/v1", api_format = "openai"),
  kimi     = list(base_url = "https://api.moonshot.cn/v1", api_format = "openai"),
  zai      = list(base_url = "https://api.z.ai/v1", api_format = "openai"),
  groq     = list(base_url = "https://api.groq.com/openai/v1", api_format = "openai"),
  together = list(base_url = "https://api.together.xyz/v1", api_format = "openai"),
  mistral  = list(base_url = "https://api.mistral.ai/v1", api_format = "openai"),
  perplexity = list(base_url = "https://api.perplexity.ai", api_format = "openai"),
  lmstudio = list(base_url = "http://localhost:1234/v1", api_format = "openai"),
  vllm     = list(base_url = "http://localhost:8000/v1", api_format = "openai"),
  openrouter = list(base_url = "https://openrouter.ai/api/v1", api_format = "openai")
)

#' Configure AIR — works with ANY model, ANY endpoint
#'
#' Bring your own model. AIR auto-detects API format from the URL or
#' provider name. Use a known preset (ollama, openai, groq, mistral, etc.)
#' or provide a custom base_url for any OpenAI-compatible endpoint.
#'
#' @param provider Display name or preset: "ollama","openai","claude","groq",
#'   "together","mistral","perplexity","lmstudio","vllm","deepseek","kimi","zai",
#'   "openrouter" — or any custom name.
#' @param model Any model name (e.g., "gpt-4o","llama3.2","claude-3-opus",
#'   "mixtral-8x7b","gemma2:9b","custom-model")
#' @param api_key API key (not needed for local models)
#' @param base_url Custom API endpoint (overrides preset). Any OpenAI-compatible
#'   v1/chat/completions URL will work.
#' @param api_format Force API format: "openai", "ollama", or "claude".
#'   Auto-detected if not specified.
#' @param system_prompt Custom system prompt
#' @param temperature Creativity (0-1). Lower = more deterministic.
#' @param max_tokens Maximum response tokens
#'
#' @return Invisibly returns the configuration list
#' @export
#'
#' @examples
#' \dontrun{
#' # Known presets
#' air_configure(provider = "ollama", model = "llama3.2")
#' air_configure(provider = "openai", model = "gpt-4o", api_key = "sk-...")
#' air_configure(provider = "groq", model = "mixtral-8x7b", api_key = "gsk-...")
#'
#' # Custom: any OpenAI-compatible endpoint
#' air_configure(provider = "my-custom", model = "my-model",
#'               base_url = "https://my-api.example.com/v1", api_key = "...")
#'
#' # Local: LM Studio, vLLM, Ollama
#' air_configure(provider = "lmstudio", model = "local-model")
#' air_configure(provider = "vllm", model = "mistral-7b")
#' }
air_configure <- function(provider = NULL, model = NULL, api_key = NULL,
                          base_url = NULL, api_format = NULL,
                          system_prompt = NULL, temperature = NULL,
                          max_tokens = NULL) {
  # Set provider (default: keep current)
  if (!is.null(provider)) {
    air_env$provider <- provider
    # Look up preset
    preset <- PROVIDER_PRESETS[[tolower(provider)]]
    if (!is.null(preset)) {
      if (is.null(base_url))    air_env$base_url   <- preset$base_url
      if (is.null(api_format))  air_env$api_format <- preset$api_format
    }
  }

  if (!is.null(model))        air_env$model        <- model
  if (!is.null(api_key))      air_env$api_key      <- api_key
  if (!is.null(system_prompt)) air_env$system_prompt <- system_prompt
  if (!is.null(temperature))  air_env$temperature  <- temperature
  if (!is.null(max_tokens))   air_env$max_tokens   <- max_tokens

  # Override base_url if provided
  if (!is.null(base_url)) {
    air_env$base_url <- base_url
  }

  # Auto-detect API format from URL if not set
  if (is.null(api_format) && !is.null(base_url)) {
    air_env$api_format <- air_detect_format(base_url)
  }
  if (!is.null(api_format)) {
    if (!api_format %in% c("openai", "ollama", "claude")) {
      stop("api_format must be 'openai', 'ollama', or 'claude'")
    }
    air_env$api_format <- api_format
  }

  # Set default model when switching providers
  if (is.null(model)) {
    p <- tolower(provider %||% air_env$provider)
    defaults <- c(openai = "gpt-4o", ollama = "llama3.2", claude = "claude-3-5-sonnet-20241022",
                  groq = "mixtral-8x7b-32768", together = "mistralai/Mixtral-8x7B-Instruct-v0.1",
                  mistral = "mistral-large-latest", perplexity = "sonar-pro",
                  deepseek = "deepseek-chat", kimi = "moonshot-v1-8k")
    if (p %in% names(defaults)) air_env$model <- defaults[[p]]
  }

  cli::cli_alert_success("AIR configured: {air_env$provider} / {air_env$model} [{air_env$api_format}]")
  invisible(as.list(air_env))
}

# Auto-detect API format from URL -------------------------------------------------
air_detect_format <- function(url) {
  if (grepl("localhost:11434|ollama", tolower(url))) return("ollama")
  if (grepl("anthropic", tolower(url))) return("claude")
  return("openai")  # default: OpenAI-compatible (covers most providers)
}

`%||%` <- function(a, b) if (is.null(a)) b else a

#' Send a message to the AI and get a response
#'
#' @param prompt The message to send
#' @param context Optional additional context (e.g., current R code)
#' @param stream Whether to stream the response (console-friendly)
#'
#' @return The AI's response as a character string
#' @export
air_send <- function(prompt, context = NULL, stream = FALSE) {
  if (missing(prompt) || is.null(prompt) || is.na(prompt) ||
      !is.character(prompt) || nchar(trimws(prompt)) == 0) {
    stop("prompt must be a non-empty character string")
  }
  if (!is.null(context)) {
    prompt <- paste0("Context:\n```r\n", context, "\n```\n\nUser: ", prompt)
  }

  messages <- list(
    list(role = "system", content = air_env$system_prompt),
    list(role = "user", content = prompt)
  )

  resp <- switch(air_env$api_format,
    openai = air_openai_compatible(messages, stream),
    ollama = air_ollama_native(messages, stream),
    claude = air_claude_native(messages, stream),
    stop("Unknown API format: ", air_env$api_format)
  )

  air_env$chat_history <- c(air_env$chat_history,
    list(list(role = "user", content = prompt)),
    list(list(role = "assistant", content = resp)))

  resp
}

# ── User-facing helpers (unchanged) ────────────────────────────────────────

#' @export
air_explain <- function(code) {
  if (missing(code) || is.null(code) || is.na(code) || !is.character(code) || nchar(trimws(code)) == 0) {
    stop("code must be a non-empty character string (an R expression or function name)")
  }
  if (exists(code, mode = "function")) code <- paste(deparse(get(code)), collapse = "\n")
  air_send(paste0("Explain this R code in simple terms:\n\n```r\n", code, "\n```"))
}

#' @export
air_debug <- function(error_msg = NULL) {
  if (is.null(error_msg)) {
    error_msg <- tryCatch(geterrmessage(), error = function(e) "")
    if (is.null(error_msg) || nchar(error_msg) == 0)
      stop("No error to debug. Provide error_msg or run air_debug() immediately after an error.")
  }
  trace <- tryCatch(paste(utils::capture.output(traceback()), collapse = "\n"), error = function(e) "")
  prompt <- paste0("I got this R error:\n\n", error_msg, "\n\n",
    if (nchar(trace) > 0) paste0("Traceback:\n", trace, "\n\n") else "",
    "Explain the root cause and suggest a fix.")
  air_send(prompt)
}

#' @export
air_document <- function(code, func_name = NULL) {
  if (missing(code) || is.null(code) || is.na(code) || !is.character(code) || nchar(trimws(code)) == 0) {
    stop("code must be a non-empty character string containing an R function")
  }
  air_send(paste0("Generate roxygen2 documentation for this R function:\n\n```r\n", code, "\n```\n\nOutput ONLY the roxygen block."))
}

#' @export
air_generate <- function(description, context = NULL) {
  if (missing(description) || is.null(description) || is.na(description) ||
      !is.character(description) || nchar(trimws(description)) == 0) {
    stop("description must be a non-empty character string")
  }
  air_send(paste0("Write R code for: ", description, ". Output ONLY the R code."), context = context)
}

#' @export
air_chat <- function() {
  cli::cli_h1("AIR Chat — {air_env$provider} / {air_env$model}")
  cli::cli_text("Type 'exit' or press ESC to end.")
  while (TRUE) {
    user_input <- readline(cli::col_blue("\nYou> "))
    if (tolower(trimws(user_input)) %in% c("exit", "quit", "q")) break
    if (nchar(trimws(user_input)) == 0) next
    cat("\n")
    response <- air_send(user_input)
    cli::cli_text(cli::col_green("AIR> "), response); cat("\n")
  }
  invisible(NULL)
}

#' @export
air_info <- function() {
  cli::cli_h2("AIR Configuration")
  cli::cli_li("Provider: {air_env$provider}")
  cli::cli_li("Model: {air_env$model}")
  cli::cli_li("API Format: {air_env$api_format}")
  cli::cli_li("Base URL: {air_env$base_url}")
  cli::cli_li("Temperature: {air_env$temperature}")
  cli::cli_li("Max tokens: {air_env$max_tokens}")
  cli::cli_li("History: {length(air_env$chat_history)} messages")
  cli::cli_text(""); cli::cli_text("Run {.fn air_check} to test connectivity.")
  invisible(NULL)
}
