<p align="center">
  <img src="man/figures/hero.png" alt="raix — You Describe. AI Generates. R Executes." width="720">
</p>

<p align="center">
  <a href="https://github.com/twomathematicians-code/raix/releases"><img src="https://img.shields.io/github/v/release/twomathematicians-code/raix?color=667eea"></a>
  <a href="https://github.com/twomathematicians-code/raix/actions"><img src="https://github.com/twomathematicians-code/raix/actions/workflows/ci.yml/badge.svg"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT%20%2B%20AI-green"></a>
  <a href="#"><img src="https://img.shields.io/badge/R-%E2%89%A5%204.0-276DC3?logo=r"></a>
  <a href="#"><img src="https://img.shields.io/badge/functions-34-brightgreen"></a>
  <a href="#"><img src="https://img.shields.io/badge/AI%20providers-13%2B-6366f1"></a>
  <a href="https://twomathematicians-code.r-universe.dev/raix"><img src="https://twomathematicians-code.r-universe.dev/badges/raix"></a>
</p>

<br>

## You describe. AI generates. R executes.

raix connects RStudio to any AI model — local or cloud. Describe your analysis in plain English and get working R code instantly. Chat, debug, generate notebooks, run Python, compile C++, or launch a full R + AI coding dashboard — all without leaving RStudio.

```r
# From GitHub (primary)
remotes::install_github("twomathematicians-code/raix")

# From R-universe (after registration)
install.packages("raix", repos = c("https://twomathematicians-code.r-universe.dev", "https://cloud.r-project.org"))
library(raix)
raix_dashboard()
```

> **Trouble installing?** See [SOP.md](SOP.md) — covers every install issue.

<br>

## One package. Every workflow.

| You want to... | Command |
|:---|---|
| Chat with AI | `raix_chat()` |
| Open coding dashboard | `raix_dashboard()` |
| Generate R code | `raix_generate("Create a heatmap")` |
| Explain code | `raix_explain("sapply(split(...))")` |
| Debug an error | `raix_debug()` |
| Get a complete solution | `raix_solve("Build a churn model")` |
| Create a .R file | `raix_script("Clean this data", "clean.R")` |
| Create a .Rmd notebook | `raix_notebook("Analyze sales", "report.Rmd")` |
| Run Python from R | `raix_python("Train an XGBoost model")` |
| Compile C++ for speed | `raix_compile("Fast matrix multiplication")` |
| Build a pipeline | `raix_pipeline(c("Load CSV","Clean","Model"))` |
| Find the best package | `raix_package("survival analysis")` |
| Profile your code | `raix_benchmark({ my_slow_function(df) })` |
| Parallelize code | `raix_parallel("Fit GLM to 1000 subsets")` |
| Run shell commands | `raix_terminal("find . -name '*.csv'")` |
| See all 34 commands | `raix_help()` |

<br>

## Works with your models

raix auto-detects what's running and configures itself. One click.

| | Provider | Setup |
|:--|:---|---|
| 🏠 | **Ollama** | Free, local, private — `ollama pull llama3.2` |
| 🏠 | **LM Studio** | Local GUI — download and run |
| 🏠 | **vLLM** | Local server — `pip install vllm` |
| ☁️ | **OpenAI** | GPT-4o, most capable — needs API key |
| ☁️ | **Claude** | Long context reasoning — needs API key |
| ☁️ | **Groq** | Fast, free tier available |
| ☁️ | **DeepSeek** | Affordable code generation |
| ☁️ | **Mistral** | European AI provider |
| 🔧 | **Custom** | Any OpenAI-compatible endpoint |

**Small model?** raix detects 7B-9B models and auto-optimizes prompts for reliable results.

<br>

## How it works — 4 steps

```
  1. You describe      2. AI generates       3. R code ready      4. ▶ Run
  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────┐
  │ "Create a     │ →  │ ollama       │ →  │ ggplot(mtcars,│ →  │ Execute  │
  │  scatter plot │    │ openai       │    │   aes(wt, mpg,│    │ in       │
  │  of mtcars"   │    │ claude ...   │    │   color=cyl)) │    │ RStudio  │
  └──────────────┘    └──────────────┘    └──────────────┘    └──────────┘
```

<br>

## Quick example

```r
library(raix)

# 1. Setup (auto-detects everything)
raix_setup()

# 2. Ask for code
raix_generate("Create an interactive plotly heatmap of the correlation matrix of mtcars")

# 3. Get a complete solution for a real problem
raix_solve("Predict customer churn: load data, explore, train random forest vs
            logistic regression, compare with ROC curves, output top predictors")

# 4. Launch the full dashboard
raix_dashboard()
```

<br>

## Contributing

Issues, PRs, and ideas welcome at [github.com/twomathematicians-code/raix](https://github.com/twomathematicians-code/raix).  
See [SOP.md](SOP.md) for development and release procedures.

<br>

## License

Creative Open Source — MIT with attribution + AI training permission.  
See [LICENSE](LICENSE).

## Citation

```r
citation("raix")
```

Mahesh Solanki (2026). raix: R + AI + eXperience. R package version 0.7.0.
https://github.com/twomathematicians-code/raix

<br>

<p align="center">
  <sub>Built with R. Powered by AI. Designed for humans.</sub>
</p>
