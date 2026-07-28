#' Conexión API Epicollect5
#' Funciones para obtener y procesar datos desde Epicollect5


library(httr)
library(jsonlite)
library(dplyr)
library(lubridate)
library(purrr)



# ----------- FUNCIONES DE CARGA DE DATOS API ----------- #

obtener_datos <- function(url) {
  response <- GET(url)
  if (status_code(response) == 200) {
    content <- fromJSON(content(response, as = "text"))
    return(content)
  } else {
    warning(paste("Error al acceder al enlace:", url, " - Código de estado: ", status_code(response)))
    return(NULL)
  }
}

obtener_todas_entradas <- function(base_url) {
  
  all_entries <- tibble()  # Inicializar el tibble vacío
  all_lugar <- tibble()    # Inicializar el tibble para coordenadas si existen
  
  # Obtener el primer conjunto de datos
  operarios_crudo_get <- obtener_datos(base_url)
  # operarios_crudo_get <- obtener_datos(EPICOLLECT_ENTRIES)
  # operarios_crudo_get <- obtener_datos(EPICOLLECT_BRANCH_PROCEDIMIENTO)
  
  
  while (!is.null(operarios_crudo_get$links$self)) {
    
    if (!is.null(operarios_crudo_get$data$entries)) {
      
      # Convertir a tibble
      entries <- as_tibble(operarios_crudo_get$data$entries)
      
      # Convertir todas las columnas numéricas a character
      entries <- entries %>%
        mutate(across(where(is.numeric), as.character))
      
      # Detectar si hay una columna con datos de ubicación y procesarla
      
      col_lugar <- names(entries)[
        sapply(entries, function(x) {
          is.list(x) &&
            length(x) > 0 &&
            all(c("latitude","longitude","accuracy") %in% names(x[[1]]))
        })
      ]
      
      if (length(col_lugar) > 0) {
        
        lugar_df <- entries |>
          dplyr::pull(col_lugar[1]) |>
          purrr::map_dfr(~tibble::tibble(
            latitude  = .x$latitude,
            longitude = .x$longitude,
            accuracy  = .x$accuracy
          ))
        
      }
  
      # Acumular los datos
      all_entries <- bind_rows(all_entries, entries)
    }
    
    # Obtener el siguiente enlace
    next_link <- operarios_crudo_get$links$`next`
    
    # Si no hay más páginas, salir del bucle
    if (is.null(next_link)) {
      break
    }
    
    # Obtener el siguiente conjunto de datos
    operarios_crudo_get <- obtener_datos(next_link)
    Sys.sleep(1)
  }
  
  # Retornar los datos combinados si existe información de ubicación
  if (nrow(all_lugar) > 0) {
    return(cbind(all_entries, all_lugar))
  } else {
    return(all_entries)
  }
}

unir_entries_branch <- function(
    datos_entries,
    datos_branch){
  
  datos_proc <-
    datos_entries %>%
    merge(datos_branch, by.y ="ec5_branch_owner_uuid", by.x="ec5_uuid") 
  
  # head(datos_proc)
  
  return(datos_proc)
}

################# OBTENER DATOS CON API#################

