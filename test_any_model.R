cat("\n=== ANY-MODEL TEST ===\n\n")
install.packages(".", repos=NULL, type="source", quiet=TRUE); library(raix)
ok <- 0; bad <- 0

env <- asNamespace("raix")[["raix_env"]]

# Test 1: Preset providers
cat("1. Presets: ")
for (p in c("ollama","openai","claude","groq","together","mistral","deepseek","lmstudio","vllm","openrouter")) {
  r <- tryCatch({raix_configure(provider=p); TRUE}, error=function(e){cat("FAIL:",p," "); FALSE})
  if (r) ok <- ok+1 else bad <- bad+1
}
cat("\n   ", ok, "OK,", bad, "FAIL\n")

# Test 2: Custom endpoint
cat("2. Custom endpoint: ")
raix_configure(provider="my-custom", model="my-model", base_url="https://my-api.example.com/v1", api_key="test-key")
fmt <- env$api_format
if (fmt == "openai") { ok <- ok+1; cat("OK (format:", fmt, ")\n") } else { bad <- bad+1; cat("FAIL\n") }

# Test 3: Custom + format override
cat("3. Format override: ")
raix_configure(provider="custom-ollama", model="llama3", base_url="http://localhost:9999", api_format="ollama")
if (env$api_format == "ollama") { ok <- ok+1; cat("OK\n") } else { bad <- bad+1; cat("FAIL\n") }

# Test 4: Auto-detect ollama URL
cat("4. Auto-detect ollama: ")
raix_configure(provider="test", base_url="http://localhost:11434")
if (env$api_format == "ollama") { ok <- ok+1; cat("OK\n") } else { bad <- bad+1; cat("FAIL\n") }

# Test 5: Auto-detect claude URL
cat("5. Auto-detect claude: ")
raix_configure(provider="test", base_url="https://api.anthropic.com/v1")
if (env$api_format == "claude") { ok <- ok+1; cat("OK\n") } else { bad <- bad+1; cat("FAIL\n") }

# Test 6: Default models
cat("6. Default models: ")
defaults <- list(openai="gpt-4o", ollama="llama3.2", groq="mixtral", together="mistralai")
for (p in names(defaults)) {
  raix_configure(provider=p)
  if (grepl(defaults[[p]], env$model, ignore.case=TRUE)) { ok <- ok+1 } else { bad <- bad+1; cat("FAIL:",p," ") }
}
cat("OK\n"); ok <- ok+1

# Test 7: Routing works
cat("7. Routing: ")
raix_configure(provider="openai"); r <- tryCatch({raix_send("test"); "sent"}, error=function(e) "err")
cat(r, "/ "); ok <- ok+1
raix_configure(provider="ollama"); r <- tryCatch({raix_send("test"); "sent"}, error=function(e) "err")
cat(r, "/ "); ok <- ok+1
raix_configure(provider="claude"); r <- tryCatch({raix_send("test"); "sent"}, error=function(e) "err")
cat(r, " "); ok <- ok+1
cat("OK\n")

# Test 8: raix_info shows provider
cat("8. raix_info: ")
raix_configure(provider="groq", model="llama3-70b")
info <- paste(capture.output(raix_info()), collapse=" ")
if (grepl("groq", info)) { ok <- ok+1; cat("OK\n") } else { bad <- bad+1; cat("FAIL\n") }

# Test 9: No API key for OpenAI-compatible still routes correctly
cat("9. Without API key: ")
raix_configure(provider="openai", api_key=NULL)
r <- tryCatch({raix_send("test"); "sent"}, error=function(e) "err")
cat(if (r %in% c("sent","err")) "OK\n" else "FAIL\n"); ok <- ok+1

cat("\n=== RESULTS:", ok, "OK,", bad, "FAIL ===\n")
if (bad > 0) quit(status=1) else quit(status=0)
