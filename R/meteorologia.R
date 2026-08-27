# ============================================================
# Web Scraping - Estación Meteorológica EMA Paraná
# Fuente:
# https://www.hidraulica.gob.ar/ema/ema-parana/downld08.txt
# ============================================================


# ------------------------------------------------------------
# 0. CONFIGURACIÓN
# ------------------------------------------------------------

ruta_relativa <- "data/ema_parana_2026.csv"

url <- "https://www.hidraulica.gob.ar/ema/ema-parana/downld08.txt"

tz_local <- "America/Argentina/Cordoba"


# ------------------------------------------------------------
# 1. CARGAR DATOS HISTÓRICOS
# ------------------------------------------------------------

datos_hidraulicos_historicos_diarios <-
  get_data_local_csv(
    ruta_relativa,
    ","
  ) %>%
  mutate(
    Datetime = ymd_hms(
      Datetime,
      tz = tz_local
    )
  )


# Verificar que el archivo tenga datos
if (nrow(datos_hidraulicos_historicos_diarios) == 0) {
  
  stop(
    "El archivo histórico está vacío."
  )
  
}


# ------------------------------------------------------------
# 2. NORMALIZAR TIPOS DE DATOS HISTÓRICOS
# ------------------------------------------------------------

# Todas las variables meteorológicas son numéricas.
# Solamente Datetime es fecha/hora.

columnas_numericas <- c(
  "Temp_Ext",
  "Temp_Max",
  "Temp_Min",
  "Hum_Ext",
  "Pto_Rocio",
  "Vel_Viento",
  "Dir_Viento",
  "Rec_Viento",
  "Vel_Max",
  "Dir_Max",
  "Sens_Term",
  "Ind_Calor",
  "Ind_THW",
  "Ind_THSW",
  "Bar",
  "Lluvia",
  "Int_Lluvia",
  "Rad_Solar",
  "Int_Rad_Solar",
  "Max_Rad_Solar",
  "Indice_UV",
  "Dosis_UV",
  "UV_Max",
  "Grad_D_Calor",
  "Grad_D_Frio",
  "Temp_Int",
  "Hum_Int",
  "Rocio_Int",
  "In_Cal_Int",
  "EMC_Int",
  "Dens_Int",
  "ET",
  "Hum_Hoja1",
  "Vel_Muest_Viento",
  "Dir_Muest_Viento",
  "ISS",
  "Arc"
)


columnas_numericas <- intersect(
  columnas_numericas,
  names(datos_hidraulicos_historicos_diarios)
)


datos_hidraulicos_historicos_diarios[columnas_numericas] <-
  lapply(
    datos_hidraulicos_historicos_diarios[columnas_numericas],
    function(x) {
      suppressWarnings(
        as.numeric(x)
      )
    }
  )


# ------------------------------------------------------------
# 3. OBTENER ÚLTIMA FECHA HISTÓRICA
# ------------------------------------------------------------

ultima_fecha <- max(
  datos_hidraulicos_historicos_diarios$Datetime,
  na.rm = TRUE
)


cat(
  "\n========================================\n"
)

cat(
  "Última fecha histórica: ",
  format(
    ultima_fecha,
    "%d/%m/%Y %H:%M"
  ),
  "\n",
  sep = ""
)

cat(
  "========================================\n"
)


# ------------------------------------------------------------
# 4. DESCARGAR DATOS DE HIDRÁULICA
# ------------------------------------------------------------

response <- GET(url)


if (status_code(response) != 200) {
  
  stop(
    "Error al acceder al URL. Código de estado: ",
    status_code(response)
  )
  
}


# Decodificar contenido
contenido <- content(
  response,
  as = "text",
  encoding = "latin1"
)


# ------------------------------------------------------------
# 5. PROCESAMIENTO DE LÍNEAS
# ------------------------------------------------------------

lineas <- str_split(
  contenido,
  "\n"
)[[1]]


# Buscar separador
linea_sep <- which(
  str_detect(
    lineas,
    "^---"
  )
)[1]


if (is.na(linea_sep)) {
  
  stop(
    "No se encontró la línea separadora en el archivo descargado."
  )
  
}


# Obtener datos posteriores al separador
lineas_datos <- lineas[
  (linea_sep + 1):length(lineas)
]


# Eliminar líneas vacías
lineas_datos <- lineas_datos[
  nzchar(
    str_trim(lineas_datos)
  )
]


# ------------------------------------------------------------
# 6. DEFINIR NOMBRES DE COLUMNAS
# ------------------------------------------------------------

