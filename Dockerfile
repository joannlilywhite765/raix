# raix — R + AI + eXperience
# Docker image with R, raix, and all dependencies pre-installed

FROM rocker/r-ver:latest

LABEL org.opencontainers.image.title="raix"
LABEL org.opencontainers.image.description="AI-powered coding assistant for R"
LABEL org.opencontainers.image.source="https://github.com/twomathematicians-code/raix"
LABEL org.opencontainers.image.licenses="MIT"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R package dependencies
RUN R -e 'install.packages(c("remotes","httr","jsonlite","cli","shiny","rstudioapi","testthat"), repos="https://cran.rstudio.com")'

# Install raix from GitHub
RUN R -e 'remotes::install_github("twomathematicians-code/raix")'

# Set working directory
WORKDIR /home/rstudio

# Default command: start R with raix loaded
CMD ["R", "-e", "library(raix); cat('raix v', as.character(packageVersion('raix')), 'ready\\n'); raix_info()"]
