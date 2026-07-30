# raix Compute — Terminal, Python, Compile, Pipeline, Benchmark
#
# Extends raix beyond R: interact with CMD, run Python, compile C++,
# design multi-language pipelines, benchmark and optimize code.

#' Execute a shell command and optionally have AI interpret the results
#'
#' Runs any system command, captures stdout/stderr/exit code, and can
#' have the AI explain what happened, suggest fixes for errors, or
#' analyze the output.
#'
#' @param command Shell command to execute
#' @param explain If TRUE, AI explains/interprets the command output
#' @param capture If TRUE, captures and returns output (default: TRUE)
#' @return List with status, stdout, stderr, and optional AI explanation
#' @export
raix_terminal <- function(command, explain = FALSE, capture = TRUE) {
  if (missing(command) || !is.character(command) || nchar(trimws(command)) == 0) {
    stop("command must be a non-empty shell command string")
  }
  
  cli::cli_h2("raix Terminal")
  cli::cli_text("{.code {command}}")
  cat("\n")
  
  # Execute
  result <- tryCatch({
    if (capture) {
      if (requireNamespace("processx", quietly = TRUE)) {
        proc <- processx::run("sh", c("-c", command), error_on_status = FALSE, 
                              spinner = TRUE, timeout = 60)
        list(status = proc$status, stdout = proc$stdout, stderr = proc$stderr)
      } else {
        # Fallback: base R system()
        tmp_stdout <- tempfile(); tmp_stderr <- tempfile()
        status <- system(paste(command, ">", tmp_stdout, "2>", tmp_stderr), 
                        intern = FALSE)
        list(status = status, 
             stdout = paste(readLines(tmp_stdout, warn = FALSE), collapse = "\n"),
             stderr = paste(readLines(tmp_stderr, warn = FALSE), collapse = "\n"))
      }
    } else {
      system(command)
      list(status = 0, stdout = "", stderr = "")
    }
  }, error = function(e) {
    list(status = -1, stdout = "", stderr = conditionMessage(e))
  })
  
  # Display output
  if (nchar(result$stdout) > 0) {
    cat(cli::col_green("--- stdout ---\n"))
    cat(result$stdout, "\n")
  }
  if (nchar(result$stderr) > 0) {
    cat(cli::col_red("--- stderr ---\n"))
    cat(result$stderr, "\n")
  }
  cli::cli_text("Exit code: {result$status}")
  
  # AI explanation
  if (explain && (nchar(result$stdout) > 0 || nchar(result$stderr) > 0)) {
    cat("\n")
    cli::cli_h3("AI Analysis")
    prompt <- paste0(
      "I ran this shell command: ", command, "\n",
      "Exit code: ", result$status, "\n",
      if (nchar(result$stdout) > 0) paste0("stdout:\n", substr(result$stdout, 1, 2000), "\n") else "",
      if (nchar(result$stderr) > 0) paste0("stderr:\n", substr(result$stderr, 1, 2000), "\n") else "",
      if (result$status != 0) "Explain what went wrong and how to fix it." 
      else "Briefly summarize the output."
    )
    explanation <- tryCatch(raix_send(prompt), error = function(e) NULL)
    if (!is.null(explanation)) cat(explanation, "\n")
  }
  
  invisible(result)
}