nombres_col <- c(
  
  "Fecha",
  "Hora",
  
  "Temp_Ext",
  "Temp_Max",
  "Temp_Min",
  
  "Hum_Ext",
  "Pto_Rocio",
  
  "Vel_Viento",
  "Dir_Viento",
  "Rec_Viento",
  
  "Vel_Max",
  "Dir_Max",
  
  "Sens_Term",
  "Ind_Calor",
  "Ind_THW",
  "Ind_THSW",
  
  "Bar",
  "Lluvia",
  "Int_Lluvia",
  
  "Rad_Solar",
  "Int_Rad_Solar",
  "Max_Rad_Solar",
  
  "Indice_UV",
  "Dosis_UV",
  "UV_Max",
  
  "Grad_D_Calor",
  "Grad_D_Frio",
  
  "Temp_Int",
  "Hum_Int",
  "Rocio_Int",
  
  "In_Cal_Int",
  "EMC_Int",
  "Dens_Int",
  
  "ET",
  "Hum_Hoja1",
  
  "Vel_Muest_Viento",
  "Dir_Muest_Viento",
  
  "ISS",
  "Arc"
)


n_col_esperadas <- length(
  nombres_col
)


# ------------------------------------------------------------
# 7. PARSEAR REGISTROS
# ------------------------------------------------------------

datos_lista <- lapply(
  
  lineas_datos,
  
  function(linea) {
    
    # Reemplazar "---" por NA
    linea_limpia <- str_replace_all(
      linea,
      "---",
      "NA"
    )
    
    # Separar columnas por espacios
    tokens <- str_split(
      str_trim(linea_limpia),
      "\\s+"
    )[[1]]
    
    tokens
    
  }
  
)


# ------------------------------------------------------------
# 8. FILTRAR REGISTROS VÁLIDOS
# ------------------------------------------------------------

datos_lista_ok <- Filter(
  
  function(x) {
    
    length(x) == n_col_esperadas
    
  },
  
  datos_lista
  
)


cat(
  "\nRegistros descargados: ",
  length(datos_lista),
  "\n",
  sep = ""
)

cat(
  "Registros válidos: ",
  length(datos_lista_ok),
  "\n",
  sep = ""
)


if (length(datos_lista_ok) == 0) {
  
  stop(
    "No se encontraron registros válidos en el archivo descargado."
  )
  
}


# ------------------------------------------------------------
# 9. CONSTRUIR DATA FRAME
# ------------------------------------------------------------

df_raw <- as.data.frame(
  
  do.call(
    rbind,
    datos_lista_ok
  ),
  
  stringsAsFactors = FALSE
  
)


colnames(df_raw) <- nombres_col


# ------------------------------------------------------------
# 10. CREAR DATETIME
# ------------------------------------------------------------

df_raw$Datetime <- as.POSIXct(
  
  paste(
    df_raw$Fecha,
    df_raw$Hora
  ),
  
  format = "%d/%m/%y %H:%M",
  
  tz = tz_local
  
)


# Eliminar registros con fecha inválida
df_raw <- df_raw %>%
  
  filter(
    !is.na(Datetime)
  )


# ------------------------------------------------------------
# 11. FILTRAR DATOS NUEVOS
# ------------------------------------------------------------

df_raw <- df_raw %>%
  
  filter(
    Datetime > ultima_fecha
  )


# ------------------------------------------------------------
# 12. PREPARAR DATOS NUEVOS
# ------------------------------------------------------------

if (nrow(df_raw) == 0) {
  
  message(
    "No hay nuevos datos posteriores a ",
    format(
      ultima_fecha,
      "%d/%m/%Y %H:%M"
    )
  )
  
  
  # Crear data frame vacío con la misma estructura
  datos_hidraulica_nuevos <-
    datos_hidraulicos_historicos_diarios[0, ]
  
  
} else {
  
  
  # ----------------------------------------------------------
  # CONVERTIR VARIABLES NUMÉRICAS
  # ----------------------------------------------------------
  
  columnas_nuevas <- intersect(
    columnas_numericas,
    names(df_raw)
  )
  
  
  df_raw[columnas_nuevas] <-
    lapply(
      
      df_raw[columnas_nuevas],
      
      function(x) {
        
        suppressWarnings(
          as.numeric(x)
        )
        
      }
      
    )
  
  
  # ----------------------------------------------------------
  # SELECCIONAR Y ORDENAR
  # ----------------------------------------------------------
  
  datos_hidraulica_nuevos <- df_raw %>%
    
    select(
      Datetime,
      everything(),
      -Fecha,
      -Hora
    ) %>%
    
    arrange(
      Datetime
    )
  
  
  cat(
    "\nRegistros nuevos encontrados: ",
    nrow(datos_hidraulica_nuevos),
    "\n",
    sep = ""
  )
  
}


# ------------------------------------------------------------
# 13. ASEGURAR TIPOS COMPATIBLES
# ------------------------------------------------------------

