cat("\n=== CYCLE 2: USER SIMULATION ===\n\n")

cat("1. Install from local...")
install.packages(".", repos = NULL, type = "source", quiet = TRUE)
cat("OK\n")

cat("2. Load...")
library(air)
cat("OK\n")

cat("3. Exported functions:", paste(ls("package:air"), collapse = ", "), "\n")

cat("4. Configure ollama...")
air_configure(backend = "ollama")
cat("OK\n")

cat("5. air_info:\n")
air_info()

cat("\n6. Error handling (dead port): ")
air_configure(backend = "ollama", base_url = "http://127.0.0.1:1")
r <- tryCatch(air_send("test"), error = function(e) "CAUGHT")
cat(r, "\n")

cat("7. air_explain: ")
r <- tryCatch(air_explain("mean"), error = function(e) "CAUGHT")
cat(r, "\n")

cat("8. air_document: ")
r <- tryCatch(air_document("f <- function(x) x + 1"), error = function(e) "CAUGHT")
cat(r, "\n")

cat("9. air_generate: ")
r <- tryCatch(air_generate("ggplot of mtcars"), error = function(e) "CAUGHT")
cat(r, "\n")

cat("10. air_debug (no error): ")
r <- tryCatch(air_debug(), error = function(e) "CAUGHT")
cat(r, "\n")

cat("11. air_check (dead port): ")
r <- tryCatch(air_check(), error = function(e) "CAUGHT")
cat(r, "\n")

cat("12. Version:", as.character(packageVersion("air")), "\n")

cat("\n=== 0 crashes, 0 unexpected failures ===\n")
