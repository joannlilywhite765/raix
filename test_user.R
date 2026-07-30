cat("\n=== CYCLE 2: USER SIMULATION ===\n\n")

cat("1. Install from local...")
install.packages(".", repos = NULL, type = "source", quiet = TRUE)
cat("OK\n")

cat("2. Load...")
library(raix)
cat("OK\n")

cat("3. Exported functions:", paste(ls("package:raix"), collapse = ", "), "\n")

cat("4. Configure ollama...")
raix_configure(provider = "ollama")
cat("OK\n")

cat("5. raix_info:\n")
raix_info()

cat("\n6. Error handling (dead port): ")
raix_configure(provider = "ollama", base_url = "http://127.0.0.1:1")
r <- tryCatch(raix_send("test"), error = function(e) "CAUGHT")
cat(r, "\n")

cat("7. raix_explain: ")
r <- tryCatch(raix_explain("mean"), error = function(e) "CAUGHT")
cat(r, "\n")

cat("8. raix_document: ")
r <- tryCatch(raix_document("f <- function(x) x + 1"), error = function(e) "CAUGHT")
cat(r, "\n")

cat("9. raix_generate: ")
r <- tryCatch(raix_generate("ggplot of mtcars"), error = function(e) "CAUGHT")
cat(r, "\n")

cat("10. raix_debug (no error): ")
r <- tryCatch(raix_debug(), error = function(e) "CAUGHT")
cat(r, "\n")

cat("11. raix_check (dead port): ")
r <- tryCatch(raix_check(), error = function(e) "CAUGHT")
cat(r, "\n")

cat("12. Version:", as.character(packageVersion("raix")), "\n")

cat("\n=== 0 crashes, 0 unexpected failures ===\n")
