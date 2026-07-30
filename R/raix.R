# raix --- R + AI + eXperiment: Core API Client
#
# Model-agnostic: works with ANY OpenAI-compatible, Ollama, or Claude API.
# No hardcoded provider list --- bring your own model, your own endpoint.

#' @keywords internal
"_PACKAGE"

# Startup message on library(raix)
.onAttach <- function(libname, pkgname) {
  configured <- !is.null(raix_env$api_key) || 
    (raix_env$provider == "ollama" && raix_env$base_url == "http://localhost:11434")
  
  if (!configured || length(raix_env$chat_history) == 0) {
    packageStartupMessage(
      "raix = R + AI + eXperiment\n",
      "Run raix_setup() to configure in under 2 minutes.",
      if (!configured) " Or raix_gui() to open the chat window." else ""
    )
  }
}

# Global state ---------------------------------------------------------------
raix_env <- new.env(parent = emptyenv())
raix_env$provider   <- "ollama"       # Display name (any string)
raix_env$model      <- "llama3.2"     # Any model name
raix_env$api_key    <- NULL
raix_env$base_url   <- "http://localhost:11434"
raix_env$api_format <- "ollama"       # "openai", "ollama", or "claude"
raix_env$small_model <- FALSE         # Auto-detected, can be overridden
raix_env$system_prompt <- paste0(
  "You are raix, an AI coding assistant for R. ",
  "You help users write, explain, debug, and document R code. ",
  "Always respond with valid R code when asked to generate code. ",
  "Keep explanations concise and R-focused."
)
raix_env$temperature  <- 0.2
raix_env$max_tokens   <- 2048
raix_env$chat_history <- list()

# Small-model optimized system prompt
SMALL_SYSTEM_PROMPT <- paste0(
  "You are an R coding assistant. Reply with ONLY what is asked. ",
  "For code: output ONLY the R code, no explanation. ",
  "For explanations: 2-3 bullet points max. ",
  "For debugging: state the cause in 1 line, then the fix. ",
  "Be direct. Be brief. Use base R when possible."
)

# Detect if a model is "small" (< ~10B params) based on naming patterns
raix_detect_model_size <- function(model_name) {
  if (is.null(model_name) || nchar(model_name) == 0) return(FALSE)
  m <- tolower(model_name)
  # Known small model patterns
  small_patterns <- c(
    "7b", "8b", "9b", "3b", "1b", "3.8b",
    "phi", "llama3.2", "llama3.1:8b",
    "gemma2:2b", "gemma2:9b",
    "qwen2.5:7b", "qwen2.5:3b", "qwen2:7b", "qwen2:1.5b",
    "mistral:7b", "mistral-nemo",
    "codellama:7b", "deepseek-coder:1.3b", "deepseek-coder:6.7b",
    "tinyllama", "smollm", "orca-mini", "dolphin-mistral",
    "nomic-embed-text"  # embedding model, not for chat
  )
  any(sapply(small_patterns, function(p) grepl(p, m, fixed = TRUE)))
}

# Apply small-model optimizations
raix_optimize_for_model <- function(model_name) {
  is_small <- raix_detect_model_size(model_name)
  raix_env$small_model <- is_small
  if (is_small) {
    raix_env$system_prompt <- SMALL_SYSTEM_PROMPT
    if (raix_env$temperature < 0.3) raix_env$temperature <- 0.3
    raix_env$max_tokens <- min(raix_env$max_tokens, 1024)
  } else {
    raix_env$system_prompt <- paste0(
      "You are raix, an AI coding assistant for R. ",
      "You help users write, explain, debug, and document R code. ",
      "Always respond with valid R code when asked to generate code. ",
      "Keep explanations concise and R-focused."
    )
  }
  invisible(is_small)
}

#' Toggle small-model optimization mode
#'
#' Forces small-model optimized prompts on/off. Auto-detected by default
#' based on model name (7B, 9B, phi, etc.). Small mode uses shorter, more
#' directive prompts that work better with local models.
#'
#' @param enable TRUE to force small-model mode, FALSE for standard, NULL to auto-detect
#' @return Invisibly returns TRUE if small mode is active
#' @export
raix_small_mode <- function(enable = NULL) {
  if (!is.null(enable)) {
    raix_env$small_model <- isTRUE(enable)
    if (raix_env$small_model) {
      raix_env$system_prompt <- SMALL_SYSTEM_PROMPT
      if (raix_env$temperature < 0.3) raix_env$temperature <- 0.3
      cli::cli_alert_info("Small-model mode ON --- optimized prompts for local models")
    } else {
      raix_env$system_prompt <- paste0(
        "You are raix, an AI coding assistant for R. ",
        "You help users write, explain, debug, and document R code. ",
        "Always respond with valid R code when asked to generate code. ",
        "Keep explanations concise and R-focused."
      )
      cli::cli_alert_info("Small-model mode OFF --- standard prompts")
    }
  }
  invisible(raix_env$small_model)
}

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

