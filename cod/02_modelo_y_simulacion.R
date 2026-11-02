# ==============================================================================
# 02_modelo_y_simulacion.R
# Proyecto: Evaluacion del Impacto Economico de Terremotos Historicos
# Autor: Derek Matias Escobar Jaramillo (C5E850)
# Objetivo: Ajuste del modelo econometrico log-lineal y definicion de funciones
#           analiticas de estimacion y busqueda de analogos historicos.
# ==============================================================================

source("config/paquetes.R")

# 1. Cargar datos consolidados -------------------------------------------------
datos <- readRDS("data/datos_consolidados.rds")

# 2. Ajuste del Modelo Econometrico -------------------------------------------
modelo_dano <- lm(
  log(porc_dano_pib) ~ magnitud + profundidad_km + si_tsunami,
  data = datos
)

# 3. Funcion: estimar_dano_sismo ----------------------------------------------
estimar_dano_sismo <- function(magnitud, profundidad_km, si_tsunami = 0, 
                               pib_mill_usd = NULL, tipo_intervalo = "P") {
  tipo_intervalo   <- toupper(tipo_intervalo)
  opcion_intervalo <- if_else(tipo_intervalo == "C", "confidence", "prediction")
  
  nueva_obs <- tibble(
    magnitud       = magnitud, 
    profundidad_km = profundidad_km, 
    si_tsunami     = si_tsunami
  )
  pred_log <- predict(modelo_dano, newdata = nueva_obs, interval = opcion_intervalo, level = 0.95)
  
  resultado <- tibble(
    magnitud          = magnitud,
    profundidad_km    = profundidad_km,
    si_tsunami        = si_tsunami,
    tipo_intervalo    = if_else(tipo_intervalo == "C", "Confianza (Promedio)", "Prediccion (Individual)"),
    porc_pib_estimado = round(exp(pred_log[1, "fit"]), 4),
    porc_pib_ic_inf   = round(exp(pred_log[1, "lwr"]), 4),
    porc_pib_ic_sup   = round(exp(pred_log[1, "upr"]), 4)
  )
  
  if (!is.null(pib_mill_usd)) {
    resultado <- resultado |> 
      mutate(
        dano_estimado_mill_usd = round((porc_pib_estimado / 100) * pib_mill_usd, 2),
        dano_inf_mill_usd      = round((porc_pib_ic_inf / 100) * pib_mill_usd, 2),
        dano_sup_mill_usd      = round((porc_pib_ic_sup / 100) * pib_mill_usd, 2)
      )
  }
  return(resultado)
}

# 4. Funcion: buscar_sismos_analogos ------------------------------------------
buscar_sismos_analogos <- function(mag_ref, tol_mag = 0.2, prof_max = NULL, 
                                  porc_referencia = NULL, data = datos) {
  filtro <- data |> 
    filter(magnitud >= (mag_ref - tol_mag), magnitud <= (mag_ref + tol_mag))
  
  if (!is.null(prof_max)) {
    filtro <- filtro |> filter(profundidad_km <= prof_max)
  }
  
  if (!is.null(porc_referencia)) {
    filtro <- filtro |> 
      mutate(diferencia = abs(porc_dano_pib - porc_referencia)) |> 
      arrange(diferencia)
  } else {
    filtro <- filtro |> arrange(porc_dano_pib)
  }
  
  filtro |> 
    select(anio, pais, codigo_pais, magnitud, profundidad_km, si_tsunami, porc_dano_pib, dano_mill_usd_vp)
}