#' Run Python code from R — generate, execute, return results
#'
#' Describe what you want in Python and raix generates the code,
#' runs it via reticulate or system Python, and returns the output.
#'
#' @param description What you want Python to do (in English)
#' @param code Optional: direct Python code to run (skips generation)
#' @param output Optional .py file path to save the generated code
#' @param return_value If TRUE, attempts to return Python result to R
#' @return Python output or result
#' @export
raix_python <- function(description = NULL, code = NULL, output = NULL, return_value = FALSE) {
  if (is.null(description) && is.null(code)) {
    stop("Provide either description (English task) or code (Python code)")
  }
  
  cli::cli_h2("raix Python")
  
  # Generate code if needed
  if (!is.null(description)) {
    cli::cli_text("Generating Python code for: {description}")
    prompt <- if (raix_env$small_model) {
      paste0("Write Python code. Output ONLY code.\n", description)
    } else {
      paste0("Write a complete Python script for:\n\n", description,
             "\n\nInclude necessary imports. Output ONLY the Python code.")
    }
    py_code <- tryCatch(raix_send(prompt), error = function(e) NULL)
    if (is.null(py_code)) {
      cli::cli_alert_danger("Code generation failed")
      return(invisible(NULL))
    }
    py_code <- raix_extract_code(py_code)
    cat("\n", cli::col_green("Generated Python:"), "\n")
    cat(py_code, "\n\n")
  } else {
    py_code <- code
  }
  
  # Save to file if requested
  if (!is.null(output)) {
    writeLines(py_code, output)
    cli::cli_alert_success("Saved to {.file {output}}")
  }
  
  # Execute
  cli::cli_h3("Executing Python...")
  if (requireNamespace("reticulate", quietly = TRUE) && !return_value) {
    # Use reticulate for inline execution
    result <- tryCatch({
      reticulate::py_run_string(py_code)
      "Python code executed via reticulate"
    }, error = function(e) paste("Error:", conditionMessage(e)))
  } else {
    # Use system Python
    tmp_py <- tempfile(fileext = ".py")
    writeLines(py_code, tmp_py)
    py_cmd <- paste("python3", shQuote(tmp_py))
    if (return_value) py_cmd <- paste(py_cmd, "2>&1")
    
    if (requireNamespace("processx", quietly = TRUE)) {
      proc <- processx::run("sh", c("-c", py_cmd), error_on_status = FALSE, timeout = 120)
      result <- paste(proc$stdout, proc$stderr, sep = "\n")
      cli::cli_text("Exit code: {proc$status}")
    } else {
      result <- system(py_cmd, intern = TRUE)
      result <- paste(result, collapse = "\n")
    }
    unlink(tmp_py)
  }
  
  cat(result, "\n")
  cli::cli_alert_success("Done")
  invisible(result)
}

#' Design and execute a multi-step compute pipeline
#'
#' Define a pipeline as a series of steps. raix generates the code
#' for each step, chains them together, and executes the full workflow.
#' Supports mixing R, Python, and shell commands.
#'
#' @param steps Character vector of step descriptions
#' @param output Optional output file path (.R or .sh)
#' @param execute If TRUE, runs the pipeline after generating
#' @return Pipeline code and results
#' @export
raix_pipeline <- function(steps, output = NULL, execute = FALSE) {
  if (missing(steps) || length(steps) == 0) {
    stop("steps must be a character vector of pipeline steps")
  }
  
  cli::cli_h1("raix Pipeline")
  cli::cli_text("{length(steps)} step(s)")
  
  # Show the plan
  for (i in seq_along(steps)) {
    cli::cli_bullets(c("*" = "Step {i}: {steps[i]}"))
  }
  
  # Build context
  sys_info <- raix_sysinfo()
  context <- paste0(
    "System: ", sys_info$os, ", ", sys_info$cpu_cores, " cores, ",
    sys_info$ram_gb, "GB RAM\n",
    "Working directory: ", getwd(), "\n",
    "R version: ", R.version.string
  )
  
  # Generate pipeline
  steps_text <- paste(sapply(seq_along(steps), function(i) {
    paste0("Step ", i, ": ", steps[i])
  }), collapse = "\n")
  
  prompt <- if (raix_env$small_model) {
    paste0("Create pipeline script for:\n", steps_text, "\n\n",
           context, "\nOutput complete script. Use R for analysis, shell for system tasks.")
  } else {
    paste0("Design a complete compute pipeline for these steps:\n\n", steps_text, "\n\n",
           context, "\n\n",
           "Generate a single R script that executes all steps in sequence. ",
           "Use system2() for shell commands, install missing packages if needed, ",
           "add error handling at each step, and save intermediate results to CSV/RDS. ",
           "Output the complete, ready-to-run R script.")
  }
  
  pipeline <- tryCatch(raix_send(prompt), error = function(e) NULL)
  if (is.null(pipeline)) {
    cli::cli_alert_danger("Pipeline generation failed")
    return(invisible(NULL))
  }
  
  pipeline <- raix_extract_code(pipeline)
  
  cat("\n", cli::col_green("Generated Pipeline:"), "\n")
  cat(pipeline, "\n\n")
  
  # Save
  if (!is.null(output)) {
    writeLines(pipeline, output)
    cli::cli_alert_success("Pipeline saved to {.file {output}}")
  }
  
  # Execute
  if (execute) {
    cli::cli_h3("Executing pipeline...")
    result <- tryCatch({
      eval(parse(text = pipeline), envir = globalenv())
      cli::cli_alert_success("Pipeline complete!")
    }, error = function(e) {
      cli::cli_alert_danger("Pipeline error: {conditionMessage(e)}")
    })
  }
  
  invisible(pipeline)
}

