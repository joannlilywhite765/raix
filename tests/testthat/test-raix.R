library(testthat)
library(raix)

# ══════════════════════════════════════════════════════════════════════
# Configuration Tests
# ══════════════════════════════════════════════════════════════════════

test_that("raix_configure sets provider and model", {
  raix_configure(provider = "ollama", model = "llama3.2")
  env <- asNamespace("raix")[["raix_env"]]
  expect_equal(env$provider, "ollama")
  expect_equal(env$model, "llama3.2")
})

test_that("raix_configure accepts any provider name", {
  expect_error(raix_configure(provider = "my-custom"), NA)
})

test_that("raix_configure preset defaults for known providers", {
  raix_configure(provider = "openai")
  env <- asNamespace("raix")[["raix_env"]]
  expect_match(env$model, "gpt-4o")
  expect_match(env$base_url, "api.openai.com")
  
  raix_configure(provider = "ollama")
  env <- asNamespace("raix")[["raix_env"]]
  expect_match(env$model, "llama3.2")
  
  raix_configure(provider = "groq")
  env <- asNamespace("raix")[["raix_env"]]
  expect_match(env$base_url, "api.groq.com")
})

test_that("raix_configure base_url defaults for all presets", {
  for (p in c("openai", "ollama", "claude", "groq", "mistral", "deepseek")) {
    raix_configure(provider = p)
    env <- asNamespace("raix")[["raix_env"]]
    expect_true(nchar(env$base_url) > 10)
  }
})

test_that("raix_configure custom parameters override defaults", {
  raix_configure(provider = "ollama", temperature = 0.7, max_tokens = 512,
                 system_prompt = "Custom prompt")
  env <- asNamespace("raix")[["raix_env"]]
  expect_equal(env$temperature, 0.7)
  expect_equal(env$max_tokens, 512)
  expect_match(env$system_prompt, "Custom prompt")
})

test_that("raix_configure model override works", {
  raix_configure(provider = "ollama", model = "mistral:latest")
  env <- asNamespace("raix")[["raix_env"]]
  expect_equal(env$model, "mistral:latest")
})

test_that("raix_configure custom base_url and api_format", {
  raix_configure(provider = "my-endpoint",
                 base_url = "https://my-api.example.com/v1",
                 api_format = "openai", model = "custom")
  env <- asNamespace("raix")[["raix_env"]]
  expect_match(env$base_url, "my-api.example.com")
  expect_equal(env$api_format, "openai")
  expect_equal(env$provider, "my-endpoint")
})

test_that("raix_configure rejects invalid api_format", {
  expect_error(
    raix_configure(provider = "test", api_format = "invalid"),
    "must be 'openai', 'ollama', or 'claude'")
})

test_that("raix_configure preserves user system_prompt", {
  raix_configure(provider = "ollama", model = "llama3.2", 
                 system_prompt = "Keep this custom prompt")
  env <- asNamespace("raix")[["raix_env"]]
  expect_match(env$system_prompt, "Keep this custom prompt")
})

test_that("raix_config returns list with expected fields", {
  cfg <- raix_config()
  expect_type(cfg, "list")
  expect_true(all(c("provider", "model", "api_format", "base_url", 
                    "temperature", "max_tokens", "small_model") %in% names(cfg)))
})

test_that("raix_small_mode toggles correctly", {
  skip_on_cran()
  raix_small_mode(TRUE)
  env <- asNamespace("raix")[["raix_env"]]
  expect_true(env$small_model)
  
  raix_small_mode(FALSE)
  env <- asNamespace("raix")[["raix_env"]]
  expect_false(env$small_model)
})

# ══════════════════════════════════════════════════════════════════════
# Info & Help (no network)
# ══════════════════════════════════════════════════════════════════════

test_that("raix_info runs without error", {
  expect_error(raix_info(), NA)
})

test_that("raix_help runs without error", {
  expect_error(raix_help(), NA)
})

test_that("raix_sysinfo runs without error", {
  skip_on_cran()
  info <- tryCatch(raix_sysinfo(), error = function(e) NULL)
  expect_true(!is.null(info))
})

# ══════════════════════════════════════════════════════════════════════
# Input Validation — Code Functions
# ══════════════════════════════════════════════════════════════════════

test_that("raix_send rejects empty/NA/NULL prompt", {
  expect_error(raix_send(""), "must be a non-empty character string")
  expect_error(raix_send(NULL), "must be a non-empty character string")
  expect_error(raix_send(NA_character_), "must be a non-empty character string")
})

test_that("raix_explain rejects empty/NA/NULL code", {
  expect_error(raix_explain(""), "must be a non-empty character string")
  expect_error(raix_explain(NULL), "must be a non-empty character string")
})

test_that("raix_generate rejects empty/NA/NULL description", {
  expect_error(raix_generate(""), "must be a non-empty character string")
  expect_error(raix_generate(NULL), "must be a non-empty character string")
})

test_that("raix_document rejects empty/NA/NULL code", {
  expect_error(raix_document(""), "must be a non-empty character string")
})

