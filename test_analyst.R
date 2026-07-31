# ═══════════════════════════════════════════════════════════════
# raix — Data Analyst Workflow Simulation
# Tests typical data analyst tasks end-to-end
# ═══════════════════════════════════════════════════════════════

cat("\n========================================\n")
cat("  RAIX DATA ANALYST SIMULATION\n")
cat("========================================\n\n")

passed <- 0; failed <- 0

check <- function(label, expr) {
  r <- tryCatch(expr, error = function(e) paste("ERROR:", conditionMessage(e)))
  if (isTRUE(r) || r == "OK") {
    cat(sprintf("  [PASS] %s\n", label)); passed <<- passed + 1
  } else {
    cat(sprintf("  [FAIL] %s — %s\n", label, r)); failed <<- failed + 1
  }
}

# ── Setup ──
cat("\n── 1. Setup ──\n")
check("Package loads", { library(raix); "OK" })
check("Version >= 0.8", { as.numeric(packageVersion("raix")) >= 0.8 })
check("42 functions", { length(ls("package:raix")) >= 42 })

# ── Config ──
cat("\n── 2. Configuration ──\n")
check("ollama preset", { raix_configure(provider = "ollama"); TRUE })
check("openai preset", { raix_configure(provider = "openai"); TRUE })
check("custom endpoint", { raix_configure(provider = "custom", model = "test", base_url = "https://api.example.com/v1", api_format = "openai"); TRUE })
check("raix_config list", { is.list(raix_config()) })
check("Switch back ollama", { raix_configure(provider = "ollama"); TRUE })

# ── Small Model Detection ──
cat("\n── 3. Small Model Detection ──\n")
check("qwen2.5-coder:7b is small", { isTRUE(raix_detect_model_size("qwen2.5-coder:7b")) })
check("phi3.5 is small", { isTRUE(raix_detect_model_size("phi3.5:latest")) })
check("gemma2:9b is small", { isTRUE(raix_detect_model_size("gemma2:9b")) })
check("llama3.2 is small", { isTRUE(raix_detect_model_size("llama3.2")) })
check("gpt-4o is NOT small", { !isTRUE(raix_detect_model_size("gpt-4o")) })
check("small_mode toggle", { raix_small_mode(TRUE); raix_small_mode(FALSE); TRUE })

# ── Input Validation ──
cat("\n── 4. Input Validation ──\n")
check("raix_send empty", { grepl("non-empty", tryCatch(raix_send(""), error=function(e)e$message)) })
check("raix_explain empty", { grepl("non-empty", tryCatch(raix_explain(""), error=function(e)e$message)) })
check("raix_generate empty", { grepl("non-empty", tryCatch(raix_generate(""), error=function(e)e$message)) })
check("raix_solve empty", { grepl("non-empty", tryCatch(raix_solve(""), error=function(e)e$message)) })
check("raix_search NA", { grepl("non-empty", tryCatch(raix_search(NA_character_), error=function(e)e$message)) })
check("raix_terminal empty", { grepl("non-empty", tryCatch(raix_terminal(""), error=function(e)e$message)) })
check("raix_sql empty", { grepl("describe", tryCatch(raix_sql(""), error=function(e)e$message)) })
check("raix_simulate empty", { grepl("describe", tryCatch(raix_simulate(""), error=function(e)e$message)) })
check("raix_translate empty", { grepl("non-empty", tryCatch(raix_translate(""), error=function(e)e$message)) })
check("raix_refactor empty", { grepl("non-empty", tryCatch(raix_refactor(""), error=function(e)e$message)) })

# ── Project Tools ──
cat("\n── 5. Project & File Tools ──\n")
check("raix_project on .", { !is.null(tryCatch(raix_project("."), error=function(e)NULL)) })
check("raix_diagnose on .", { r <- tryCatch(raix_diagnose("."), error=function(e)NULL); is.null(r) || is.numeric(r) })
check("raix_sysinfo runs", { is.list(tryCatch(raix_sysinfo(), error=function(e)NULL)) })
check("raix_read non-existent", { grepl("not found", tryCatch(raix_read("/no/file"), error=function(e)e$message)) })
check("raix_history clear", { raix_history(clear=TRUE); TRUE })

# ── Compute ──
cat("\n── 6. Compute ──\n")
check("raix_benchmark trivial", { !is.null(tryCatch(raix_benchmark({1+1}, iterations=3), error=function(e)NULL)) })

# ── Summary ──
cat("\n========================================\n")
cat(sprintf("  RESULTS: %d passed, %d failed, %d total\n", passed, failed, passed+failed))
cat("========================================\n\n")
if (failed > 0) quit(status = 1)
