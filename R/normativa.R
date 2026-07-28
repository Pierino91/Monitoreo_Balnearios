#' Funciones Normativas - Resolución 084 SMA Entre Ríos
#' Cálculos de medias geométricas y validación de cumplimiento

library(dplyr)
library(lubridate)

#' Calcular media geométrica con validaciones
#' 
#' @param valores Vector numérico de concentraciones
#' @param remover_na Remover NA antes de calcular
#' @return Media geométrica o NA si no hay suficientes datos
#' 
calcular_media_geometrica <- function(valores, remover_na = TRUE) {
  
  if (remover_na) {
    valores <- valores[!is.na(valores)]
  }
  
  # Validación: valores positivos
  if (any(valores <= 0, na.rm = TRUE)) {
    warning("Valores <= 0 encontrados. Se excluyen del cálculo.")
    valores <- valores[valores > 0]
  }
  
  # Validación: mínimo de datos
  if (length(valores) < 5) {
    return(NA_real_)
  }
  
  # Cálculo: exp(mean(log(x)))
  media_geo <- exp(mean(log(valores), na.rm = TRUE))
  
  return(media_geo)
}


#' Calcular media geométrica móvil (ventana 30 días)
#' 
#' @param df Data frame con columnas: fecha_muestreo, parametro
#' @param fecha_referencia Fecha para calcular ventana
#' @param parametro Nombre de la columna con valores
#' @return Lista con media geométrica y cantidad de muestras
#' 
media_geometrica_30dias <- function(df, fecha_referencia, parametro = "e_coli") {
  
  fecha_ref <- as.Date(fecha_referencia)
  fecha_inicio <- fecha_ref - days(30)
  
  # Filtrar ventana temporal
  datos_ventana <- df %>%
    filter(
      fecha_muestreo >= fecha_inicio,
      fecha_muestreo <= fecha_ref,
      !is.na(.data[[parametro]])
    )
  
  n_muestras <- nrow(datos_ventana)
  
  if (n_muestras < 5) {
    return(list(
      media_geometrica = NA_real_,
      n_muestras = n_muestras,
      suficientes_datos = FALSE,
      fecha_inicio = fecha_inicio,
      fecha_fin = fecha_ref
    ))
  }
  
  mg <- calcular_media_geometrica(datos_ventana[[parametro]])
  
  return(list(
    media_geometrica = mg,
    n_muestras = n_muestras,
    suficientes_datos = TRUE,
    fecha_inicio = fecha_inicio,
    fecha_fin = fecha_ref,
    valores_min = min(datos_ventana[[parametro]], na.rm = TRUE),
    valores_max = max(datos_ventana[[parametro]], na.rm = TRUE)
  ))
}


#' Validar cumplimiento Art. 8 - E. coli
#' 
#' @param media_geo Media geométrica calculada
#' @param valores_individuales Vector con valores de la ventana
#' @return Lista con estado de cumplimiento
#' 
validar_ecoli_art8 <- function(media_geo, valores_individuales) {
  
  # Límites Art. 8
  LIMITE_MEDIA_GEO <- 300  # UFC/100ml
  LIMITE_MUESTRA_CRITICA <- 800  # UFC/100ml
  
  # Validaciones
  cumple_media <- !is.na(media_geo) && media_geo < LIMITE_MEDIA_GEO
  
  valores_validos <- valores_individuales[!is.na(valores_individuales)]
  excedencias_criticas <- sum(valores_validos >= LIMITE_MUESTRA_CRITICA)
  cumple_muestras <- excedencias_criticas == 0
  
  cumplimiento_total <- cumple_media && cumple_muestras
  
  return(list(
    cumplimiento = cumplimiento_total,
    cumple_media_geometrica = cumple_media,
    cumple_valores_individuales = cumple_muestras,
    media_geometrica = media_geo,
    limite_media = LIMITE_MEDIA_GEO,
    excedencias_criticas = excedencias_criticas,
    limite_critico = LIMITE_MUESTRA_CRITICA,
    margen_media = ifelse(!is.na(media_geo), 
                          round((LIMITE_MEDIA_GEO - media_geo) / LIMITE_MEDIA_GEO * 100, 1),
                          NA)
  ))
}


#' Validar cumplimiento Art. 8 - Coliformes Termotolerantes
#' 
#' @param media_geo Media geométrica calculada
#' @param valores_individuales Vector con valores de la ventana
#' @return Lista con estado de cumplimiento
#' 
validar_coliformes_art8 <- function(media_geo, valores_individuales) {
  
  # Límites Art. 8
  LIMITE_MEDIA_GEO <- 600  # UFC/100ml
  LIMITE_MUESTRA_CRITICA <- 1000  # UFC/100ml
  
  # Validaciones
  cumple_media <- !is.na(media_geo) && media_geo < LIMITE_MEDIA_GEO
  
  valores_validos <- valores_individuales[!is.na(valores_individuales)]
  excedencias_criticas <- sum(valores_validos >= LIMITE_MUESTRA_CRITICA)
  cumple_muestras <- excedencias_criticas == 0
  
  cumplimiento_total <- cumple_media && cumple_muestras
  
  return(list(
    cumplimiento = cumplimiento_total,
    cumple_media_geometrica = cumple_media,
    cumple_valores_individuales = cumple_muestras,
    media_geometrica = media_geo,
    limite_media = LIMITE_MEDIA_GEO,
    excedencias_criticas = excedencias_criticas,
    limite_critico = LIMITE_MUESTRA_CRITICA,
    margen_media = ifelse(!is.na(media_geo), 
                          round((LIMITE_MEDIA_GEO - media_geo) / LIMITE_MEDIA_GEO * 100, 1),
                          NA)
  ))
}


