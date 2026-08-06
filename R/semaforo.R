#' Sistema de Semáforo Sanitario
#' Clasificación de balnearios según cumplimiento normativo


#' Clasificar estado sanitario del balneario
#' 
#' @param evaluacion Lista retornada por evaluar_balneario_completo()
#' @return Lista con clasificación y detalles
#' 
clasificar_estado_sanitario <- function(evaluacion) {
  
  resumen <- evaluacion$resumen
  detalle_ecoli <- evaluacion$detalle_ecoli
  detalle_colif <- evaluacion$detalle_colif
  
  # Verificar datos suficientes
  if (!resumen$datos_suficientes) {
    return(list(
      estado = "SIN_DATOS",
      color = "#999999",
      color_hex = "#999999",
      icono = "⚪",
      texto_corto = "Sin Datos Suficientes",
      texto_largo = "No hay al menos 5 muestras en los últimos 30 días para realizar la evaluación.",
      habilitado = FALSE,
      prioridad = 99,
      accion_requerida = "Aumentar frecuencia de muestreo"
    ))
  }
  
  # Variables de decisión
  ecoli_cumple <- resumen$ecoli_cumple
  colif_cumple <- resumen$colif_cumple
  ecoli_excedencias <- resumen$ecoli_excedencias
  colif_excedencias <- resumen$colif_excedencias
  
  ecoli_mg <- resumen$ecoli_mg
  colif_mg <- resumen$colif_mg
  
  # Límites para zona amarilla (90% del límite)
  UMBRAL_ALERTA_ECOLI <- 300 * 0.90  # 270
  UMBRAL_ALERTA_COLIF <- 600 * 0.90  # 540
  
  # ROJO - No Habilitado
  if (!ecoli_cumple || !colif_cumple) {
    
    razones <- c()
    if (!detalle_ecoli$cumple_media_geometrica) {
      razones <- c(razones, sprintf("E. coli MG: %.0f (límite: 300)", ecoli_mg))
    }
    if (!detalle_colif$cumple_media_geometrica) {
      razones <- c(razones, sprintf("Coliformes MG: %.0f (límite: 600)", colif_mg))
    }
    if (ecoli_excedencias > 0) {
      razones <- c(razones, sprintf("%d muestra(s) E. coli ≥800", ecoli_excedencias))
    }
    if (colif_excedencias > 0) {
      razones <- c(razones, sprintf("%d muestra(s) Coliformes ≥1000", colif_excedencias))
    }
    
    return(list(
      estado = "ROJO",
      color = "#dc3545",
      color_hex = "#dc3545",
      icono = "🔴",
      texto_corto = "NO APTO - No Habilitado",
      texto_largo = paste(
        "El balneario NO CUMPLE con los requisitos del Art. 8 de la Resolución 084/SMA.",
        paste(razones, collapse = ". "),
        "Requiere acciones correctivas inmediatas."
      ),
      habilitado = FALSE,
      prioridad = 1,
      razones = razones,
      accion_requerida = "Prohibir baño - Investigar fuentes de contaminación"
    ))
  }
  
  # AMARILLO - Alerta
  # Cumple normativa pero está cerca de los límites
  zona_alerta_ecoli <- ecoli_mg >= UMBRAL_ALERTA_ECOLI
  zona_alerta_colif <- colif_mg >= UMBRAL_ALERTA_COLIF
  
  # Excedencias puntuales (no críticas, pero presentes)
  valores_altos_ecoli <- any(evaluacion$ventana_ecoli$valores_max > 500, na.rm = TRUE)
  valores_altos_colif <- any(evaluacion$ventana_colif$valores_max > 800, na.rm = TRUE)
  
  if (zona_alerta_ecoli || zona_alerta_colif || valores_altos_ecoli || valores_altos_colif) {
    
    advertencias <- c()
    if (zona_alerta_ecoli) {
      advertencias <- c(advertencias, sprintf("E. coli MG en zona de alerta: %.0f (90%% límite: 270)", ecoli_mg))
    }
    if (zona_alerta_colif) {
      advertencias <- c(advertencias, sprintf("Coliformes MG en zona de alerta: %.0f (90%% límite: 540)", colif_mg))
    }
    if (valores_altos_ecoli) {
      advertencias <- c(advertencias, "Valores individuales de E. coli cercanos al límite crítico")
    }
    
    return(list(
      estado = "AMARILLO",
      color = "#ffc107",
      color_hex = "#ffc107",
      icono = "🟡",
      texto_corto = "ALERTA - Habilitación con Monitoreo Reforzado",
      texto_largo = paste(
        "El balneario CUMPLE con el Art. 8 pero presenta condiciones de alerta.",
        paste(advertencias, collapse = ". "),
        "Se recomienda intensificar el monitoreo."
      ),
      habilitado = TRUE,
      prioridad = 2,
      advertencias = advertencias,
      accion_requerida = "Monitoreo cada 48-72hs - Señalización preventiva"
    ))
  }
  
  # VERDE - Apto
  return(list(
    estado = "VERDE",
    color = "#28a745",
    color_hex = "#28a745",
    icono = "🟢",
    texto_corto = "APTO - Habilitado",
    texto_largo = sprintf(
      "El balneario CUMPLE con todos los requisitos del Art. 8 de la Resolución 084/SMA. E. coli MG: %.0f (límite: 300). Coliformes MG: %.0f (límite: 600). Mantener protocolo de monitoreo regular.",
      ecoli_mg, colif_mg
    ),
    habilitado = TRUE,
    prioridad = 3,
    accion_requerida = "Mantener monitoreo semanal de rutina"
  ))
}


