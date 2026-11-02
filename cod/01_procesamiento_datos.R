# ==============================================================================
# 01_procesamiento_datos.R
# Proyecto: Evaluacion del Impacto Economico de Terremotos Historicos
# Autor: Derek Matias Escobar Jaramillo (C5E850)
# Objetivo: Carga, estandarizacion, union de bases (NOAA, PIB, IPC) y calculo
#           de variables economicas normalizadas (% PIB y Valor Presente).
# ==============================================================================

source("config/paquetes.R")

# 1. Carga de datos crudos (rutas relativas) -----------------------------------
data_terremotos_raw <- read_tsv("data/Datos_terremotos.tsv", show_col_types = FALSE)
data_pib_raw        <- read_csv("data/Datos_pib.csv", skip = 4, show_col_types = FALSE)
data_ipc_raw        <- read_csv("data/Datos_ipc.csv", skip = 4, show_col_types = FALSE)

# 2. Limpieza y estandarizacion de Terremotos (NOAA) ---------------------------
terremotos_clean <- data_terremotos_raw |> 
  select(
    anio             = Year,
    pais_lugar       = `Location Name`,
    latitud          = Latitude,
    longitud         = Longitude,
    profundidad_km   = `Focal Depth (km)`,
    magnitud         = Mag,
    intensidad_mmi   = `MMI Int`,
    tsunami          = Tsu,
    muertes          = `Total Deaths`,
    casas_destruidas = `Total Houses Destroyed`,
    dano_directo     = `Damage ($Mil)`,
    dano_total       = `Total Damage ($Mil)`
  ) |> 
  mutate(
    pais          = str_to_title(str_trim(str_extract(pais_lugar, "^[^:]+"))),
    codigo_pais   = countrycode(pais, origin = "country.name", destination = "iso3c"),
    dano_mill_usd = coalesce(dano_total, dano_directo),
    si_tsunami    = if_else(!is.na(tsunami), 1, 0)
  ) |> 
  filter(
    anio >= 1960,
    !is.na(dano_mill_usd),
    !is.na(magnitud)
  ) |> 
  select(-pais_lugar, -tsunami, -dano_directo, -dano_total)

# 3. Limpieza de PIB (Banco Mundial) -------------------------------------------
pib_clean <- data_pib_raw |> 
  pivot_longer(
    cols = -c(`Country Name`, `Country Code`, `Indicator Name`, `Indicator Code`),
    names_to = "anio",
    values_to = "pib_usd"
  ) |> 
  rename(pais_pib = `Country Name`, codigo_pais = `Country Code`) |> 
  mutate(
    anio         = as.integer(anio),
    pib_mill_usd = pib_usd / 1e6
  ) |> 
  filter(!is.na(pib_usd)) |> 
  select(codigo_pais, anio, pib_mill_usd)

# 4. Limpieza de IPC EE. UU. (Banco Mundial) -----------------------------------
ipc_clean <- data_ipc_raw |> 
  filter(`Country Code` == "USA") |> 
  pivot_longer(
    cols = -c(`Country Name`, `Country Code`, `Indicator Name`, `Indicator Code`),
    names_to = "anio",
    values_to = "ipc"
  ) |> 
  mutate(anio = as.integer(anio)) |> 
  filter(!is.na(ipc)) |> 
  select(anio, ipc)

# 5. Consolidacion final con ajuste monetario y relativo -----------------------
ipc_referencia <- last(ipc_clean$ipc)

datos_consolidados <- terremotos_clean |> 
  left_join(pib_clean, by = join_by(codigo_pais == codigo_pais, anio == anio)) |> 
  left_join(ipc_clean, by = join_by(anio == anio)) |> 
  mutate(
    porc_dano_pib    = (dano_mill_usd / pib_mill_usd) * 100,
    dano_mill_usd_vp = dano_mill_usd * (ipc_referencia / ipc)
  ) |> 
  filter(
    !is.na(pib_mill_usd),
    !is.na(dano_mill_usd_vp),
    !is.na(profundidad_km),
    porc_dano_pib > 0
  ) |> 
  select(
    anio, pais, codigo_pais, latitud, longitud, 
    profundidad_km, magnitud, si_tsunami, 
    pib_mill_usd, porc_dano_pib, dano_mill_usd_vp
  )

# Guardar base procesada en data/
saveRDS(datos_consolidados, file = "data/datos_consolidados.rds")
