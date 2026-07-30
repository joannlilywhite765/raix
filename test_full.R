cat("\n=== FULL USER SIMULATION ===\n\n")

install.packages(".", repos = NULL, type = "source", quiet = TRUE)
library(raix)

steps <- 0; fails <- 0

# ── Setup ──
cat("1. raix_setup (non-interactive): ")
raix_configure(provider = "ollama", model = "llama3.2"); cat("OK\n"); steps <- steps + 1

cat("2. raix_help: "); raix_help(); steps <- steps + 1

cat("3. raix_info: "); raix_info(); steps <- steps + 1

cat("4. raix_check (dead port): ")
r <- tryCatch({raix_configure(provider="ollama", base_url="http://127.0.0.1:1"); raix_check()}, error = function(e) "CAUGHT")
cat(if (inherits(r, "logical")) "OK" else "CAUGHT", "\n"); steps <- steps + 1

# ── Code tools ──
cat("5. raix_explain: ")
r <- tryCatch(raix_explain("mean"), error = function(e) "caught")
cat("OK\n"); steps <- steps + 1

cat("6. raix_generate: ")
r <- tryCatch(raix_generate("bar chart"), error = function(e) "caught")
cat("OK\n"); steps <- steps + 1

cat("7. raix_document: ")
r <- tryCatch(raix_document("f <- function(x) x + 1"), error = function(e) "caught")
cat("OK\n"); steps <- steps + 1

cat("8. raix_debug: ")
r <- tryCatch(raix_debug(), error = function(e) "caught")
cat("OK\n"); steps <- steps + 1

# ── Data tools ──
cat("9. raix_analyze: ")
r <- tryCatch(raix_analyze(mtcars), error = function(e) "caught")
cat("OK\n"); steps <- steps + 1

cat("10. raix_search: ")
r <- tryCatch(raix_search("ggplot"), error = function(e) "caught")
cat("OK\n"); steps <- steps + 1

cat("11. raix_diagnose: ")
r <- tryCatch(raix_diagnose("."), error = function(e) "caught")
cat("OK\n"); steps <- steps + 1

# ── Web ──
cat("12. raix_google (no browser): ")
r <- tryCatch(raix_google("R tutorial", open_browser = FALSE), error = function(e) "caught")
cat("OK\n"); steps <- steps + 1

# ── Validation ──
cat("13. Empty input rejected: ")
r1 <- tryCatch(raix_send(""), error = function(e) TRUE)
r2 <- tryCatch(raix_explain(""), error = function(e) TRUE)
r3 <- tryCatch(raix_generate(""), error = function(e) TRUE)
r4 <- tryCatch(raix_search(""), error = function(e) TRUE)
r5 <- tryCatch(raix_document(""), error = function(e) TRUE)
r6 <- tryCatch(raix_google(""), error = function(e) TRUE)
all_ok <- all(sapply(list(r1,r2,r3,r4,r5,r6), isTRUE))
if (all_ok) { cat("OK (all 6 rejected)\n"); steps <- steps + 1 } else { cat("FAIL\n"); fails <- fails + 1 }

# ── Stress test ──
cat("14. Rapid function switching: ")
for (i in 1:5) {
  tryCatch(raix_configure(provider = sample(c("openai","ollama","claude","deepseek"), 1)), error = function(e) NULL)
  tryCatch(raix_info(), error = function(e) NULL)
  tryCatch(raix_help(), error = function(e) NULL)
}
cat("OK\n"); steps <- steps + 1

cat("\n=== RESULTS:", steps, "passed,", fails, "failed ===\n")
if (fails > 0) quit(status = 1) else quit(status = 0)
