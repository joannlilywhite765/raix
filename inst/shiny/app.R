# AIR Chat — Shiny GUI
# Opens in RStudio Viewer as a chat panel

library(shiny)
library(air)

ui <- fluidPage(
  tags$head(tags$style(HTML("
    body { font-family: 'Segoe UI', system-ui, sans-serif; margin:0; padding:0; }
    .container-fluid { padding: 0; max-width: 100%; }
    .sidebar { background: #1a1a2e; color: #e2e8f0; padding: 12px; min-height: 100vh; }
    .sidebar h4 { color: #818cf8; margin-top: 12px; font-size: 13px; text-transform: uppercase; letter-spacing: 1px; }
    .sidebar select, .sidebar input { width: 100%; margin-bottom: 6px; font-size: 12px; padding: 4px 6px; border-radius: 4px; border: 1px solid #334155; background: #0f172a; color: #e2e8f0; }
    .sidebar .btn { width: 100%; margin-top: 4px; font-size: 12px; }
    .chat-area { padding: 8px 12px; display: flex; flex-direction: column; height: 100vh; }
    .messages { flex:1; overflow-y: auto; padding: 8px 0; }
    .msg { margin-bottom: 10px; padding: 8px 12px; border-radius: 8px; max-width: 85%; font-size: 13px; line-height: 1.5; white-space: pre-wrap; word-wrap: break-word; }
    .msg-user { background: #2563eb; color: #fff; margin-left: auto; border-bottom-right-radius: 2px; }
    .msg-ai { background: #f1f5f9; color: #1e293b; margin-right: auto; border-bottom-left-radius: 2px; }
    .msg-ai code { background: #e2e8f0; padding: 1px 4px; border-radius: 3px; font-size: 12px; }
    .msg-ai pre { background: #1e293b; color: #e2e8f0; padding: 8px; border-radius: 6px; overflow-x: auto; font-size: 12px; margin: 6px 0; }
    .msg-err { background: #fef2f2; color: #dc2626; margin-right: auto; border: 1px solid #fecaca; font-size: 12px; }
    .input-row { display: flex; gap: 6px; padding: 8px 0; border-top: 1px solid #e2e8f0; }
    .input-row textarea { flex: 1; resize: none; border-radius: 8px; border: 1px solid #cbd5e1; padding: 8px 10px; font-size: 13px; height: 44px; }
    .input-row .btn-primary { border-radius: 8px; padding: 0 16px; font-size: 13px; height: 44px; }
    .status { font-size: 11px; color: #94a3b8; padding: 4px 12px; text-align: center; }
    .provider-badge { display: inline-block; background: #818cf8; color: #fff; font-size: 10px; padding: 2px 8px; border-radius: 10px; font-weight: 600; }
  "))),
  fluidRow(
    column(3, class = "sidebar",
      h4("⚙️ Model"),
      selectInput("provider", NULL,
        choices = c("ollama","openai","claude","groq","together","mistral","deepseek","lmstudio","vllm","openrouter","custom"),
        selected = "ollama", width = "100%"),
      textInput("model", NULL, value = "llama3.2", placeholder = "Model name"),
      textInput("base_url", NULL, value = "", placeholder = "Custom URL (optional)"),
      passwordInput("api_key", NULL, value = "", placeholder = "API key (optional)"),
      selectInput("api_format", NULL, choices = c("auto","openai","ollama","claude"), selected = "auto"),
      h4("🎛️ Settings"),
      sliderInput("temperature", "Temperature", min = 0, max = 1, value = 0.2, step = 0.1, ticks = FALSE),
      numericInput("max_tokens", "Max tokens", value = 2048, min = 64, max = 16384, step = 256),
      textAreaInput("system_prompt", "System prompt", value = "", rows = 3, placeholder = "Custom system prompt..."),
      br(),
      actionButton("apply", "Apply & Connect", class = "btn-primary", width = "100%"),
      actionButton("clear", "Clear Chat", class = "btn-default", width = "100%"),
      br(), br(),
      div(class = "status", textOutput("status"))
    ),
    column(9, class = "chat-area",
      div(class = "messages", uiOutput("messages")),
      div(class = "input-row",
        textAreaInput("user_input", NULL, value = "", rows = 1, placeholder = "Type your message... (Shift+Enter for new line)"),
        actionButton("send", "Send", class = "btn-primary")
      )
    )
  )
)

server <- function(input, output, session) {
  messages <- reactiveVal(list())
  connected <- reactiveVal(FALSE)

  # Apply configuration
  observeEvent(input$apply, {
    fmt <- if (input$api_format == "auto") NULL else input$api_format
    url <- if (nchar(input$base_url) > 0) input$base_url else NULL
    key <- if (nchar(input$api_key) > 0) input$api_key else NULL
    sp <- if (nchar(input$system_prompt) > 0) input$system_prompt else NULL

    tryCatch({
      air_configure(
        provider = input$provider,
        model = input$model,
        base_url = url,
        api_key = key,
        api_format = fmt,
        system_prompt = sp,
        temperature = input$temperature,
        max_tokens = input$max_tokens
      )
      # Test connection
      reachable <- tryCatch(air_check(), error = function(e) FALSE)
      connected(TRUE)
      output$status <- renderText(paste0("✅ Connected: ", input$provider, " / ", input$model))
    }, error = function(e) {
      connected(FALSE)
      output$status <- renderText(paste0("❌ ", conditionMessage(e)))
    })
  })

  # Send message
  observeEvent(input$send, {
    req(nchar(trimws(input$user_input)) > 0)
    user_msg <- input$user_input
    updateTextAreaInput(session, "user_input", value = "")

    msgs <- messages()
    msgs <- c(msgs, list(list(role = "user", content = user_msg)))
    messages(msgs)

    # Call AI
    ai_response <- tryCatch(
      air_send(user_msg),
      error = function(e) paste0("❌ Error: ", conditionMessage(e))
    )
    msgs <- messages()
    role <- if (grepl("^❌", ai_response)) "error" else "ai"
    msgs <- c(msgs, list(list(role = role, content = ai_response)))
    messages(msgs)
  })

  # Enter key sends
  observeEvent(input$user_input_key, {
    if (!is.null(input$user_input_key) && input$user_input_key == "Enter") {
      click("send")
    }
  })

  # Clear chat
  observeEvent(input$clear, { messages(list()) })

  # Render messages
  output$messages <- renderUI({
    msgs <- messages()
    if (length(msgs) == 0) {
      return(div(
        style = "text-align:center; color:#94a3b8; padding:40px;",
        h3("AIR Chat"), p("Configure a model and start chatting!"),
        p(style="font-size:11px;", "Try: 'Explain what dplyr does' or 'Write a ggplot for mtcars'")
      ))
    }
    lapply(seq_along(msgs), function(i) {
      m <- msgs[[i]]
      cls <- switch(m$role, user = "msg msg-user", ai = "msg msg-ai", error = "msg msg-err")
      # Convert markdown code blocks to HTML
      content <- gsub("```r\\s*", "<pre><code>", m$content)
      content <- gsub("```\\s*", "</code></pre>", content)
      content <- gsub("`([^`]+)`", "<code>\\1</code>", content)
      div(class = cls, HTML(content))
    })
  })

  # Auto-connect on start
  air_configure(provider = "ollama", model = "llama3.2")
}

shinyApp(ui, server)
