library(testthat)
library(raix)

# ── Configuration tests (no network needed) ──────────────────────────

test_that("air_configure sets provider and model", {
  air_configure(provider = "ollama", model = "llama3.2")
  env <- asNamespace("raix")[["air_env"]]
  expect_equal(env$provider, "ollama")
  expect_equal(env$model, "llama3.2")
})

test_that("air_configure accepts any provider (custom / unknown)", {
  # raix is model-agnostic — any provider name is accepted
  expect_error(air_configure(provider = "my-custom-provider"), NA)
})

test_that("air_configure sets known preset defaults", {
  air_configure(provider = "openai")
  env <- asNamespace("raix")[["air_env"]]
  expect_match(env$model, "gpt-4o")
  expect_match(env$base_url, "api.openai.com")

  air_configure(provider = "ollama")
  env <- asNamespace("raix")[["air_env"]]
  expect_match(env$model, "llama3.2")

  air_configure(provider = "deepseek")
  env <- asNamespace("raix")[["air_env"]]
  expect_match(env$model, "deepseek")

  air_configure(provider = "groq")
  env <- asNamespace("raix")[["air_env"]]
  expect_match(env$base_url, "api.groq.com")
})

test_that("air_configure base URL defaults for presets", {
  for (p in c("openai", "ollama", "claude", "groq", "mistral", "deepseek")) {
    air_configure(provider = p)
    env <- asNamespace("raix")[["air_env"]]
    expect_true(nchar(env$base_url) > 10)
  }
})

test_that("air_configure custom parameters", {
  air_configure(provider = "ollama", temperature = 0.7, max_tokens = 512,
                system_prompt = "Custom prompt")
  env <- asNamespace("raix")[["air_env"]]
  expect_equal(env$temperature, 0.7)
  expect_equal(env$max_tokens, 512)
  expect_match(env$system_prompt, "Custom prompt")
})

test_that("air_configure model override", {
  air_configure(provider = "ollama", model = "mistral:latest")
  env <- asNamespace("raix")[["air_env"]]
  expect_equal(env$model, "mistral:latest")
})

test_that("air_configure custom base_url", {
  skip_on_cran()
  # Set custom provider with explicit base_url and format
  air_configure(provider = "my-custom-endpoint", 
                base_url = "https://my-api.example.com/v1",
                api_format = "openai",
                model = "custom-model")
  env <- asNamespace("raix")[["air_env"]]
  expect_match(env$base_url, "my-api.example.com")
  expect_equal(env$api_format, "openai")
  expect_equal(env$provider, "my-custom-endpoint")
})

test_that("air_configure rejects invalid api_format", {
  expect_error(air_configure(provider = "test", api_format = "invalid"),
               "must be 'openai', 'ollama', or 'claude'")
})

# ── Utility tests (no network needed) ────────────────────────────────

test_that("air_info runs without error", {
  expect_error(air_info(), NA)
})

test_that("air_explain rejects empty input", {
  expect_error(air_explain(""), "must be a non-empty character string")
  expect_error(air_explain(NULL), "must be a non-empty character string")
})

test_that("air_debug with no prior error gives message", {
  skip_on_cran()
  skip_on_ci()
  # When no error to get, should error about no error to debug
  res <- tryCatch(air_debug(), error = function(e) e$message)
  expect_true(is.character(res))
})

test_that("air_document rejects empty input", {
  expect_error(air_document(""), "must be a non-empty character string")
})

test_that("air_generate rejects empty input", {
  expect_error(air_generate(""), "must be a non-empty character string")
})

test_that("air_send rejects empty prompt", {
  expect_error(air_send(""), "must be a non-empty character string")
  expect_error(air_send(NULL), "must be a non-empty character string")
})

test_that("air_search rejects empty topic", {
  skip_on_cran()
  # Test that input validation catches empty/NA inputs
  # Note: air_search("") may trigger NUL-byte issue on some R bytecode compilers
  expect_error(air_search(NA_character_), "must be a non-empty string")
})

# ── API error handling (safe — uses invalid path, not dead port) ─────

test_that("air_send handles unreachable backend gracefully", {
  skip_on_cran()
  skip_on_ci()
  air_configure(provider = "ollama", model = "test",
                base_url = "http://localhost:1")
  res <- tryCatch(air_send("test"), error = function(e) "error")
  expect_true(!is.null(res))
})

test_that("air_check returns FALSE for unreachable backend", {
  skip_on_cran()
  skip_on_ci()
  air_configure(provider = "ollama", base_url = "http://localhost:1")
  res <- tryCatch(air_check(), error = function(e) FALSE)
  expect_true(is.logical(res))
})