#' Obtener color para mapas según estado
#' 
#' @param estado String: VERDE, AMARILLO, ROJO, SIN_DATOS
#' @return String con código de color hexadecimal
#' 
obtener_color_semaforo <- function(estado) {
  colores <- c(
    "VERDE" = "#28a745",
    "AMARILLO" = "#ffc107",
    "ROJO" = "#dc3545",
    "SIN_DATOS" = "#999999"
  )
  
  return(colores[estado])
}


#' Generar tabla resumen de clasificación
#' 
#' @param df_evaluaciones Data frame con evaluaciones de múltiples balnearios
#' @return Data frame con clasificación agregada
#' 
generar_resumen_clasificacion <- function(df_evaluaciones) {
  
  df_evaluaciones %>%
    group_by(estado) %>%
    summarise(
      cantidad = n(),
      balnearios = paste(balneario_nombre, collapse = ", "),
      .groups = "drop"
    ) %>%
    mutate(
      porcentaje = round(cantidad / sum(cantidad) * 100, 1),
      prioridad = case_when(
        estado == "ROJO" ~ 1,
        estado == "AMARILLO" ~ 2,
        estado == "VERDE" ~ 3,
        TRUE ~ 99
      )
    ) %>%
    arrange(prioridad)
}


#' Evaluar múltiples balnearios
#' 
#' @param df Data frame completo con datos de todos los balnearios
#' @param fecha_referencia Fecha de evaluación
#' @return Data frame con evaluación y clasificación por balneario
#' 
evaluar_todos_balnearios <- function(df, fecha_referencia = Sys.Date()) {
  
  balnearios_unicos <- unique(df$balneario_id)
  
  
  
  resultados <- lapply(balnearios_unicos, function(id) {
    
    df_balneario <- df %>% filter(balneario_id == id)
    
    # Información básica
    info_basica <- df_balneario %>%
      arrange(desc(fecha_muestreo)) %>%
      slice(1) %>%
      select(balneario_id, balneario_nombre, lat, lon)
    
    # Evaluación normativa
    evaluacion <- evaluar_balneario_completo(df_balneario, fecha_referencia)
    
    # Clasificación
    clasificacion <- clasificar_estado_sanitario(evaluacion)
    
    # Última muestra
    ultima_muestra <- df_balneario %>%
      filter(!is.na(fecha_muestreo)) %>%
      arrange(desc(fecha_muestreo)) %>%
      slice(1) %>%
      select(fecha_muestreo, e_coli, coliformes_termotolerantes)
    
    # Compilar resultado
    tibble(
      balneario_id = info_basica$balneario_id,
      balneario_nombre = info_basica$balneario_nombre,
      lat = info_basica$lat,
      lon = info_basica$lon,
      
      estado = clasificacion$estado,
      color = clasificacion$color,
      icono = clasificacion$icono,
      texto_corto = clasificacion$texto_corto,
      texto_largo = clasificacion$texto_largo,
      habilitado = clasificacion$habilitado,
      accion_requerida = clasificacion$accion_requerida,
      
      fecha_ultima_muestra = ultima_muestra$fecha_muestreo,
      ecoli_ultima = ultima_muestra$e_coli,
      colif_ultima = ultima_muestra$coliformes_termotolerantes,
      
      ecoli_mg_30d = evaluacion$resumen$ecoli_mg,
      colif_mg_30d = evaluacion$resumen$colif_mg,
      n_muestras_30d = evaluacion$resumen$ecoli_n_muestras,
      
      ecoli_excedencias = evaluacion$resumen$ecoli_excedencias,
      colif_excedencias = evaluacion$resumen$colif_excedencias
    )
  })
  
  bind_rows(resultados)
}


#' Generar reporte ejecutivo
#' 
#' @param clasificacion_df Data frame retornado por evaluar_todos_balnearios()
#' @return Lista con KPIs principales
#' 
generar_kpis_ejecutivos <- function(clasificacion_df) {
  
  total <- nrow(clasificacion_df)
  
  list(
    total_balnearios = total,
    aptos = sum(clasificacion_df$estado == "VERDE"),
    alerta = sum(clasificacion_df$estado == "AMARILLO"),
    no_aptos = sum(clasificacion_df$estado == "ROJO"),
    sin_datos = sum(clasificacion_df$estado == "SIN_DATOS"),
    
    pct_aptos = round(sum(clasificacion_df$estado == "VERDE") / total * 100, 1),
    pct_habilitados = round(sum(clasificacion_df$habilitado) / total * 100, 1),
    
    balnearios_criticos = clasificacion_df %>%
      filter(estado == "ROJO") %>%
      pull(balneario_nombre),
    
    fecha_evaluacion = Sys.Date()
  )
}