#' Obtener datos desde Epicollect5
#' 
#' @param project_slug Nombre del proyecto en Epicollect5
#' @param form_ref Referencia del formulario (default: NULL usa primer form)
#' @param client_id Client ID para autenticación (opcional)
#' @param client_secret Client Secret para autenticación (opcional)
#' 
#' @return Data frame con datos crudos
#' 
# obtener_datos_epicollect5 <- function(project_slug, 
#                                       form_ref = NULL,
#                                       client_id = NULL,
#                                       client_secret = NULL) {
#   
#   # URL base de la API
#   base_url <- "https://five.epicollect.net/api/export/entries"
#   
#   # Construir URL
#   url <- paste0(base_url, "/", project_slug)
#   
#   # Parámetros de consulta
#   query_params <- list(
#     per_page = 1000,  # Máximo permitido
#     page = 1
#   )
#   
#   if (!is.null(form_ref)) {
#     query_params$form_ref <- form_ref
#   }
#   
#   # Headers
#   headers <- c(
#     "Accept" = "application/json"
#   )
#   
#   # Si hay credenciales, obtener token OAuth2
#   if (!is.null(client_id) && !is.null(client_secret)) {
#     token <- obtener_token_oauth2(client_id, client_secret)
#     headers <- c(headers, "Authorization" = paste("Bearer", token))
#   }
#   
#   # Inicializar lista para almacenar datos
#   todos_los_datos <- list()
#   pagina_actual <- 1
#   
#   message(sprintf("Descargando datos del proyecto: %s", project_slug))
#   
#   # Paginación
#   repeat {
#     
#     query_params$page <- pagina_actual
#     
#     # Realizar request
#     response <- tryCatch({
#       GET(
#         url = url,
#         query = query_params,
#         add_headers(.headers = headers),
#         timeout(30)
#       )
#     }, error = function(e) {
#       stop(sprintf("Error de conexión: %s", e$message))
#     })
#     
#     # Verificar status
#     if (status_code(response) != 200) {
#       stop(sprintf(
#         "Error en API Epicollect5 (código %d): %s",
#         status_code(response),
#         content(response, "text", encoding = "UTF-8")
#       ))
#     }
#     
#     # Parsear JSON
#     datos_json <- content(response, "text", encoding = "UTF-8")
#     datos_lista <- fromJSON(datos_json, flatten = TRUE)
#     
#     # Extraer entries
#     if (is.null(datos_lista$data$entries) || length(datos_lista$data$entries) == 0) {
#       break  # No hay más datos
#     }
#     
#     todos_los_datos[[pagina_actual]] <- datos_lista$data$entries
#     
#     message(sprintf("  Página %d descargada: %d registros", 
#                     pagina_actual, 
#                     nrow(datos_lista$data$entries)))
#     
#     # Verificar si hay más páginas
#     if (is.null(datos_lista$links$`next`) || datos_lista$links$`next` == "") {
#       break
#     }
#     
#     pagina_actual <- pagina_actual + 1
#     
#     # Pausa cortés entre requests
#     Sys.sleep(0.5)
#   }
#   
#   # Combinar todas las páginas
#   if (length(todos_los_datos) == 0) {
#     stop("No se obtuvieron datos del proyecto")
#   }
#   
#   df_completo <- bind_rows(todos_los_datos)
#   
#   message(sprintf("✓ Total descargado: %d registros", nrow(df_completo)))
#   
#   return(df_completo)
# }

obtener_datos_epicollect5 <- function(client_entries,
                                      client_branch = NULL) {
  
  df_entries <- obtener_todas_entradas(client_entries)
  
  if(!is.null(client_branch)){
    
    df_branch <- obtener_todas_entradas(client_branch)
    
    message(sprintf("✓ Total descargado: %d registros", nrow(df_entries)))
    message(sprintf("✓ Total descargado: %d branch", nrow(df_branch)))
    
    return(unir_entries_branch(df_entries,df_branch))
  }else{
    message(sprintf("✓ Total descargado: %d registros", nrow(df_entries)))
    return(df_entries)
    
  }
  
}

#' Wrapper completo: obtener y procesar datos
#' 
#' @param project_slug Nombre del proyecto
#' @param mapeo_campos Mapeo personalizado (opcional)
#' @param client_id Client ID OAuth2 (opcional)
#' @param client_secret Client Secret OAuth2 (opcional)
#' @return Data frame limpio listo para análisis
#' 
# cargar_datos_epicollect5 <- function(project_slug,
#                                      mapeo_campos = NULL,
#                                      client_id = NULL,
#                                      client_secret = NULL) {
#   
#   
#   # Obtener datos crudos
#   df_raw <- obtener_datos_epicollect5(
#     project_slug = project_slug,
#     client_id = client_id,
#     client_secret = client_secret
#   )
#   
#   # Procesar
#   df_limpio <- procesar_datos_epicollect5(df_raw, mapeo_campos)
#   
#   # Validar
#   source("R/normativa.R")
#   df_validado <- validar_datos_entrada(df_limpio)
#   
#   # Reporte de calidad
#   n_invalidos <- sum(!df_validado$registro_valido)
#   if (n_invalidos > 0) {
#     warning(sprintf(
#       "⚠ %d registros inválidos encontrados (%.1f%%)",
#       n_invalidos,
#       n_invalidos / nrow(df_validado) * 100
#     ))
#   }
#   
#   return(df_validado)
# }


