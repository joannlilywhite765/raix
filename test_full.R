# ═══════════════════════════════════════════════════════════════
# raix — Full User Simulation
# Simulates a complete user session from install to advanced use
# ═══════════════════════════════════════════════════════════════

cat("\n========================================\n")
cat("  RAIX FULL USER SIMULATION\n")
cat("========================================\n\n")

library(raix)
cat("raix v", as.character(packageVersion("raix")), " — ", 
    length(ls("package:raix")), " functions\n\n")

steps <- 0; fails <- 0

step <- function(label, expr) {
  r <- tryCatch(expr, error = function(e) paste("ERR:", conditionMessage(e)))
  steps <<- steps + 1
  if (isTRUE(r) || r == "OK") {
    cat(sprintf("  %2d. [OK] %s\n", steps, label))
  } else {
    fails <<- fails + 1
    cat(sprintf("  %2d. [FAIL] %s — %s\n", steps, label, r))
  }
}

# ── Phase 1: First-time setup ──
cat("\n── Phase 1: Setup ──\n")
step("raix_info runs", { raix_info(); "OK" })
step("raix_help runs", { raix_help(); "OK" })
step("raix_config returns list", { is.list(raix_config()) })
step("Configure ollama", { raix_configure(provider = "ollama", model = "llama3.2"); TRUE })
step("Check provider", {
  cfg <- asNamespace("raix")[["raix_env"]]
  cfg$provider == "ollama" && cfg$model == "llama3.2"
})

# ── Phase 2: Exploration ──
cat("\n── Phase 2: Exploring Features ──\n")
step("Small model detection", { isTRUE(raix_detect_model_size("llama3.2")) })
step("Not small model", { !isTRUE(raix_detect_model_size("gpt-4o")) })
step("Toggle small mode", { raix_small_mode(TRUE); raix_small_mode(FALSE); "OK" })
step("raix_sysinfo", { is.list(tryCatch(raix_sysinfo(), error=function(e)NULL)) })

# ── Phase 3: Input Validation ──
cat("\n── Phase 3: Input Validation ──\n")
step("raix_send empty", { grepl("non-empty", tryCatch(raix_send(""), error=function(e)e$message)) })
step("raix_generate empty", { grepl("non-empty", tryCatch(raix_generate(""), error=function(e)e$message)) })
step("raix_solve empty", { grepl("non-empty", tryCatch(raix_solve(""), error=function(e)e$message)) })
step("raix_sql empty", { grepl("describe", tryCatch(raix_sql(""), error=function(e)e$message)) })
step("raix_simulate empty", { grepl("describe", tryCatch(raix_simulate(""), error=function(e)e$message)) })

# ── Phase 4: Multi-Provider ──
cat("\n── Phase 4: Multi-Provider ──\n")
for (p in c("openai", "claude", "groq", "mistral", "deepseek")) {
  step(paste("Switch to", p), { raix_configure(provider = p); TRUE })
}
step("Back to ollama", { raix_configure(provider = "ollama"); TRUE })

# ── Phase 5: Project Tools ──
cat("\n── Phase 5: Project Tools ──\n")
step("raix_project on .", { !is.null(tryCatch(raix_project("."), error=function(e)NULL)) })
step("raix_diagnose on .", { r <- tryCatch(raix_diagnose("."), error=function(e)NULL); is.null(r) || is.numeric(r) })
step("raix_history clear", { raix_history(clear = TRUE); TRUE })
step("raix_history empty", { raix_history(); TRUE })

# ── Phase 6: Compute ──
cat("\n── Phase 6: Compute ──\n")
step("raix_benchmark", { !is.null(tryCatch(raix_benchmark({1+1}, iterations=3), error=function(e)NULL)) })

# ── Summary ──
cat("\n========================================\n")
cat(sprintf("  %d steps, %d failed\n", steps, fails))
if (fails == 0) cat("  ALL PASSED\n")
cat("========================================\n\n")
if (fails > 0) quit(status = 1)
