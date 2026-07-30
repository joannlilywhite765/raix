# raix <img src="man/figures/logo.svg" align="right" height="138" alt="raix logo" />

<!-- badges: start -->
[![R CMD Check](https://github.com/twomathematicians-code/raix/actions/workflows/ci.yml/badge.svg)](https://github.com/twomathematicians-code/raix/actions)
[![Version](https://img.shields.io/badge/version-0.5.0-blue)](https://github.com/twomathematicians-code/raix/releases)
[![Release](https://img.shields.io/github/v/release/twomathematicians-code/raix)](https://github.com/twomathematicians-code/raix/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![R 4.0+](https://img.shields.io/badge/R-%E2%89%A5%204.0-276DC3?logo=r)](https://www.r-project.org/)
[![Providers](https://img.shields.io/badge/providers-13%2B-6366f1)](https://github.com/twomathematicians-code/raix#-supported-providers)
[![Small LLM](https://img.shields.io/badge/small_LLM-optimized-22c55e)](https://github.com/twomathematicians-code/raix#-small-model-optimization)
<!-- badges: end -->

<p align="center">
  <img src="man/figures/demo.gif" alt="raix demo" width="720">
</p>

> **AI-powered coding assistant for R. Chat, explain, debug, and generate code — with any model, directly in RStudio.**

---

## Installation

```r
# Install from GitHub
remotes::install_github("twomathematicians-code/raix")
```

**Requirements:** R >= 4.0, [Ollama](https://ollama.com) (optional, for local models).

---

## Quick Start

```r
library(raix)

# One-command setup wizard
raix_setup()

# Or configure manually
raix_configure(provider = "ollama", model = "llama3.2")

# Or start solving immediately
raix_solve("Analyze mtcars: find what predicts mpg, with plots")
```

---

## Features

- **Any model, any provider.** 13+ presets (OpenAI, Claude, Ollama, Groq, Mistral, DeepSeek, and more) plus any custom OpenAI-compatible endpoint.
- **Chat GUI.** Open `raix_gui()` for a full chat window in RStudio Viewer — configure models, switch providers, and chat without limits.
- **Code explanation.** `raix_explain("lapply(mtcars, mean)")` — get plain-English explanations of any R code.
- **Code generation.** `raix_generate("Create an interactive plotly scatter plot")` — turn descriptions into working R code.
- **Error debugging.** `raix_debug()` — run it right after an error and the AI diagnoses the root cause.
- **Roxygen documentation.** `raix_document("f <- function(x) x + 1")` — generate roxygen2 docs automatically.
- **CRAN package search.** `raix_search("time series")` — find relevant packages without leaving R.
- **Data analysis assistant.** `raix_analyze(mtcars)` — get AI-suggested analyses for any data.frame.
- **Script diagnosis.** `raix_diagnose("my_script.R")` — scan for missing packages, syntax errors, and anti-patterns.
- **Google search.** `raix_google("R tidyverse tutorial")` — search the web from R with AI summary.
- **Beginner-friendly.** `raix_setup()` auto-detects your setup — one command, zero configuration.
- **Small-model optimized.** Auto-detects 7B-9B models (qwen2.5-coder, phi3.5, gemma2, llama3.2) and switches to concise, directive prompts that work reliably on local hardware.
- **Developer agent.** `raix_solve("problem")` generates complete R solutions. `raix_script()` and `raix_notebook()` create .R and .Rmd files. `raix_project()` scans your directory for full context.
- **Compute engine.** `raix_terminal()` runs shell commands with AI interpretation. `raix_python()` generates and runs Python from R. `raix_compile()` writes C++ with Rcpp and compiles it. `raix_pipeline()` designs multi-step cross-language workflows.
- **Performance tools.** `raix_benchmark()` times your code and suggests optimizations. `raix_parallel()` rewrites your code for multi-core execution.
- **Privacy-first.** Ollama runs entirely locally — your code never leaves your machine.

---

## Developer Agent

Beyond chat, raix acts as an autonomous coding agent that reads your project, plans solutions, and writes complete code:

```r
# Scan your project — raix reads all .R, .Rmd, and data files
raix_project(".")

# Solve problems end-to-end
raix_solve("Build a random forest model to predict house prices from this dataset",
           data = housing_data)

# Generate complete scripts and notebooks
raix_script("ETL pipeline: clean, transform, and export customer data", 
            output = "etl_pipeline.R")

raix_notebook("Exploratory analysis of sales trends with visualizations",
              output = "sales_analysis.Rmd",
              data = sales_df)

# Find the best package for any task
raix_package("time series forecasting with ARIMA")

# Read files with AI summarization
raix_read("complex_analysis.R", summarize = TRUE)

# Write AI-generated content directly to files
raix_write("A function to validate email addresses with regex",
           file = "R/validate_email.R", type = "code")
```

---

## Small-Model Optimization

raix automatically detects when you're using a small local model (7B-9B parameters) and optimizes prompts for reliable results:

| Aspect | Standard Mode | Small-Model Mode |
|:-------|:-------------|:-----------------|
| System prompt | Verbose, helpful | Direct, instruction-focused |
| Code generation | Code + brief explanation | Code only, no explanation |
| Explanations | Detailed paragraphs | 2-3 bullet points |
| Debugging | Full diagnosis | Cause + fix in 2 lines |
| Temperature | 0.2 | 0.3 (better for small models) |
| Max tokens | 2048 | 1024 |

```r
# Auto-detected (default) — raix detects qwen2.5-coder:7b, phi3.5, gemma2:9b, etc.
raix_configure(provider = "ollama", model = "qwen2.5-coder:7b")
# ✔ raix configured: ollama / qwen2.5-coder:7b [ollama] [small-model optimized]

# Manual control
raix_small_mode(TRUE)   # Force small-model prompts
raix_small_mode(FALSE)  # Force standard prompts
raix_small_mode()       # Check current mode
```

---

## Supported Providers

| Provider | Setup | Best For |
|:---------|:------|:---------|
| **Ollama** | `ollama pull llama3.2` | Free, offline, private |
| **OpenAI** | API key required | Most capable (GPT-4o) |
| **Claude** | API key required | Long context, reasoning |
| **Groq** | Free tier available | Fast inference |
| **Mistral** | API key required | European AI |
| **DeepSeek** | API key required | Affordable code gen |
| **Together AI** | API key required | Open-source models |
| **LM Studio** | Local server | GUI for local models |
| **vLLM** | Local server | High-throughput local |
| **OpenRouter** | API key required | Multi-model gateway |
| **Perplexity** | API key required | Research-focused |
| **Custom** | Any URL | Bring your own endpoint |

All providers that expose an OpenAI-compatible `/v1/chat/completions` endpoint work automatically.

---

## Usage

### Console Chat

```r
library(raix)
raix_configure(provider = "ollama", model = "llama3.2")
raix_chat()
```

### Compute & Cross-Language

```r
# Run shell commands with AI interpretation
raix_terminal("ls -la data/ | wc -l")
raix_terminal("docker ps", explain = TRUE)

# Generate + execute Python from R
raix_python("Scrape this URL and return a pandas DataFrame")

# Design a multi-step pipeline
raix_pipeline(c(
  "Load CSV data",
  "Clean and normalize with R",
  "Train XGBoost in Python",
  "Plot results back in R with ggplot2"
), output = "pipeline.R", execute = TRUE)

# Generate C++ for heavy compute, compile, call from R
raix_compile("Matrix multiplication optimized for large sparse matrices")

# Benchmark and optimize
raix_benchmark({ my_slow_function(large_data) })

# Auto-parallelize
raix_parallel("Apply a GLM to each of 1000 data subsets")

# Full system context for the AI
raix_sysinfo()
```

```r
library(raix)
raix_configure(provider = "ollama", model = "llama3.2")
raix_chat()

You> What does the `%>%` operator do in R?
raix> The `%>%` (pipe) operator comes from the magrittr package...
```

### GUI Chat

```r
raix_gui()  # Opens chat window in RStudio Viewer
```

### Code Assistance

```r
# Explain code
raix_explain("sapply(split(mtcars$mpg, mtcars$cyl), mean)")

# Debug your last error
raix_debug()

# Generate code from description
raix_generate("Create a heatmap of correlation matrix using ggplot2")

# Generate documentation
raix_document("f <- function(x) x^2")
```

### Data & Project Tools

```r
# Search CRAN for packages
raix_search("clustering")

# Get AI analysis suggestions for your dataset
raix_analyze(iris)

# Diagnose your R script
raix_diagnose("analysis.R")

# Search Google from R
raix_google("how to use pivot_longer in R")
```

---

## Configuration

```r
# Use a preset provider
raix_configure(provider = "openai", model = "gpt-4o", api_key = "sk-...")

# Use any custom OpenAI-compatible endpoint
raix_configure(
  provider = "my-api",
  model = "custom-model",
  base_url = "https://api.example.com/v1",
  api_key = "your-key"
)

# Check current configuration
raix_info()

# Test connectivity
raix_check()
```

---

## Contributing

Contributions are welcome! Please open an issue or pull request on [GitHub](https://github.com/twomathematicians-code/raix).

---

## License

MIT — see [LICENSE](LICENSE) for details.

---

Made with :heart: in R. [twomathematicians-code](https://github.com/twomathematicians-code)
