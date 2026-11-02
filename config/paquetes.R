# Configuracion de paquetes necesarios para el proyecto
paquetes <- c("tidyverse", "countrycode", "knitr", "kableExtra")

# Instalacion condicional y carga
instalados <- paquetes %in% rownames(installed.packages())
if (any(!instalados)) {
  install.packages(paquetes[!instalados])
}

invisible(lapply(paquetes, library, character.only = TRUE))
