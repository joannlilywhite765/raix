# ═══════════════════════════════════════════════════════════════
# raix — Any Model Test (13+ providers, all API formats)
# ═══════════════════════════════════════════════════════════════

cat("\n========================================\n")
cat("  RAIX ANY-MODEL TEST\n")
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

# ── All known provider presets ──
cat("\n── 1. Provider Presets (13) ──\n")
providers <- c("ollama", "openai", "claude", "groq", "together", "mistral", 
               "deepseek", "kimi", "zai", "perplexity", "lmstudio", "vllm", "openrouter")
for (p in providers) {
  t(paste("Provider:", p), { raix_configure(provider = p); TRUE })
}

# ── Custom endpoints ──
cat("\n── 2. Custom Endpoints ──\n")
t("Custom with base_url", {
  raix_configure(provider = "my-server", model = "my-model", 
                 base_url = "https://api.example.com/v1", api_format = "openai")
  cfg <- asNamespace("raix")[["raix_env"]]
  cfg$base_url == "https://api.example.com/v1" && cfg$api_format == "openai"
})

t("Custom ollama-compatible", {
  raix_configure(provider = "local-llm", model = "mistral",
                 base_url = "http://localhost:11434", api_format = "ollama")
  cfg <- asNamespace("raix")[["raix_env"]]
  cfg$api_format == "ollama"
})

t("Custom claude-compatible", {
  raix_configure(provider = "claude-proxy", model = "claude-3",
                 base_url = "https://proxy.example.com/v1", api_format = "claude")
  cfg <- asNamespace("raix")[["raix_env"]]
  cfg$api_format == "claude"
})

# ── API format detection ──
cat("\n── 3. API Format Auto-Detection ──\n")
t("Detect ollama URL", {
  fmt <- raix_detect_format("http://localhost:11434")
  fmt == "ollama"
})
t("Detect anthropic URL", {
  fmt <- raix_detect_format("https://api.anthropic.com/v1")
  fmt == "claude"
})
t("Detect openai URL", {
  fmt <- raix_detect_format("https://api.openai.com/v1")
  fmt == "openai"
})
t("Default to openai", {
  fmt <- raix_detect_format("https://unknown.example.com/v1")
  fmt == "openai"
})

# ── Model size detection ──
cat("\n── 4. Model Size Detection ──\n")
t("qwen2.5-coder:7b -> small", { isTRUE(raix_detect_model_size("qwen2.5-coder:7b")) })
t("phi3.5 -> small", { isTRUE(raix_detect_model_size("phi3.5:latest")) })
t("gemma2:9b -> small", { isTRUE(raix_detect_model_size("gemma2:9b")) })
t("llama3.2 -> small", { isTRUE(raix_detect_model_size("llama3.2")) })
t("mistral:7b -> small", { isTRUE(raix_detect_model_size("mistral:7b")) })
t("deepseek-coder:6.7b -> small", { isTRUE(raix_detect_model_size("deepseek-coder:6.7b")) })
t("gpt-4o -> standard", { !isTRUE(raix_detect_model_size("gpt-4o")) })
t("claude-3-5-sonnet -> standard", { !isTRUE(raix_detect_model_size("claude-3-5-sonnet-20241022")) })
t("deepseek-chat -> standard", { !isTRUE(raix_detect_model_size("deepseek-chat")) })

# ── Model switching ──
cat("\n── 5. Rapid Provider Switching ──\n")
for (p in sample(providers, 10)) {
  t(paste("Switch to", p), { raix_configure(provider = p); TRUE })
}
t("Back to ollama", { raix_configure(provider = "ollama", model = "llama3.2"); TRUE })

# ── Summary ──
cat("\n========================================\n")
cat(sprintf("  %d OK, %d FAIL, %d total\n", ok, bad, ok+bad))
cat("========================================\n\n")
if (bad > 0) quit(status = 1)
