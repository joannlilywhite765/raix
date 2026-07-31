# raix — Standard Operating Procedures

## Table of Contents
1. [Installation](#installation)
2. [First-Time Setup](#first-time-setup)
3. [Daily Usage Workflows](#daily-usage-workflows)
4. [Troubleshooting](#troubleshooting)
5. [Uninstalling / Clean Reinstall](#uninstalling--clean-reinstall)
6. [Contributing](#contributing)
7. [Release Process](#release-process)

---

## Installation

### Prerequisites
- **R >= 4.0** — https://cran.r-project.org
- **Rtools** (Windows only) — https://cran.r-project.org/bin/windows/Rtools/
- **Ollama** (optional, for local models) — https://ollama.com

### Install raix

```r
# Method 1: From GitHub (recommended — always latest)
remotes::install_github("twomathematicians-code/raix")

# Method 2: Specific version
remotes::install_github("twomathematicians-code/raix@v0.7.0")

# Method 3: From downloaded tarball
# Download raix_x.y.z.tar.gz from https://github.com/twomathematicians-code/raix/releases
install.packages("raix_x.y.z.tar.gz", repos = NULL, type = "source")
```

### Verify installation

```r
library(raix)
ls("package:raix")   # Should list 34 functions
raix_help()           # Full command reference
```

### If installation fails

1. **"Rtools is required"** → Install Rtools from https://cran.r-project.org/bin/windows/Rtools/
2. **"there is no package called 'X'"** → `install.packages(c("httr","jsonlite","cli","shiny","testthat"))`
3. **"unable to collate and parse R files"** → Update R to latest version, reinstall
4. **Still failing?** Clean reinstall (see below)

---

## First-Time Setup

### Option A: Auto-detect (recommended)

```r
library(raix)
raix_setup()   # Auto-detects Ollama, picks best model, warms it up
```

What happens:
1. Scans for running Ollama (port 11434)
2. Lists available models, picks best code model (coder > gemma > qwen > phi)
3. Configures automatically
4. Sends warmup request to load model into RAM
5. Ready — `raix_chat()` to start

### Option B: Manual configuration

```r
raix_configure(provider = "ollama", model = "qwen2.5-coder:7b")

# Or for cloud APIs:
raix_configure(provider = "openai", model = "gpt-4o", api_key = "sk-...")
raix_configure(provider = "claude", model = "claude-3-5-sonnet", api_key = "sk-ant-...")
```

### Option C: Custom endpoint

```r
raix_configure(
  provider = "my-server",
  model = "custom-model",
  base_url = "https://api.example.com/v1",
  api_key = "your-key"
)
```

---

## Daily Usage Workflows

### Workflow 1: Chat & Code Generation

```r
library(raix)

# Interactive chat
raix_chat()
# You> Create a ggplot2 scatter plot of mtcars
# raix> library(ggplot2)
# raix> ggplot(mtcars, aes(x=wt, y=mpg, color=factor(cyl))) + geom_point(size=3)

# One-shot code generation
raix_generate("Create a bar chart of diamond cut quality from ggplot2::diamonds")

# Explain code
raix_explain("sapply(split(mtcars$mpg, mtcars$cyl), mean)")

# Debug last error
raix_debug()
```

### Workflow 2: Full Solution Development

```r
# English description → complete R solution
raix_solve("Build a linear model predicting mpg from wt, hp, and cyl in mtcars.
            Include diagnostics plots and model summary.")

# Generate script file (opens in RStudio)
raix_script("Data cleaning pipeline: load CSV, handle NAs, normalize, export",
            output = "clean_data.R")

# Generate R Markdown report
raix_notebook("Exploratory analysis of the palmerpenguins dataset",
              output = "penguin_analysis.Rmd",
              data = palmerpenguins::penguins)
```

### Workflow 3: Project-Aware Development

```r
# Scan your project — raix reads all files for context
raix_project(".")

# Now raix understands your codebase
raix_solve("Add error handling to the data loading function in utils.R")
raix_write("Unit tests for the clean_data() function", 
           file = "tests/test_clean_data.R", type = "code")
```

### Workflow 4: Cross-Language Compute

```r
# Run shell commands with AI interpretation
raix_terminal("find . -name '*.csv' | head -20", explain = TRUE)

# Generate and run Python from R
raix_python("Scrape titles from https://news.ycombinator.com")

# Multi-step pipeline
raix_pipeline(c(
  "Load CSV data with R",
  "Clean and normalize in Python via raix_python",
  "Plot results back in R with ggplot2"
))

# Compile C++ for heavy compute
f <- raix_compile("Fast vector dot product for large numeric vectors")
```

### Workflow 5: Dashboard (RStudio Viewer)

```r
raix_dashboard()   # Opens coding workspace in RStudio Viewer
# Left panel: AI chat
# Right panel: Code editor + Run button + Output viewer
```

---

## Troubleshooting

### Problem: "cannot reach ollama"
**Cause:** Ollama is not running.
```
Solution:
1. Open terminal, run: ollama serve
2. Or start Ollama desktop app
3. Verify: curl http://localhost:11434/api/tags
```

### Problem: "model 'X' not found"
**Cause:** Model not pulled.
```
Solution:
1. List models: ollama list
2. Pull model: ollama pull qwen2.5-coder:7b
3. Or use an existing model: raix_configure(model = "phi3.5")
```

### Problem: Timeout on first call
**Cause:** Model is loading into RAM (cold start).
```
Solution:
1. Wait 30-90 seconds, try again
2. Use smaller model: raix_configure(model = "phi3.5")
3. raix_setup() pre-warms the model — use it
```

### Problem: "Error in parse(...)" during install
**Cause:** Rtools not installed or outdated R version.
```
Solution:
1. Install Rtools: https://cran.r-project.org/bin/windows/Rtools/
2. Update R to 4.0+
3. Try: install.packages("remotes"); remotes::install_github("twomathematicians-code/raix")
```

### Problem: Small model gives poor results
**Cause:** Small models (7B-9B) need optimized prompts.
```
Solution:
raix_small_mode(TRUE)   # Force small-model optimized prompts
raix_configure(model = "phi3.5")  # Try a different model
# For best results with small models:
# - Keep prompts short and specific
# - Ask for code-only output
# - Use 2-3 bullets for explanations
```

---

## Uninstalling / Clean Reinstall

```r
# 1. Remove the package
remove.packages("raix")

# 2. Clean R session
# In RStudio: Session → Restart R

# 3. Reinstall
remotes::install_github("twomathematicians-code/raix")
library(raix)
raix_setup()
```

---

## Contributing

1. Fork the repo: https://github.com/twomathematicians-code/raix
2. Create a branch: `git checkout -b feature/my-feature`
3. Make changes, add tests
4. Run `R CMD check` locally
5. Submit a Pull Request

### Code style
- Follow existing patterns in `R/*.R`
- Add roxygen2 documentation for new functions
- Run `R CMD build` then `R CMD check --no-manual --no-vignettes raix_*.tar.gz`
- Tests go in `tests/testthat/`

---

## Release Process

1. Bump version in `DESCRIPTION`
2. Run `R CMD build .` to create tarball
3. Run `R CMD check --no-manual --no-vignettes raix_*.tar.gz`
4. Ensure CI passes on GitHub Actions
5. Tag: `git tag -a vX.Y.Z -m "vX.Y.Z: Description"`
6. Push: `git push origin main --tags`
7. Create release: `gh release create vX.Y.Z --title "vX.Y.Z — Title" --notes "..." raix_*.tar.gz`
8. Update README badges if needed

---

*Last updated: 2026-07-31*