#' Configure raix --- works with ANY model, ANY endpoint
#'
#' Bring your own model. raix auto-detects API format from the URL or
#' provider name. Use a known preset (ollama, openai, groq, mistral, etc.)
#' or provide a custom base_url for any OpenAI-compatible endpoint.
#'
#' @param provider Display name or preset: "ollama","openai","claude","groq",
#'   "together","mistral","perplexity","lmstudio","vllm","deepseek","kimi","zai",
#'   "openrouter" --- or any custom name.
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
#' raix_configure(provider = "ollama", model = "llama3.2")
#' raix_configure(provider = "openai", model = "gpt-4o", api_key = "sk-...")
#' raix_configure(provider = "groq", model = "mixtral-8x7b", api_key = "gsk-...")
#'
#' # Custom: any OpenAI-compatible endpoint
#' raix_configure(provider = "my-custom", model = "my-model",
#'               base_url = "https://my-api.example.com/v1", api_key = "...")
#'
#' # Local: LM Studio, vLLM, Ollama
#' raix_configure(provider = "lmstudio", model = "local-model")
#' raix_configure(provider = "vllm", model = "mistral-7b")
#' }
raix_configure <- function(provider = NULL, model = NULL, api_key = NULL,
                          base_url = NULL, api_format = NULL,
                          system_prompt = NULL, temperature = NULL,
                          max_tokens = NULL) {
  # Set provider (default: keep current)
  if (!is.null(provider)) {
    raix_env$provider <- provider
    # Look up preset
    preset <- PROVIDER_PRESETS[[tolower(provider)]]
    if (!is.null(preset)) {
      if (is.null(base_url))    raix_env$base_url   <- preset$base_url
      if (is.null(api_format))  raix_env$api_format <- preset$api_format
    }
  }

  if (!is.null(model))        raix_env$model        <- model
  if (!is.null(api_key))      raix_env$api_key      <- api_key
  if (!is.null(system_prompt)) raix_env$system_prompt <- system_prompt
  if (!is.null(temperature))  raix_env$temperature  <- temperature
  if (!is.null(max_tokens))   raix_env$max_tokens   <- max_tokens

  # Override base_url if provided
  if (!is.null(base_url)) {
    raix_env$base_url <- base_url
  }

  # Auto-detect API format from URL if not set
  if (is.null(api_format) && !is.null(base_url)) {
    raix_env$api_format <- raix_detect_format(base_url)
  }
  if (!is.null(api_format)) {
    if (!api_format %in% c("openai", "ollama", "claude")) {
      stop("api_format must be 'openai', 'ollama', or 'claude'")
    }
    raix_env$api_format <- api_format
  }

  # Set default model when switching providers
  if (is.null(model)) {
    p <- tolower(provider %||% raix_env$provider)
    defaults <- c(openai = "gpt-4o", ollama = "llama3.2", claude = "claude-3-5-sonnet-20241022",
                  groq = "mixtral-8x7b-32768", together = "mistralai/Mixtral-8x7B-Instruct-v0.1",
                  mistral = "mistral-large-latest", perplexity = "sonar-pro",
                  deepseek = "deepseek-chat", kimi = "moonshot-v1-8k")
	  if (p %in% names(defaults)) raix_env$model <- defaults[[p]]
	  }
	
	  # Auto-detect and optimize for small models
	  is_small <- raix_optimize_for_model(raix_env$model)
	
	  cli::cli_alert_success("raix configured: {raix_env$provider} / {raix_env$model} [{raix_env$api_format}]{if(is_small) ' [small-model optimized]' else ''}")
  invisible(as.list(raix_env))
}