cargar_datos_epicollect5 <- function(client_entries = NULL,
                                     client_branch = NULL) {
  # Obtener datos crudos
  if(!is.null(client_branch)){
    df_raw <- obtener_datos_epicollect5(
      client_entries = client_entries,
      client_branch = client_branch
    )
  }else{
    df_raw <- obtener_datos_epicollect5(
      client_entries = client_entries,
      client_branch = NULL
    )
  }

  # Procesar
  df_limpio <- procesar_datos_epicollect5(df_raw)
  
  # Validar
  source("R/normativa.R")
  df_validado <- validar_datos_entrada(df_limpio)
  
  # Reporte de calidad
  n_invalidos <- sum(!df_validado$registro_valido)
  if (n_invalidos > 0) {
    warning(sprintf(
      "⚠ %d registros inválidos encontrados (%.1f%%)",
      n_invalidos,
      n_invalidos / nrow(df_validado) * 100
    ))
  }
  
  return(df_validado)
}


#' Obtener token OAuth2 (si se requiere autenticación)
#' 
#' @param client_id Client ID
#' @param client_secret Client Secret
#' @return String con token de acceso
#' 

obtener_token_oauth2 <- function(client_id, client_secret) {
  
  token_url <- "https://five.epicollect.net/api/oauth/token"
  
  response <- POST(
    url = token_url,
    body = list(
      grant_type = "client_credentials",
      client_id = client_id,
      client_secret = client_secret
    ),
    encode = "form"
  )
  
  if (status_code(response) != 200) {
    stop("Error al obtener token OAuth2")
  }
  
  token_data <- content(response)
  return(token_data$access_token)
}


#' Mapear campos de Epicollect5 a esquema interno
#' 
#' @param df_raw Data frame crudo de Epicollect5
#' @param mapeo_campos Lista con mapeo de nombres de campos
#' @return Data frame normalizado
#' 
mapear_campos_epicollect5 <- function(df_raw, mapeo_campos = NULL) {
  
  # Mapeo default (ajustar según estructura real del proyecto)
  if (is.null(mapeo_campos)) {
    mapeo_campos <- list(
      agente="2_Agente_responsable",
      balneario_nombre = "3_Balneario",
      lat = "lat_4_Localizacion",
      lon = "long_4_Localizacion",
      fecha_muestreo = "8_Fecha_Muestra",
      coliformes_termotolerantes = "8_Coliformes_totales",
      e_coli = "9_E_Coli"
      
      # balneario_id = "1_Balneario_ID",
      # municipio = "3_Municipio",
      # hora_muestreo = "6_Hora",
      # temperatura_agua = "9_Temperatura_Agua_C",
      # ph = "10_pH",
      # lluvias_previas = "11_Lluvias_72h_Previas",
      # altura_rio = "12_Altura_Rio_cm"
      
    )
  }
  
  # Crear data frame mapeado
  df_mapeado <- df_raw
  
  for (campo_interno in names(mapeo_campos)) {
    campo_epicollect <- mapeo_campos[[campo_interno]]
    
    if (campo_epicollect %in% names(df_raw)) {
      df_mapeado[[campo_interno]] <- df_raw[[campo_epicollect]]
    } else {
      warning(sprintf("Campo '%s' no encontrado en datos de Epicollect5", campo_epicollect))
      df_mapeado[[campo_interno]] <- NA
    }
  }
  
  # Seleccionar solo campos mapeados
  df_mapeado <- df_mapeado %>%
    select(all_of(names(mapeo_campos)))
  
  return(df_mapeado)
}


#' Procesar y limpiar datos de Epicollect5
#' 
#' @param df_raw Data frame crudo de Epicollect5
#' @param mapeo_campos Lista con mapeo de campos (opcional)
#' @return Data frame limpio y tipado
#' 

