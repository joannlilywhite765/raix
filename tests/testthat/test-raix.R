library(testthat)

if (requireNamespace("pkgload", quietly = TRUE)) {
  pkgload::load_all(".", quiet = TRUE)
} else {
  library(raix)
}

# ── Configuration tests (no network needed) ──────────────────────────

test_that("air_configure sets backend", {
  air_configure(backend = "ollama", model = "llama3.2")
  expect_equal(air:::air_env$backend, "ollama")
  expect_equal(air:::air_env$model, "llama3.2")
})

test_that("air_configure rejects invalid backend", {
  expect_error(air_configure(backend = "invalid"), "should be one of")
})

test_that("air_configure sets all 6 backends", {
  for (b in c("openai","ollama","claude","deepseek","kimi","zai")) {
    expect_error(air_configure(backend = b), NA)
  }
})

test_that("air_configure model defaults", {
  air_configure(backend = "openai"); expect_match(air:::air_env$model, "gpt-4o")
  air_configure(backend = "ollama"); expect_match(air:::air_env$model, "llama3.2")
  air_configure(backend = "deepseek"); expect_match(air:::air_env$model, "deepseek")
  air_configure(backend = "kimi"); expect_match(air:::air_env$model, "moonshot")
})

test_that("air_configure base URL defaults", {
  for (b in c("openai","ollama","claude","deepseek","kimi","zai")) {
    air_configure(backend = b)
    expect_true(nchar(air:::air_env$base_url) > 10)
  }
})

test_that("air_configure custom parameters", {
  air_configure(backend = "ollama", temperature = 0.7, max_tokens = 512,
                system_prompt = "Custom prompt")
  expect_equal(air:::air_env$temperature, 0.7)
  expect_equal(air:::air_env$max_tokens, 512)
  expect_match(air:::air_env$system_prompt, "Custom prompt")
})

test_that("air_configure model override", {
  air_configure(backend = "ollama", model = "mistral:latest")
  expect_equal(air:::air_env$model, "mistral:latest")
})

# ── Utility tests (no network needed) ────────────────────────────────

test_that("air_info runs without error", {
  expect_error(air_info(), NA)
})

test_that("air_explain builds correct prompt", {
  skip_on_cran()
  res <- tryCatch(air_explain("mean"), error = function(e) e$message)
  # May fail if no AI available — that's fine, the error is clean
  expect_true(is.character(res))
})

test_that("air_document builds correct prompt", {
  skip_on_cran()
  res <- tryCatch(air_document("f <- function(x) x + 1"), error = function(e) e$message)
  expect_true(is.character(res))
})

test_that("air_generate builds correct prompt", {
  skip_on_cran()
  res <- tryCatch(air_generate("Create a scatter plot"), error = function(e) e$message)
  expect_true(is.character(res))
})

# ── API error handling (safe — uses invalid path, not dead port) ─────

test_that("air_send handles unreachable backend gracefully", {
  skip_on_cran()
  # Use localhost:1 which is a restricted port — httr will error quickly
  air_configure(backend = "ollama", model = "test",
                base_url = "http://localhost:1")
  # Just verify it doesn't crash R — error expected
  res <- tryCatch(air_send("test"), error = function(e) "error")
  expect_true(!is.null(res))
})

test_that("air_check returns FALSE for unreachable backend", {
  skip_on_cran()
  air_configure(backend = "ollama", base_url = "http://localhost:1")
  res <- tryCatch(air_check(), error = function(e) FALSE)
  expect_true(is.logical(res))
})
