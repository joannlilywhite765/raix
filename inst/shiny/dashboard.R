# raix Dashboard — R + AI Coding Workspace
# Chat with AI, generate R code, execute, see outputs — all in one place
# Launch: raix_dashboard()

library(shiny)
library(raix)

# Check for optional packages
has_ace <- requireNamespace("shinyAce", quietly = TRUE)
has_themes <- requireNamespace("shinythemes", quietly = TRUE)

ui <- fluidPage(
  theme = if (has_themes) shinythemes::shinytheme("flatly") else NULL,
  
  tags$head(
    tags$title("raix Dashboard — R + AI + eXperiment"),
    tags$style(HTML("
      * { box-sizing:border-box; }
      body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; margin:0; }
      
      .main-container { display:flex; height:100vh; overflow:hidden; }
      
      /* === LEFT: Chat Panel === */
      .chat-panel {
        width:320px; min-width:280px; background:#1a1a2e; color:#e0e0e0;
        display:flex; flex-direction:column; border-right:1px solid #2a2a4a;
      }
      .chat-header {
        padding:14px 16px; background:linear-gradient(135deg,#1a1a2e,#16213e);
        border-bottom:1px solid #2a2a4a;
      }
      .chat-header h3 { 
        margin:0; font-size:16px; 
        background: linear-gradient(135deg, #667eea, #a78bfa);
        -webkit-background-clip:text; -webkit-text-fill-color:transparent;
      }
      .chat-header .model-badge {
        font-size:10px; padding:2px 8px; border-radius:10px;
        background:#16213e; color:#818cf8; margin-top:4px; display:inline-block;
      }
      .chat-messages {
        flex:1; overflow-y:auto; padding:12px; display:flex; flex-direction:column; gap:8px;
      }
      .chat-messages::-webkit-scrollbar { width:4px; }
      .chat-messages::-webkit-scrollbar-thumb { background:#333; border-radius:4px; }
      
      .c-msg { max-width:95%; padding:8px 12px; border-radius:12px; font-size:12.5px; line-height:1.45; animation:fadeIn .2s; }
      @keyframes fadeIn { from{opacity:0;transform:translateY(4px);} to{opacity:1;transform:translateY(0);} }
      .c-msg.user { background:#667eea; color:#fff; align-self:flex-end; border-bottom-right-radius:4px; }
      .c-msg.ai { background:#16213e; color:#e0e0e0; align-self:flex-start; border-bottom-left-radius:4px; }
      .c-msg.error { background:#2d1111; color:#f87171; align-self:flex-start; font-size:11px; }
      .c-msg .c-label { font-size:9px; font-weight:600; text-transform:uppercase; letter-spacing:1px; margin-bottom:2px; opacity:0.6; }
      .c-msg code { background:rgba(0,0,0,0.2); padding:1px 4px; border-radius:3px; font-size:11px; }
      .c-msg pre { background:#0a0a1a; padding:8px; border-radius:6px; overflow-x:auto; font-size:11px; margin:4px 0; }
      
      .chat-input-row { padding:10px; border-top:1px solid #2a2a4a; }
      .chat-input-row textarea {
        width:100%; background:#16213e; color:#e0e0e0; border:1px solid #2a2a4a;
        border-radius:8px; padding:8px 10px; font-size:12px; resize:none; height:40px;
        font-family:inherit;
      }
      .chat-input-row textarea:focus { border-color:#667eea; outline:none; }
      
      .chat-actions { display:flex; gap:4px; margin-top:6px; }
      .chat-actions button { 
        flex:1; padding:6px; border-radius:6px; border:none; font-size:11px; cursor:pointer; 
      }
      .btn-send { background:#667eea; color:#fff; }
      .btn-clear { background:#2a2a4a; color:#999; }
      .btn-config { background:transparent; color:#818cf8; border:1px solid #333 !important; }
      
      .chat-status { 
        padding:6px 12px; font-size:10px; text-align:center; border-top:1px solid #2a2a4a; 
      }
      .chat-status.online { color:#4ade80; }
      .chat-status.offline { color:#f87171; }
      
      /* === RIGHT: Workspace === */
      .workspace { 
        flex:1; display:flex; flex-direction:column; background:#f8f9fc; 
      }
      .ws-toolbar {
        padding:8px 14px; background:#fff; border-bottom:1px solid #e5e7eb;
        display:flex; align-items:center; gap:10px;
      }
      .ws-toolbar .ws-title { font-size:14px; font-weight:600; color:#1a1a2e; }
      .ws-toolbar .ws-actions { margin-left:auto; display:flex; gap:6px; }
      .ws-toolbar button {
        padding:5px 12px; border-radius:6px; border:1px solid #e5e7eb; 
        background:#fff; font-size:11px; cursor:pointer; color:#374151;
      }
      .ws-toolbar button:hover { background:#f3f4f6; }
      .btn-execute { background:#059669 !important; color:#fff !important; border:none !important; font-weight:600; }
      .btn-execute:hover { background:#047857 !important; }
      .btn-new { border-color:#667eea !important; color:#667eea !important; }
      
      /* === Editor + Output split === */
      .editor-area { 
        flex:1; display:flex; flex-direction:column; min-height:0;
      }
      .code-panel { 
        flex:1; min-height:200px; border-bottom:3px solid #e5e7eb; position:relative;
      }
      .code-panel .panel-label {
        position:absolute; top:6px; right:10px; font-size:9px; color:#9ca3af; 
        text-transform:uppercase; letter-spacing:1px; z-index:10; background:#fff; padding:2px 6px;
      }
      .output-panel {
        flex:1; min-height:150px; background:#fff; overflow-y:auto; padding:12px 16px;
      }
      .output-panel::-webkit-scrollbar { width:4px; }
      .output-panel::-webkit-scrollbar-thumb { background:#d1d5db; border-radius:4px; }
      .output-panel .out-section { margin-bottom:12px; }
      .output-panel .out-label { 
        font-size:9px; font-weight:600; text-transform:uppercase; letter-spacing:1px; 
        color:#9ca3af; margin-bottom:4px;
      }
      .output-panel .out-text {
        font-family:'Courier New',monospace; font-size:11px; color:#374151;
        background:#f9fafb; padding:8px; border-radius:6px; white-space:pre-wrap;
      }
      .output-panel .out-error {
        font-family:'Courier New',monospace; font-size:11px; color:#dc2626;
        background:#fef2f2; padding:8px; border-radius:6px; white-space:pre-wrap;
      }
      .output-panel .out-plot { text-align:center; }
      .output-panel .out-plot img { max-width:100%; border-radius:6px; box-shadow:0 1px 3px rgba(0,0,0,0.1); }
      
      .empty-ws {
        flex:1; display:flex; flex-direction:column; align-items:center;
        justify-content:center; color:#9ca3af; text-align:center; padding:40px;
      }
      .empty-ws .big-icon { font-size:48px; margin-bottom:12px; }
      .quick-actions { display:flex; gap:8px; margin-top:16px; flex-wrap:wrap; justify-content:center; }
      .quick-actions button {
        padding:8px 16px; border-radius:20px; border:1px solid #e5e7eb;
        background:#fff; font-size:12px; cursor:pointer; color:#6b7280;
      }
      .quick-actions button:hover { border-color:#667eea; color:#667eea; }
      
      /* === Config Modal === */
      .config-overlay {
        display:none; position:fixed; top:0; left:0; width:100%; height:100%;
        background:rgba(0,0,0,0.5); z-index:1000; justify-content:center; align-items:center;
      }
      .config-overlay.show { display:flex; }
      .config-card {
        background:#1a1a2e; padding:24px; border-radius:12px; width:400px; max-height:80vh; overflow-y:auto;
      }
    "))
  ),
  
  div(class = "main-container",
    # LEFT: Chat Panel
    div(class = "chat-panel",
      div(class = "chat-header",
        h3("raix Chat"),
        uiOutput("model_badge")
      ),
      div(class = "chat-messages", uiOutput("chat_msgs")),
      div(class = "chat-input-row",
        textAreaInput("chat_input", NULL, "", rows = 1, 
                      placeholder = "Ask anything... (Enter to send)"),
        div(class = "chat-actions",
          actionButton("chat_send", "Send", class = "btn-send"),
          actionButton("chat_clear", "Clear", class = "btn-clear"),
          actionButton("chat_config", "⚙", class = "btn-config")
        )
      ),
      div(class = "chat-status", uiOutput("chat_status"))
    ),
    
    # RIGHT: Workspace
    div(class = "workspace",
      div(class = "ws-toolbar",
        div(class = "ws-title", "📝 R Code Editor"),
        div(class = "ws-actions",
          actionButton("ws_new", "New", class = "btn-new"),
          actionButton("ws_execute", "▶ Run", class = "btn-execute"),
          actionButton("ws_clear_output", "Clear Output"),
          actionButton("ws_download", "⬇ Save .R")
        )
      ),
      uiOutput("workspace_content")
    )
  ),
  
  # Enter to send in chat
  tags$script(HTML("
    $(document).on('keydown', '#chat_input', function(e) {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault(); $('#chat_send').click();
      }
      if (e.key === 'Enter' && e.shiftKey) {
        // Allow newline
        return true;
      }
    });
  "))
)

server <- function(input, output, session) {
  # === State ===
  chat_msgs <- reactiveVal(list())
  code_text <- reactiveVal("# raix Dashboard — Generated R Code\n# Write or paste R code here, then click 'Run'\n\nlibrary(ggplot2)\n\n# Example:\n# ggplot(mtcars, aes(x=wt, y=mpg, color=factor(cyl))) + geom_point(size=3)\n")
  console_output <- reactiveVal(list())
  connected <- reactiveVal(FALSE)
  
  # === Connection ===
  observe({
    reachable <- tryCatch(raix_check(), error = function(e) FALSE)
    connected(isTRUE(reachable))
  })
  
  output$chat_status <- renderUI({
    if (connected()) {
      div(class = "online", sprintf("● Connected — %s / %s", raix_env$provider, raix_env$model))
    } else {
      div(class = "offline", "○ Not connected — run raix_setup() in R console")
    }
  })
  
  output$model_badge <- renderUI({
    div(class = "model-badge", paste(raix_env$provider, "/", raix_env$model))
  })
  
  # === Chat ===
  observeEvent(input$chat_send, {
    req(nchar(trimws(input$chat_input)) > 0)
    if (!connected()) {
      msgs <- chat_msgs()
      msgs <- c(msgs, list(list(role="error", content="Not connected. Run raix_setup() in your R console first.")))
      chat_msgs(msgs)
      return()
    }
    
    user_msg <- input$chat_input
    updateTextAreaInput(session, "chat_input", value = "")
    
    msgs <- chat_msgs()
    msgs <- c(msgs, list(list(role="user", content=user_msg)))
    msgs <- c(msgs, list(list(role="loading", content="")))
    chat_msgs(msgs)
    
    # Send to AI
    ai_response <- tryCatch(raix_send(user_msg), error = function(e) paste0("ERROR: ", conditionMessage(e)))
    
    msgs <- chat_msgs()
    msgs <- msgs[-length(msgs)]  # remove loading
    role <- if (grepl("^ERROR:", ai_response)) "error" else "ai"
    msgs <- c(msgs, list(list(role=role, content=ai_response)))
    chat_msgs(msgs)
    
    # If response contains R code, offer to send to editor
    if (grepl("```", ai_response) || grepl("library\\(|ggplot\\(|dplyr::|data\\.frame\\(", ai_response)) {
      extracted <- raix_extract_code(ai_response)
      if (nchar(extracted) > 20) {
        msgs <- chat_msgs()
        msgs <- c(msgs, list(list(role="ai", 
          content=paste0("💡 _Code detected! Click below to send to editor._"),
          code=extracted)))
        chat_msgs(msgs)
      }
    }
  })
  
  observeEvent(input$chat_clear, {
    chat_msgs(list())
  })
  
  # Handle "send code to editor" clicks
  observeEvent(input$send_to_editor, {
    code_text(input$send_to_editor)
    output$workspace_content <- renderUI({ build_workspace() })
  })
  
  output$chat_msgs <- renderUI({
    msgs <- chat_msgs()
    if (length(msgs) == 0) {
      return(div(style="padding:20px;text-align:center;color:#64748b;",
        div(style="font-size:36px;margin-bottom:8px;","💬"),
        div(style="font-size:13px;","Ask raix to write R code, explain concepts, debug errors..."),
        div(style="font-size:11px;margin-top:8px;","Try: 'Create a ggplot2 scatter plot of mtcars'")
      ))
    }
    
    tagList(lapply(seq_along(msgs), function(i) {
      m <- msgs[[i]]
      if (m$role == "loading") {
        return(div(class="c-msg ai", "Thinking", span(".", style="animation:pulse 1s infinite"), "..."))
      }
      
      # Render content
      content <- m$content
      content <- gsub("&","&amp;",content); content <- gsub("<","&lt;",content); content <- gsub(">","&gt;",content)
      content <- gsub("```(\\w*)\\n?","<pre><code>",content)
      content <- gsub("```","</code></pre>",content)
      content <- gsub("`([^`]+)`","<code>\\1</code>",content)
      content <- gsub("\\*\\*([^*]+)\\*\\*","<strong>\\1</strong>",content)
      content <- gsub("\n","<br/>",content)
      
      tagList(
        div(class=paste0("c-msg ", m$role),
          div(class="c-label", switch(m$role, user="You", ai="raix", error="Error")),
          HTML(content),
          if (!is.null(m$code)) {
            tagList(
              tags$button("📋 Send to Editor", 
                class="btn-send", style="margin-top:6px;font-size:10px;padding:4px 8px;",
                onclick=sprintf("Shiny.setInputValue('send_to_editor', '%s', {priority:'event'})", 
                               gsub("'","\\\\'",gsub("\n","\\\\n",m$code))))
            )
          }
        )
      )
    }))
  })
  
  # === Workspace ===
  build_workspace <- function() {
    code <- code_text()
    output_list <- console_output()
    
    tagList(
      div(class = "editor-area",
        # Code editor
        div(class = "code-panel",
          div(class = "panel-label", "R CODE"),
          if (has_ace) {
            shinyAce::aceEditor("code_editor", mode = "r", theme = "monokai",
                                value = code, height = "100%", fontSize = 13,
                                showPrintMargin = FALSE, tabSize = 2,
                                autoComplete = "live", wordWrap = TRUE)
          } else {
            tags$textarea(id = "code_editor_raw", style = paste0(
              "width:100%;height:100%;border:none;padding:14px;font-family:'Courier New',monospace;",
              "font-size:13px;line-height:1.5;resize:none;background:#1e1e2e;color:#cdd6f4;",
              "tab-size:2;"), code)
          }
        ),
        # Output panel
        div(class = "output-panel",
          if (length(output_list) == 0) {
            div(class = "empty-ws",
              div(class = "big-icon", "▶"),
              div("Click", tags$b("Run"), "to execute your R code"),
              div(style = "margin-top:16px;", class = "quick-actions",
                actionButton("quick_mtcars", "📊 Plot mtcars"),
                actionButton("quick_summary", "📋 Summary of iris"),
                actionButton("quick_lm", "📈 Linear model"),
                actionButton("quick_dplyr", "🔍 dplyr example")
              )
            )
          } else {
            tagList(lapply(seq_along(output_list), function(i) {
              out <- output_list[[i]]
              if (out$type == "text") {
                div(class = "out-section",
                  div(class = "out-label", "Console Output"),
                  div(class = "out-text", out$content)
                )
              } else if (out$type == "error") {
                div(class = "out-section",
                  div(class = "out-label", "Error"),
                  div(class = "out-error", out$content)
                )
              } else if (out$type == "plot") {
                div(class = "out-section",
                  div(class = "out-label", "Plot"),
                  div(class = "out-plot", 
                    imageOutput(paste0("plot_", i), height = "auto"))
                )
              }
            }))
          }
        )
      )
    )
  }
  
  output$workspace_content <- renderUI({ build_workspace() })
  
  # Keep code in sync
  observe({
    if (has_ace && !is.null(input$code_editor)) {
      code_text(input$code_editor)
    } else if (!is.null(input$code_editor_raw)) {
      code_text(input$code_editor_raw)
    }
  })
  
  # Execute code
  observeEvent(input$ws_execute, {
    code <- code_text()
    if (nchar(trimws(code)) == 0) return()
    
    output_list <- list()
    
    # Capture text output
    text_out <- tryCatch({
      tc <- textConnection("captured", "w", local = TRUE)
      sink(tc)
      on.exit({ sink(); close(tc) })
      eval(parse(text = code), envir = globalenv())
      paste(captured, collapse = "\n")
    }, error = function(e) paste("Error:", conditionMessage(e)))
    
    if (nchar(text_out) > 0) {
      is_err <- grepl("^Error:", text_out)
      output_list <- c(output_list, list(list(
        type = if(is_err) "error" else "text",
        content = text_out
      )))
    }
    
    # Check for plots
    plot_files <- list.files(tempdir(), pattern = "raix_plot_.*\\.png", full.names = TRUE)
    for (pf in plot_files) unlink(pf)
    
    has_plot <- tryCatch({
      dev_num <- dev.cur()
      if (dev_num > 1) {
        tmp_plot <- file.path(tempdir(), paste0("raix_plot_", length(output_list)+1, ".png"))
        png(tmp_plot, width = 800, height = 500)
        eval(parse(text = code), envir = globalenv())
        dev.off()
        if (file.exists(tmp_plot) && file.info(tmp_plot)$size > 100) {
          output_list <<- c(output_list, list(list(type = "plot", file = tmp_plot)))
        }
        TRUE
      } else FALSE
    }, error = function(e) FALSE)
    
    # If no plot was captured but code contains ggplot/plot, try to capture
    if (!has_plot && (grepl("ggplot|plot\\(|hist\\(|boxplot\\(", code))) {
      tryCatch({
        tmp_plot <- file.path(tempdir(), paste0("raix_plot_", length(output_list)+1, ".png"))
        png(tmp_plot, width = 800, height = 500)
        eval(parse(text = code), envir = globalenv())
        dev.off()
        if (file.exists(tmp_plot) && file.info(tmp_plot)$size > 100) {
          output_list <- c(output_list, list(list(type = "plot", file = tmp_plot)))
        }
      }, error = function(e) NULL)
    }
    
    console_output(output_list)
    
    # Render plots
    for (i in seq_along(output_list)) {
      if (output_list[[i]]$type == "plot") {
        local({
          idx <- i
          output[[paste0("plot_", idx)]] <- renderImage({
            list(src = output_list[[idx]]$file, contentType = "image/png", 
                 width = "100%", height = "auto")
          }, deleteFile = FALSE)
        })
      }
    }
  })
  
  observeEvent(input$ws_clear_output, { console_output(list()) })
  observeEvent(input$ws_new, { code_text("# Write R code here...\n"); output$workspace_content <- renderUI({ build_workspace() }) })
  
  # Download
  output$ws_download_handler <- downloadHandler(
    filename = function() paste0("raix_code_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".R"),
    content = function(file) writeLines(code_text(), file)
  )
  
  observeEvent(input$ws_download, {
    showModal(modalDialog(
      title = "Download R Script",
      downloadButton("ws_download_handler", "Download .R file"),
      easyClose = TRUE, footer = NULL
    ))
  })
  
  # Quick examples
  observeEvent(input$quick_mtcars, {
    code_text("library(ggplot2)\nggplot(mtcars, aes(x = wt, y = mpg, color = factor(cyl))) +\n  geom_point(size = 3) +\n  labs(title = 'mtcars: Weight vs MPG', x = 'Weight', y = 'MPG', color = 'Cylinders') +\n  theme_minimal()")
    output$workspace_content <- renderUI({ build_workspace() })
  })
  observeEvent(input$quick_summary, {
    code_text("library(dplyr)\niris %>%\n  group_by(Species) %>%\n  summarise(across(where(is.numeric), list(mean = mean, sd = sd), .names = '{.col}_{.fn}'))")
    output$workspace_content <- renderUI({ build_workspace() })
  })
  observeEvent(input$quick_lm, {
    code_text("model <- lm(mpg ~ wt + hp + factor(cyl), data = mtcars)\nsummary(model)\npar(mfrow = c(2,2))\nplot(model)")
    output$workspace_content <- renderUI({ build_workspace() })
  })
  observeEvent(input$quick_dplyr, {
    code_text("library(dplyr)\nlibrary(tidyr)\n\nmtcars %>%\n  group_by(cyl) %>%\n  summarise(\n    avg_mpg = mean(mpg),\n    avg_hp = mean(hp),\n    n = n()\n  ) %>%\n  arrange(desc(avg_mpg))")
    output$workspace_content <- renderUI({ build_workspace() })
  })
}

shinyApp(ui, server)
