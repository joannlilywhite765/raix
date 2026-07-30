# AIR Backend Implementations — OpenAI, Ollama, Claude, DeepSeek, Kimi, Z.Ai
#
# NOTE: On some Windows/R versions, connecting to a dead port causes a C-level
# segfault in libcurl — this is a known curl/R bug, not an AIR bug.
# Use air_check() to verify connectivity before calling air_send().

air_openai <- function(messages, stream = FALSE) {
  body <- list(
    model = air_env$model, messages = messages,
    temperature = air_env$temperature, max_tokens = air_env$max_tokens, stream = stream
  )
  air_api_call(
    paste0(air_env$base_url, "/chat/completions"),
    httr::add_headers(Authorization = paste("Bearer", air_env$api_key), `Content-Type` = "application/json"),
    body
  )
}

air_ollama <- function(messages, stream = FALSE) {
  body <- list(model = air_env$model, messages = messages, stream = stream,
               options = list(temperature = air_env$temperature))
  air_api_call(
    paste0(air_env$base_url, "/api/chat"),
    httr::add_headers(`Content-Type` = "application/json"),
    body, field = "message.content"
  )
}

air_claude <- function(messages, stream = FALSE) {
  system_msg <- NULL; user_msgs <- list()
  for (m in messages) {
    if (m$role == "system") system_msg <- m$content
    else user_msgs <- c(user_msgs, list(list(role = m$role, content = m$content)))
  }
  air_api_call(
    paste0(air_env$base_url, "/messages"),
    httr::add_headers(`x-api-key` = air_env$api_key, `anthropic-version` = "2023-06-01", `Content-Type` = "application/json"),
    list(model = air_env$model, max_tokens = air_env$max_tokens, messages = user_msgs, system = system_msg),
    field = "content.0.text"
  )
}

air_deepseek <- function(messages, stream = FALSE) {
  body <- list(model = air_env$model, messages = messages,
               temperature = air_env$temperature, max_tokens = air_env$max_tokens, stream = stream)
  air_api_call(paste0(air_env$base_url, "/chat/completions"),
    httr::add_headers(Authorization = paste("Bearer", air_env$api_key), `Content-Type` = "application/json"), body)
}

air_kimi <- function(messages, stream = FALSE) {
  body <- list(model = air_env$model, messages = messages, temperature = air_env$temperature)
  air_api_call(paste0(air_env$base_url, "/chat/completions"),
    httr::add_headers(Authorization = paste("Bearer", air_env$api_key), `Content-Type` = "application/json"), body)
}

air_zai <- function(messages, stream = FALSE) {
  body <- list(model = air_env$model, messages = messages,
               temperature = air_env$temperature, max_tokens = air_env$max_tokens)
  air_api_call(paste0(air_env$base_url, "/chat/completions"),
    httr::add_headers(Authorization = paste("Bearer", air_env$api_key), `Content-Type` = "application/json"), body)
}

# Core API call ----------------------------------------------------------------
air_api_call <- function(url, headers, body, field = "choices.0.message.content") {
  resp <- try(
    httr::POST(url, headers, body = jsonlite::toJSON(body, auto_unbox = TRUE), encode = "raw", httr::timeout(15)),
    silent = TRUE
  )
  if (inherits(resp, "try-error")) {
    cli::cli_abort(c(
      "AIR: cannot reach {air_env$backend}",
      "i" = "URL: {url}",
      "i" = "Local Ollama: `ollama serve` | Cloud: check internet + API key",
      "x" = "{trimws(as.character(resp))}"
    ))
  }
  if (httr::http_error(resp)) {
    content <- tryCatch(httr::content(resp, "text", encoding = "UTF-8"), error = function(e) "(unreadable)")
    cli::cli_abort(c("AIR: HTTP {httr::status_code(resp)} from {air_env$backend}", "x" = "{substr(content,1,300)}"))
  }
  parsed <- tryCatch(httr::content(resp, "parsed", encoding = "UTF-8"),
    error = function(e) cli::cli_abort("AIR: cannot parse {air_env$backend} response"))
  keys <- strsplit(field, "\\.")[[1]]; result <- parsed
  for (k in keys) {
    if (grepl("^\\d+$", k)) {
      idx <- as.integer(k) + 1
      if (!is.list(result) || idx > length(result)) cli::cli_abort("AIR: bad response from {air_env$backend}")
      result <- result[[idx]]
    } else {
      if (!is.list(result) || is.null(result[[k]])) cli::cli_abort("AIR: missing '{k}' in {air_env$backend} response")
      result <- result[[k]]
    }
  }
  if (is.null(result) || !is.character(result) || nchar(trimws(result)) == 0)
    cli::cli_abort("AIR: empty response from {air_env$backend}")
  trimws(result)
}

#' Check if the configured AI backend is reachable
#'
#' Tests connectivity to the configured backend. Safe to call —
#' handles connection refusal gracefully on all platforms.
#'
#' @return TRUE if reachable, FALSE otherwise (with a message)
#' @export
air_check <- function() {
  url <- paste0(air_env$base_url, if (air_env$backend == "ollama") "/api/tags" else "/models")
  headers <- if (air_env$backend == "ollama") {
    httr::add_headers(`Content-Type` = "application/json")
  } else if (air_env$backend == "claude") {
    httr::add_headers(`x-api-key` = air_env$api_key, `anthropic-version` = "2023-06-01")
  } else {
    httr::add_headers(Authorization = paste("Bearer", air_env$api_key))
  }
  resp <- try(httr::GET(url, headers, httr::timeout(5)), silent = TRUE)
  if (inherits(resp, "try-error")) {
    cli::cli_alert_danger("{air_env$backend} is NOT reachable at {air_env$base_url}")
    return(invisible(FALSE))
  }
  ok <- httr::status_code(resp) < 500
  if (ok) {
    cli::cli_alert_success("{air_env$backend} is reachable ({httr::status_code(resp)})")
  } else {
    cli::cli_alert_danger("{air_env$backend} returned {httr::status_code(resp)}")
  }
  invisible(ok)
}
