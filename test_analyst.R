# raix — Data Analyst Simulation Test
# Tests every function as a real data analyst would use it.

cat("\n╔══════════════════════════════════════╗\n")
cat("║   DATA ANALYST USER SIMULATION      ║\n")
cat("╚══════════════════════════════════════╝\n\n")

# ── Setup ────────────────────────────────────────────────────────
cat("═══ STEP 1: Installation ═══\n")
cat("1.1 install.packages from source... ")
install.packages(".", repos = NULL, type = "source", quiet = TRUE)
cat("OK\n")

cat("1.2 library(raix)... ")
suppressPackageStartupMessages(library(raix))
cat("OK\n")

cat("1.3 Check version... ")
v <- as.character(packageVersion("raix"))
cat(v, "\n")

cat("1.4 List exported functions... ")
fns <- ls("package:raix")
cat(length(fns), "functions:", paste(fns, collapse=", "), "\n")

# ── Configuration ─────────────────────────────────────────────────
cat("\n═══ STEP 2: Configuration ═══\n")
cat("2.1 raix_configure with preset... ")
r <- tryCatch({raix_configure(provider="ollama", model="llama3.2"); "OK"}, error=function(e) paste("ERR:", e$message))
cat(r, "\n")

cat("2.2 raix_configure with custom... ")
r <- tryCatch({raix_configure(provider="my-custom-api", model="data-analyst-model", base_url="https://api.example.com/v1", api_key="test"); "OK"}, error=function(e) paste("ERR:", e$message))
cat(r, "\n")

cat("2.3 raix_info... ")
r <- tryCatch({capture.output(raix_info()); "OK"}, error=function(e) paste("ERR:", e$message))
cat(r, "\n")

cat("2.4 raix_check (expect failure/no server)... ")
r <- tryCatch({raix_check(); "checked"}, error=function(e) paste("ERR:", e$message))
cat(r, "\n")

# ── Code Tools ────────────────────────────────────────────────────
cat("\n═══ STEP 3: Code Development Tools ═══\n")
cat("3.1 raix_explain('mean')... ")
r <- tryCatch({raix_explain("mean"); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("3.2 raix_explain('lapply(mtcars, function(x) mean(x, na.rm=TRUE))')... ")
r <- tryCatch({raix_explain("lapply(mtcars, function(x) mean(x, na.rm=TRUE))"); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("3.3 raix_explain(empty)... ")
r <- tryCatch({raix_explain(""); "OK"}, error=function(e) paste("REJECTED:", substr(e$message,1,50)))
cat(r, "\n")

cat("3.4 raix_generate('bar chart of mtcars mpg')... ")
r <- tryCatch({raix_generate("Create a bar chart of mtcars mpg by cyl"); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("3.5 raix_generate(empty)... ")
r <- tryCatch({raix_generate(""); "OK"}, error=function(e) paste("REJECTED:", substr(e$message,1,50)))
cat(r, "\n")

cat("3.6 raix_document... ")
r <- tryCatch({raix_document("my_func <- function(x, y) { x + y }"); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("3.7 raix_document(empty)... ")
r <- tryCatch({raix_document(""); "OK"}, error=function(e) paste("REJECTED:", substr(e$message,1,50)))
cat(r, "\n")

cat("3.8 raix_debug (no error)... ")
r <- tryCatch({raix_debug(); "OK"}, error=function(e) paste("EXPECTED:", substr(e$message,1,50)))
cat(r, "\n")

# ── Data Tools ─────────────────────────────────────────────────────
cat("\n═══ STEP 4: Data Analysis Tools ═══\n")
cat("4.1 raix_analyze(mtcars)... ")
r <- tryCatch({raix_analyze(mtcars); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("4.2 raix_analyze(iris)... ")
r <- tryCatch({raix_analyze(iris); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("4.3 raix_analyze(NULL)... ")
r <- tryCatch({raix_analyze(NULL); "OK"}, error=function(e) paste("REJECTED:", substr(e$message,1,50)))
cat(r, "\n")

cat("4.4 raix_analyze(no argument)... ")
r <- tryCatch({raix_analyze(); "OK"}, error=function(e) paste("REJECTED:", substr(e$message,1,50)))
cat(r, "\n")

cat("4.5 raix_search('time series')... ")
r <- tryCatch({raix_search("time series"); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("4.6 raix_search('ggplot2')... ")
r <- tryCatch({raix_search("ggplot2"); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("4.7 raix_search(empty)... ")
r <- tryCatch({raix_search(""); "OK"}, error=function(e) paste("REJECTED:", substr(e$message,1,50)))
cat(r, "\n")

# ── Project Tools ──────────────────────────────────────────────────
cat("\n═══ STEP 5: Project Diagnosis ═══\n")
cat("5.1 raix_diagnose(current dir)... ")
r <- tryCatch({issues <- raix_diagnose("."); paste("OK (", issues, "issues)")}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("5.2 raix_diagnose(nonexistent)... ")
r <- tryCatch({raix_diagnose("nonexistent_path"); "OK"}, error=function(e) paste("REJECTED:", substr(e$message,1,50)))
cat(r, "\n")

# ── Google Search ──────────────────────────────────────────────────
cat("\n═══ STEP 6: Google Search ═══\n")
cat("6.1 raix_google(no browser)... ")
r <- tryCatch({raix_google("R data analysis tutorial", open_browser=FALSE); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("6.2 raix_google(empty)... ")
r <- tryCatch({raix_google(""); "OK"}, error=function(e) paste("REJECTED:", substr(e$message,1,50)))
cat(r, "\n")

# ── Help & Info ────────────────────────────────────────────────────
cat("\n═══ STEP 7: Help System ═══\n")
cat("7.1 raix_help... ")
r <- tryCatch({capture.output(raix_help()); "OK"}, error=function(e) paste("ERR:", e$message))
cat(r, "\n")

cat("7.2 raix_setup non-interactive test... ")
r <- tryCatch({raix_configure(provider="ollama"); "OK"}, error=function(e) paste("ERR:", e$message))
cat(r, "\n")

# ── Stress Tests ───────────────────────────────────────────────────
cat("\n═══ STEP 8: Stress & Edge Cases ═══\n")
cat("8.1 Rapid provider switching (10x)... ")
for (i in 1:10) tryCatch(raix_configure(provider=sample(c("ollama","openai","groq","together","mistral"),1)), error=function(e) NULL)
cat("OK\n")

cat("8.2 raix_send with special characters... ")
r <- tryCatch({raix_send("Analysis: mean ± sd, p < 0.05, n = 100"); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("8.3 raix_send with long prompt... ")
long <- paste(rep("Analyze this dataset. ", 200), collapse="")
r <- tryCatch({raix_send(long); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("8.4 raix_generate with complex request... ")
r <- tryCatch({raix_generate("Create a Shiny dashboard with ggplot2, plotly, and DT datatable for mtcars"); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("\n═══ RESULTS ═══\n")
cat("All tests completed.\n")
cat("Check output above for any ERR lines.\n")
