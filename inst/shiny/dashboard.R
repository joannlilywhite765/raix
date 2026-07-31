# raix Dashboard — Self-Configuring R + AI Workspace
# No console needed — configure, connect, chat, code, execute all inside

library(shiny)
library(raix)

has_ace <- requireNamespace("shinyAce", quietly = TRUE)
has_themes <- requireNamespace("shinythemes", quietly = TRUE)

ui <- fluidPage(
  theme = if (has_themes) shinythemes::shinytheme("flatly") else NULL,
  
  tags$head(
    tags$title("raix Dashboard — R + AI + eXperiment"),
    tags$script(HTML("
      Shiny.addCustomMessageHandler('updateEditor', function(msg) {
        var ed = document.getElementById('code_editor_raw');
        if (ed) { ed.value = msg; Shiny.setInputValue('code_editor_raw', msg); }
      });
      Shiny.addCustomMessageHandler('hideSetup', function(msg) {
        document.getElementById('setup_overlay').classList.remove('show');
      });
      Shiny.addCustomMessageHandler('setConnClass', function(msg) {
        var bar = document.getElementById('conn_bar');
        bar.className = 'conn-bar ' + msg;
      });
      $(document).on('keydown', '#chat_input', function(e) {
        if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); $('#chat_send').click(); }
      });
    ")),
    tags$style(HTML("
      * { box-sizing:border-box; margin:0; }
      body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background:#f0f2f5; }
      
      .app-container { display:flex; height:100vh; }
      
      /* === LEFT PANEL: Chat + Setup === */
      .left-panel { width:340px; min-width:300px; display:flex; flex-direction:column; background:#1a1a2e; color:#e0e0e0; }
      .lp-header { padding:14px 16px; border-bottom:1px solid #2a2a4a; }
      .lp-header h3 { margin:0 0 2px 0; font-size:18px; background:linear-gradient(135deg,#667eea,#a78bfa); -webkit-background-clip:text; -webkit-text-fill-color:transparent; }
      .lp-header .lp-sub { font-size:10px; color:#64748b; }
      
      .lp-chat { flex:1; display:flex; flex-direction:column; overflow:hidden; }
      .lp-messages { flex:1; overflow-y:auto; padding:12px; display:flex; flex-direction:column; gap:8px; }
      .lp-messages::-webkit-scrollbar { width:4px; }
      .lp-messages::-webkit-scrollbar-thumb { background:#333; border-radius:4px; }
      
      .msg { max-width:95%; padding:8px 12px; border-radius:12px; font-size:12px; line-height:1.45; animation:fadeIn .2s; word-wrap:break-word; }
      @keyframes fadeIn { from{opacity:0;transform:translateY(4px);} to{opacity:1;transform:translateY(0);} }
      .msg.user { background:#667eea; color:#fff; align-self:flex-end; border-bottom-right-radius:3px; }
      .msg.ai { background:#16213e; color:#d4d4d8; align-self:flex-start; border-bottom-left-radius:3px; }
      .msg.error { background:#2d1111; color:#f87171; align-self:flex-start; font-size:11px; }
      .msg code { background:rgba(0,0,0,0.2); padding:1px 4px; border-radius:3px; font-size:10px; }
      .msg pre { background:#0a0a1a; padding:8px; border-radius:6px; overflow-x:auto; font-size:10px; margin:4px 0; color:#cdd6f4; }
      
      .lp-input { padding:10px; border-top:1px solid #2a2a4a; }
      .lp-input textarea { width:100%; background:#16213e; color:#e0e0e0; border:1px solid #2a2a4a; border-radius:8px; padding:8px 10px; font-size:12px; resize:none; height:40px; font-family:inherit; }
      .lp-input textarea:focus { border-color:#667eea; outline:none; }
      .lp-input .btn-row { display:flex; gap:4px; margin-top:4px; }
      .lp-input button { flex:1; padding:6px; border-radius:6px; border:none; font-size:11px; cursor:pointer; font-weight:600; }
      .btn-send { background:#667eea; color:#fff; }
      .btn-clear { background:#2a2a4a; color:#999; }
      .btn-send:disabled, .btn-clear:disabled { opacity:0.4; cursor:default; }
      
      /* Connection Bar */
      .conn-bar { padding:8px 14px; font-size:11px; display:flex; align-items:center; gap:8px; border-top:1px solid #2a2a4a; }
      .conn-bar.connected { background:#0d2818; color:#4ade80; }
      .conn-bar.disconnected { background:#2d1111; color:#f87171; }
      .conn-dot { width:8px; height:8px; border-radius:50%; flex-shrink:0; }
      .connected .conn-dot { background:#4ade80; }
      .disconnected .conn-dot { background:#f87171; }
      .conn-bar button { margin-left:auto; padding:3px 8px; border-radius:4px; border:1px solid currentColor; background:transparent; color:inherit; font-size:10px; cursor:pointer; }
      
      /* === RIGHT: Workspace === */
      .right-panel { flex:1; display:flex; flex-direction:column; background:#fff; }
      .rp-toolbar { padding:10px 16px; background:#fafbfc; border-bottom:1px solid #e5e7eb; display:flex; align-items:center; gap:10px; }
      .rp-toolbar .rp-title { font-size:14px; font-weight:600; color:#1a1a2e; }
      .rp-actions { margin-left:auto; display:flex; gap:6px; }
      .rp-actions button { padding:6px 14px; border-radius:6px; font-size:11px; cursor:pointer; border:1px solid #e5e7eb; background:#fff; color:#374151; }
      .rp-actions button:hover { background:#f3f4f6; }
      .btn-run { background:#059669 !important; color:#fff !important; border:none !important; font-weight:600; }
      .btn-run:hover { background:#047857 !important; }
      
      .ws-body { flex:1; display:flex; flex-direction:column; min-height:0; }
      
      /* Code editor area */
      .code-area { flex:1; min-height:150px; position:relative; border-bottom:3px solid #e5e7eb; }
      .code-area .area-label { position:absolute; top:6px; right:12px; font-size:9px; color:#9ca3af; letter-spacing:1px; z-index:5; background:#fff; padding:2px 6px; border-radius:3px; }
      
      /* Output */
      .output-area { flex:1; min-height:120px; overflow-y:auto; padding:16px; background:#fafbfc; }
      .output-area::-webkit-scrollbar { width:4px; }
      .output-area::-webkit-scrollbar-thumb { background:#d1d5db; }
      .out-item { margin-bottom:12px; }
      .out-label { font-size:9px; font-weight:600; color:#9ca3af; text-transform:uppercase; letter-spacing:1px; margin-bottom:4px; }
      .out-text { font-family:'Courier New',monospace; font-size:11px; background:#fff; padding:8px 12px; border-radius:6px; border:1px solid #e5e7eb; white-space:pre-wrap; }
      .out-error { font-family:'Courier New',monospace; font-size:11px; background:#fef2f2; color:#dc2626; padding:8px 12px; border-radius:6px; border:1px solid #fecaca; white-space:pre-wrap; }
      .out-plot { text-align:center; }
      .out-plot img { max-width:100%; border-radius:6px; box-shadow:0 1px 3px rgba(0,0,0,0.08); }
      
      .empty-state { flex:1; display:flex; flex-direction:column; align-items:center; justify-content:center; color:#9ca3af; text-align:center; padding:40px; }
      .empty-state .es-icon { font-size:40px; margin-bottom:12px; }
      .empty-state .es-title { font-size:16px; color:#6b7280; margin-bottom:4px; }
      .empty-state .es-sub { font-size:12px; }
      
      /* Setup overlay */
      .setup-overlay { display:none; position:fixed; top:0; left:0; width:100%; height:100%; background:rgba(0,0,0,0.6); z-index:100; justify-content:center; align-items:center; }
      .setup-overlay.show { display:flex; }
      .setup-card { background:#1a1a2e; border-radius:14px; padding:28px 24px; width:420px; max-height:85vh; overflow-y:auto; color:#e0e0e0; }
      .setup-card h3 { color:#fff; margin:0 0 16px 0; font-size:18px; }
      .setup-card label { font-size:10px; color:#888; text-transform:uppercase; letter-spacing:1px; display:block; margin:12px 0 3px; }
      .setup-card select, .setup-card input { width:100%; padding:8px 10px; border-radius:6px; background:#16213e; color:#e0e0e0; border:1px solid #2a2a4a; font-size:13px; }
      .setup-card select:focus, .setup-card input:focus { border-color:#667eea; outline:none; }
      .setup-card .setup-btns { display:flex; gap:8px; margin-top:18px; }
      .setup-card button { flex:1; padding:10px; border-radius:8px; border:none; font-size:13px; font-weight:600; cursor:pointer; }
      .btn-autodetect { background:#667eea; color:#fff; }
      .btn-autodetect:hover { opacity:0.9; }
      .btn-connect { background:#059669; color:#fff; }
      .btn-connect:hover { opacity:0.9; }
      .btn-cancel { background:#2a2a4a; color:#999; }
      .setup-status { margin-top:12px; font-size:11px; padding:8px 10px; border-radius:6px; }
      .setup-status.ok { background:#0d2818; color:#4ade80; }
      .setup-status.fail { background:#2d1111; color:#f87171; }
    "))
  ),
  
  div(class = "app-container",
    # LEFT PANEL
    div(class = "left-panel",
      div(class = "lp-header",
        h3("raix Chat"),
        div(class = "lp-sub", "R + AI + eXperience")
      ),
      # Connection bar
      div(class = "conn-bar disconnected", id = "conn_bar",
        span(class = "conn-dot"),
        uiOutput("conn_text"),
        tags$button("Setup", onclick = "document.getElementById('setup_overlay').classList.add('show')")
      ),
      # Chat
      div(class = "lp-chat",
        div(class = "lp-messages", uiOutput("chat_messages")),
        div(class = "lp-input",
          textAreaInput("chat_input", NULL, "", rows = 1, placeholder = "Ask raix..."),
          div(class = "btn-row",
            actionButton("chat_send", "Send", class = "btn-send"),
            actionButton("chat_clear", "Clear", class = "btn-clear")
          )
        )
      )
    ),
    
    # RIGHT PANEL
    div(class = "right-panel",
      div(class = "rp-toolbar",
        div(class = "rp-title", "📝 R Code Editor"),
        div(class = "rp-actions",
          actionButton("ws_new", "New"),
          actionButton("ws_run", "▶ Run", class = "btn-run"),
          actionButton("ws_clear", "Clear Output"),
          downloadButton("ws_dl", "⬇ Save .R", style = "padding:6px 14px;font-size:11px;")
        )
      ),
      uiOutput("workspace")
    )
  ),
  
  # Setup overlay
  div(class = "setup-overlay", id = "setup_overlay",
    div(class = "setup-card",
      h3("⚙ Configure raix"),
      tags$label("Provider"),
      selectInput("setup_provider", NULL, 
        choices = c("ollama","openai","claude","groq","mistral","deepseek","lmstudio","vllm","custom"),
        selected = "ollama"),
      tags$label("Model"),
      textInput("setup_model", NULL, value = "llama3.2", placeholder = "e.g. qwen2.5-coder:7b"),
      tags$label("Custom URL (optional)"),
      textInput("setup_url", NULL, "", placeholder = "Leave empty for default"),
      tags$label("API Key (optional)"),
      passwordInput("setup_key", NULL, "", placeholder = "Not needed for local models"),
      div(class = "setup-btns",
        actionButton("setup_auto", "🔍 Auto-Detect", class = "btn-autodetect"),
        actionButton("setup_connect", "Connect", class = "btn-connect"),
        actionButton("setup_cancel", "Cancel", class = "btn-cancel")
      ),
      uiOutput("setup_status")
    )
  )
)

server <- function(input, output, session) {
  # === State ===
  chat_msgs <- reactiveVal(list())
  code_text <- reactiveVal("library(ggplot2)\n\n# Write R code here or ask raix to generate it\n# Click ▶ Run to execute\n\nggplot(mtcars, aes(x = wt, y = mpg, color = factor(cyl))) +\n  geom_point(size = 3) +\n  theme_minimal()")
  console_out <- reactiveVal(list())
  connected <- reactiveVal(FALSE)
  
  # === Auto-detect on launch ===
  observe({
    # Try to auto-detect and connect immediately
    detected <- tryCatch(raix_autodetect(), error = function(e) NULL)
    if (!is.null(detected)) {
      tryCatch({
        raix_configure(provider = detected$provider, model = detected$model, api_key = detected$api_key)
        ok <- tryCatch(raix_check_silent(), error = function(e) FALSE)
        if (isTRUE(ok)) {
          connected(TRUE)
          updateSelectInput(session, "setup_provider", selected = detected$provider)
          updateTextInput(session, "setup_model", value = detected$model)
        }
      }, error = function(e) NULL)
    }
  })
  
  # === Connection UI ===
  output$conn_text <- renderUI({
    if (connected()) {
      span(paste("Connected —", raix_env$provider, "/", raix_env$model))
    } else {
      span("Not connected — click Setup")
    }
  })
  
  observe({
    cls <- if (connected()) "connected" else "disconnected"
    session$sendCustomMessage("setConnClass", cls)
  })
  
  # === Setup Overlay ====
  observeEvent(input$setup_auto, {
    output$setup_status <- renderUI({
      div(class = "setup-status", "Scanning for AI backends...")
    })
    
    detected <- tryCatch(raix_autodetect(), error = function(e) NULL)
    
    if (!is.null(detected)) {
      updateSelectInput(session, "setup_provider", selected = detected$provider)
      updateTextInput(session, "setup_model", value = detected$model)
      output$setup_status <- renderUI({
        div(class = "setup-status ok", 
            paste0("✓ Found: ", detected$provider, " / ", detected$model))
      })
    } else {
      output$setup_status <- renderUI({
        div(class = "setup-status fail", 
            "No backends auto-detected. Is Ollama running? Try manual config.")
      })
    }
  })
  
  observeEvent(input$setup_connect, {
    output$setup_status <- renderUI({
      div(class = "setup-status", "Connecting...")
    })
    
    url <- if (nchar(trimws(input$setup_url)) > 0) input$setup_url else NULL
    key <- if (nchar(trimws(input$setup_key)) > 0) input$setup_key else NULL
    
    result <- tryCatch({
      raix_configure(provider = input$setup_provider, model = input$setup_model,
                     base_url = url, api_key = key)
      ok <- raix_check_silent()
      if (isTRUE(ok)) {
        if (input$setup_provider == "ollama") {
          tryCatch(raix_send("hi"), error = function(e) NULL)
          raix_env$first_call <- FALSE
        }
        connected(TRUE)
        output$setup_status <- renderUI({
          div(class = "setup-status ok", 
              paste0("✓ Connected! ", input$setup_provider, " / ", input$setup_model))
        })
      } else {
        output$setup_status <- renderUI({
          div(class = "setup-status fail", "Backend not reachable. Check URL and try again.")
        })
      }
    }, error = function(e) {
      output$setup_status <- renderUI({
        div(class = "setup-status fail", paste("Error:", conditionMessage(e)))
      })
    })
  })
  
  observeEvent(input$setup_cancel, {
    session$sendCustomMessage("hideSetup", TRUE)
  })
  
  # === Chat ===
  observeEvent(input$chat_send, {
    req(nchar(trimws(input$chat_input)) > 0)
    
    if (!connected()) {
      msgs <- chat_msgs()
      msgs <- c(msgs, list(list(role = "error", 
        content = "Not connected. Click 'Setup' in the bar above to configure raix.")))
      chat_msgs(msgs)
      return()
    }
    
    user_msg <- input$chat_input
    updateTextAreaInput(session, "chat_input", value = "")
    
    msgs <- chat_msgs()
    msgs <- c(msgs, list(list(role = "user", content = user_msg)))
    msgs <- c(msgs, list(list(role = "loading", content = "")))
    chat_msgs(msgs)
    
    ai_response <- tryCatch(raix_send(user_msg), error = function(e) paste0("ERROR: ", conditionMessage(e)))
    
    msgs <- chat_msgs()
    msgs <- msgs[-length(msgs)]
    role <- if (grepl("^ERROR:", ai_response)) "error" else "ai"
    msgs <- c(msgs, list(list(role = role, content = ai_response)))
    chat_msgs(msgs)
    
    # Offer code to editor
    if (grepl("```", ai_response) || grepl("library\\(|ggplot\\(|dplyr::|read\\.csv\\(", ai_response)) {
      extracted <- raix_extract_code(ai_response)
      if (nchar(extracted) > 15) {
        msgs <- chat_msgs()
        msgs <- c(msgs, list(list(role = "ai", content = "💡 _Code ready — click below to open in editor_", code = extracted)))
        chat_msgs(msgs)
      }
    }
  })
  
  observeEvent(input$chat_clear, { chat_msgs(list()) })
  
  output$chat_messages <- renderUI({
    msgs <- chat_msgs()
    if (length(msgs) == 0) {
      return(div(style = "padding:30px 20px;text-align:center;color:#64748b;",
        div(style = "font-size:36px;margin-bottom:10px;", "💬"),
        div(style = "font-size:13px;", "Ask raix to write code, explain concepts, debug errors..."),
        div(style = "font-size:11px;margin-top:8px;color:#475569;", if(connected()) "Try: 'Create a ggplot2 scatter plot'" else "Click Setup above to get started")
      ))
    }
    tagList(lapply(seq_along(msgs), function(i) {
      m <- msgs[[i]]
      if (m$role == "loading") {
        return(div(class = "msg ai", span("Thinking", style = "opacity:0.6"), "..."))
      }
      content <- m$content
      content <- gsub("&", "&amp;", content); content <- gsub("<", "&lt;", content); content <- gsub(">", "&gt;", content)
      content <- gsub("```(\\w*)\\n?", "<pre><code>", content)
      content <- gsub("```", "</code></pre>", content)
      content <- gsub("`([^`]+)`", "<code>\\1</code>", content)
      content <- gsub("\n", "<br/>", content)
      
      tagList(
        div(class = paste0("msg ", m$role), HTML(content),
          if (!is.null(m$code)) {
            tagList(
              tags$button("📋 Open in Editor", style = "margin-top:6px;font-size:10px;padding:4px 8px;border-radius:4px;background:#667eea;color:#fff;border:none;cursor:pointer;",
                onclick = sprintf("Shiny.setInputValue('send_to_editor', '%s', {priority:'event'})",
                  gsub("'", "\\\\'", gsub("\n", "\\\\n", m$code))))
            )
          }
        )
      )
    }))
  })
  
  observeEvent(input$send_to_editor, {
    code_text(input$send_to_editor)
    session$sendCustomMessage("updateEditor", input$send_to_editor)
  })
  
  # === Workspace ===
  output$workspace <- renderUI({
    div(class = "ws-body",
      div(class = "code-area",
        div(class = "area-label", paste0("R CODE  •  ", raix_env$provider, "/", raix_env$model)),
        if (has_ace) {
          shinyAce::aceEditor("code_editor", mode = "r", theme = "monokai",
            value = code_text(), height = "100%", fontSize = 13,
            showPrintMargin = FALSE, tabSize = 2, autoComplete = "live", wordWrap = TRUE)
        } else {
          tags$textarea(id = "code_editor_raw", style = paste0(
            "width:100%;height:100%;border:none;padding:14px;font-family:'Courier New',monospace;",
            "font-size:13px;line-height:1.5;resize:none;background:#1e1e2e;color:#cdd6f4;tab-size:2;"),
            code_text())
        }
      ),
      div(class = "output-area",
        if (length(console_out()) == 0) {
          div(class = "empty-state",
            div(class = "es-icon", "▶"),
            div(class = "es-title", "Run your code"),
            div(class = "es-sub", "Click ▶ Run or ask raix to generate code in the chat")
          )
        } else {
          tagList(lapply(seq_along(console_out()), function(i) {
            o <- console_out()[[i]]
            if (o$type == "plot") {
              div(class = "out-item",
                div(class = "out-label", "Plot"),
                div(class = "out-plot", imageOutput(paste0("plot_", i), height = "auto"))
              )
            } else {
              div(class = "out-item",
                div(class = "out-label", if(o$type == "error") "Error" else "Console"),
                div(class = if(o$type == "error") "out-error" else "out-text", o$content)
              )
            }
          }))
        }
      )
    )
  })
  
  observe({
    if (!is.null(input$code_editor)) code_text(input$code_editor)
    if (!is.null(input$code_editor_raw)) code_text(input$code_editor_raw)
  })
  
  observeEvent(input$ws_run, {
    code <- code_text()
    if (nchar(trimws(code)) == 0) return()
    
    output_list <- list()
    
    # Capture text
    text_out <- tryCatch({
      tc <- textConnection("captured", "w", local = TRUE)
      sink(tc); on.exit({ sink(); close(tc) })
      eval(parse(text = code), envir = globalenv())
      paste(captured, collapse = "\n")
    }, error = function(e) paste("Error:", conditionMessage(e)))
    
    if (nchar(text_out) > 0) {
      output_list <- c(output_list, list(list(
        type = if(grepl("^Error:", text_out)) "error" else "text",
        content = text_out
      )))
    }
    
    # Capture plots
    if (grepl("ggplot|plot\\(|hist\\(|boxplot\\(|barplot\\(", code)) {
      tryCatch({
        tmp <- file.path(tempdir(), paste0("raix_plot_", sample(10000,1), ".png"))
        png(tmp, width = 800, height = 500)
        eval(parse(text = code), envir = globalenv())
        dev.off()
        if (file.exists(tmp) && file.info(tmp)$size > 100) {
          output_list <- c(output_list, list(list(type = "plot", file = tmp)))
        }
      }, error = function(e) NULL)
    }
    
    console_out(output_list)
    
    for (i in seq_along(output_list)) {
      if (output_list[[i]]$type == "plot") {
        local({
          idx <- i
          output[[paste0("plot_", idx)]] <- renderImage({
            list(src = output_list[[idx]]$file, contentType = "image/png", width = "100%")
          }, deleteFile = FALSE)
        })
      }
    }
  })
  
  observeEvent(input$ws_clear, { console_out(list()) })
  
  observeEvent(input$ws_new, {
    code_text("# New script\n\n")
    if (!is.null(input$code_editor_raw)) {
      session$sendCustomMessage("updateEditor", "# New script\n\n")
    }
  })
  
  output$ws_dl <- downloadHandler(
    filename = function() paste0("raix_code_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".R"),
    content = function(file) writeLines(code_text(), file)
  )
}

shinyApp(ui, server)
