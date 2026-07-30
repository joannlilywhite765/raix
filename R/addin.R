# AIR RStudio Add-in — Quick Chat
#
# Adds an RStudio Add-in that opens the AIR GUI directly

air_addin_chat <- function() {
  air_configure(provider = getOption("air.provider", "ollama"),
                model = getOption("air.model", "llama3.2"))
  if (requireNamespace("shiny", quietly = TRUE)) {
    air_gui()
  } else {
    air_chat()
  }
}
