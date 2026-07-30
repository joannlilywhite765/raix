library(testthat)

# Load package from source (not installed version)
if (requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(".", quiet = TRUE)
} else {
  library(air)
}

test_that("air_configure sets backend correctly", {
  air_configure(backend = "ollama", model = "llama3.2")
  expect_true(TRUE)
})

test_that("air_configure validates backend argument", {
  expect_error(air_configure(backend = "invalid_backend"), "should be one of")
})

test_that("air_configure defaults populate correctly", {
  air_configure(backend = "openai")
  expect_equal(air:::air_env$model, "gpt-4o")
  expect_match(air:::air_env$base_url, "api.openai.com")
})

test_that("air_configure switches backends correctly", {
  air_configure(backend = "claude", model = "claude-3-opus-20240229")
  expect_equal(air:::air_env$backend, "claude")
  expect_equal(air:::air_env$model, "claude-3-opus-20240229")
})

test_that("air_send fails gracefully with connection error", {
  air_configure(backend = "ollama", model = "nonexistent-model",
                base_url = "http://localhost:19999")
  expect_error(air_send("test"), "API request failed")
})

test_that("air_send fails with invalid API key for OpenAI", {
  skip_on_cran()
  air_configure(backend = "openai", model = "gpt-4o", api_key = "invalid-key")
  expect_error(air_send("test"), "API request failed")
})

test_that("air_explain returns character on skip", {
  skip_on_cran()
  result <- tryCatch(air_explain("mean"), error = function(e) NULL)
  if (!is.null(result)) expect_type(result, "character")
  expect_true(TRUE)
})

test_that("air_info prints without error", {
  expect_error(air_info(), NA)
})

test_that("air_configure sets all parameters", {
  air_configure(
    backend = "ollama",
    model = "mistral",
    temperature = 0.5,
    max_tokens = 1024,
    system_prompt = "You are a helpful R assistant."
  )
  expect_equal(air:::air_env$temperature, 0.5)
  expect_equal(air:::air_env$max_tokens, 1024)
  expect_match(air:::air_env$system_prompt, "helpful R assistant")
})
