# raix <img src="man/figures/logo.svg" align="right" height="138" alt="raix logo" />

<!-- badges: start -->
[![R CMD Check](https://github.com/twomathematicians-code/raix/actions/workflows/ci.yml/badge.svg)](https://github.com/twomathematicians-code/raix/actions)
[![Version](https://img.shields.io/badge/version-0.4.1-blue)](https://github.com/twomathematicians-code/raix)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![R 4.0+](https://img.shields.io/badge/R-%E2%89%A5%204.0-276DC3?logo=r)](https://www.r-project.org/)
[![Providers](https://img.shields.io/badge/providers-13%2B-6366f1)](https://github.com/twomathematicians-code/raix#-supported-providers)
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
air_setup()

# Or configure manually
air_configure(provider = "ollama", model = "llama3.2")

# Start chatting
air_chat()
```

---

## Features

- **Any model, any provider.** 13+ presets (OpenAI, Claude, Ollama, Groq, Mistral, DeepSeek, and more) plus any custom OpenAI-compatible endpoint.
- **Chat GUI.** Open `air_gui()` for a full chat window in RStudio Viewer — configure models, switch providers, and chat without limits.
- **Code explanation.** `air_explain("lapply(mtcars, mean)")` — get plain-English explanations of any R code.
- **Code generation.** `air_generate("Create an interactive plotly scatter plot")` — turn descriptions into working R code.
- **Error debugging.** `air_debug()` — run it right after an error and the AI diagnoses the root cause.
- **Roxygen documentation.** `air_document("f <- function(x) x + 1")` — generate roxygen2 docs automatically.
- **CRAN package search.** `air_search("time series")` — find relevant packages without leaving R.
- **Data analysis assistant.** `air_analyze(mtcars)` — get AI-suggested analyses for any data.frame.
- **Script diagnosis.** `air_diagnose("my_script.R")` — scan for missing packages, syntax errors, and anti-patterns.
- **Google search.** `air_google("R tidyverse tutorial")` — search the web from R with AI summary.
- **Beginner-friendly.** `air_setup()` walks first-time users through everything in under 2 minutes.
- **Privacy-first.** Ollama runs entirely locally — your code never leaves your machine.

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
air_configure(provider = "ollama", model = "llama3.2")
air_chat()

You> What does the `%>%` operator do in R?
AIR> The `%>%` (pipe) operator comes from the magrittr package...
```

### GUI Chat

```r
air_gui()  # Opens chat window in RStudio Viewer
```

### Code Assistance

```r
# Explain code
air_explain("sapply(split(mtcars$mpg, mtcars$cyl), mean)")

# Debug your last error
air_debug()

# Generate code from description
air_generate("Create a heatmap of correlation matrix using ggplot2")

# Generate documentation
air_document("f <- function(x) x^2")
```

### Data & Project Tools

```r
# Search CRAN for packages
air_search("clustering")

# Get AI analysis suggestions for your dataset
air_analyze(iris)

# Diagnose your R script
air_diagnose("analysis.R")

# Search Google from R
air_google("how to use pivot_longer in R")
```

---

## Configuration

```r
# Use a preset provider
air_configure(provider = "openai", model = "gpt-4o", api_key = "sk-...")

# Use any custom OpenAI-compatible endpoint
air_configure(
  provider = "my-api",
  model = "custom-model",
  base_url = "https://api.example.com/v1",
  api_key = "your-key"
)

# Check current configuration
air_info()

# Test connectivity
air_check()
```

---

## Contributing

Contributions are welcome! Please open an issue or pull request on [GitHub](https://github.com/twomathematicians-code/raix).

---

## License

MIT — see [LICENSE](LICENSE) for details.

---

Made with :heart: in R. [twomathematicians-code](https://github.com/twomathematicians-code)
