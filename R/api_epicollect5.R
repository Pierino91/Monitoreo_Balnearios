#' Conexión API Epicollect5
#' Funciones para obtener y procesar datos desde Epicollect5


library(httr)
library(jsonlite)
library(dplyr)
library(tidyr)
library(lubridate)
library(purrr)
library(roxygen2)


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

# TODO por el momento no se v a avalidar, lo vamos a dejar apra despues

#' @param project_slug Nombre del proyecto
#' @param mapeo_campos Mapeo personalizado (opcional)
#' @param client_id Client ID OAuth2 (opcional)
#' @param client_secret Client Secret OAuth2 (opcional)
#' @return Data frame limpio listo para análisis
#' 
cargar_datos_epicollect5 <- function(project_slug,
                                     client_entries,
                                     client_branch,
                                     verbose = FALSE) {
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
  if(verbose){
    message("PROCESAR")
    # cat(colnames(df_raw))
    cat(str(df_raw))
    
  }
  df_limpio <- procesar_datos_epicollect5(df_raw)
  
  # Validar
  if(verbose){
    message("VALIDAR")
    cat(colnames(df_limpio))
  }
  df_validado <- validar_datos_entrada(df_limpio)
  
  # Reporte de calidad
  if(verbose){
    message("REPORTE DE CALIDAD")
    cat(colnames(df_validado))
  }
  
  n_invalidos <- sum(!df_validado$registro_valido)
  if (n_invalidos > 0) {
    
    df_invalidado <- df_validado %>%
      filter(!registro_valido)
    
    warning(
      sprintf(
        "⚠ %d registros inválidos encontrados (%.1f%%). Balnearios: %s",
        n_invalidos,
        100 * n_invalidos / nrow(df_validado),
        paste(str(df_invalidado), collapse = ", ")
      )
    )
  }
  
  return(df_validado)
}


#' Obtener y Consolidar Datos de Formulario Principal y Subformularios (Branches) de Epicollect5
#'
#' @description
#' Descarga los registros principales de un formulario de Epicollect5 y realiza la unión 
#' secuencial con $N$ subformularios o branches pasados como lista o vector.
#'
#' @param client_entries \code{character} o \code{list}. Cadena de texto, URL o lista de parámetros 
#'   que identifica las entradas del formulario principal de Epicollect5.
#' @param client_branch \code{character}, \code{vector} o \code{list}, opcional. Identificador(es) 
#'   de uno o más subformularios/branches. Si es \code{NULL} o está vacío, únicamente se retornan 
#'   las entradas del formulario principal. Por defecto es \code{NULL}.
#' @param verbose \code{logical}. Si es \code{TRUE}, muestra en consola los mensajes de progreso 
#'   y diagnóstico de columnas (útil para depuración). Por defecto es \code{FALSE}.
#'
#' @return Un \code{tibble} o \code{data.frame} consolidado que contiene los datos del formulario 
#'   principal unidos (\code{left_join}) con todos los subformularios/branches procesados.
#'
#' @details
#' La función orquesta el proceso en cuatro pasos principales:
#' \enumerate{
#'   \item Descarga las entradas del formulario principal mediante \code{obtener_todas_entradas()}.
#'   \item Aplana el argumento \code{client_branch} para admitir múltiples estructuras (\code{list} o \code{c()}).
#'   \item Iterativamente descarga cada subformulario/branch y efectúa la unión relacional mediante \code{unir_entries_branch()}.
#'   \item Controla de forma defensiva los branches vacíos o nulos para evitar interrupciones en la ejecución.
#' }
#'
#' @import dplyr
#'
#' @examples
#' \dontrun{
#' # Descargar solo formulario principal
#' df_main <- obtener_datos_epicollect5(client_entries = "mi_form_ref")
#'
#' # Descargar principal y múltiples branches
#' df_completo <- obtener_datos_epicollect5(
#'   client_entries = "mi_form_ref",
#'   client_branch  = c("branch_laboratorio", "branch_campo"),
#'   verbose        = TRUE
#' )
#' }
#'
#' @export
obtener_datos_epicollect5 <- function(client_entries,
                                      client_branch = NULL,
                                      verbose = FALSE) {
  
  # 1. Obtener entradas del formulario principal
  df_entries <- obtener_todas_entradas(client_entries)
  
  if (is.null(df_entries) || nrow(df_entries) == 0) {
    warning("⚠ No se obtuvieron registros del formulario principal.")
    return(df_entries)
  }
  
  if (verbose) {
    message(sprintf("✓ Total descargado principal: %d registros", nrow(df_entries)))
  }
  
  # 2. Si no hay branches pasadas como argumento, retornar entradas principales
  if (is.null(client_branch) || length(client_branch) == 0) {
    return(df_entries)
  }
  
  # 3. Aplanar la lista/vector para soportar list() o vector c()
  branches_lista <- unlist(client_branch)
  
  if (verbose) {
    message(sprintf("✓ Branches a procesar (%d): %s", 
                    length(branches_lista), 
                    paste(branches_lista, collapse = ", ")))
  }
  
  df_resultado <- df_entries
  total_branches_descargadas <- 0
  
  # 4. Iterar dinámicamente sobre cada branch recibida
  for (branch in branches_lista) {
    
    df_branch <- obtener_todas_entradas(branch)
    
    if (!is.null(df_branch) && nrow(df_branch) > 0) {
      total_branches_descargadas <- total_branches_descargadas + nrow(df_branch)
      
      if (verbose) {
        message(sprintf("  -> Uniendo branch con %d registros...", nrow(df_branch)))
        message("Branch colnames: ")
        print(colnames(df_branch))
        
      }
      
      # Unir recursivamente la branch con el data frame acumulado
      df_resultado <- unir_entries_branch(df_resultado, df_branch)
    } else if (verbose) {
      message(sprintf("  ⚠ La branch '%s' está vacía o es nula. Se omite el cruce.", branch))
    }
  }
  
  if (verbose) {
    message(sprintf("✓ Total acumulado descargado en branches: %d registros", total_branches_descargadas))
    message(sprintf("✓ Total de columnas finales: %d", ncol(df_resultado)))
  }
  
  return(df_resultado)
}

