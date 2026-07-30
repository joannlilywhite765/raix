# raix Chat — Modern Chat GUI for RStudio Viewer
# Sleek, user-friendly design with collapsible sidebar

library(shiny)
library(raix)

ui <- fluidPage(
  tags$head(
    tags$title("raix Chat"),
    tags$style(HTML("
      /* === Reset & Base === */
      * { box-sizing: border-box; }
      body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin:0; padding:0; background:#fff; }
      .container-fluid { padding:0 !important; max-width:100%; height:100vh; }
      .row { margin:0 !important; }
      
      /* === Sidebar === */
      .sidebar-col { 
        background: #1a1a2e; color: #e0e0e0; padding:0; height:100vh; 
        display:flex; flex-direction:column; overflow:hidden;
      }
      .sidebar-header {
        padding:20px 18px 14px; border-bottom:1px solid #2a2a4a;
      }
      .sidebar-header h3 { 
        color:#fff; margin:0 0 4px 0; font-size:20px; font-weight:700; 
        background: linear-gradient(135deg, #667eea, #a78bfa);
        -webkit-background-clip: text; -webkit-text-fill-color: transparent;
      }
      .sidebar-header p { color:#888; font-size:11px; margin:0; }
      
      .sidebar-scroll {
        flex:1; overflow-y:auto; padding:12px 18px;
      }
      .sidebar-scroll label { 
        color:#aaa; font-size:10px; font-weight:600; text-transform:uppercase; 
        letter-spacing:1px; margin:14px 0 4px 0; display:block;
      }
      .sidebar-scroll select, .sidebar-scroll input, .sidebar-scroll textarea {
        width:100%; padding:9px 11px; border-radius:8px; font-size:13px;
        background:#16213e; color:#e0e0e0; border:1px solid #2a2a4a;
        transition: border-color .2s;
      }
      .sidebar-scroll select:focus, .sidebar-scroll input:focus, .sidebar-scroll textarea:focus {
        border-color:#667eea; outline:none; box-shadow:0 0 0 3px rgba(102,126,234,0.1);
      }
      .sidebar-scroll textarea { resize:vertical; min-height:50px; }
      .sidebar-scroll .irs--shiny .irs-bar { background:#667eea; border-color:#667eea; }
      .sidebar-scroll .irs--shiny .irs-handle { border-color:#667eea; }
      
      .sidebar-footer { padding:12px 18px; border-top:1px solid #2a2a4a; }
      .btn { 
        width:100%; padding:10px; border-radius:8px; font-size:13px; font-weight:600;
        border:none; cursor:pointer; transition:all .2s;
      }
      .btn-connect { 
        background: linear-gradient(135deg, #667eea, #764ba2); color:#fff; margin-bottom:6px;
      }
      .btn-connect:hover { opacity:0.9; transform:translateY(-1px); }
      .btn-clear { background:#2a2a4a; color:#999; }
      .btn-clear:hover { background:#333; color:#ccc; }
      
      .status-badge {
        display:flex; align-items:center; gap:6px; padding:8px 12px; 
        border-radius:8px; font-size:12px; margin-top:8px;
      }
      .status-badge.online { background:#0d2818; color:#4ade80; }
      .status-badge.offline { background:#2d1111; color:#f87171; }
      .status-dot { width:8px; height:8px; border-radius:50%; }
      .online .status-dot { background:#4ade80; }
      .offline .status-dot { background:#f87171; }
      
      /* === Main Chat === */
      .chat-col { 
        display:flex; flex-direction:column; height:100vh; background:#f8f9fc; padding:0;
      }
      .chat-header {
        padding:16px 20px; background:#fff; border-bottom:1px solid #e5e7eb;
        display:flex; align-items:center; gap:10px;
      }
      .chat-header h4 { margin:0; font-size:15px; font-weight:600; color:#1a1a2e; flex:1; }
      .chat-header .model-tag {
        font-size:11px; padding:4px 10px; border-radius:20px; 
        background:#ede9fe; color:#7c3aed; font-weight:500;
      }
      
      .messages-area { 
        flex:1; overflow-y:auto; padding:20px; display:flex; flex-direction:column; gap:8px;
      }
      .messages-area::-webkit-scrollbar { width:5px; }
      .messages-area::-webkit-scrollbar-thumb { background:#d1d5db; border-radius:10px; }
      
      .msg-row { display:flex; gap:10px; max-width:85%; animation: fadeIn .2s ease; }
      @keyframes fadeIn { from { opacity:0; transform:translateY(5px); } to { opacity:1; transform:translateY(0); } }
      .msg-row.user { align-self:flex-end; flex-direction:row-reverse; }
      .msg-row.ai { align-self:flex-start; }
      .msg-row.error { align-self:flex-start; }
      
      .msg-avatar {
        width:32px; height:32px; border-radius:50%; display:flex; align-items:center;
        justify-content:center; font-size:14px; flex-shrink:0;
      }
      .user .msg-avatar { background:#667eea; color:#fff; }
      .ai .msg-avatar { background:#e5e7eb; color:#667eea; }
      .error .msg-avatar { background:#fecaca; color:#dc2626; }
      
      .msg-bubble {
        padding:10px 14px; border-radius:14px; font-size:13.5px; line-height:1.55;
      }
      .user .msg-bubble { background:#667eea; color:#fff; border-bottom-right-radius:4px; }
      .ai .msg-bubble { background:#fff; color:#1f2937; border:1px solid #e5e7eb; border-bottom-left-radius:4px; }
      .error .msg-bubble { background:#fef2f2; color:#991b1b; border:1px solid #fecaca; }
      
      .msg-bubble code { 
        background:rgba(0,0,0,0.08); padding:2px 5px; border-radius:4px; font-size:12px; 
      }
      .user .msg-bubble code { background:rgba(255,255,255,0.2); }
      .msg-bubble pre {
        background:#1e1e2e; color:#cdd6f4; padding:12px 14px; border-radius:8px; 
        overflow-x:auto; font-size:12px; line-height:1.5; margin:8px 0;
      }
      .msg-bubble pre code { background:transparent; padding:0; }
      .copy-btn {
        float:right; font-size:10px; padding:2px 8px; border-radius:4px;
        background:rgba(255,255,255,0.1); color:inherit; border:1px solid rgba(255,255,255,0.2);
        cursor:pointer; margin-bottom:6px;
      }
      
      .typing-indicator {
        display:flex; gap:4px; padding:10px 14px;
      }
      .typing-indicator span {
        width:7px; height:7px; border-radius:50%; background:#667eea;
        animation: bounce 1.4s infinite ease-in-out;
      }
      .typing-indicator span:nth-child(2) { animation-delay:0.2s; }
      .typing-indicator span:nth-child(3) { animation-delay:0.4s; }
      @keyframes bounce { 0%,80%,100% { transform:scale(0.6); } 40% { transform:scale(1); } }
      
      /* === Empty State === */
      .empty-state {
        flex:1; display:flex; flex-direction:column; align-items:center;
        justify-content:center; padding:40px; text-align:center;
      }
      .empty-state .logo { font-size:48px; margin-bottom:16px; }
      .empty-state h2 { color:#1a1a2e; margin:0 0 6px 0; font-size:22px; }
      .empty-state p { color:#9ca3af; font-size:13px; max-width:400px; margin:0 0 20px 0; }
      .quick-prompts { display:flex; flex-wrap:wrap; gap:8px; justify-content:center; }
      .quick-pill {
        padding:8px 16px; border-radius:20px; font-size:12px; background:#fff;
        border:1px solid #e5e7eb; color:#6b7280; cursor:pointer; transition:all .15s;
      }
      .quick-pill:hover { border-color:#667eea; color:#667eea; background:#f5f3ff; }
      
      /* === Input Row === */
      .input-row {
        padding:14px 20px; background:#fff; border-top:1px solid #e5e7eb;
        display:flex; gap:10px; align-items:flex-end;
      }
      .input-row textarea {
        flex:1; border-radius:12px; border:1px solid #e5e7eb; padding:10px 14px;
        font-size:13.5px; resize:none; height:44px; max-height:120px; 
        font-family:inherit; transition:border-color .2s; line-height:1.4;
      }
      .input-row textarea:focus { border-color:#667eea; outline:none; box-shadow:0 0 0 3px rgba(102,126,234,0.1); }
      .input-row .btn-send {
        width:44px; height:44px; border-radius:12px; background:#667eea; color:#fff;
        border:none; font-size:16px; cursor:pointer; flex-shrink:0; transition:all .15s;
        display:flex; align-items:center; justify-content:center;
      }
      .input-row .btn-send:hover { background:#5a6fd6; transform:scale(1.03); }
      .input-row .btn-send:disabled { background:#d1d5db; cursor:default; transform:none; }
      .input-hint { font-size:10px; color:#bbb; text-align:center; padding:6px; }
    "))
  ),
  
  fluidRow(
    column(3, class="sidebar-col",
      div(class="sidebar-header",
        h3("raix Chat"),
        p("R + AI + eXperience")
      ),
      div(class="sidebar-scroll",
        tags$label("Provider"),
        selectInput("provider", NULL,
          choices = c("ollama","openai","claude","groq","mistral","deepseek",
                      "together","perplexity","lmstudio","vllm","openrouter","custom"),
          selected = getOption("raix.provider", "ollama")),
        tags$label("Model"),
        textInput("model", NULL, value = getOption("raix.model", "llama3.2"), 
                  placeholder = "e.g. llama3.2, gpt-4o"),
        tags$label("Custom URL (optional)"),
        textInput("base_url", NULL, value = "", placeholder = "Leave empty for default"),
        tags$label("API Key (optional)"),
        passwordInput("api_key", NULL, value = "", placeholder = "Not needed for local models"),
        tags$label("API Format"),
        selectInput("api_format", NULL, 
                    choices = c("auto","openai","ollama","claude"), selected = "auto"),
        tags$label("Temperature"),
        sliderInput("temperature", NULL, min = 0, max = 1, value = 0.2, step = 0.1, ticks = FALSE),
        tags$label("Max Tokens"),
        numericInput("max_tokens", NULL, value = 2048, min = 64, max = 16384, step = 256),
        tags$label("System Prompt"),
        textAreaInput("system_prompt", NULL, value = "", rows = 2, 
                      placeholder = "Custom system prompt (optional)")
      ),
      div(class="sidebar-footer",
        actionButton("apply", "Connect", class = "btn-connect"),
        actionButton("clear", "Clear Chat", class = "btn-clear"),
        uiOutput("connection_status")
      )
    ),
    column(9, class="chat-col",
      div(class="chat-header",
        h4("Chat"),
        uiOutput("current_model_tag")
      ),
      uiOutput("messages_area"),
      div(class="input-row",
        textAreaInput("user_input", NULL, value = "", rows = 1, 
                      placeholder = "Ask raix anything... (Enter to send, Shift+Enter for newline)"),
        actionButton("send", "↑", class = "btn-send")
      ),
      div(class="input-hint", "Enter to send · Shift+Enter for newline")
    )
  ),
  
  # JavaScript for Enter key and auto-scroll
  tags$script(HTML("
    $(document).on('keydown', '#user_input', function(e) {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        $('#send').click();
      }
    });
    
    // Auto-scroll to bottom on new messages
    var observer = new MutationObserver(function() {
      var area = document.querySelector('.messages-area');
      if (area) area.scrollTop = area.scrollHeight;
    });
    $(function() {
      var target = document.querySelector('.messages-area');
      if (target) observer.observe(target, { childList: true, subtree: true });
    });
    
    // Auto-resize textarea
    $(document).on('input', '#user_input', function() {
      this.style.height = 'auto';
      this.style.height = Math.min(this.scrollHeight, 120) + 'px';
    });
  "))
)

server <- function(input, output, session) {
  messages <- reactiveVal(list())
  connected <- reactiveVal(FALSE)
  current_provider <- reactiveVal("ollama")
  current_model <- reactiveVal("llama3.2")
  is_loading <- reactiveVal(FALSE)

  observeEvent(input$apply, {
    fmt <- if (input$api_format == "auto") NULL else input$api_format
    url <- if (nchar(trimws(input$base_url)) > 0) input$base_url else NULL
    key <- if (nchar(trimws(input$api_key)) > 0) input$api_key else NULL
    sp <- if (nchar(trimws(input$system_prompt)) > 0) input$system_prompt else NULL
    
    tryCatch({
      raix_configure(
        provider = input$provider, model = input$model,
        base_url = url, api_key = key, api_format = fmt,
        system_prompt = sp, temperature = input$temperature,
        max_tokens = input$max_tokens
      )
      reachable <- tryCatch(raix_check(), error = function(e) FALSE)
      connected(isTRUE(reachable))
      current_provider(input$provider)
      current_model(input$model)
      
      output$connection_status <- renderUI({
        if (isTRUE(reachable)) {
          div(class = "status-badge online",
            span(class = "status-dot"),
            span(paste(input$provider, "/", input$model))
          )
        } else {
          div(class = "status-badge offline",
            span(class = "status-dot"),
            span("Not reachable")
          )
        }
      })
    }, error = function(e) {
      connected(FALSE)
      output$connection_status <- renderUI({
        div(class = "status-badge offline",
          span(class = "status-dot"),
          span(conditionMessage(e))
        )
      })
    })
  })
  
  output$current_model_tag <- renderUI({
    if (connected()) {
      div(class = "model-tag", paste(current_provider(), "/", current_model()))
    }
  })

  observeEvent(input$send, {
    req(nchar(trimws(input$user_input)) > 0)
    if (!connected()) {
      msgs <- messages()
      msgs <- c(msgs, list(list(
        role = "error", 
        content = "Not connected. Click 'Connect' in the sidebar first."
      )))
      messages(msgs)
      return()
    }
    
    user_msg <- input$user_input
    updateTextAreaInput(session, "user_input", value = "")
    msgs <- messages()
    msgs <- c(msgs, list(list(role = "user", content = user_msg)))
    msgs <- c(msgs, list(list(role = "loading", content = "")))
    messages(msgs)
    is_loading(TRUE)
    
    # Send message (blocks briefly while waiting for AI)
    ai_response <- tryCatch(
      raix_send(user_msg), 
      error = function(e) paste0("ERROR: ", conditionMessage(e))
    )
    is_loading(FALSE)
    msgs <- messages()
    msgs <- msgs[-length(msgs)]   # remove loading indicator
    role <- if (grepl("^ERROR:", ai_response)) "error" else "ai"
    msgs <- c(msgs, list(list(role = role, content = ai_response)))
    messages(msgs)
  })

  observeEvent(input$clear, { messages(list()) })
  
  # Quick prompt clicks from empty state
  observeEvent(input$quick_prompt, {
    updateTextAreaInput(session, "user_input", value = input$quick_prompt)
  })

  output$messages_area <- renderUI({
    msgs <- messages()
    if (length(msgs) == 0) {
      return(
        div(class = "empty-state",
          div(class = "logo", "💬"),
          h2("raix Chat"),
          p("Connect a model in the sidebar, then start chatting. Works with Ollama, OpenAI, Claude, and 10+ other providers."),
          div(class = "quick-prompts",
            tags$button("Explain dplyr::mutate()", class = "quick-pill",
              onclick = sprintf("Shiny.setInputValue('quick_prompt', '%s', {priority:'event'})", 
                               "Explain what dplyr::mutate() does in R")),
            tags$button("Plot mtcars mpg vs wt", class = "quick-pill",
              onclick = sprintf("Shiny.setInputValue('quick_prompt', '%s', {priority:'event'})",
                               "Create a ggplot2 scatter plot of mtcars mpg vs wt colored by cyl")),
            tags$button("Debug my code", class = "quick-pill",
              onclick = sprintf("Shiny.setInputValue('quick_prompt', '%s', {priority:'event'})",
                               "I'm getting an error: 'object not found'. How do I debug this in R?")),
            tags$button("Tutorial: R functions", class = "quick-pill",
              onclick = sprintf("Shiny.setInputValue('quick_prompt', '%s', {priority:'event'})",
                               "Explain how to write custom functions in R with examples"))
          )
        )
      )
    }
    
    tagList(lapply(seq_along(msgs), function(i) {
      m <- msgs[[i]]
      
      if (m$role == "loading") {
        return(div(class = "msg-row ai",
          div(class = "msg-avatar", "⏳"),
          div(class = "msg-bubble",
            div(class = "typing-indicator",
              span(), span(), span()
            )
          )
        ))
      }
      
      cls <- sprintf("msg-row %s", m$role)
      avatar <- switch(m$role, user = "👤", ai = "🤖", error = "⚠️")
      
      # Simple markdown-like rendering
      content <- m$content
      # Escape HTML first
      content <- gsub("&", "&amp;", content)
      content <- gsub("<", "&lt;", content)
      content <- gsub(">", "&gt;", content)
      # Code blocks
      content <- gsub("```(\\w*)\\s*\\n?", "<pre><code>", content)
      content <- gsub("```\\s*", "</code></pre>", content)
      # Inline code
      content <- gsub("`([^`]+)`", "<code>\\1</code>", content)
      # Bold
      content <- gsub("\\*\\*([^*]+)\\*\\*", "<strong>\\1</strong>", content)
      # Newlines
      content <- gsub("\n", "<br/>", content)
      
      div(class = cls,
        div(class = "msg-avatar", avatar),
        div(class = "msg-bubble", HTML(content))
      )
    }))
  })
  
  # Auto-connect on launch
  observe({
    # Try to connect using current raix defaults
    tryCatch({
      if (!connected()) {
        # Load current raix env settings into UI
        updateSelectInput(session, "provider", selected = raix_env$provider)
        updateTextInput(session, "model", value = raix_env$model)
        if (!is.null(raix_env$api_key)) updateTextInput(session, "api_key", value = raix_env$api_key)
        updateSelectInput(session, "api_format", selected = raix_env$api_format)
        updateSliderInput(session, "temperature", value = raix_env$temperature)
        updateNumericInput(session, "max_tokens", value = raix_env$max_tokens)
        
        # Try auto-connect
        reachable <- tryCatch(raix_check(), error = function(e) FALSE)
        if (isTRUE(reachable)) {
          connected(TRUE)
          current_provider(raix_env$provider)
          current_model(raix_env$model)
        }
      }
    }, error = function(e) NULL)
  })
}

shinyApp(ui, server)