#' Evaluación completa de balneario
#' 
#' @param df_balneario Data frame filtrado para un balneario específico
#' @param fecha_referencia Fecha de evaluación (default: hoy)
#' @return Data frame con resultados completos
#' 
evaluar_balneario_completo <- function(df_balneario, fecha_referencia = Sys.Date()) {
  
  # E. coli
  mg_ecoli <- media_geometrica_30dias(df_balneario, fecha_referencia, "e_coli")
  
  valores_ecoli <- df_balneario %>%
    filter(
      fecha_muestreo >= (as.Date(fecha_referencia) - days(30)),
      fecha_muestreo <= as.Date(fecha_referencia),
      !is.na(e_coli)
    ) %>%
    pull(e_coli)
  
  validacion_ecoli <- validar_ecoli_art8(mg_ecoli$media_geometrica, valores_ecoli)
  
  # Coliformes termotolerantes
  mg_colif <- media_geometrica_30dias(df_balneario, fecha_referencia, "coliformes_termotolerantes")
  
  valores_colif <- df_balneario %>%
    filter(
      fecha_muestreo >= (as.Date(fecha_referencia) - days(30)),
      fecha_muestreo <= as.Date(fecha_referencia),
      !is.na(coliformes_termotolerantes)
    ) %>%
    pull(coliformes_termotolerantes)
  
  validacion_colif <- validar_coliformes_art8(mg_colif$media_geometrica, valores_colif)
  
  # Compilar resultado
  resultado <- tibble(
    fecha_evaluacion = as.Date(fecha_referencia),
    
    # E. coli
    ecoli_mg = mg_ecoli$media_geometrica,
    ecoli_n_muestras = mg_ecoli$n_muestras,
    ecoli_cumple = validacion_ecoli$cumplimiento,
    ecoli_excedencias = validacion_ecoli$excedencias_criticas,
    
    # Coliformes
    colif_mg = mg_colif$media_geometrica,
    colif_n_muestras = mg_colif$n_muestras,
    colif_cumple = validacion_colif$cumplimiento,
    colif_excedencias = validacion_colif$excedencias_criticas,
    
    # Datos suficientes
    datos_suficientes = mg_ecoli$suficientes_datos && mg_colif$suficientes_datos
  )
  
  return(list(
    resumen = resultado,
    detalle_ecoli = validacion_ecoli,
    detalle_colif = validacion_colif,
    ventana_ecoli = mg_ecoli,
    ventana_colif = mg_colif
  ))
}


#' Validar datos de entrada
#' 
#' @param df Data frame con datos crudos
#' @return Data frame con flags de validación
#' 
validar_datos_entrada <- function(df) {
  
  df %>%
    mutate(
      # Validaciones de integridad
      flag_fecha_na = is.na(fecha_muestreo),
      flag_ecoli_na = is.na(e_coli),
      flag_colif_na = is.na(coliformes_termotolerantes),
      
      # Validaciones de rango
      flag_ecoli_negativo = !is.na(e_coli) & e_coli < 0,
      flag_colif_negativo = !is.na(coliformes_termotolerantes) & coliformes_termotolerantes < 0,
      flag_ecoli_extremo = !is.na(e_coli) & e_coli > 10000,
      flag_colif_extremo = !is.na(coliformes_termotolerantes) & coliformes_termotolerantes > 20000,
      
      # Validaciones de coherencia
      # flag_ph_fuera_rango = !is.na(ph) & (ph < 4 | ph > 10),
      # flag_temp_fuera_rango = !is.na(temperatura_agua) & (temperatura_agua < 0 | temperatura_agua > 45),
      
      # Resumen
      registro_valido = !(flag_fecha_na | flag_ecoli_na | flag_colif_na | 
                          flag_ecoli_negativo | flag_colif_negativo |
                          flag_ecoli_extremo | flag_colif_extremo)
    )
  
}


#' Detectar temporada según fecha
#' 
#' @param fecha Vector de fechas
#' @return Vector con temporada (Verano, Resto)
#' 
detectar_temporada <- function(fecha) {
  mes <- month(fecha)
  
  temporada <- case_when(
    mes %in% c(12, 1, 2, 3) ~ "Verano",
    TRUE ~ "Resto del año"
  )
  
  return(temporada)
}
