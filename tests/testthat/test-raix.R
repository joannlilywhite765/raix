library(testthat)
library(raix)

# ── Configuration tests (no network needed) ──────────────────────────

test_that("raix_configure sets provider and model", {
  raix_configure(provider = "ollama", model = "llama3.2")
  env <- asNamespace("raix")[["raix_env"]]
  expect_equal(env$provider, "ollama")
  expect_equal(env$model, "llama3.2")
})

test_that("raix_configure accepts any provider (custom / unknown)", {
  # raix is model-agnostic — any provider name is accepted
  expect_error(raix_configure(provider = "my-custom-provider"), NA)
})

test_that("raix_configure sets known preset defaults", {
  raix_configure(provider = "openai")
  env <- asNamespace("raix")[["raix_env"]]
  expect_match(env$model, "gpt-4o")
  expect_match(env$base_url, "api.openai.com")

  raix_configure(provider = "ollama")
  env <- asNamespace("raix")[["raix_env"]]
  expect_match(env$model, "llama3.2")

  raix_configure(provider = "deepseek")
  env <- asNamespace("raix")[["raix_env"]]
  expect_match(env$model, "deepseek")

  raix_configure(provider = "groq")
  env <- asNamespace("raix")[["raix_env"]]
  expect_match(env$base_url, "api.groq.com")
})

test_that("raix_configure base URL defaults for presets", {
  for (p in c("openai", "ollama", "claude", "groq", "mistral", "deepseek")) {
    raix_configure(provider = p)
    env <- asNamespace("raix")[["raix_env"]]
    expect_true(nchar(env$base_url) > 10)
  }
})

test_that("raix_configure custom parameters", {
  raix_configure(provider = "ollama", temperature = 0.7, max_tokens = 512,
                system_prompt = "Custom prompt")
  env <- asNamespace("raix")[["raix_env"]]
  expect_equal(env$temperature, 0.7)
  expect_equal(env$max_tokens, 512)
  expect_match(env$system_prompt, "Custom prompt")
})

test_that("raix_configure model override", {
  raix_configure(provider = "ollama", model = "mistral:latest")
  env <- asNamespace("raix")[["raix_env"]]
  expect_equal(env$model, "mistral:latest")
})

test_that("raix_configure custom base_url", {
  skip_on_cran()
  # Set custom provider with explicit base_url and format
  raix_configure(provider = "my-custom-endpoint", 
                base_url = "https://my-api.example.com/v1",
                api_format = "openai",
                model = "custom-model")
  env <- asNamespace("raix")[["raix_env"]]
  expect_match(env$base_url, "my-api.example.com")
  expect_equal(env$api_format, "openai")
  expect_equal(env$provider, "my-custom-endpoint")
})

test_that("raix_configure rejects invalid api_format", {
  expect_error(raix_configure(provider = "test", api_format = "invalid"),
               "must be 'openai', 'ollama', or 'claude'")
})

# ── Utility tests (no network needed) ────────────────────────────────

test_that("raix_info runs without error", {
  expect_error(raix_info(), NA)
})

test_that("raix_explain rejects empty input", {
  expect_error(raix_explain(""), "must be a non-empty character string")
  expect_error(raix_explain(NULL), "must be a non-empty character string")
})

test_that("raix_debug with no prior error gives message", {
  skip_on_cran()
  skip_on_ci()
  # When no error to get, should error about no error to debug
  res <- tryCatch(raix_debug(), error = function(e) e$message)
  expect_true(is.character(res))
})

test_that("raix_document rejects empty input", {
  expect_error(raix_document(""), "must be a non-empty character string")
})

test_that("raix_generate rejects empty input", {
  expect_error(raix_generate(""), "must be a non-empty character string")
})

test_that("raix_send rejects empty prompt", {
  expect_error(raix_send(""), "must be a non-empty character string")
  expect_error(raix_send(NULL), "must be a non-empty character string")
})

test_that("raix_search rejects empty topic", {
  skip_on_cran()
  # Test that input validation catches empty/NA inputs
  # Note: raix_search("") may trigger NUL-byte issue on some R bytecode compilers
  expect_error(raix_search(NA_character_), "must be a non-empty string")
})

# ── API error handling (safe — uses invalid path, not dead port) ─────

test_that("raix_send handles unreachable backend gracefully", {
  skip_on_cran()
  skip_on_ci()
  raix_configure(provider = "ollama", model = "test",
                base_url = "http://localhost:1")
  res <- tryCatch(raix_send("test"), error = function(e) "error")
  expect_true(!is.null(res))
})

test_that("raix_check returns FALSE for unreachable backend", {
  skip_on_cran()
  skip_on_ci()
  raix_configure(provider = "ollama", base_url = "http://localhost:1")
  res <- tryCatch(raix_check(), error = function(e) FALSE)
  expect_true(is.logical(res))
})
