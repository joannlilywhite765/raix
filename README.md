<p align="center">
  <img src="man/figures/hero.svg" alt="raix — English to R Code with AI" width="720">
</p>

<!-- badges: start -->
<p align="center">
  <a href="https://github.com/twomathematicians-code/raix/releases"><img src="https://img.shields.io/github/v/release/twomathematicians-code/raix?color=667eea"></a>
  <a href="https://github.com/twomathematicians-code/raix/actions"><img src="https://img.shields.io/github/actions/workflow/status/twomathematicians-code/raix/ci.yml?branch=main"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green"></a>
  <a href="#"><img src="https://img.shields.io/badge/R-%E2%89%A5%204.0-276DC3?logo=r"></a>
  <a href="#"><img src="https://img.shields.io/badge/functions-34-22c55e"></a>
  <a href="#"><img src="https://img.shields.io/badge/providers-13%2B-6366f1"></a>
</p>
<!-- badges: end -->

<br>

## Describe in English. Get R code. Execute.

raix connects RStudio to any AI model — local or cloud. You describe what you want, it writes the R code. Chat, debug, generate notebooks, run Python, compile C++, execute shell commands. All from your R console.

```r
raix::raix_setup()          # auto-detects Ollama, configures in seconds
raix::raix_dashboard()      # coding workspace in RStudio Viewer
```

<br>

## How it works

```
   "Analyze customer churn"        AI generates complete solution        Run and iterate
   ┌─────────────────────┐         ┌──────────────────────────┐         ┌─────────────────┐
   │ Describe your data  │    →    │ library(tidyverse)       │    →    │ [model summary] │
   │ problem in English  │         │ df <- read_csv(...)      │         │ [ROC curve]     │
   │                     │         │ model <- glm(...)        │         │ [predictions]   │
   └─────────────────────┘         └──────────────────────────┘         └─────────────────┘
```

<br>

## Install

```r
remotes::install_github("twomathematicians-code/raix")
```

<br>

## Core commands

```r
library(raix)
raix_setup()                                           # one click, auto-detects everything

raix_chat()                                            # interactive AI chat in console
raix_dashboard()                                       # coding workspace in RStudio Viewer

raix_explain("sapply(split(mtcars$mpg, mtcars$cyl), mean)")  # explain any R code
raix_generate("Create a heatmap of the correlation matrix")  # English → R code
raix_debug()                                           # run after an error, AI fixes it

raix_solve("Build a churn prediction model from customer data")  # complete solution
raix_notebook("Quarterly sales analysis", output = "report.Rmd") # .Rmd notebook
```

<br>

## Everything raix can do

| | | |
|:--|:--|:--|
| `raix_setup` | Auto-detect & configure | One click |
| `raix_chat` | Interactive AI chat | Console |
| `raix_dashboard` | Coding workspace | Browser |
| `raix_explain` | Explain R code | |
| `raix_generate` | English → R code | |
| `raix_debug` | Fix errors | |
| `raix_document` | roxygen2 docs | |
| `raix_solve` | Complete solutions | Developer Agent |
| `raix_script` | Generate .R files | |
| `raix_notebook` | Generate .Rmd | |
| `raix_project` | Scan project for AI | |
| `raix_terminal` | Shell commands + AI | Compute |
| `raix_python` | Run Python from R | |
| `raix_compile` | C++ with Rcpp | |
| `raix_pipeline` | Multi-step workflows | |
| `raix_benchmark` | Profile & optimize | |
| `raix_parallel` | Auto-parallelize | |
| `raix_analyze` | AI data analysis | |
| `raix_small_mode` | Small LLM optimizer | |

**34 functions. See `raix_help()` for all.**

<br>

## Works with any model

Local or cloud. raix auto-detects your setup and adapts.

| Provider | Type | Setup |
|:---------|:-----|:------|
| Ollama | Local, free | `ollama pull llama3.2` |
| LM Studio | Local, GUI | Download app |
| vLLM | Local, server | Docker/Python |
| OpenAI | Cloud, paid | API key |
| Claude | Cloud, paid | API key |
| Groq | Cloud, free tier | API key |
| DeepSeek | Cloud, cheap | API key |
| Mistral | Cloud | API key |
| Custom | Any endpoint | Your URL |

<br>

## Small model? No problem.

raix detects 7B–9B models (qwen2.5-coder, phi3.5, gemma2, llama3.2) and switches to concise prompts that small models handle reliably. Zero config — just works.

```r
raix_configure(provider = "ollama", model = "qwen2.5-coder:7b")
# ✔ raix configured: ollama / qwen2.5-coder:7b [small-model optimized]
```

<br>

## Contributing

Issues and PRs welcome at [github.com/twomathematicians-code/raix](https://github.com/twomathematicians-code/raix).

<br>

## License

MIT © [Mahesh Solanki](https://github.com/twomathematicians-code)

<br>

<p align="center">
  <sub>Built with R. Powered by AI. Designed for humans.</sub>
</p>
