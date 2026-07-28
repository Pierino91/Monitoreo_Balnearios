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

# ---- CONFIGURACIÓN GLOBAL ----
MODO <- "produccion"   # "produccion" | "desarrollo"
EPICOLLECT_PROJECT <- "https://five.epicollect.net/api/export/project/aguas-recreativas-parana"
EPICOLLECT_ENTRIES <- "https://five.epicollect.net/api/export/entries/aguas-recreativas-parana?form_ref=0644b69a5e6e43f58e30699b127ee59c_6989c7775da43"
EPICOLLECT_BRANCH_ANALISIS <- "https://five.epicollect.net/api/export/entries/aguas-recreativas-parana?form_ref=0644b69a5e6e43f58e30699b127ee59c_6989c7775da43&branch_ref=0644b69a5e6e43f58e30699b127ee59c_6989c7775da43_6989c965fb6aa"
EPICOLLECT_BRANCH_PROCEDIMIENTO <- "https://five.epicollect.net/api/export/entries/aguas-recreativas-parana?form_ref=0644b69a5e6e43f58e30699b127ee59c_6989c7775da43&branch_ref=0644b69a5e6e43f58e30699b127ee59c_6989c7775da43_69984a61d5f08"

# TODO APPS en desarrollo
APPS <- FALSE
INTERVALO_ACTUALIZACION <- 3600  # segundos

# ---- MÓDULOS ----
source("R/api_epicollect5.R")
source("R/normativa.R")
source("R/semaforo.R")
# source("R/epicollect5Function.R")