procesar_datos_epicollect5 <- function(df_raw, mapeo_campos = NULL) {
  
  # Mapear campos
  df <- mapear_campos_epicollect5(df_raw, mapeo_campos)
  
  # Limpiar y tipar
  df <- df %>%
    mutate(
      # Fechas
      fecha_muestreo = as.Date(fecha_muestreo),
      
      # Numéricos
      e_coli = as.numeric(e_coli),
      coliformes_termotolerantes = as.numeric(coliformes_termotolerantes),
      # temperatura_agua = as.numeric(temperatura_agua),
      # ph = as.numeric(ph),
      lat = as.numeric(lat),
      lon = as.numeric(lon),
      # altura_rio = as.numeric(altura_rio),
      
      # Caracteres
      # balneario_id = as.character(balneario_id),
      balneario_nombre = as.character(balneario_nombre),

      # Temporada (calculada)
      temporada = case_when(
        month(fecha_muestreo) %in% c(12, 1, 2, 3) ~ "Verano",
        TRUE ~ "Resto del año"
      )
    ) %>%
    # Remover duplicados exactos
      mutate(ID = row_number()
      )
  
  message(sprintf("✓ Datos procesados: %d registros únicos", nrow(df)))
  
  return(df)
  
}



#' Simular datos para desarrollo/testing
#' 
#' @param n_balnearios Número de balnearios
#' @param n_muestras_por_balneario Muestras por balneario
#' @return Data frame simulado
#' 
simular_datos_desarrollo <- function(n_balnearios = 5, n_muestras_por_balneario = 30) {
  
  set.seed(42)
  
  balnearios <- tibble(
    balneario_id = sprintf("BAL_%03d", 1:n_balnearios),
    balneario_nombre = c(
      "Balneario La Toma",
      "Balneario Thompson",
      "Camping La Delfina",
      "Playa Ubajay",
      "Costa del Sol"
    )[1:n_balnearios],
    municipio = sample(c("Concordia", "Colón", "Gualeguaychú", "Concepción del Uruguay"), 
                       n_balnearios, replace = TRUE),
    lat = runif(n_balnearios, -32.5, -31.0),
    lon = runif(n_balnearios, -58.5, -58.0)
  )
  
  datos <- lapply(1:n_balnearios, function(i) {
    
    # Simular perfil del balneario
    perfil <- sample(c("BUENO", "REGULAR", "MALO"), 1, prob = c(0.5, 0.3, 0.2))
    
    # Parámetros según perfil
    params <- switch(perfil,
      "BUENO" = list(
        ecoli_media = 150,
        ecoli_sd = 80,
        colif_media = 300,
        colif_sd = 150
      ),
      "REGULAR" = list(
        ecoli_media = 250,
        ecoli_sd = 100,
        colif_media = 500,
        colif_sd = 200
      ),
      "MALO" = list(
        ecoli_media = 400,
        ecoli_sd = 200,
        colif_media = 800,
        colif_sd = 300
      )
    )
    
    tibble(
      balneario_id = balnearios$balneario_id[i],
      balneario_nombre = balnearios$balneario_nombre[i],
      municipio = balnearios$municipio[i],
      lat = balnearios$lat[i],
      lon = balnearios$lon[i],
      
      fecha_muestreo = seq(Sys.Date() - days(n_muestras_por_balneario * 2), 
                           Sys.Date(), 
                           by = "2 days")[1:n_muestras_por_balneario],
      hora_muestreo = "10:00",
      
      e_coli = pmax(0, rnorm(n_muestras_por_balneario, params$ecoli_media, params$ecoli_sd)),
      coliformes_termotolerantes = pmax(0, rnorm(n_muestras_por_balneario, params$colif_media, params$colif_sd)),
      
      temperatura_agua = rnorm(n_muestras_por_balneario, 22, 3),
      ph = rnorm(n_muestras_por_balneario, 7.2, 0.4),
      lluvias_previas = sample(c("SI", "NO"), n_muestras_por_balneario, replace = TRUE, prob = c(0.3, 0.7)),
      altura_rio = rnorm(n_muestras_por_balneario, 250, 50),
      
      temporada = case_when(
        month(fecha_muestreo) %in% c(12, 1, 2, 3) ~ "Verano",
        TRUE ~ "Resto del año"
      ),
      
      registro_valido = TRUE
    )
  })
  
  df <- bind_rows(datos)
  
  message(sprintf("✓ Datos simulados generados: %d registros", nrow(df)))
  
  return(df)
}