#' Obtener todas las entradas de una URL/Ref de Epicollect5 y desempaquetar ubicación
#'
#' @description
#' Pagina automáticamente sobre todas las respuestas de la API de Epicollect5, 
#' convierte los tipos de datos numéricos a character de forma segura y desanida
#' las estructuras complejas de geolocalización (\code{latitude}, \code{longitude}, \code{accuracy}).
#'
#' @param base_url Carácter. URL completa, slug o referencia endpoint de la API.
#' @param verbose \code{logical}. Si es \code{TRUE}, imprime el avance de la paginación y el listado de columnas. Por defecto es \code{FALSE}.
#'
#' @return Un \code{tibble} con todos los registros parseados y las coordenadas desanidadas en caso de existir.
#' @export
obtener_todas_entradas <- function(base_url, verbose = FALSE) {
  
  all_entries <- dplyr::tibble()  # Inicializar el tibble vacío

  # Obtener el primer conjunto de datos
  operarios_crudo_get <- obtener_datos(base_url)
  pagina <- 1
  
  while (!is.null(operarios_crudo_get$links$self)) {
    
    if (!is.null(operarios_crudo_get$data$entries)) {
      
      # Convertir a tibble
      entries <- tibble::as_tibble(operarios_crudo_get$data$entries)
      
      # Convertir todas las columnas numéricas a character para evitar inconsistencias
      entries <- entries %>%
        dplyr::mutate(dplyr::across(dplyr::where(is.numeric), as.character))
      
      # Detectar si hay columnas con datos de ubicación (listas anidadas)
      if (verbose) {
        tipos_vars_entries <- sapply(entries, class)
        # Retorna un vector con los nombres de las columnas que son data frames/listas
        entries_desglosado<-desglosar_columnas_nested(entries)
        tipos_vars_entries_desglosado <- sapply(entries_desglosado, class)
        
      }
      
      entries_desglosado<-desglosar_columnas_nested(entries)

      # Acumular los datos principales
      all_entries <- dplyr::bind_rows(all_entries, entries_desglosado)
      
      if (verbose) {
        message(sprintf("   Página %d procesada (%d registros acumulados)", pagina, nrow(all_entries)))
      }
    }
    
    # Obtener el siguiente enlace de paginación
    next_link <- operarios_crudo_get$links$`next`
    
    if (is.null(next_link)) {
      break
    }
    
    pagina <- pagina + 1
    operarios_crudo_get <- obtener_datos(next_link)
    Sys.sleep(1)
  }
  
  # Reporte de diagnóstico solo si verbose = TRUE
  if (verbose) {
    message("\n--- Tipo de variable de 'tipos_vars_entries' ---")
    print(tipos_vars_entries)
    message("\n--- Tipo de variable de 'tipos_vars_entries_desglosado' ---")
    print(tipos_vars_entries_desglosado)
    message("--- Nombres de 'all_entries' (Ordenados) ---")
    print(sort(names(all_entries)))
  }
  
  # Retornar los datos combinados si existe información de ubicación desanidada
  return(all_entries)
}

