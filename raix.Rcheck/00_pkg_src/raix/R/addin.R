# raix RStudio Add-in --- Quick Chat
#
# Adds an RStudio Add-in that opens the raix GUI directly

raix_addin_chat <- function() {
  raix_configure(provider = getOption("raix.provider", "ollama"),
                model = getOption("raix.model", "llama3.2"))
  if (requireNamespace("shiny", quietly = TRUE)) {
    raix_gui()
  } else {
    raix_chat()
  }
}
