# AIR Backend Implementations — OpenAI, Ollama, Claude, DeepSeek, Kimi, Z.Ai
# All backends handle connection failures gracefully via tryCatch.

air_openai <- function(messages, stream = FALSE) {
  body <- list(
    model = air_env$model,
    messages = messages,
    temperature = air_env$temperature,
    max_tokens = air_env$max_tokens,
    stream = stream
  )
  air_api_call(
    paste0(air_env$base_url, "/chat/completions"),
    httr::add_headers(
      Authorization = paste("Bearer", air_env$api_key),
      `Content-Type` = "application/json"
    ),
    body
  )
}

air_ollama <- function(messages, stream = FALSE) {
  body <- list(
    model = air_env$model,
    messages = messages,
    stream = stream,
    options = list(temperature = air_env$temperature)
  )
  air_api_call(
    paste0(air_env$base_url, "/api/chat"),
    httr::add_headers(`Content-Type` = "application/json"),
    body,
    field = "message.content"
  )
}

air_claude <- function(messages, stream = FALSE) {
  system_msg <- NULL
  user_msgs <- list()
  for (m in messages) {
    if (m$role == "system") system_msg <- m$content
    else user_msgs <- c(user_msgs, list(list(role = m$role, content = m$content)))
  }
  body <- list(
    model = air_env$model,
    max_tokens = air_env$max_tokens,
    messages = user_msgs,
    system = system_msg
  )
  air_api_call(
    paste0(air_env$base_url, "/messages"),
    httr::add_headers(
      `x-api-key` = air_env$api_key,
      `anthropic-version` = "2023-06-01",
      `Content-Type` = "application/json"
    ),
    body,
    field = "content.0.text"
  )
}

air_deepseek <- function(messages, stream = FALSE) {
  body <- list(
    model = air_env$model,
    messages = messages,
    temperature = air_env$temperature,
    max_tokens = air_env$max_tokens,
    stream = stream
  )
  air_api_call(
    paste0(air_env$base_url, "/chat/completions"),
    httr::add_headers(
      Authorization = paste("Bearer", air_env$api_key),
      `Content-Type` = "application/json"
    ),
    body
  )
}

air_kimi <- function(messages, stream = FALSE) {
  body <- list(
    model = air_env$model,
    messages = messages,
    temperature = air_env$temperature
  )
  air_api_call(
    paste0(air_env$base_url, "/chat/completions"),
    httr::add_headers(
      Authorization = paste("Bearer", air_env$api_key),
      `Content-Type` = "application/json"
    ),
    body
  )
}

air_zai <- function(messages, stream = FALSE) {
  body <- list(
    model = air_env$model,
    messages = messages,
    temperature = air_env$temperature,
    max_tokens = air_env$max_tokens
  )
  air_api_call(
    paste0(air_env$base_url, "/chat/completions"),
    httr::add_headers(
      Authorization = paste("Bearer", air_env$api_key),
      `Content-Type` = "application/json"
    ),
    body
  )
}

# Core API call with connection error handling ---------------------------------
air_api_call <- function(url, headers, body, field = "choices.0.message.content") {
  resp <- tryCatch(
    httr::POST(
      url,
      headers,
      body = jsonlite::toJSON(body, auto_unbox = TRUE),
      encode = "raw",
      httr::timeout(30)
    ),
    error = function(e) {
      cli::cli_abort(c(
        "AIR API request failed — cannot connect to {air_env$backend}",
        "i" = "URL: {url}",
        "i" = "Is the server running? For Ollama: `ollama serve`",
        "x" = "{conditionMessage(e)}"
      ))
    }
  )

  if (httr::http_error(resp)) {
    content <- httr::content(resp, "text", encoding = "UTF-8")
    cli::cli_abort(c(
      "AIR API request failed [{httr::status_code(resp)}]",
      "i" = "Backend: {air_env$backend}",
      "x" = "{substr(content, 1, 300)}"
    ))
  }

  parsed <- tryCatch(
    httr::content(resp, "parsed", encoding = "UTF-8"),
    error = function(e) {
      cli::cli_abort(c(
        "AIR failed to parse {air_env$backend} response",
        "x" = "{conditionMessage(e)}"
      ))
    }
  )

  # Navigate the field path (e.g., "choices.0.message.content")
  keys <- strsplit(field, "\\.")[[1]]
  result <- parsed
  for (k in keys) {
    if (grepl("^\\d+$", k)) {
      idx <- as.integer(k) + 1
      if (idx > length(result)) {
        cli::cli_abort("AIR: unexpected response structure from {air_env$backend}")
      }
      result <- result[[idx]]
    } else {
      if (!is.list(result) || is.null(result[[k]])) {
        cli::cli_abort("AIR: field '{k}' not found in {air_env$backend} response")
      }
      result <- result[[k]]
    }
  }

  if (is.null(result) || !is.character(result)) {
    cli::cli_abort("AIR: could not extract text response from {air_env$backend}")
  }

  trimws(result)
}
