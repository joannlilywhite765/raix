# AIR Backend Implementations — OpenAI, Ollama, Claude, DeepSeek, Kimi, Z.Ai

air_openai <- function(messages, stream = FALSE) {
  body <- list(
    model = air_env$model,
    messages = messages,
    temperature = air_env$temperature,
    max_tokens = air_env$max_tokens,
    stream = stream
  )
  resp <- httr::POST(
    paste0(air_env$base_url, "/chat/completions"),
    httr::add_headers(
      Authorization = paste("Bearer", air_env$api_key),
      `Content-Type` = "application/json"
    ),
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    encode = "raw"
  )
  air_parse_response(resp)
}

air_ollama <- function(messages, stream = FALSE) {
  body <- list(
    model = air_env$model,
    messages = messages,
    stream = stream,
    options = list(temperature = air_env$temperature)
  )
  resp <- httr::POST(
    paste0(air_env$base_url, "/api/chat"),
    httr::add_headers(`Content-Type` = "application/json"),
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    encode = "raw"
  )
  air_parse_response(resp, field = "message.content")
}

air_claude <- function(messages, stream = FALSE) {
  # Extract system message if present
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
  resp <- httr::POST(
    paste0(air_env$base_url, "/messages"),
    httr::add_headers(
      `x-api-key` = air_env$api_key,
      `anthropic-version` = "2023-06-01",
      `Content-Type` = "application/json"
    ),
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    encode = "raw"
  )
  air_parse_response(resp, field = "content.0.text")
}

air_deepseek <- function(messages, stream = FALSE) {
  body <- list(
    model = air_env$model,
    messages = messages,
    temperature = air_env$temperature,
    max_tokens = air_env$max_tokens,
    stream = stream
  )
  resp <- httr::POST(
    paste0(air_env$base_url, "/chat/completions"),
    httr::add_headers(
      Authorization = paste("Bearer", air_env$api_key),
      `Content-Type` = "application/json"
    ),
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    encode = "raw"
  )
  air_parse_response(resp)
}

air_kimi <- function(messages, stream = FALSE) {
  body <- list(
    model = air_env$model,
    messages = messages,
    temperature = air_env$temperature
  )
  resp <- httr::POST(
    paste0(air_env$base_url, "/chat/completions"),
    httr::add_headers(
      Authorization = paste("Bearer", air_env$api_key),
      `Content-Type` = "application/json"
    ),
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    encode = "raw"
  )
  air_parse_response(resp)
}

air_zai <- function(messages, stream = FALSE) {
  body <- list(
    model = air_env$model,
    messages = messages,
    temperature = air_env$temperature,
    max_tokens = air_env$max_tokens
  )
  resp <- httr::POST(
    paste0(air_env$base_url, "/chat/completions"),
    httr::add_headers(
      Authorization = paste("Bearer", air_env$api_key),
      `Content-Type` = "application/json"
    ),
    body = jsonlite::toJSON(body, auto_unbox = TRUE),
    encode = "raw"
  )
  air_parse_response(resp)
}

# Parse HTTP response ---------------------------------------------------------
air_parse_response <- function(resp, field = "choices.0.message.content") {
  if (httr::http_error(resp)) {
    content <- httr::content(resp, "text", encoding = "UTF-8")
    cli::cli_abort(c(
      "AIR API request failed [{httr::status_code(resp)}]",
      "i" = "Backend: {air_env$backend}",
      "x" = "{substr(content, 1, 300)}"
    ))
  }

  parsed <- httr::content(resp, "parsed", encoding = "UTF-8")

  # Navigate the field path (e.g., "choices.0.message.content")
  keys <- strsplit(field, "\\.")[[1]]
  result <- parsed
  for (k in keys) {
    if (grepl("^\\d+$", k)) {
      result <- result[[as.integer(k) + 1]]
    } else {
      result <- result[[k]]
    }
  }

  if (is.null(result)) {
    cli::cli_abort("Could not extract response from {air_env$backend} API")
  }

  trimws(result)
}
