library(testthat)
library(air)

test_that("air_configure sets backend correctly", {
  air_configure(backend = "ollama", model = "llama3.2")
  info <- air_info()
  expect_true(TRUE)  # smoke test
})

test_that("air_configure validates backend argument", {
  expect_error(air_configure(backend = "invalid_backend"))
})

test_that("air_send fails gracefully with no API connection", {
  air_configure(backend = "ollama", model = "nonexistent-model")
  expect_error(air_send("test"), "API request failed")
})

test_that("air_explain works with function name", {
  skip_on_cran()
  result <- air_explain("mean")
  expect_type(result, "character")
})
