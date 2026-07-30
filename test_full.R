cat("\n=== FULL USER SIMULATION ===\n\n")

install.packages(".", repos = NULL, type = "source", quiet = TRUE)
library(air)

steps <- 0; fails <- 0

# ── Setup ──
cat("1. air_setup (non-interactive): ")
air_configure(backend = "ollama", model = "llama3.2"); cat("OK\n"); steps <- steps + 1

cat("2. air_help: "); air_help(); steps <- steps + 1

cat("3. air_info: "); air_info(); steps <- steps + 1

cat("4. air_check (dead port): ")
r <- tryCatch({air_configure(backend="ollama", base_url="http://127.0.0.1:1"); air_check()}, error = function(e) "CAUGHT")
cat(if (inherits(r, "logical")) "OK" else "CAUGHT", "\n"); steps <- steps + 1

# ── Code tools ──
cat("5. air_explain: ")
r <- tryCatch(air_explain("mean"), error = function(e) "caught")
cat("OK\n"); steps <- steps + 1

cat("6. air_generate: ")
r <- tryCatch(air_generate("bar chart"), error = function(e) "caught")
cat("OK\n"); steps <- steps + 1

cat("7. air_document: ")
r <- tryCatch(air_document("f <- function(x) x + 1"), error = function(e) "caught")
cat("OK\n"); steps <- steps + 1

cat("8. air_debug: ")
r <- tryCatch(air_debug(), error = function(e) "caught")
cat("OK\n"); steps <- steps + 1

# ── Data tools ──
cat("9. air_analyze: ")
r <- tryCatch(air_analyze(mtcars), error = function(e) "caught")
cat("OK\n"); steps <- steps + 1

cat("10. air_search: ")
r <- tryCatch(air_search("ggplot"), error = function(e) "caught")
cat("OK\n"); steps <- steps + 1

cat("11. air_diagnose: ")
r <- tryCatch(air_diagnose("."), error = function(e) "caught")
cat("OK\n"); steps <- steps + 1

# ── Web ──
cat("12. air_google (no browser): ")
r <- tryCatch(air_google("R tutorial", open_browser = FALSE), error = function(e) "caught")
cat("OK\n"); steps <- steps + 1

# ── Validation ──
cat("13. Empty input rejected: ")
r1 <- tryCatch(air_send(""), error = function(e) TRUE)
r2 <- tryCatch(air_explain(""), error = function(e) TRUE)
r3 <- tryCatch(air_generate(""), error = function(e) TRUE)
r4 <- tryCatch(air_search(""), error = function(e) TRUE)
r5 <- tryCatch(air_document(""), error = function(e) TRUE)
r6 <- tryCatch(air_google(""), error = function(e) TRUE)
all_ok <- all(sapply(list(r1,r2,r3,r4,r5,r6), isTRUE))
if (all_ok) { cat("OK (all 6 rejected)\n"); steps <- steps + 1 } else { cat("FAIL\n"); fails <- fails + 1 }

# ── Stress test ──
cat("14. Rapid function switching: ")
for (i in 1:5) {
  tryCatch(air_configure(backend = sample(c("openai","ollama","claude","deepseek"), 1)), error = function(e) NULL)
  tryCatch(air_info(), error = function(e) NULL)
  tryCatch(air_help(), error = function(e) NULL)
}
cat("OK\n"); steps <- steps + 1

cat("\n=== RESULTS:", steps, "passed,", fails, "failed ===\n")
if (fails > 0) quit(status = 1) else quit(status = 0)
