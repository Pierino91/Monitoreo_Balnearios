# server.R
server <- function(input, output, session) {
  
  # ---- DATOS REACTIVOS ----
  
  datos_base <- reactiveVal(NULL)
  clasificacion_actual <- reactiveVal(NULL)
  ultima_actualizacion <- reactiveVal(NULL)
  
  # Cargar datos al inicio
  observeEvent(TRUE, {
    
    message("🚀 Inicio de carga de datos")
    
    withProgress(message = 'Cargando datos...', value = 0, {
      
      incProgress(0.3, detail = "Conectando con Epicollect5...")
      
      datos <- NULL
      
      if (MODO == "produccion") {
        
        message("📡 Modo producción")
        message("📡 Proyecto: ", EPICOLLECT_PROJECT)
        
        datos <- tryCatch({
          
          resultado <- cargar_datos_epicollect5(
            project_slug = EPICOLLECT_PROJECT,
            client_entries = EPICOLLECT_ENTRIES,
            client_branch = EPICOLLECT_BRANCH_ANALISIS
          )
          
          message("✅ cargar_datos_epicollect5 finalizó")
          message("📊 Registros recibidos: ", nrow(resultado))
          
          resultado
          
        }, error = function(e) {
          
          message("❌ ERROR: ", e$message)
          
          showNotification(
            paste("Error al cargar datos:", e$message),
            type = "error",
            duration = 10
          )
          
          NULL
        })
        
      } else {
        
        message("🧪 Modo desarrollo")
        
        datos <- simular_datos_desarrollo(
          n_balnearios = 8,
          n_muestras_por_balneario = 40
        )
        
        message("📊 Registros simulados: ", nrow(datos))
      }
      
      message("🔍 is.null(datos) = ", is.null(datos))
      
      if (is.null(datos)) {
        message("⛔ Se aborta porque datos es NULL")
        return()
      }
      
      message("📋 Columnas:")
      print(names(datos))
      
      message("📋 Primeras filas:")
      print(head(datos))
      
      datos_base(datos)
      
      incProgress(0.9, detail = "Evaluando balnearios...")
      
      message("🏖️ Ejecutando evaluar_todos_balnearios()")
      
      clasificacion <- evaluar_todos_balnearios(datos)
      
      message("✅ Balnearios evaluados: ", nrow(clasificacion))
      
      clasificacion_actual(clasificacion)
      
      ultima_actualizacion(Sys.time())
      
      incProgress(1, detail = "Completado")
      
      message("🎉 Proceso completado")
    })
  })
  
  # Actualización manual
  # observeEvent(input$btn_actualizar, {
  #   
  #   withProgress(message = 'Actualizando...', value = 0, {
  #     
  #     incProgress(0.5)
  #     
  #     if (MODO == "produccion") {
  #       datos <- cargar_datos_epicollect5(
  #         client_entries = EPICOLLECT_ENTRIES,
  #         client_branch = EPICOLLECT_BRANCH_ANALISIS
  #       )
  #     } else {
  #       datos <- simular_datos_desarrollo(n_balnearios = 8, n_muestras_por_balneario = 40)
  #     }
  #     
  #     datos_base(datos)
  #     clasificacion <- evaluar_todos_balnearios(datos)
  #     clasificacion_actual(clasificacion)
  #     ultima_actualizacion(Sys.time())
  #     
  #     incProgress(1)
  #   })
  #   
  #   showNotification("Datos actualizados", type = "message")
  # })
  # Actualización automática periódica
  
  observe({
    invalidateLater(INTERVALO_ACTUALIZACION * 1000)
    
    if (MODO == "produccion") {
      # Solo en producción
      datos <- cargar_datos_epicollect5(
        client_entries = EPICOLLECT_ENTRIES,
        client_branch = EPICOLLECT_BRANCH_ANALISIS
      )
      
      datos_base(datos)
      
      clasificacion <- evaluar_todos_balnearios(datos)
      clasificacion_actual(clasificacion)
      ultima_actualizacion(Sys.time())
    }
  })
  
  # Actualizar selectores
  observe({
    req(datos_base())
    
    balnearios <- sort(unique(datos_base()$balneario_nombre))
    updateSelectInput(session, "filtro_balneario", choices = c("Todos" = "all", balnearios))
  })
  
  # ---- DATOS FILTRADOS ----
  
  datos_diarios <- reactive({
    req(datos_hidraulicos_historicos_diarios)
    
    datos_hidraulicos_historicos_diarios %>%
      group_by(Fecha = as.Date(Datetime)) %>%
      summarise(
        Temp_Max = max(Temp_Max, na.rm = TRUE),
        Temp_Min = min(Temp_Min, na.rm = TRUE),
        Temp_Prom = mean(Temp_Ext, na.rm = TRUE),
        Lluvia_Total = sum(Lluvia, na.rm = TRUE),
        .groups = "drop"
      )
  })
  
  datos_semanales <- reactive({
    datos_hidraulica_ultima_semana
  })
  
  ### TODO incorporar el filtro en los datos meteorológicos
  
  datos_filtrados <- reactive({
    req(datos_base())
    
    df <- datos_base()
    
    # Filtro de fechas
    df <- df %>%
      filter(
        fecha_muestreo >= input$rango_fechas[1],
        fecha_muestreo <= input$rango_fechas[2]
      )
    
    
    # Filtro de balneario
    if (!is.null(input$filtro_balneario) && input$filtro_balneario != "all") {
      df <- df %>% filter(balneario_nombre == input$filtro_balneario)
    }
    
    return(df)
  })
  
  clasificacion_filtrada <- reactive({
    
    req(clasificacion_actual(), datos_filtrados())
    
    balnearios_filtrados <- unique(datos_filtrados()$balneario_id)

    clasificacion_actual() %>%
      filter(balneario_id %in% balnearios_filtrados)
    
  })
  
  # ---- KPIs ----
  
  output$kpi_total <- renderValueBox({
    req(clasificacion_filtrada())
    
    valueBox(
      value = nrow(clasificacion_filtrada()),
      subtitle = "Total Balnearios",
      icon = icon("water"),
      color = "blue"
    )
  })
  
  output$kpi_aptos <- renderValueBox({
    req(clasificacion_filtrada())
    
    n_aptos <- sum(clasificacion_filtrada()$estado == "VERDE")
    
    valueBox(
      value = n_aptos,
      subtitle = "Aptos (Verde)",
      icon = icon("check-circle"),
      color = "green"
    )
  })
  
  output$kpi_alerta <- renderValueBox({
    req(clasificacion_filtrada())
    
    n_alerta <- sum(clasificacion_filtrada()$estado == "AMARILLO")
    
    valueBox(
      value = n_alerta,
      subtitle = "Alerta (Amarillo)",
      icon = icon("exclamation-triangle"),
      color = "yellow"
    )
  })
  
  output$kpi_no_aptos <- renderValueBox({
    req(clasificacion_filtrada())
    
    n_rojo <- sum(clasificacion_filtrada()$estado == "ROJO")
    
    valueBox(
      value = n_rojo,
      subtitle = "No Aptos (Rojo)",
      icon = icon("times-circle"),
      color = "red"
    )
  })
  
  # ---- GRÁFICO RESUMEN ESTADOS ----
  
  output$grafico_resumen_estados <- renderPlotly({
    req(clasificacion_filtrada())
    
    resumen <- clasificacion_filtrada() %>%
      count(estado) %>%
      mutate(
        color = case_when(
          estado == "VERDE" ~ "#28a745",
          estado == "AMARILLO" ~ "#ffc107",
          estado == "ROJO" ~ "#dc3545",
          TRUE ~ "#999999"
        ),
        etiqueta = case_when(
          estado == "VERDE" ~ "Apto",
          estado == "AMARILLO" ~ "Alerta",
          estado == "ROJO" ~ "No Apto",
          TRUE ~ "Sin Datos"
        )
      )
    
    plot_ly(
      data = resumen,
      labels = ~etiqueta,
      values = ~n,
      type = 'pie',
      marker = list(colors = ~color),
      textinfo = 'label+percent',
      hovertemplate = '<b>%{label}</b><br>Cantidad: %{value}<extra></extra>'
    ) %>%
      layout(
        showlegend = TRUE,
        margin = list(l = 10, r = 10, t = 10, b = 10)
      )
  })
  
  # ---- MAPA RESUMEN ----
  
  output$mapa_resumen <- renderLeaflet({
    req(clasificacion_filtrada())
    
    clasificacion_filtrada() %>%
      leaflet() %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      addCircleMarkers(
        lng = ~lon,
        lat = ~lat,
        radius = 8,
        color = ~color,
        fillColor = ~color,
        fillOpacity = 0.8,
        weight = 2,
        popup = ~paste0(
          "<b>", balneario_nombre, "</b><br>",
          "Estado: ", icono, " ", texto_corto, "<br>"
      )
      ) %>%
      setView(lng = -58.2, lat = -31.8, zoom = 8)
  })
  
  # ---- DATOS METEOROLÓGICOS ----
  
  output$grafico_meteo_horario <- renderPlotly({
    req(datos_hidraulicos)
    
    df_diario <- datos_diarios()
    
    req(nrow(df_diario) > 0)
    
    plot_ly(data = df_diario, x = ~Fecha) %>%
      
      add_trace(
        y = ~Temp_Max, 
        name = 'Temp. Máxima Diaria (°C)', 
        type = 'scatter', 
        mode = 'lines',
        line = list(
          color = 'rgba(239, 83, 80, 0.7)', 
          width = 1.5, 
          dash = 'dot'
        )
      ) %>%
      
      add_trace(
        y = ~Temp_Prom, 
        name = 'Temp. Promedio Diaria (°C)', 
        type = 'scatter', 
        mode = 'lines+markers',
        line = list(
          color = '#FF5722', 
          width = 2
        ),
        marker = list(
          color = '#FF5722', 
          size = 6
        )
      ) %>%
      
      add_trace(
        y = ~Temp_Min, 
        name = 'Temp. Mínima Diaria (°C)', 
        type = 'scatter', 
        mode = 'lines',
        line = list(
          color = 'rgba(66, 165, 245, 0.7)', 
          width = 1.5, 
          dash = 'dot'
        )
      ) %>%
      
      add_trace(
        y = ~Lluvia_Total, 
        name = 'Lluvia Total (mm/día)', 
        type = 'bar',
        yaxis = 'y2',
        marker = list(
          color = '#2196F3', 
          opacity = 0.5
        )
      ) %>%
      
      layout(
        
        title = list(
          text = "<b>Resumen Meteorológico Diario - Estación Paraná</b>", 
          font = list(size = 16)
        ),
        
        xaxis = list(
          title = "Fecha", 
          type = 'date', 
          tickformat = "%d/%m/%Y", 
          showgrid = TRUE
        ),
        
        yaxis = list(
          title = "Temperatura (°C)", 
          showgrid = TRUE
        ),
        
        yaxis2 = list(
          title = "Precipitación Acumulada (mm)", 
          overlaying = "y", 
          side = "right", 
          showgrid = FALSE
        ),
        
        hovermode = "x unified",
        
        legend = list(
          orientation = 'h', 
          x = 0.05, 
          y = -0.2
        ),
        
        # --------------------------------------------------------
        # FUENTE
        # --------------------------------------------------------
        
        annotations = list(
          list(
            text = 'Fuente: <a href="https://www.hidraulica.gob.ar/" target="_blank">Dirección de Hidráulica de Entre Ríos</a>',
            x = 0,
            y = -0.35,
            xref = "paper",
            yref = "paper",
            showarrow = FALSE,
            xanchor = "left",
            font = list(
              size = 10
            )
          )
        )
      )
  })
  
  
  output$grafico_meteo_diario <- renderPlotly({
    req(datos_hidraulica_ultima_semana)
    
    plot_ly(
      data = datos_hidraulica_ultima_semana,
      x = ~Datetime
    ) %>%
      
      add_trace(
        y = ~Temp_Ext, 
        name = 'Temp. Exterior (°C)', 
        type = 'scatter', 
        mode = 'lines+markers',
        line = list(
          color = '#FF5722', 
          width = 2
        ),
        marker = list(
          color = '#FF5722', 
          size = 5
        )
      ) %>%
      
      add_trace(
        y = ~Sens_Term,
        name = 'Sensación Térmica (°C)',
        type = 'scatter',
        mode = 'lines',
        line = list(
          color = '#E64A19', 
          width = 1.2, 
          dash = 'dash'
        )
      ) %>%
      
      add_trace(
        y = ~Lluvia,
        name = 'Lluvia (mm)',
        type = 'bar',
        yaxis = 'y2',
        marker = list(
          color = '#2196F3', 
          opacity = 0.5
        )
      ) %>%
      
      layout(
        
        title = list(
          text = "<b>Monitoreo Meteorológico - Estación Paraná</b>", 
          font = list(size = 16)
        ),
        
        xaxis = list(
          title = "Fecha y Hora", 
          type = 'date', 
          tickformat = "%d/%m/%Y %H:%M", 
          showgrid = TRUE
        ),
        
        yaxis = list(
          title = "Temperatura (°C)", 
          showgrid = TRUE
        ),
        
        yaxis2 = list(
          title = "Precipitación (mm)", 
          overlaying = "y", 
          side = "right", 
          showgrid = FALSE
        ),
        
        hovermode = "x unified",
        
        legend = list(
          orientation = 'h', 
          x = 0.05, 
          y = -0.2
        ),
        
        # --------------------------------------------------------
        # FUENTE
        # --------------------------------------------------------
        
        annotations = list(
          list(
            text = 'Fuente: <a href="https://www.hidraulica.gob.ar/" target="_blank">Dirección de Hidráulica de Entre Ríos</a>',
            x = 0,
            y = -0.35,
            xref = "paper",
            yref = "paper",
            showarrow = FALSE,
            xanchor = "left",
            font = list(
              size = 10
            )
          )
        )
      )
    
})
  
  
  # ---- TABLA CRÍTICOS ----
  
  output$tabla_criticos <- renderDT({
    req(clasificacion_filtrada())
    
    criticos <- clasificacion_filtrada() %>%
      filter(estado %in% c("ROJO", "AMARILLO")) %>%
      select(
        Balneario = balneario_nombre,
        Estado = icono,
        `E. coli MG` = ecoli_mg_30d,
        `Colif. MG` = colif_mg_30d,
        `Acción Requerida` = accion_requerida
      ) %>%
      arrange(Estado)
    
    datatable(
      criticos,
      options = list(
        pageLength = 10,
        language = list(url = '//cdn.datatables.net/plug-ins/1.10.11/i18n/Spanish.json')
      ),
      rownames = FALSE,
      escape = FALSE
    ) %>%
      formatRound(columns = c("E. coli MG", "Colif. MG"), digits = 0)
  })
  
  # ---- INFO SISTEMA ----
  
  output$info_sistema <- renderUI({
    req(ultima_actualizacion())
    
    tagList(
      p(
        icon("clock"),
        strong(" Última actualización: "),
        format(ultima_actualizacion(), "%d/%m/%Y %H:%M:%S")
      ),
      p(
        icon("database"),
        strong(" Fuente de datos: "),
        ifelse(MODO == "produccion", "Epicollect5 (Producción)", "Simulación (Desarrollo)")
      ),
      p(
        icon("balance-scale"),
        strong(" Normativa aplicada: "),
        "Resolución Nº 084 SMA - Provincia de Entre Ríos"
      )
    )
  })
  
  # ---- MAPA PRINCIPAL ----
  
  output$mapa_principal <- renderLeaflet({
    req(clasificacion_filtrada())
    
    clasificacion_filtrada() %>%
      leaflet() %>%
      addProviderTiles(providers$Esri.WorldImagery, group = "Satélite") %>%
      addProviderTiles(providers$CartoDB.Positron, group = "Calles") %>%
      addCircleMarkers(
        lng = ~lon,
        lat = ~lat,
        radius = 10,
        color = "#333",
        fillColor = ~color,
        fillOpacity = 0.9,
        weight = 2,
        popup = ~paste0(
          "<h4>", icono, " ", balneario_nombre, "</h4>",
          "<b>Estado:</b> ", texto_corto, "<br>",
          "<hr>",
          "<b>Última muestra:</b> ", format(fecha_ultima_muestra, "%d/%m/%Y"), "<br>",
          "<b>E. coli:</b> ", round(ecoli_ultima, 0), " UFC/100ml<br>",
          "<b>Coliformes:</b> ", round(colif_ultima, 0), " UFC/100ml<br>",
          "<hr>",
          "<b>Media geométrica (30d):</b><br>",
          "E. coli: ", round(ecoli_mg_30d, 0), " UFC/100ml<br>",
          "Coliformes: ", round(colif_mg_30d, 0), " UFC/100ml<br>",
          "<b>Muestras:</b> ", n_muestras_30d, "<br>",
          "<hr>",
          "<b>Acción:</b> ", accion_requerida
        ),
        label = ~balneario_nombre
      ) %>%
      addLayersControl(
        baseGroups = c("Calles", "Satélite"),
        options = layersControlOptions(collapsed = FALSE)
      )
  })
  
  # ---- LEYENDA SEMÁFORO ----
  
  output$leyenda_semaforo <- renderUI({
    tagList(
      fluidRow(
        column(3,
               div(style = "background-color: #28a745; color: white; padding: 10px; text-align: center; border-radius: 5px;",
                   h4(icon("check-circle"), "VERDE - APTO"),
                   p("Cumple Art. 8", style = "margin: 0;")
               )
        ),
        column(3,
               div(style = "background-color: #ffc107; color: black; padding: 10px; text-align: center; border-radius: 5px;",
                   h4(icon("exclamation-triangle"), "AMARILLO - ALERTA"),
                   p("Cumple pero en zona de alerta", style = "margin: 0;")
               )
        ),
        column(3,
               div(style = "background-color: #dc3545; color: white; padding: 10px; text-align: center; border-radius: 5px;",
                   h4(icon("times-circle"), "ROJO - NO APTO"),
                   p("Incumplimiento Art. 8", style = "margin: 0;")
               )
        ),
        column(3,
               div(style = "background-color: #999999; color: white; padding: 10px; text-align: center; border-radius: 5px;",
                   h4(icon("question-circle"), "GRIS - SIN DATOS"),
                   p("< 5 muestras en 30 días", style = "margin: 0;")
               )
        )
      )
    )
  })
  
  # ---- GRÁFICO E. COLI ----
  
  output$grafico_ecoli <- renderPlotly({
    req(datos_filtrados())
    
    df <- datos_filtrados()
    
    if (input$filtro_balneario != "all") {
      df <- df %>% filter(balneario_nombre == input$filtro_balneario)
      titulo <- paste("E. coli -", input$filtro_balneario)
    } else {
      titulo <- "E. coli - Todos los balnearios"
    }
    
    p <- ggplot(df, aes(x = fecha_muestreo, y = e_coli, color = balneario_nombre)) +
      geom_line(linewidth = 0.8, alpha = 0.7) +
      geom_point(size = 2, alpha = 0.8) +
      geom_hline(yintercept = 300, linetype = "dashed", color = "#ffc107", linewidth = 1) +
      geom_hline(yintercept = 800, linetype = "dashed", color = "#dc3545", linewidth = 1) +
      annotate("text", x = min(df$fecha_muestreo), y = 320, label = "Límite MG: 300", hjust = 0, color = "#ffc107") +
      annotate("text", x = min(df$fecha_muestreo), y = 820, label = "Límite crítico: 800", hjust = 0, color = "#dc3545") +
      labs(
        title = titulo,
        x = "Fecha",
        y = "E. coli (UFC/100ml)",
        color = "Balneario"
      ) +
      theme_minimal() +
      theme(
        legend.position = if(input$filtro_balneario == "all") "right" else "none",
        plot.title = element_text(hjust = 0.5, size = 14, face = "bold")
      )
    
    ggplotly(p, tooltip = c("x", "y", "colour")) %>%
      layout(hovermode = "closest")
  })
  
  # ---- GRÁFICO COLIFORMES ----
  
  output$grafico_coliformes <- renderPlotly({
    req(datos_filtrados())
    
    df <- datos_filtrados()
    
    if (input$filtro_balneario != "all") {
      df <- df %>% filter(balneario_nombre == input$filtro_balneario)
      titulo <- paste("Coliformes Termotolerantes -", input$filtro_balneario)
    } else {
      titulo <- "Coliformes Termotolerantes - Todos los balnearios"
    }
    
    p <- ggplot(df, aes(x = fecha_muestreo, y = coliformes_termotolerantes, color = balneario_nombre)) +
      geom_line(linewidth = 0.8, alpha = 0.7) +
      geom_point(size = 2, alpha = 0.8) +
      geom_hline(yintercept = 600, linetype = "dashed", color = "#ffc107", linewidth = 1) +
      geom_hline(yintercept = 1000, linetype = "dashed", color = "#dc3545", linewidth = 1) +
      annotate("text", x = min(df$fecha_muestreo), y = 630, label = "Límite MG: 600", hjust = 0, color = "#ffc107") +
      annotate("text", x = min(df$fecha_muestreo), y = 1030, label = "Límite crítico: 1000", hjust = 0, color = "#dc3545") +
      labs(
        title = titulo,
        x = "Fecha",
        y = "Coliformes Termotolerantes (UFC/100ml)",
        color = "Balneario"
      ) +
      theme_minimal() +
      theme(
        legend.position = if(input$filtro_balneario == "all") "right" else "none",
        plot.title = element_text(hjust = 0.5, size = 14, face = "bold")
      )
    
    ggplotly(p, tooltip = c("x", "y", "colour")) %>%
      layout(hovermode = "closest")
  })
  
  # ---- GRÁFICO MEDIA GEOMÉTRICA ----
  
  output$grafico_media_geometrica <- renderPlotly({
    req(datos_filtrados())
    
    if (input$filtro_balneario == "all") {
      showNotification("Seleccione un balneario específico para ver medias geométricas", type = "warning")
      return(NULL)
    }
    
    df <- datos_filtrados() %>%
      filter(balneario_nombre == input$filtro_balneario) %>%
      arrange(fecha_muestreo)
    
    # Calcular MG para cada fecha
    fechas <- seq(min(df$fecha_muestreo) + 30, max(df$fecha_muestreo), by = "7 days")
    
    mg_data <- lapply(fechas, function(fecha) {
      
      mg_ecoli <- media_geometrica_30dias(df, fecha, "e_coli")
      mg_colif <- media_geometrica_30dias(df, fecha, "coliformes_termotolerantes")
      
      tibble(
        fecha = fecha,
        ecoli_mg = mg_ecoli$media_geometrica,
        colif_mg = mg_colif$media_geometrica,
        n_muestras = mg_ecoli$n_muestras
      )
    })
    
    mg_df <- bind_rows(mg_data) %>%
      filter(!is.na(ecoli_mg))
    
    if (nrow(mg_df) == 0) {
      showNotification("Datos insuficientes para calcular medias geométricas", type = "warning")
      return(NULL)
    }
    
    p <- ggplot(mg_df) +
      geom_line(aes(x = fecha, y = ecoli_mg, color = "E. coli"), linewidth = 1) +
      geom_line(aes(x = fecha, y = colif_mg, color = "Coliformes"), linewidth = 1) +
      geom_hline(yintercept = 300, linetype = "dashed", color = "#ffc107", linewidth = 0.8, alpha = 0.6) +
      geom_hline(yintercept = 600, linetype = "dashed", color = "#ff6b6b", linewidth = 0.8, alpha = 0.6) +
      scale_color_manual(values = c("E. coli" = "#4CAF50", "Coliformes" = "#2196F3")) +
      labs(
        title = paste("Media Geométrica Móvil (30d) -", input$filtro_balneario),
        x = "Fecha",
        y = "Concentración (UFC/100ml)",
        color = "Parámetro"
      ) +
      theme_minimal() +
      theme(
        legend.position = "bottom",
        plot.title = element_text(hjust = 0.5, size = 14, face = "bold")
      )
    
    ggplotly(p) %>%
      layout(hovermode = "x unified")
  })
  
  # ---- TABLA COMPLETA ----
  
  output$tabla_completa <- renderDT({
    req(datos_filtrados())
    

      # df_tabla <- datos_filtrados() %>%
      #   select(
      #     Balneario = balneario_nombre,
      #     Fecha = fecha_muestreo,
      #     `E. coli` = e_coli,
      #     `Coliformes Termotel.` = coliformes_termotolerantes,
      #     `Temp. °C` = temperatura_agua,
      #     pH = ph,
      #     `Altura río (cm)` = altura_rio
      #   )
      # Vista técnica completa
    
      df_tabla <- datos_filtrados() %>%
        select(
          Balneario = balneario_nombre,
          Fecha = fecha_muestreo,
          `E. coli` = e_coli,
          `Coliformes Termotel.` = coliformes_termotolerantes,
          # `Temp. °C` = temperatura_agua,
          # pH = ph,
          # `Lluvias 72h` = lluvias_previas,
          # `Altura río (cm)` = altura_rio,
          Temporada = temporada,
          Valido = registro_valido
        )%>%
        mutate(
          Valido = if_else(Valido, "Verdadero", "Falso")
        )
    
    datatable(
      df_tabla,
      options = list(
        pageLength = 25,
        order = list(list(2, 'desc')),  # Ordenar por fecha desc
        language = list(url = '//cdn.datatables.net/plug-ins/1.10.11/i18n/Spanish.json')
      ),
      rownames = FALSE,
      filter = 'top'
    ) %>%
      formatRound(columns = c("E. coli", 
                              "Coliformes Termotel." 
                              # "Temp. °C", 
                              # "pH", 
                              # "Altura río (cm)"
                              ), 
                  digits = 1)
  })
  
  # ---- DESCARGAS ----
  
  output$descargar_csv <- downloadHandler(
    filename = function() {
      paste0("datos_calidad_agua_", Sys.Date(), ".csv")
    },
    content = function(file) {
      write.csv(datos_filtrados(), file, row.names = FALSE, fileEncoding = "UTF-8")
    }
  )
  
  output$descargar_excel <- downloadHandler(
    filename = function() {
      paste0("datos_calidad_agua_", Sys.Date(), ".xlsx")
    },
    content = function(file) {
      library(writexl)
      write_xlsx(datos_filtrados(), file)
    }
  )
  
  # ---- CONTENIDO NORMATIVAS ----
  
  output$contenido_normativa <- renderUI({
    box(
      title = "Normativa Vigente",
      status = "primary",
      solidHeader = TRUE,
      width = 12,
      tags$iframe(
        style = "width:100%; height:800px; border:none;",
        src = "Resolución084.pdf"
      )
    )
  })
  
}