#' Desglosar y Aplanar Columnas Anidadas en un Data Frame / Tibble
#'
#' @description
#' Detecta automáticamente las columnas dentro de un `data.frame` o `tibble` que 
#' contengan estructuras de datos anidadas (como `data.frame` internos o listas 
#' de `data.frame` provenientes de APIs o respuestas JSON) y las alana/desanida 
#' de forma segura y defensiva.
#'
#' @details
#' La función realiza dos pasos principales:
#' 1. **Detección Dinámica:** Evalúa cada columna para verificar si sus elementos 
#'    son de clase `data.frame` o si contiene listas cuyos elementos internos 
#'    son data frames (común en subformularios *branches* de Epicollect5 o APIs REST).
#' 2. **Desanidado Seguro:** Filtra registros nulos (`NULL`) para prevenir errores de 
#'    memoria o tipos de datos, y aplica `tidyr::unnest()` resolviendo duplicados de 
#'    nombres de columnas con `names_repair = "unique"` y preservando filas vacías 
#'    con `keep_empty = TRUE`.
#'
#' @param df Un `data.frame` o `tibble` que puede contener una o más columnas anidadas (*list-columns*).
#'
#' @return Un `tibble` desglosado con las columnas internas aplanadas al nivel principal.
#'
#' @keywords manipulación-datos api epicollect5 unnest tidyverse
#'
#' @export
#'
#' @examples
#' \link{dontrun}{
#'   # Ejemplo de uso con datos que contienen subformularios/branches
#'   df_procesado <- desglosar_columnas_nested(entries_raw)
#' }
#' 
desglosar_columnas_nested <- function(df) {
  
  # Validar que el argumento recibido sea un data.frame o tibble
  if (!is.data.frame(df)) {
    stop("El parámetro 'df' debe ser un data.frame o tibble.")
  }
  
  # ----------------------------------------------------------------------------
  # Paso 1: Detección automática de columnas anidadas
  # ----------------------------------------------------------------------------
  # Se mapea cada columna para verificar si:
  # - La columna en sí es un data.frame anidado.
  # - O la columna es una lista que contiene data.frames dentro de sus elementos.
  cols_nested <- names(df)[map_lgl(df, function(col_data) {
    is.data.frame(col_data) || 
      (is.list(col_data) && any(map_lgl(col_data, is.data.frame)))
  })]
  
  # Retorno temprano si no hay columnas anidadas que procesar
  if (length(cols_nested) == 0) {
    message("ℹ No se encontraron columnas anidadas con Data Frames.")
    return(df)
  }
  
  message(sprintf("✓ Columnas anidadas detectadas: %s", paste(cols_nested, collapse = ", ")))
  
  # ----------------------------------------------------------------------------
  # Paso 2: Desanidado dinámico y seguro de cada columna
  # ----------------------------------------------------------------------------
  df_desglosado <- df
  
  for (col in cols_nested) {
    df_desglosado <- df_desglosado %>% 
      # Elimina elementos NULL en la columna anidada para evitar excepciones al desanidar
      filter(!map_lgl(.data[[col]], is.null)) %>% 
      # Desanida expandiendo filas y columnas
      # - names_repair = "unique": evita errores si hay nombres de columnas duplicados entre el padre y el hijo
      # - keep_empty = TRUE: conserva filas de la tabla padre aunque el hijo no tenga datos (asigna NA)
      unnest(cols = all_of(col), names_repair = "unique", keep_empty = TRUE)
  }
  
  return(df_desglosado)
}

