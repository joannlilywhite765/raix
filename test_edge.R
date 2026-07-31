# ═══════════════════════════════════════════════════════════════
# raix — Edge Cases & Bug Hunt
# Tests boundary conditions, weird inputs, rapid state changes
# ═══════════════════════════════════════════════════════════════

cat("\n========================================\n")
cat("  RAIX EDGE CASE HUNT\n")
cat("========================================\n\n")

library(raix)
ok <- 0; bad <- 0

t <- function(label, expr) {
  r <- tryCatch(expr, error = function(e) paste("ERR:", conditionMessage(e)))
  if (isTRUE(r) || r == "OK") {
    cat(sprintf("  [OK] %s\n", label)); ok <<- ok + 1
  } else {
    cat(sprintf("  [FAIL] %s — %s\n", label, r)); bad <<- bad + 1
  }
}

# ── NA, NULL, empty string handling ──
cat("\n── 1. NA/NULL/Empty String Defense ──\n")
t("raix_send(NA)", { grepl("non-empty", tryCatch(raix_send(NA_character_), error=function(e)e$message)) })
t("raix_send(NULL)", { grepl("non-empty", tryCatch(raix_send(NULL), error=function(e)e$message)) })
t("raix_explain(NA)", { grepl("non-empty", tryCatch(raix_explain(NA_character_), error=function(e)e$message)) })
t("raix_generate(NA)", { grepl("non-empty", tryCatch(raix_generate(NA_character_), error=function(e)e$message)) })
t("raix_search(NA)", { grepl("non-empty", tryCatch(raix_search(NA_character_), error=function(e)e$message)) })
t("raix_solve(NA)", { grepl("non-empty", tryCatch(raix_solve(NA_character_), error=function(e)e$message)) })
t("raix_google(NA)", { grepl("non-empty", tryCatch(raix_google(NA_character_), error=function(e)e$message)) })
t("raix_terminal(NA)", { grepl("non-empty", tryCatch(raix_terminal(NA_character_), error=function(e)e$message)) })
t("raix_sql(NA)", { grepl("describe", tryCatch(raix_sql(NA_character_), error=function(e)e$message)) })
t("raix_simulate(NA)", { grepl("describe", tryCatch(raix_simulate(NA_character_), error=function(e)e$message)) })
t("raix_translate(NA)", { grepl("non-empty", tryCatch(raix_translate(NA_character_), error=function(e)e$message)) })
t("raix_refactor(NA)", { grepl("non-empty", tryCatch(raix_refactor(NA_character_), error=function(e)e$message)) })
t("raix_web(NA)", { grepl("valid", tryCatch(raix_web(NA_character_), error=function(e)e$message)) })

# ── Rapid provider switching (10x in loop) ──
cat("\n── 2. Rapid Provider Switching ──\n")
providers <- c("ollama", "openai", "claude", "groq", "mistral", "deepseek")
for (i in 1:10) {
  p <- sample(providers, 1)
  t(paste("Switch #", i, "->", p), {
    raix_configure(provider = p)
    env <- asNamespace("raix")[["raix_env"]]
    env$provider == p
  })
}

# ── Boundary values ──
cat("\n── 3. Boundary Values ──\n")
t("Temp = 0", { raix_configure(temperature = 0); TRUE })
t("Temp = 1", { raix_configure(temperature = 1); TRUE })
t("Max tokens = 1", { raix_configure(max_tokens = 1); TRUE })
t("Max tokens = 16384", { raix_configure(max_tokens = 16384); TRUE })
t("Long system prompt", {
  raix_configure(system_prompt = paste(rep("x", 500), collapse = ""))
  TRUE
})
t("Empty model name", {
  raix_configure(provider = "ollama", model = "")
  TRUE
})

# ── Repeated calls ──
cat("\n── 4. Repeated Calls ──\n")
for (i in 1:5) { t(paste("raix_info #", i), { raix_info(); TRUE }) }
for (i in 1:5) { t(paste("raix_config #", i), { is.list(raix_config()) }) }
for (i in 1:5) { t(paste("raix_small_mode #", i), { raix_small_mode(FALSE); TRUE }) }

# ── Concurrent access ──
cat("\n── 5. State Consistency ──\n")
raix_configure(provider = "ollama", model = "test-model")
cfg <- asNamespace("raix")[["raix_env"]]
t("Provider consistent", { cfg$provider == "ollama" })
t("Model consistent", { cfg$model == "test-model" })
t("First call flag exists", { exists("first_call", envir = cfg) })

# ── Summary ──
cat("\n========================================\n")
cat(sprintf("  %d OK, %d FAIL, %d total\n", ok, bad, ok+bad))
cat("========================================\n\n")
if (bad > 0) quit(status = 1)
