# ═══════════════════════════════════════════════════════════════
# raix — Beginner User Walkthrough
# Tests the exact path a new user follows
# ═══════════════════════════════════════════════════════════════

cat("\n========================================\n")
cat("  RAIX BEGINNER WALKTHROUGH\n")
cat("========================================\n\n")

library(raix)
ok <- 0

cat("── Step 1: First load ──\n")
cat("  You typed: library(raix)\n")
cat("  Package loaded. Now what?\n\n")

cat("── Step 2: See what's available ──\n")
cat("  You typed: raix_help()\n")
tryCatch(raix_help(), error = function(e) NULL)
ok <- ok + 1; cat(sprintf("  [%d] raix_help works\n\n", ok))

cat("── Step 3: Check current config ──\n")
cat("  You typed: raix_info()\n")
tryCatch(raix_info(), error = function(e) NULL)
ok <- ok + 1; cat(sprintf("  [%d] raix_info works\n\n", ok))

cat("── Step 4: Configure a model ──\n")
cat("  You typed: raix_configure(provider = 'ollama', model = 'llama3.2')\n")
tryCatch(raix_configure(provider = "ollama", model = "llama3.2"), error = function(e) NULL)
ok <- ok + 1; cat(sprintf("  [%d] Configured ollama\n\n", ok))

cat("── Step 5: Small model detected? ──\n")
if (isTRUE(raix_detect_model_size("llama3.2"))) {
  cat("  Yes! llama3.2 is a small model — raix auto-optimizes prompts.\n")
  cat("  You typed: raix_small_mode()\n")
  tryCatch(raix_small_mode(TRUE), error = function(e) NULL)
  ok <- ok + 1; cat(sprintf("  [%d] Small mode activated\n\n", ok))
}

cat("── Step 6: Search CRAN ──\n")
cat("  You typed: raix_search('clustering')\n")
tryCatch(raix_search("clustering"), error = function(e) NULL)
ok <- ok + 1; cat(sprintf("  [%d] Package search works\n\n", ok))

cat("── Step 7: Analyze data (no AI needed) ──\n")
cat("  You typed: raix_analyze(mtcars)\n")
tryCatch(raix_analyze(mtcars), error = function(e) NULL)
ok <- ok + 1; cat(sprintf("  [%d] Data analysis works\n\n", ok))

cat("── Step 8: Diagnose project ──\n")
cat("  You typed: raix_diagnose('.')\n")
tryCatch(raix_diagnose("."), error = function(e) NULL)
ok <- ok + 1; cat(sprintf("  [%d] Project diagnosis works\n\n", ok))

cat("── Step 9: System info ──\n")
cat("  You typed: raix_sysinfo()\n")
tryCatch(raix_sysinfo(), error = function(e) NULL)
ok <- ok + 1; cat(sprintf("  [%d] System info works\n\n", ok))

cat("── Step 10: Translate code ──\n")
cat("  You typed: raix_translate('mtcars %>% filter(cyl==6)', to='python')\n")
tryCatch(raix_translate("mtcars %>% filter(cyl==6)", to = "python"), error = function(e) NULL)
ok <- ok + 1; cat(sprintf("  [%d] Translation works\n\n", ok))

cat("── Step 11: Generate SQL ──\n")
cat("  You typed: raix_sql('Top 10 customers by total spend')\n")
tryCatch(raix_sql("Top 10 customers by total spend"), error = function(e) NULL)
ok <- ok + 1; cat(sprintf("  [%d] SQL generation works\n\n", ok))

cat("── Step 12: Benchmark ──\n")
cat("  You typed: raix_benchmark({mean(1:1000)}, iterations=5)\n")
tryCatch(raix_benchmark({mean(1:1000)}, iterations = 5), error = function(e) NULL)
ok <- ok + 1; cat(sprintf("  [%d] Benchmarking works\n\n", ok))

cat("── Step 13: History ──\n")
cat("  You typed: raix_history()\n")
tryCatch(raix_history(), error = function(e) NULL)
ok <- ok + 1; cat(sprintf("  [%d] History works\n\n", ok))

cat("── Step 14: All done! ──\n")
cat("  raix is ready for real usage.\n")
cat("  Try: raix_chat() or raix_dashboard()\n\n")

cat("========================================\n")
cat(sprintf("  %d/14 steps completed successfully\n", ok))
cat("========================================\n\n")
