# AIR — Data Analyst Simulation Test
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
cat("2.1 air_configure with preset... ")
r <- tryCatch({air_configure(provider="ollama", model="llama3.2"); "OK"}, error=function(e) paste("ERR:", e$message))
cat(r, "\n")

cat("2.2 air_configure with custom... ")
r <- tryCatch({air_configure(provider="my-custom-api", model="data-analyst-model", base_url="https://api.example.com/v1", api_key="test"); "OK"}, error=function(e) paste("ERR:", e$message))
cat(r, "\n")

cat("2.3 air_info... ")
r <- tryCatch({capture.output(air_info()); "OK"}, error=function(e) paste("ERR:", e$message))
cat(r, "\n")

cat("2.4 air_check (expect failure/no server)... ")
r <- tryCatch({air_check(); "checked"}, error=function(e) paste("ERR:", e$message))
cat(r, "\n")

# ── Code Tools ────────────────────────────────────────────────────
cat("\n═══ STEP 3: Code Development Tools ═══\n")
cat("3.1 air_explain('mean')... ")
r <- tryCatch({air_explain("mean"); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("3.2 air_explain('lapply(mtcars, function(x) mean(x, na.rm=TRUE))')... ")
r <- tryCatch({air_explain("lapply(mtcars, function(x) mean(x, na.rm=TRUE))"); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("3.3 air_explain(empty)... ")
r <- tryCatch({air_explain(""); "OK"}, error=function(e) paste("REJECTED:", substr(e$message,1,50)))
cat(r, "\n")

cat("3.4 air_generate('bar chart of mtcars mpg')... ")
r <- tryCatch({air_generate("Create a bar chart of mtcars mpg by cyl"); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("3.5 air_generate(empty)... ")
r <- tryCatch({air_generate(""); "OK"}, error=function(e) paste("REJECTED:", substr(e$message,1,50)))
cat(r, "\n")

cat("3.6 air_document... ")
r <- tryCatch({air_document("my_func <- function(x, y) { x + y }"); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("3.7 air_document(empty)... ")
r <- tryCatch({air_document(""); "OK"}, error=function(e) paste("REJECTED:", substr(e$message,1,50)))
cat(r, "\n")

cat("3.8 air_debug (no error)... ")
r <- tryCatch({air_debug(); "OK"}, error=function(e) paste("EXPECTED:", substr(e$message,1,50)))
cat(r, "\n")

# ── Data Tools ─────────────────────────────────────────────────────
cat("\n═══ STEP 4: Data Analysis Tools ═══\n")
cat("4.1 air_analyze(mtcars)... ")
r <- tryCatch({air_analyze(mtcars); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("4.2 air_analyze(iris)... ")
r <- tryCatch({air_analyze(iris); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("4.3 air_analyze(NULL)... ")
r <- tryCatch({air_analyze(NULL); "OK"}, error=function(e) paste("REJECTED:", substr(e$message,1,50)))
cat(r, "\n")

cat("4.4 air_analyze(no argument)... ")
r <- tryCatch({air_analyze(); "OK"}, error=function(e) paste("REJECTED:", substr(e$message,1,50)))
cat(r, "\n")

cat("4.5 air_search('time series')... ")
r <- tryCatch({air_search("time series"); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("4.6 air_search('ggplot2')... ")
r <- tryCatch({air_search("ggplot2"); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("4.7 air_search(empty)... ")
r <- tryCatch({air_search(""); "OK"}, error=function(e) paste("REJECTED:", substr(e$message,1,50)))
cat(r, "\n")

# ── Project Tools ──────────────────────────────────────────────────
cat("\n═══ STEP 5: Project Diagnosis ═══\n")
cat("5.1 air_diagnose(current dir)... ")
r <- tryCatch({issues <- air_diagnose("."); paste("OK (", issues, "issues)")}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("5.2 air_diagnose(nonexistent)... ")
r <- tryCatch({air_diagnose("nonexistent_path"); "OK"}, error=function(e) paste("REJECTED:", substr(e$message,1,50)))
cat(r, "\n")

# ── Google Search ──────────────────────────────────────────────────
cat("\n═══ STEP 6: Google Search ═══\n")
cat("6.1 air_google(no browser)... ")
r <- tryCatch({air_google("R data analysis tutorial", open_browser=FALSE); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("6.2 air_google(empty)... ")
r <- tryCatch({air_google(""); "OK"}, error=function(e) paste("REJECTED:", substr(e$message,1,50)))
cat(r, "\n")

# ── Help & Info ────────────────────────────────────────────────────
cat("\n═══ STEP 7: Help System ═══\n")
cat("7.1 air_help... ")
r <- tryCatch({capture.output(air_help()); "OK"}, error=function(e) paste("ERR:", e$message))
cat(r, "\n")

cat("7.2 air_setup non-interactive test... ")
r <- tryCatch({air_configure(provider="ollama"); "OK"}, error=function(e) paste("ERR:", e$message))
cat(r, "\n")

# ── Stress Tests ───────────────────────────────────────────────────
cat("\n═══ STEP 8: Stress & Edge Cases ═══\n")
cat("8.1 Rapid provider switching (10x)... ")
for (i in 1:10) tryCatch(air_configure(provider=sample(c("ollama","openai","groq","together","mistral"),1)), error=function(e) NULL)
cat("OK\n")

cat("8.2 air_send with special characters... ")
r <- tryCatch({air_send("Analysis: mean ± sd, p < 0.05, n = 100"); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("8.3 air_send with long prompt... ")
long <- paste(rep("Analyze this dataset. ", 200), collapse="")
r <- tryCatch({air_send(long); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("8.4 air_generate with complex request... ")
r <- tryCatch({air_generate("Create a Shiny dashboard with ggplot2, plotly, and DT datatable for mtcars"); "OK"}, error=function(e) paste("ERR:", substr(e$message,1,60)))
cat(r, "\n")

cat("\n═══ RESULTS ═══\n")
cat("All tests completed.\n")
cat("Check output above for any ERR lines.\n")