#' Unir Entradas Principales con Subformulario (Branch) de Epicollect5
#'
#' @description
#' Realiza una unión relacional (\code{left_join}) entre el data frame de entradas 
#' principales y un subformulario/branch. Limpia automáticamente columnas de auditoría
#' duplicadas y reporta detalles del proceso si se activa \code{verbose}.
#'
#' @param datos_entries \code{data.frame} o \code{tbl_df}. Entradas principales con la columna \code{ec5_uuid}.
#' @param datos_branch \code{data.frame} o \code{tbl_df}. Datos del subformulario con la columna \code{ec5_branch_owner_uuid}.
#' @param verbose \code{logical}. Si es \code{TRUE}, imprime los detalles de la unión y columnas excluidas. Por defecto es \code{FALSE}.
#'
#' @return Un \code{tibble} resultante del cruce relacional.
#' @export
#' 
unir_entries_branch <- function(datos_entries, datos_branch, verbose = FALSE) {
  
  # 1. Validaciones defensivas iniciales
  if (is.null(datos_entries) || nrow(datos_entries) == 0) {
    if (verbose) message("⚠ 'datos_entries' está vacío o es NULL. Se retorna 'datos_branch'.")
    return(datos_branch)
  }
  
  if (is.null(datos_branch) || nrow(datos_branch) == 0) {
    if (verbose) message("⚠ 'datos_branch' está vacío o es NULL. Se retorna 'datos_entries'.")
    return(datos_entries)
  }
  
  # 2. Verificar existencia de las llaves relacionales
  if (!"ec5_uuid" %in% names(datos_entries)) {
    stop("❌ Error: 'ec5_uuid' no existe en datos_entries.")
  }
  
  if (!"ec5_branch_owner_uuid" %in% names(datos_branch)) {
    stop("❌ Error: 'ec5_branch_owner_uuid' no existe en datos_branch.")
  }
  
  # 3. Evitar duplicidad de columnas administrativas (sufijos .x y .y)
  cols_repetidas <- intersect(names(datos_entries), names(datos_branch))
  cols_a_excluir <- setdiff(cols_repetidas, "ec5_branch_owner_uuid")
  
  if (length(cols_a_excluir) > 0) {
    if (verbose) {
      message(sprintf("ℹ Excluyendo %d columnas duplicadas del branch para evitar sufijos: %s", 
                      length(cols_a_excluir), 
                      paste(cols_a_excluir, collapse = ", ")))
    }
    datos_branch <- datos_branch %>% 
      dplyr::select(-dplyr::all_of(cols_a_excluir))
  }
  
  # 4. Unión relacional
  if (verbose) {
    message(sprintf("🔄 Uniendo entries (%d filas) con branch (%d filas)...", 
                    nrow(datos_entries), nrow(datos_branch)))
  }
  
  datos_proc <- datos_entries %>%
    dplyr::left_join(datos_branch, by = c("ec5_uuid" = "ec5_branch_owner_uuid"))
  
  if (verbose) {
    message(sprintf("✓ Unión completada: %d filas y %d columnas finales.", 
                    nrow(datos_proc), ncol(datos_proc)))
  }
  
  return(datos_proc)
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


#' Procesar y limpiar datos de Epicollect5
#' 
#' @param df_raw Data frame crudo de Epicollect5
#' @param mapeo_campos Lista con mapeo de campos (opcional)
#' @return Data frame limpio y tipado
#' 

procesar_datos_epicollect5 <- function(df_raw, mapeo_campos = NULL, verbose = FALSE) {
  
  if(verbose){
    message("🔄 nombres de las variables antes de er mapeadas")
    cat(sort(colnames(df_raw)))
    
  }
  
  # Mapear campos
  df <- mapear_campos_epicollect5(df_raw, mapeo_campos)
  
  if(verbose){
    message("🔄 nombres de las variables luego de mapear_campos_epicollect5")
    cat(sort(colnames(df)))
  }
  
  df_raw <- union_tipeo_mapa_datos(df)
  
  if(verbose){
    message("🔄 nombres de las variables luego de union_tipeo_mapa_datos")
    cat(sort(colnames(df_raw)))
  }
  
  
  message(sprintf("✓ Datos procesados: %d registros únicos", nrow(df_raw)))
  
  return(df_raw)
  
}

#' Mapear campos de Epicollect5 a esquema interno
#' 
#' @param df_raw Data frame crudo de Epicollect5
#' @param mapeo_campos Lista con mapeo de nombres de campos
#' @return Data frame normalizado
#' 

mapear_campos_epicollect5 <- function(df_raw, mapeo_campos = NULL, Verbose = FALSE) {
  
  # Mapeo default (ajustar según estructura real del proyecto)
  if(Verbose){
    message("Nombres de mapear_campos_epicollect5 de df_raw: ", paste(names(df_raw), collapse = ", "))
  }
  
  if (is.null(mapeo_campos)) {
    mapeo_campos <- list(
      clave_unica = "ec5_uuid",
      clave_unica_branch ="ec5_branch_uuid",
      Fecha_creación_entrada ="created_at",
      Fecha_subida_entrada = "uploaded_at",
      titulo_unico = "title",
      agente="2_Agente_responsable",
      balneario_nombre = "3_Balneario",
      actividad = "4_Qu_actividad_va_a_",
      analisis_agua = "5_Anlisis_de_aguas_b",
      proceso_agua = "12_Procedimiento_par",
      fecha_muestreo = "7_Fecha",
      N_muestra = "8_Nmero_de_muestra",
      coliformes_termotolerantes = "9_Coliformes_totales",
      e_coli = "10_E_Coli",
      imagenes = "11_ImagenDelAnalisis"
    
    )
  }
  
  # Crear data frame mapeado
  df_mapeado <- df_raw
  if(Verbose){
    message("Clase de mapeo_campos: ", class(mapeo_campos))
    message("Longitud: ", length(mapeo_campos))
    message("Nombres de mapeo_campos: ", paste(names(mapeo_campos), collapse = ", "))
  }
  for ( campo_interno in names(mapeo_campos)) {
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
  
  if(Verbose){
    message("--- FLAG Nombres de df_mapeado ---")
    cat(class(df_mapeado), sep = "\n")
    cat(str(df_mapeado), sep = "\n")
  }

  return(df_mapeado)
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
