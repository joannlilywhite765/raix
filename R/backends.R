# AIR Backend Handlers — 3 API formats cover ALL providers
#
# air_openai_compatible() — GPT-4o, Groq, Together, Mistral, DeepSeek, Kimi,
#   Z.Ai, Perplexity, LM Studio, vLLM, OpenRouter, any custom endpoint
# air_ollama_native()     — Ollama local API format
# air_claude_native()     — Anthropic Claude Messages API

# ── OpenAI-compatible (covers 90% of all providers) ─────────────────────────
air_openai_compatible <- function(messages, stream = FALSE) {
  body <- list(model = air_env$model, messages = messages,
               temperature = air_env$temperature, max_tokens = air_env$max_tokens, stream = stream)
  headers <- httr::add_headers(`Content-Type` = "application/json")
  if (!is.null(air_env$api_key) && nchar(air_env$api_key) > 0) {
    headers <- httr::add_headers(
      Authorization = paste("Bearer", air_env$api_key),
      `Content-Type` = "application/json"
    )
  }
  air_api_call(paste0(air_env$base_url, "/chat/completions"), headers, body)
}

# ── Ollama native API ───────────────────────────────────────────────────────
air_ollama_native <- function(messages, stream = FALSE) {
  body <- list(model = air_env$model, messages = messages, stream = stream,
               options = list(temperature = air_env$temperature))
  air_api_call(paste0(air_env$base_url, "/api/chat"),
    httr::add_headers(`Content-Type` = "application/json"), body,
    field = "message.content")
}

# ── Claude native API ───────────────────────────────────────────────────────
air_claude_native <- function(messages, stream = FALSE) {
  system_msg <- NULL; user_msgs <- list()
  for (m in messages) {
    if (m$role == "system") system_msg <- m$content
    else user_msgs <- c(user_msgs, list(list(role = m$role, content = m$content)))
  }
  air_api_call(paste0(air_env$base_url, "/messages"),
    httr::add_headers(`x-api-key` = air_env$api_key, `anthropic-version` = "2023-06-01", `Content-Type` = "application/json"),
    list(model = air_env$model, max_tokens = air_env$max_tokens, messages = user_msgs, system = system_msg),
    field = "content.0.text")
}

# ── Core API call ───────────────────────────────────────────────────────────
air_api_call <- function(url, headers, body, field = "choices.0.message.content") {
  resp <- try(httr::POST(url, headers, body = jsonlite::toJSON(body, auto_unbox = TRUE),
    encode = "raw", httr::timeout(30)), silent = TRUE)
  if (inherits(resp, "try-error")) {
    cli::cli_abort(c("AIR: cannot reach {air_env$provider}",
      "i" = "URL: {url}", "x" = "{trimws(as.character(resp))}"))
  }
  if (httr::http_error(resp)) {
    content <- tryCatch(httr::content(resp, "text", encoding = "UTF-8"), error = function(e) "(unreadable)")
    cli::cli_abort(c("AIR: HTTP {httr::status_code(resp)} from {air_env$provider}",
      "x" = "{substr(content,1,300)}"))
  }
  parsed <- tryCatch(httr::content(resp, "parsed", encoding = "UTF-8"),
    error = function(e) cli::cli_abort("AIR: cannot parse response"))
  keys <- strsplit(field, "\\.")[[1]]; result <- parsed
  for (k in keys) {
    if (grepl("^\\d+$", k)) {
      idx <- as.integer(k) + 1
      if (!is.list(result) || idx > length(result)) cli::cli_abort("AIR: bad response structure")
      result <- result[[idx]]
    } else {
      if (!is.list(result) || is.null(result[[k]])) cli::cli_abort("AIR: missing '{k}' in response")
      result <- result[[k]]
    }
  }
  if (is.null(result) || !is.character(result) || nchar(trimws(result)) == 0)
    cli::cli_abort("AIR: empty response")
  trimws(result)
}

#' Check if the configured AI backend is reachable
#' @export
air_check <- function() {
  url <- if (air_env$api_format == "ollama") paste0(air_env$base_url, "/api/tags")
         else if (air_env$api_format == "claude") paste0(air_env$base_url, "/models")
         else paste0(air_env$base_url, "/models")
  headers <- if (air_env$api_format == "ollama") httr::add_headers(`Content-Type` = "application/json")
    else if (air_env$api_format == "claude") httr::add_headers(`x-api-key` = air_env$api_key %||% "", `anthropic-version` = "2023-06-01")
    else if (!is.null(air_env$api_key) && nchar(air_env$api_key) > 0)
      httr::add_headers(Authorization = paste("Bearer", air_env$api_key))
    else httr::add_headers()
  resp <- try(httr::GET(url, headers, httr::timeout(5)), silent = TRUE)
  if (inherits(resp, "try-error")) {
    cli::cli_alert_danger("{air_env$provider} NOT reachable at {air_env$base_url}")
    return(invisible(FALSE))
  }
  ok <- httr::status_code(resp) < 500
  if (ok) cli::cli_alert_success("{air_env$provider} reachable ({httr::status_code(resp)})")
  else cli::cli_alert_danger("{air_env$provider} returned {httr::status_code(resp)}")
  invisible(ok)
}

`%||%` <- function(a, b) if (is.null(a)) b else a