#' Generate and compile high-performance code for R
#'
#' Describe a computation-heavy task and raix generates optimized
#' C++ code with Rcpp bindings. Compiles it and returns an R function
#' you can call directly. For tasks where base R is too slow.
#'
#' @param description What the function should compute
#' @param func_name Name for the compiled R function
#' @param output Optional .cpp file path
#' @return An R function wrapping the compiled C++ code (if compilation succeeds)
#' @export
raix_compile <- function(description, func_name = NULL, output = NULL) {
  if (missing(description) || !is.character(description)) {
    stop("description must describe the computation to optimize")
  }
  
  if (!requireNamespace("Rcpp", quietly = TRUE)) {
    cli::cli_alert_warning("Rcpp not installed. Install with: install.packages('Rcpp')")
    cli::cli_text("Generating C++ code without compilation...")
  }
  
  if (is.null(func_name)) {
    func_name <- make.names(paste0("raix_compiled_", 
                                    format(Sys.time(), "%H%M%S")))
  }
  
  cli::cli_h1("raix Compile")
  cli::cli_text("Task: {description}")
  cli::cli_text("Function name: {func_name}")
  
  prompt <- if (raix_env$small_model) {
    paste0("Write Rcpp C++ function for: ", description, 
           "\nFunction name: ", func_name, "\nOutput ONLY C++ code.")
  } else {
    paste0("Write a high-performance Rcpp C++ function for this task:\n\n",
           description, "\n\n",
           "The function should be named: ", func_name, "\n",
           "Use efficient algorithms, minimize allocations. ",
           "Include // [[Rcpp::export]] before the function. ",
           "Output ONLY the C++ code, ready to sourceCpp().")
  }
  
  cpp_code <- tryCatch(raix_send(prompt), error = function(e) NULL)
  if (is.null(cpp_code)) {
    cli::cli_alert_danger("Code generation failed")
    return(invisible(NULL))
  }
  
  cpp_code <- raix_extract_code(cpp_code)
  
  cat("\n", cli::col_green("Generated C++:"), "\n")
  cat(cpp_code, "\n\n")
  
  if (!is.null(output)) {
    writeLines(cpp_code, output)
    cli::cli_alert_success("Saved to {.file {output}}")
  }
  
  # Try to compile
  if (requireNamespace("Rcpp", quietly = TRUE)) {
    cli::cli_h3("Compiling...")
    tmp_cpp <- tempfile(fileext = ".cpp")
    writeLines(cpp_code, tmp_cpp)
    
    compiled <- tryCatch({
      Rcpp::sourceCpp(tmp_cpp)
      cli::cli_alert_success("Compiled! Function '{func_name}' is now available.")
      get(func_name, envir = globalenv())
    }, error = function(e) {
      cli::cli_alert_danger("Compilation failed: {conditionMessage(e)}")
      cat("\nFix with: raix_debug()\n")
      NULL
    })
    unlink(tmp_cpp)
    return(invisible(compiled))
  }
  
  invisible(cpp_code)
}

