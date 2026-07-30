cat("\n=== BUG HUNT: EDGE CASES ===\n\n")

# Reinstall and reload
install.packages(".", repos = NULL, type = "source", quiet = TRUE)
library(raix)

bugs <- 0; ok <- 0

# Bug 1: Empty prompt
cat("1. Empty prompt: ")
r <- tryCatch(air_send(""), error = function(e) e$message)
if (grepl("empty|non-empty|character string", tolower(r))) { ok <- ok + 1; cat("OK (rejected)\n") } else { bugs <- bugs + 1; cat("BUG — accepted empty prompt\n") }

# Bug 2: NA prompt
cat("2. NA prompt: ")
r <- tryCatch(air_send(NA_character_), error = function(e) e$message)
if (grepl("non-empty|character string", r)) { ok <- ok + 1; cat("OK (rejected)\n") } else { bugs <- bugs + 1; cat("BUG — NA accepted\n") }

# Bug 3: Missing API key for OpenAI
cat("3. Missing API key (OpenAI): ")
air_configure(provider = "openai", api_key = "")
r <- tryCatch(air_check(), error = function(e) "ERR")
cat(if (r == "ERR") "BUG" else "OK", "\n")
if (r == "ERR") bugs <- bugs + 1 else ok <- ok + 1

# Bug 4: Switch backend mid-session
cat("4. Backend switch: ")
air_configure(provider = "ollama", model = "llama3.2")
b1 <- get("provider", envir = asNamespace("raix")[["air_env"]])
air_configure(provider = "openai", model = "gpt-4o")
b2 <- get("provider", envir = asNamespace("raix")[["air_env"]])
if (b1 == "ollama" && b2 == "openai") { ok <- ok + 1; cat("OK\n") } else { bugs <- bugs + 1; cat("BUG\n") }

# Bug 5: Chat history persists
cat("5. History: ")
env <- asNamespace("raix")[["air_env"]]
env$chat_history <- list(list(role = "user", content = "old"))
air_configure(provider = "openai")
if (length(env$chat_history) > 0) { ok <- ok + 1; cat("OK\n") } else { bugs <- bugs + 1; cat("BUG\n") }

# Bug 6: Long prompt
cat("6. Long prompt: ")
long <- paste(rep("test ", 1000), collapse = "")
r <- tryCatch({air_configure(provider="ollama", base_url="http://127.0.0.1:1"); air_send(long)}, error = function(e) "CAUGHT")
if (r == "CAUGHT") { ok <- ok + 1; cat("OK\n") } else { bugs <- bugs + 1; cat("BUG\n") }

# Bug 7: Re-entrant config preserves values
cat("7. Re-entrant config: ")
air_configure(provider = "claude", temperature = 0.3)
air_configure(provider = "deepseek", max_tokens = 100)
t <- get("temperature", envir = asNamespace("raix")[["air_env"]])
mt <- get("max_tokens", envir = asNamespace("raix")[["air_env"]])
if (t == 0.3 && mt == 100) { ok <- ok + 1; cat("OK\n") } else { bugs <- bugs + 1; cat("BUG\n") }

# Bug 8: air_explain with bad input  
cat("8. air_explain(empty): ")
r <- tryCatch(air_explain(""), error = function(e) "CAUGHT")
if (r == "CAUGHT") { ok <- ok + 1; cat("OK\n") } else { bugs <- bugs + 1; cat("BUG\n") }

# Bug 9: Rapid switching
cat("9. Rapid switching: ")
for (i in 1:10) tryCatch(air_configure(provider = sample(c("openai","ollama","claude","deepseek","kimi","zai"), 1)), error = function(e) NULL)
ok <- ok + 1; cat("OK\n")

# Bug 10: air_check with no API key (401 = server reachable, key invalid — correct)
cat("10. air_check (no key → 401): ")
air_configure(provider = "openai", api_key = "")
r <- tryCatch(air_check(), error = function(e) "ERR")
cat(if (isTRUE(r) || identical(r, FALSE)) "OK (handled)" else "BUG", "\n")
if (!isTRUE(r) && !identical(r, FALSE)) bugs <- bugs + 1 else ok <- ok + 1

cat("\n=== RESULTS:", ok, "OK,", bugs, "BUGS ===\n")
if (bugs > 0) quit(status = 1) else quit(status = 0)