# Auto-detect API format from URL -------------------------------------------------
raix_detect_format <- function(url) {
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
raix_send <- function(prompt, context = NULL, stream = FALSE) {
  if (missing(prompt) || is.null(prompt) || is.na(prompt) ||
      !is.character(prompt) || nchar(trimws(prompt)) == 0) {
    stop("prompt must be a non-empty character string")
  }
  if (!is.null(context)) {
    prompt <- paste0("Context:\n```r\n", context, "\n```\n\nUser: ", prompt)
  }

  messages <- list(
    list(role = "system", content = raix_env$system_prompt),
    list(role = "user", content = prompt)
  )

  resp <- switch(raix_env$api_format,
    openai = raix_openai_compatible(messages, stream),
    ollama = raix_ollama_native(messages, stream),
    claude = raix_claude_native(messages, stream),
    stop("Unknown API format: ", raix_env$api_format)
  )

  raix_env$chat_history <- c(raix_env$chat_history,
    list(list(role = "user", content = prompt)),
    list(list(role = "assistant", content = resp)))

  resp
}

# ── User-facing helpers ──────────────────────────────────────────────────────

#' @export
raix_explain <- function(code) {
  if (missing(code) || is.null(code) || is.na(code) || !is.character(code) || nchar(trimws(code)) == 0) {
    stop("code must be a non-empty character string (an R expression or function name)")
  }
  if (exists(code, mode = "function")) code <- paste(deparse(get(code)), collapse = "\n")
  if (raix_env$small_model) {
    prompt <- paste0("Explain this R code in 2-3 bullet points:\n\n", code)
  } else {
    prompt <- paste0("Explain this R code in simple terms:\n\n```r\n", code, "\n```")
  }
  raix_send(prompt)
}

#' @export
raix_debug <- function(error_msg = NULL) {
  if (is.null(error_msg)) {
    error_msg <- tryCatch(geterrmessage(), error = function(e) "")
    if (is.null(error_msg) || nchar(error_msg) == 0)
      stop("No error to debug. Provide error_msg or run raix_debug() immediately after an error.")
  }
  if (raix_env$small_model) {
    prompt <- paste0("R error: ", error_msg, "\nCause (1 line):\nFix (R code):")
  } else {
    trace <- tryCatch(paste(utils::capture.output(traceback()), collapse = "\n"), error = function(e) "")
    prompt <- paste0("I got this R error:\n\n", error_msg, "\n\n",
      if (nchar(trace) > 0) paste0("Traceback:\n", trace, "\n\n") else "",
      "Explain the root cause and suggest a fix.")
  }
  raix_send(prompt)
}

#' @export
raix_document <- function(code, func_name = NULL) {
  if (missing(code) || is.null(code) || is.na(code) || !is.character(code) || nchar(trimws(code)) == 0) {
    stop("code must be a non-empty character string containing an R function")
  }
  if (raix_env$small_model) {
    prompt <- paste0("Generate roxygen2 docs for this function. Output ONLY the comment block:\n\n", code)
  } else {
    prompt <- paste0("Generate roxygen2 documentation for this R function:\n\n```r\n", code, "\n```\n\nOutput ONLY the roxygen block.")
  }
  raix_send(prompt)
}

#' @export
raix_generate <- function(description, context = NULL) {
  if (missing(description) || is.null(description) || is.na(description) ||
      !is.character(description) || nchar(trimws(description)) == 0) {
    stop("description must be a non-empty character string")
  }
  if (raix_env$small_model) {
    prompt <- paste0("Write R code. Output code only, no explanation.\nTask: ", description)
  } else {
    prompt <- paste0("Write R code for: ", description, ". Output ONLY the R code.")
  }
  raix_send(prompt, context = context)
}

#' @export
raix_chat <- function() {
  cli::cli_h1("raix Chat --- {raix_env$provider} / {raix_env$model}")
  cli::cli_text("Type 'exit' or press ESC to end.")
  while (TRUE) {
    user_input <- readline(cli::col_blue("\nYou> "))
    if (tolower(trimws(user_input)) %in% c("exit", "quit", "q")) break
    if (nchar(trimws(user_input)) == 0) next
    cat("\n")
    response <- raix_send(user_input)
    cli::cli_text(cli::col_green("raix> "), response); cat("\n")
  }
  invisible(NULL)
}

#' @export
raix_info <- function() {
  cli::cli_h2("raix Configuration")
  cli::cli_li("Provider: {raix_env$provider}")
  cli::cli_li("Model: {raix_env$model}")
  cli::cli_li("API Format: {raix_env$api_format}")
  cli::cli_li("Base URL: {raix_env$base_url}")
  cli::cli_li("Temperature: {raix_env$temperature}")
  cli::cli_li("Max tokens: {raix_env$max_tokens}")
  cli::cli_li("History: {length(raix_env$chat_history)} messages")
  cli::cli_text(""); cli::cli_text("Run {.fn raix_check} to test connectivity.")
  invisible(NULL)
}
