# raix Backend Handlers --- 3 API formats cover ALL providers
#
# raix_openai_compatible() --- GPT-4o, Groq, Together, Mistral, DeepSeek, Kimi,
#   Z.Ai, Perplexity, LM Studio, vLLM, OpenRouter, any custom endpoint
# raix_ollama_native()     --- Ollama local API format
# raix_claude_native()     --- Anthropic Claude Messages API

# ── OpenAI-compatible (covers 90% of all providers) ─────────────────────────
raix_openai_compatible <- function(messages, stream = FALSE) {
  body <- list(model = raix_env$model, messages = messages,
               temperature = raix_env$temperature, max_tokens = raix_env$max_tokens, stream = stream)
  headers <- httr::add_headers(`Content-Type` = "application/json")
  if (!is.null(raix_env$api_key) && nchar(raix_env$api_key) > 0) {
    headers <- httr::add_headers(
      Authorization = paste("Bearer", raix_env$api_key),
      `Content-Type` = "application/json"
    )
  }
  raix_api_call(paste0(raix_env$base_url, "/chat/completions"), headers, body)
}

# ── Ollama native API ───────────────────────────────────────────────────────
raix_ollama_native <- function(messages, stream = FALSE) {
  body <- list(model = raix_env$model, messages = messages, stream = stream,
               options = list(temperature = raix_env$temperature))
  raix_api_call(paste0(raix_env$base_url, "/api/chat"),
    httr::add_headers(`Content-Type` = "application/json"), body,
    field = "message.content")
}

# ── Claude native API ───────────────────────────────────────────────────────
raix_claude_native <- function(messages, stream = FALSE) {
  system_msg <- NULL; user_msgs <- list()
  for (m in messages) {
    if (m$role == "system") system_msg <- m$content
    else user_msgs <- c(user_msgs, list(list(role = m$role, content = m$content)))
  }
  raix_api_call(paste0(raix_env$base_url, "/messages"),
    httr::add_headers(`x-api-key` = raix_env$api_key, `anthropic-version` = "2023-06-01", `Content-Type` = "application/json"),
    list(model = raix_env$model, max_tokens = raix_env$max_tokens, messages = user_msgs, system = system_msg),
    field = "content.0.text")
}

# ── Core API call with smart retry ──────────────────────────────────────────

# Maximum seconds to wait for model loading (first inference on cold model)
RAIX_FIRST_LOAD_TIMEOUT <- 180  
# Normal timeout for subsequent calls
RAIX_NORMAL_TIMEOUT <- 120

raix_api_call <- function(url, headers, body, field = "choices.0.message.content", 
                          retry_on_timeout = TRUE) {
  timeout <- if (raix_env$first_call) RAIX_FIRST_LOAD_TIMEOUT else RAIX_NORMAL_TIMEOUT
  
  resp <- try(httr::POST(url, headers, body = jsonlite::toJSON(body, auto_unbox = TRUE),
    encode = "raw", httr::timeout(timeout)), silent = TRUE)
  
  # Smart retry for timeout (model cold-start loading)
  if (inherits(resp, "try-error") && retry_on_timeout && 
      grepl("[Tt]imeout|timed out", as.character(resp))) {
    if (raix_env$first_call) {
      cli::cli_alert_info("Model is loading into memory (first call)... waiting up to {RAIX_FIRST_LOAD_TIMEOUT}s...")
    }
    # Retry once with longer timeout
    resp <- try(httr::POST(url, headers, body = jsonlite::toJSON(body, auto_unbox = TRUE),
      encode = "raw", httr::timeout(RAIX_FIRST_LOAD_TIMEOUT)), silent = TRUE)
    raix_env$first_call <- FALSE
  }
  
  if (inherits(resp, "try-error")) {
    msg <- trimws(as.character(resp))
    if (grepl("[Tt]imeout|timed out", msg)) {
      cli::cli_abort(c("raix: {raix_env$provider} model '{raix_env$model}' took too long to respond",
        "i" = "Large models need 30-90s for first load into RAM",
        "i" = "Try again — subsequent calls will be faster",
        "i" = "Or use a smaller model: raix_configure(model = 'phi3.5')"))
    } else if (grepl("[Rr]efused|refused", msg)) {
      cli::cli_abort(c("raix: {raix_env$provider} is not running at {raix_env$base_url}",
        "i" = "Start Ollama: open terminal and run 'ollama serve'",
        "i" = "Or switch provider: raix_setup()"))
    } else {
      cli::cli_abort(c("raix: cannot reach {raix_env$provider}",
        "i" = "URL: {url}", "x" = "{msg}"))
    }
  }
  
  if (httr::http_error(resp)) {
    content <- tryCatch(httr::content(resp, "text", encoding = "UTF-8"), error = function(e) "(unreadable)")
    code <- httr::status_code(resp)
    if (code == 404) {
      cli::cli_abort(c("raix: model '{raix_env$model}' not found on {raix_env$provider}",
        "i" = "List models: run 'ollama list' in terminal",
        "i" = "Pull model: run 'ollama pull {raix_env$model}'",
        "i" = "Check available models: raix_setup() to auto-detect"))
    } else {
      cli::cli_abort(c("raix: HTTP {code} from {raix_env$provider}",
        "x" = "{substr(content,1,300)}"))
    }
  }
  
  # Mark first call as done
  raix_env$first_call <- FALSE
  
  parsed <- tryCatch(httr::content(resp, "parsed", encoding = "UTF-8"),
    error = function(e) cli::cli_abort("raix: cannot parse response"))
  keys <- strsplit(field, "\\.")[[1]]; result <- parsed
  for (k in keys) {
    if (grepl("^\\d+$", k)) {
      idx <- as.integer(k) + 1
      if (!is.list(result) || idx > length(result)) cli::cli_abort("raix: bad response structure")
      result <- result[[idx]]
    } else {
      if (!is.list(result) || is.null(result[[k]])) cli::cli_abort("raix: missing '{k}' in response")
      result <- result[[k]]
    }
  }
  if (is.null(result) || !is.character(result) || nchar(trimws(result)) == 0)
    cli::cli_abort("raix: empty response")
  trimws(result)
}

#' Check if the configured AI backend is reachable
#' @export
raix_check <- function() {
  url <- if (raix_env$api_format == "ollama") paste0(raix_env$base_url, "/api/tags")
         else if (raix_env$api_format == "claude") paste0(raix_env$base_url, "/models")
         else paste0(raix_env$base_url, "/models")
  headers <- if (raix_env$api_format == "ollama") httr::add_headers(`Content-Type` = "application/json")
    else if (raix_env$api_format == "claude") httr::add_headers(`x-api-key` = raix_env$api_key %||% "", `anthropic-version` = "2023-06-01")
    else if (!is.null(raix_env$api_key) && nchar(raix_env$api_key) > 0)
      httr::add_headers(Authorization = paste("Bearer", raix_env$api_key))
    else httr::add_headers()
  resp <- try(httr::GET(url, headers, httr::timeout(5)), silent = TRUE)
  if (inherits(resp, "try-error")) {
    cli::cli_alert_danger("{raix_env$provider} NOT reachable at {raix_env$base_url}")
    return(invisible(FALSE))
  }
  ok <- httr::status_code(resp) < 500
  if (ok) cli::cli_alert_success("{raix_env$provider} reachable ({httr::status_code(resp)})")
  else cli::cli_alert_danger("{raix_env$provider} returned {httr::status_code(resp)}")
  invisible(ok)
}

# `%||%` is defined in raix.R --- see top of that file