#' Benchmark R code and get AI optimization suggestions
#'
#' Times your code, identifies bottlenecks, and provides
#' AI-generated suggestions for making it faster.
#'
#' @param expr An R expression to benchmark (quoted)
#' @param iterations Number of iterations for timing
#' @return Benchmark results with AI suggestions (invisibly)
#' @export
raix_benchmark <- function(expr, iterations = 10) {
  expr <- substitute(expr)
  if (is.null(expr)) stop("Provide an R expression to benchmark")
  
  cli::cli_h2("raix Benchmark")
  
  # Time it
  times <- numeric(iterations)
  for (i in seq_len(iterations)) {
    times[i] <- system.time(eval(expr, envir = parent.frame()))["elapsed"]
  }
  
  cli::cli_h3("Results ({iterations} iterations)")
  cli::cli_bullets(c(
    "*" = "Mean: {round(mean(times), 4)}s",
    "*" = "Median: {round(median(times), 4)}s",
    "*" = "Min: {round(min(times), 4)}s",
    "*" = "Max: {round(max(times), 4)}s",
    "*" = "Total: {round(sum(times), 2)}s"
  ))
  
  # AI analysis
  prompt <- paste0(
    "This R code takes ", round(mean(times), 4), "s per run (", iterations, 
    " iterations):\n\n```r\n", paste(deparse(expr), collapse = "\n"), 
    "\n```\n\n",
    if (raix_env$small_model) {
      "Suggest 1-2 specific optimizations. Be brief."
    } else {
      "Analyze this code for performance bottlenecks. Suggest specific, ",
      "concrete optimizations with code examples. Consider: vectorization, ",
      "pre-allocation, avoiding copies, using data.table, parallelization."
    }
  )
  
  suggestion <- tryCatch(raix_send(prompt), error = function(e) NULL)
  if (!is.null(suggestion)) {
    cat("\n", cli::col_green("Optimization Suggestions:"), "\n")
    cat(suggestion, "\n")
  }
  
  invisible(list(mean = mean(times), median = median(times), 
                 times = times, suggestion = suggestion))
}

#' Parallelize R code with AI assistance
#'
#' Given a description of a computation, raix rewrites it using
#' future/furrr/parallel for multi-core execution.
#'
#' @param description What computation to parallelize
#' @param output Optional .R file to save the parallelized code
#' @return Parallelized R code (invisibly)
#' @export
raix_parallel <- function(description, output = NULL) {
  if (missing(description) || !is.character(description)) {
    stop("description must describe the computation to parallelize")
  }
  
  cli::cli_h2("raix Parallel")
  
  cores <- parallel::detectCores()
  cli::cli_text("Available cores: {cores}")
  
  prompt <- if (raix_env$small_model) {
    paste0("Rewrite this for parallel execution (", cores, " cores). Use future/furrr.\n",
           description, "\nOutput ONLY parallelized R code.")
  } else {
    paste0("Rewrite this computation for parallel execution on ", cores, " cores:\n\n",
           description, "\n\n",
           "Use the 'future' and 'furrr' packages. Include:\n",
           "- plan(multisession) setup\n",
           "- future_map() for loops over data\n",
           "- Proper error handling per worker\n",
           "- Progress reporting if applicable\n",
           "Output the complete parallelized R code.")
  }
  
  result <- tryCatch(raix_send(prompt), error = function(e) NULL)
  if (is.null(result)) {
    cli::cli_alert_danger("Generation failed")
    return(invisible(NULL))
  }
  
  result <- raix_extract_code(result)
  cat("\n", result, "\n")
  
  if (!is.null(output)) {
    writeLines(result, output)
    cli::cli_alert_success("Saved to {.file {output}}")
  }
  
  invisible(result)
}