columnas_numericas_final <- intersect(
  
  columnas_numericas,
  
  intersect(
    names(datos_hidraulicos_historicos_diarios),
    names(datos_hidraulica_nuevos)
  )
  
)


# Histórico
datos_hidraulicos_historicos_diarios[
  columnas_numericas_final
] <-
  
  lapply(
    
    datos_hidraulicos_historicos_diarios[
      columnas_numericas_final
    ],
    
    function(x) {
      
      suppressWarnings(
        as.numeric(x)
      )
      
    }
    
  )


# Nuevos
datos_hidraulica_nuevos[
  columnas_numericas_final
] <-
  
  lapply(
    
    datos_hidraulica_nuevos[
      columnas_numericas_final
    ],
    
    function(x) {
      
      suppressWarnings(
        as.numeric(x)
      )
      
    }
    
  )


# ------------------------------------------------------------
# 14. ACTUALIZAR HISTÓRICO
# ------------------------------------------------------------

datos_hidraulicos_historicos_diarios <-
  
  bind_rows(
    
    datos_hidraulicos_historicos_diarios,
    
    datos_hidraulica_nuevos
    
  ) %>%
  
  arrange(
    Datetime
  )


# Eliminar posibles duplicados
datos_hidraulicos_historicos_diarios <-
  
  datos_hidraulicos_historicos_diarios %>%
  
  distinct(
    Datetime,
    .keep_all = TRUE
  )


# ------------------------------------------------------------
# 15. OBTENER ÚLTIMA SEMANA
# ------------------------------------------------------------

fecha_maxima <- max(
  
  datos_hidraulicos_historicos_diarios$Datetime,
  
  na.rm = TRUE
  
)


fecha_minima <- fecha_maxima - days(7)


datos_hidraulica_ultima_semana <-
  
  datos_hidraulicos_historicos_diarios %>%
  
  filter(
    
    Datetime >= fecha_minima,
    
    Datetime <= fecha_maxima
    
  ) %>%
  
  arrange(
    Datetime
  )


# ------------------------------------------------------------
# 16. RESUMEN DEL PROCESO
# ------------------------------------------------------------

cat(
  "\n\n"
)

cat(
  "========================================\n"
)

cat(
  "       RESUMEN EMA PARANÁ\n"
)

cat(
  "========================================\n"
)

cat(
  "Registros históricos: ",
  nrow(datos_hidraulicos_historicos_diarios),
  "\n",
  sep = ""
)

cat(
  "Registros nuevos: ",
  nrow(datos_hidraulica_nuevos),
  "\n",
  sep = ""
)

cat(
  "Registros última semana: ",
  nrow(datos_hidraulica_ultima_semana),
  "\n",
  sep = ""
)


cat(
  "Última fecha disponible: ",
  format(
    fecha_maxima,
    "%d/%m/%Y %H:%M"
  ),
  "\n",
  sep = ""
)


cat(
  "========================================\n"
)


# ------------------------------------------------------------
# 17. PERÍODO DE LA ÚLTIMA SEMANA
# ------------------------------------------------------------

if (
  nrow(datos_hidraulica_ultima_semana) > 0
) {
  
  cat(
    "Período analizado: ",
    format(
      min(
        datos_hidraulica_ultima_semana$Datetime,
        na.rm = TRUE
      ),
      "%d/%m/%Y %H:%M"
    ),
    " → ",
    format(
      max(
        datos_hidraulica_ultima_semana$Datetime,
        na.rm = TRUE
      ),
      "%d/%m/%Y %H:%M"
    ),
    "\n",
    sep = ""
  )
  
}


# ------------------------------------------------------------
# 18. RESUMEN ESTADÍSTICO
# ------------------------------------------------------------

vars_resumen <- c(
  
  "Temp_Ext",
  "Temp_Max",
  "Temp_Min",
  "Hum_Ext",
  "Vel_Viento",
  "Bar",
  "Lluvia",
  "Rad_Solar"
  
)


vars_resumen <- intersect(
  
  vars_resumen,
  
  names(
    datos_hidraulica_ultima_semana
  )
  
)


if (
  nrow(datos_hidraulica_ultima_semana) > 0 &&
  length(vars_resumen) > 0
) {
  
  cat(
    "\n=== RESUMEN ESTADÍSTICO ===\n"
  )
  
  print(
    
    summary(
      
      datos_hidraulica_ultima_semana[
        vars_resumen
      ]
      
    )
    
  )
  
}


# ------------------------------------------------------------
# 19. PRIMEROS REGISTROS
# ------------------------------------------------------------

if (
  nrow(datos_hidraulica_nuevos) > 0
) {
  
  cat(
    "\n=== PRIMEROS DATOS NUEVOS ===\n"
  )
  
  print(
    head(
      datos_hidraulica_nuevos[, 1:min(8, ncol(datos_hidraulica_nuevos))]
    )
  )
  
}