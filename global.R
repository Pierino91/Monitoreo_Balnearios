# global.R
# ============================================================================
# Carga GLOBAL de dependencias y configuración
# Se ejecuta ANTES de ui.R y server.R
# ============================================================================

# ---- LIBRERÍAS CORE ----
library(shiny)
library(shinydashboard)

# ---- VISUALIZACIÓN ----
library(leaflet)     
library(ggplot2)
library(plotly)
library(DT)

# ---- DATA ----
library(dplyr)
library(lubridate)
library(sf)
library(stringr)
library(httr)

# ---- CONFIGURACIÓN GLOBAL ----
MODO <- "produccion"   # "produccion" | "desarrollo"
EPICOLLECT_PROJECT <- "https://five.epicollect.net/api/export/project/aguas-recreativas-parana"
EPICOLLECT_ENTRIES <- "https://five.epicollect.net/api/export/entries/aguas-recreativas-parana?form_ref=0644b69a5e6e43f58e30699b127ee59c_6989c7775da43"
EPICOLLECT_BRANCH_ANALISIS <- "https://five.epicollect.net/api/export/entries/aguas-recreativas-parana?form_ref=0644b69a5e6e43f58e30699b127ee59c_6989c7775da43&branch_ref=0644b69a5e6e43f58e30699b127ee59c_6989c7775da43_6989c965fb6aa"
EPICOLLECT_BRANCH_PROCEDIMIENTO <- "https://five.epicollect.net/api/export/entries/aguas-recreativas-parana?form_ref=0644b69a5e6e43f58e30699b127ee59c_6989c7775da43&branch_ref=0644b69a5e6e43f58e30699b127ee59c_6989c7775da43_69984a61d5f08"

# TODO APPS en desarrollo
VERBOSE <- TRUE
APPS <- FALSE
INTERVALO_ACTUALIZACION <- 3600  # segundos
# ---- MÓDULOS ----

source("R/api_epicollect5.R")
source("R/normativa.R")
source("R/semaforo.R")
source("R/meteorologia.R")
source("R/data_access_local.R")

# source("R/epicollect5Function.R")

# ---- Complemento ----

mapa_balnearios <- sf::st_read("www/balnearios.geojson", quiet = TRUE)%>%
  dplyr::mutate(
    lon = sf::st_coordinates(geometry)[, 1],
    lat = sf::st_coordinates(geometry)[, 2]
  )%>%
  dplyr::rename(
    balneario_id="id_lugar"
  )

# ---- Funciones auxiliares ----

union_tipeo_mapa_datos <- function(df_raw, verbose = FALSE) {
  
  df_raw <- df_raw %>%
    mutate(
      # Fechas
      fecha_muestreo = as.Date(fecha_muestreo, format = "%d/%m/%Y"),
      
      # Numéricos
      e_coli = as.numeric(e_coli),
      coliformes_termotolerantes = as.numeric(coliformes_termotolerantes),
      # temperatura_agua = as.numeric(temperatura_agua),
      # ph = as.numeric(ph),
      # altura_rio = as.numeric(altura_rio),
      
      # Caracteres
      balneario_nombre = as.character(balneario_nombre),
      
      # Temporada (calculada)
      temporada = case_when(
        month(fecha_muestreo) %in% c(12, 1, 2, 3) ~ "Verano",
        TRUE ~ "Resto del año"
      )
    )
  
  #### Union con mapa ####
  
  df <- df_raw %>%
    left_join(mapa_balnearios %>%
                sf::st_drop_geometry(),
              by = c("balneario_nombre" = "balneario")
    ) %>%
    select(-any_of(c("fid")))%>%
    mutate(
      lat = as.numeric(lat),
      lon = as.numeric(lon)
    )
  

  if(verbose){
    
    message("🔄 union_tipeo_mapa_datos nombre de mapa")
    cat(sort(colnames(df)))
    
  }
  
  return(df)
}




  