#' Gather comprehensive system information for AI context
#'
#' Collects CPU, RAM, OS, GPU, R version, and installed packages.
#' Used internally to give the AI full context about your compute environment.
#'
#' @return List of system information (invisibly)
#' @export
raix_sysinfo <- function() {
  info <- list()
  
  # OS
  info$os <- paste(R.version$os, R.version$platform)
  info$r_version <- R.version.string
  
  # CPU
  if (.Platform$OS.type == "windows") {
    info$cpu_cores <- as.integer(Sys.getenv("NUMBER_OF_PROCESSORS", "4"))
    info$cpu_name <- tryCatch(
      system("wmic cpu get name 2>nul", intern = TRUE)[2], 
      error = function(e) "Unknown")
  } else {
    info$cpu_cores <- tryCatch(
      as.integer(system("nproc 2>/dev/null", intern = TRUE)),
      error = function(e) parallel::detectCores())
    info$cpu_name <- tryCatch(
      system("lscpu 2>/dev/null | grep 'Model name' | cut -d: -f2", intern = TRUE),
      error = function(e) "Unknown")
  }
  
  # RAM
  if (.Platform$OS.type == "windows") {
    mem <- tryCatch({
      out <- system("wmic OS get TotalVisibleMemorySize /Value 2>nul", intern = TRUE)
      as.numeric(gsub("\\D", "", out[grep("TotalVisibleMemorySize", out)])) / 1024
    }, error = function(e) 8)
    info$ram_gb <- round(mem, 1)
  } else {
    info$ram_gb <- tryCatch({
      mem_kb <- as.numeric(system("grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}'", intern = TRUE))
      round(mem_kb / 1024 / 1024, 1)
    }, error = function(e) 8)
  }
  
  # GPU
  info$gpu <- tryCatch({
    if (.Platform$OS.type == "windows") {
      system("wmic path win32_VideoController get name 2>nul", intern = TRUE)[2:3]
    } else {
      system("lspci 2>/dev/null | grep -i vga | head -1", intern = TRUE)
    }
  }, error = function(e) "Unknown")
  
  # Python
  info$python <- tryCatch({
    ver <- system("python3 --version 2>&1", intern = TRUE)
    if (length(ver) > 0) ver[1] else "Not found"
  }, error = function(e) "Not found")
  
  # R packages
  info$r_packages_count <- nrow(installed.packages())
  info$key_packages <- head(rownames(installed.packages()), 30)
  
  # Disk
  info$wd <- getwd()
  info$wd_space <- tryCatch({
    df <- system(if (.Platform$OS.type == "windows") {
      paste("wmic LogicalDisk where \"DeviceID='", substr(getwd(), 1, 2), "'\" get FreeSpace /Value 2>nul", sep = "")
    } else {
      "df -h . 2>/dev/null | tail -1"
    }, intern = TRUE)
    df
  }, error = function(e) "Unknown")
  
  # Display
  cli::cli_h2("System Information")
  cli::cli_bullets(c(
    "*" = "OS: {info$os}",
    "*" = "CPU: {info$cpu_cores} cores | {trimws(info$cpu_name[1])}",
    "*" = "RAM: {info$ram_gb} GB",
    "*" = "GPU: {trimws(info$gpu[1])}",
    "*" = "Python: {info$python}",
    "*" = "R packages: {info$r_packages_count}",
    "*" = "WD: {info$wd}"
  ))
  
  invisible(info)
}

#' Run any script file and capture output
#'
#' Auto-detects language from file extension (.py, .sh, .R, .js, .cpp)
#' and executes with the appropriate runtime.
#'
#' @param file Path to script file
#' @param args Additional command-line arguments
#' @return Execution output (invisibly)
#' @export
raix_run <- function(file, args = NULL) {
  if (!file.exists(file)) stop("File not found: ", file)
  
  ext <- tolower(tools::file_ext(file))
  
  runners <- list(
    r = "Rscript",
    R = "Rscript",
    py = "python3",
    sh = "bash",
    bash = "bash",
    js = "node",
    pl = "perl",
    rb = "ruby"
  )
  
  runner <- runners[[ext]]
  if (is.null(runner)) stop("Unknown file type: .", ext)
  
  cli::cli_h2("raix Run: {basename(file)}")
  
  cmd <- paste(runner, shQuote(file), paste(args, collapse = " "))
  cli::cli_text("{.code {cmd}}")
  cat("\n")
  
  result <- raix_terminal(cmd, explain = FALSE)
  invisible(result)
}