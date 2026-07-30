# AIR Chat — Shiny GUI for RStudio Viewer
# v0.4.1 — Fixed Enter-to-send, error handling, responsive layout

library(shiny)
library(raix)

ui <- fluidPage(
  tags$head(tags$style(HTML("
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif; margin:0; padding:0; }
    .container-fluid { padding: 0; max-width: 100%; }
    .sidebar { background: #0f172a; color: #e2e8f0; padding: 10px; min-height: 100vh; overflow-y: auto; }
    .sidebar h4 { color: #818cf8; margin: 10px 0 4px 0; font-size: 11px; text-transform: uppercase; letter-spacing: 1.5px; }
    .sidebar select, .sidebar input { width: 100%; margin-bottom: 5px; font-size: 12px; padding: 5px 7px; border-radius: 6px; border: 1px solid #334155; background: #1e293b; color: #e2e8f0; }
    .sidebar .btn { width: 100%; margin-top: 3px; font-size: 12px; border-radius: 6px; }
    .sidebar .btn-primary { background: #2563eb; border-color: #2563eb; }
    .sidebar .btn-primary:hover { background: #1d4ed8; }
    .chat-area { padding: 0; display: flex; flex-direction: column; height: 100vh; background: #fff; }
    .messages { flex:1; overflow-y: auto; padding: 12px 16px; }
    .msg { margin-bottom: 8px; padding: 10px 14px; border-radius: 12px; max-width: 85%; font-size: 13px; line-height: 1.5; white-space: pre-wrap; word-wrap: break-word; animation: fadeIn 0.2s; }
    @keyframes fadeIn { from { opacity:0; transform:translateY(4px); } to { opacity:1; transform:translateY(0); } }
    .msg-user { background: #2563eb; color: #fff; margin-left: auto; border-bottom-right-radius: 3px; }
    .msg-ai { background: #f1f5f9; color: #1e293b; margin-right: auto; border-bottom-left-radius: 3px; }
    .msg-ai code { background: #e2e8f0; padding: 1px 5px; border-radius: 3px; font-size: 12px; }
    .msg-ai pre { background: #1e293b; color: #e2e8f0; padding: 10px; border-radius: 8px; overflow-x: auto; font-size: 12px; margin: 8px 0; }
    .msg-err { background: #fef2f2; color: #dc2626; margin-right: auto; border: 1px solid #fecaca; font-size: 12px; }
    .input-row { display: flex; gap: 8px; padding: 10px 16px; border-top: 1px solid #e2e8f0; background: #fafbfc; }
    .input-row textarea { flex: 1; resize: none; border-radius: 10px; border: 1px solid #cbd5e1; padding: 10px 12px; font-size: 13px; height: 46px; }
    .input-row textarea:focus { border-color: #2563eb; box-shadow: 0 0 0 2px rgba(37,99,235,0.2); outline: none; }
    .input-row .btn { border-radius: 10px; padding: 0 18px; font-size: 13px; height: 46px; }
    .status-bar { font-size: 11px; color: #94a3b8; padding: 8px 16px; text-align: center; border-top: 1px solid #e2e8f0; background: #fafbfc; }
    .status-bar .connected { color: #059669; font-weight: 600; }
    .status-bar .disconnected { color: #dc2626; }
    .empty-state { text-align:center; color:#94a3b8; padding:60px 20px; }
    .empty-state h3 { color: #64748b; margin-bottom: 8px; }
    .empty-state p { font-size: 12px; }
  "))),
  fluidRow(
    column(3, class = "sidebar",
      h4("⚙️ Provider & Model"),
      selectInput("provider", NULL,
        choices = c("ollama","openai","claude","groq","together","mistral","deepseek","lmstudio","vllm","openrouter","custom"),
        selected = "ollama"),
      textInput("model", NULL, value = "llama3.2", placeholder = "Model name"),
      textInput("base_url", NULL, value = "", placeholder = "Custom URL (optional)"),
      passwordInput("api_key", NULL, value = "", placeholder = "API key (optional)"),
      selectInput("api_format", NULL, choices = c("auto","openai","ollama","claude"), selected = "auto"),
      h4("🎛️ Parameters"),
      sliderInput("temperature", "Temperature", min = 0, max = 1, value = 0.2, step = 0.1, ticks = FALSE),
      numericInput("max_tokens", "Max tokens", value = 2048, min = 64, max = 16384, step = 256),
      textAreaInput("system_prompt", "System prompt", value = "", rows = 2, placeholder = "Custom prompt..."),
      actionButton("apply", "Apply & Connect", class = "btn-primary"),
      actionButton("clear", "Clear Chat", class = "btn-default", style = "margin-top:2px"),
      div(class = "status-bar", style = "margin-top:10px; background:transparent; border:none; padding:6px 0;",
        htmlOutput("status"))
    ),
    column(9, class = "chat-area",
      div(class = "messages", uiOutput("messages")),
      div(class = "input-row",
        textAreaInput("user_input", NULL, value = "", rows = 1, placeholder = "Message AIR... (Enter to send)"),
        actionButton("send", "Send", class = "btn-primary")
      )
    )
  ),
  tags$script(HTML("
    $(document).on('keydown', '#user_input', function(e) {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        $('#send').click();
      }
    });
  "))
)

server <- function(input, output, session) {
  messages <- reactiveVal(list())
  connected <- reactiveVal(FALSE)

  observeEvent(input$apply, {
    fmt <- if (input$api_format == "auto") NULL else input$api_format
    url <- if (nchar(trimws(input$base_url)) > 0) input$base_url else NULL
    key <- if (nchar(trimws(input$api_key)) > 0) input$api_key else NULL
    sp <- if (nchar(trimws(input$system_prompt)) > 0) input$system_prompt else NULL

    tryCatch({
      air_configure(provider = input$provider, model = input$model,
        base_url = url, api_key = key, api_format = fmt,
        system_prompt = sp, temperature = input$temperature,
        max_tokens = input$max_tokens)
      reachable <- tryCatch(air_check(), error = function(e) FALSE)
      connected(TRUE)
      output$status <- renderUI({
        HTML(paste0('<span class="connected">●</span> ', input$provider, ' / ', input$model))
      })
    }, error = function(e) {
      connected(FALSE)
      output$status <- renderUI({
        HTML(paste0('<span class="disconnected">●</span> ', conditionMessage(e)))
      })
    })
  })

  observeEvent(input$send, {
    req(nchar(trimws(input$user_input)) > 0)
    user_msg <- input$user_input
    updateTextAreaInput(session, "user_input", value = "")
    msgs <- messages()
    msgs <- c(msgs, list(list(role = "user", content = user_msg)))
    messages(msgs)

    ai_response <- tryCatch(air_send(user_msg), error = function(e) paste0("❌ ", conditionMessage(e)))
    msgs <- messages()
    role <- if (grepl("^❌", ai_response)) "error" else "ai"
    msgs <- c(msgs, list(list(role = role, content = ai_response)))
    messages(msgs)
  })

  observeEvent(input$clear, { messages(list()) })

  output$messages <- renderUI({
    msgs <- messages()
    if (length(msgs) == 0) {
      return(div(class = "empty-state",
        h3("💬 AIR Chat"), p("Configure a model and start chatting."),
        p("Try: 'Explain dplyr', 'Plot mtcars mpg vs wt', 'Debug my code'")
      ))
    }
    lapply(seq_along(msgs), function(i) {
      m <- msgs[[i]]
      cls <- switch(m$role, user = "msg msg-user", ai = "msg msg-ai", error = "msg msg-err")
      content <- gsub("```(r|python|sql)?\\s*", "<pre><code>", m$content)
      content <- gsub("```\\s*", "</code></pre>", content)
      content <- gsub("`([^`]+)`", "<code>\\1</code>", content)
      div(class = cls, HTML(content))
    })
  })
}

shinyApp(ui, server)