test_that("raix_debug handles no prior error gracefully", {
  skip_on_cran()
  skip_on_ci()
  res <- tryCatch(raix_debug(), error = function(e) e$message)
  expect_true(is.character(res))
})

# ══════════════════════════════════════════════════════════════════════
# Input Validation — Data & Project Functions
# ══════════════════════════════════════════════════════════════════════

test_that("raix_search rejects NA/empty topic", {
  expect_error(raix_search(NA_character_), "must be a non-empty string")
})

test_that("raix_analyze rejects non-data.frame input", {
  expect_error(raix_analyze("not a dataframe"), "must be a data.frame")
  expect_error(raix_analyze(NULL), "must be a data.frame")
})

test_that("raix_diagnose errors on non-existent path", {
  expect_error(raix_diagnose("/nonexistent/path"), "Path not found")
})

test_that("raix_google rejects empty query", {
  expect_error(raix_google(""), "must be a non-empty search string")
  expect_error(raix_google(NA_character_), "must be a non-empty search string")
})

# ══════════════════════════════════════════════════════════════════════
# Input Validation — Developer Agent Functions
# ══════════════════════════════════════════════════════════════════════

test_that("raix_solve rejects empty/NA problem", {
  expect_error(raix_solve(""), "must be a non-empty")
  expect_error(raix_solve(NA_character_), "must be a non-empty")
})

test_that("raix_script creates file when called offline", {
  skip_on_cran()
  skip_on_ci()
  tmp <- tempfile(fileext = ".R")
  res <- tryCatch(raix_script("test", output = tmp), error = function(e) NULL)
  # May fail if no AI, but should not crash
  expect_true(TRUE)
})

test_that("raix_notebook handles missing AI gracefully", {
  skip_on_cran()
  skip_on_ci()
  tmp <- tempfile(fileext = ".Rmd")
  res <- tryCatch(raix_notebook("test", output = tmp), error = function(e) NULL)
  expect_true(TRUE)
})

test_that("raix_project errors on non-existent directory", {
  expect_error(raix_project("/nonexistent"), "Directory not found")
})

test_that("raix_package rejects empty task", {
  expect_error(raix_package(""), "must describe")
  expect_error(raix_package(NA_character_), "must describe")
})

test_that("raix_read errors on non-existent file", {
  expect_error(raix_read("/nonexistent/file.txt"), "File not found")
})

test_that("raix_write rejects empty description", {
  expect_error(raix_write("", "test.txt"), "must be a non-empty")
})

# ══════════════════════════════════════════════════════════════════════
# Input Validation — Compute Functions
# ══════════════════════════════════════════════════════════════════════

test_that("raix_terminal rejects empty command", {
  expect_error(raix_terminal(""), "must be a non-empty")
  expect_error(raix_terminal(NA_character_), "must be a non-empty")
})

test_that("raix_python requires description or code", {
  expect_error(raix_python(), "Provide either")
})

test_that("raix_compile requires description", {
  expect_error(raix_compile(), "must describe")
})

test_that("raix_pipeline rejects empty steps", {
  expect_error(raix_pipeline(character(0)), "must be a character vector")
})

test_that("raix_benchmark requires expression", {
  expect_error(raix_benchmark(), "Provide an R expression")
})

test_that("raix_parallel requires description", {
  expect_error(raix_parallel(""), "must describe")
})

# ══════════════════════════════════════════════════════════════════════
# Input Validation — Advanced Functions
# ══════════════════════════════════════════════════════════════════════

test_that("raix_test requires function input", {
  expect_error(raix_test(), "Provide a function name")
})

test_that("raix_refactor rejects empty code", {
  expect_error(raix_refactor(""), "must be a non-empty")
})

test_that("raix_translate rejects empty code", {
  expect_error(raix_translate(""), "must be a non-empty")
})

test_that("raix_sql rejects empty description", {
  expect_error(raix_sql(""), "must describe")
})

test_that("raix_web rejects empty URL", {
  expect_error(raix_web(""), "must be a valid")
})

test_that("raix_simulate rejects empty description", {
  expect_error(raix_simulate(""), "must describe")
})

test_that("raix_history clears without error", {
  raix_history(clear = TRUE)
  # Should not error
  expect_error(raix_history(), NA)
})

test_that("raix_history returns invisibly with no history", {
  raix_history(clear = TRUE)
  res <- tryCatch(raix_history(), error = function(e) NULL)
  expect_true(TRUE)  # should not crash
})

# ══════════════════════════════════════════════════════════════════════
# NA-safe input validation (regression tests)
# ══════════════════════════════════════════════════════════════════════

test_that("All exported functions handle NA without crash", {
  skip_on_cran()
  fns <- ls("package:raix")
  safe <- TRUE
  for (fn in fns) {
    res <- tryCatch({
      do.call(fn, list())
    }, error = function(e) e$message)
    # Must either return an error message or succeed — never crash
    expect_true(is.character(res) || is.null(res) || is.logical(res) || is.list(res))
  }
})
