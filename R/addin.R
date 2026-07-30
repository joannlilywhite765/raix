# AIR RStudio Add-in — Quick Chat
#
# Adds an RStudio Add-in that opens a chat session
# Install: copy this file to inst/rstudio/addins.dcf

air_addin_chat <- function() {
  air_configure(backend = getOption("air.backend", "ollama"),
                model = getOption("air.model", "llama3.2"))
  air_chat()
}
