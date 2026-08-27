# ui.R
ui <- dashboardPage(
  skin = "green",
  
  header = dashboardHeader(
    title = "Calidad de Agua - Paraná",
    titleWidth = 350
  ),
  
  sidebar = dashboardSidebar(
    width = 300,
    sidebarMenu(
      id = "tabs",
      
      menuItem("Panel Principal", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Mapa Interactivo", tabName = "mapa", icon = icon("map-marked-alt")),
      menuItem("Series Temporales", tabName = "series", icon = icon("chart-line")),
      menuItem("Datos Meteorológicos", tabName = "meteorologia", icon = icon("cloud-sun-rain")), 
      menuItem("Tabla Técnica", tabName = "tabla", icon = icon("table")),
      menuItem("Normativa", tabName = "normativa", icon = icon("balance-scale")),
      
      hr(),
      
      selectInput("filtro_balneario", "Balneario:", choices = NULL),
      dateRangeInput(
        "rango_fechas",
        "Rango de Fechas:",
        start = Sys.Date() - 90,
        end = Sys.Date(),
        language = "es"
      ),
      
      hr()
      
      # actionButton(
      #   "btn_actualizar",
      #   "Actualizar Datos",
      #   icon = icon("sync"),
      #   width = "100%",
      #   class = "btn-primary"
      # )
    )
  ),
  
  body = dashboardBody(
    # Estilos personalizados
    tags$head(
      tags$link(
        rel = "stylesheet", 
        href = "https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700;800&display=swap"
      ),
      tags$style(HTML("
        /* ============================================
           VARIABLES CSS & ESTILOS GENERALES
        ============================================ */
        :root {
          --primary-green: #2e7d32;
          --light-green: #4caf50;
          --lighter-green: #66bb6a;
          --bg-light: #f5f7fa;
          --bg-green-tint: #e8f5e9;
          --text-dark: #2c3e50;
          --shadow-sm: 0 2px 8px rgba(0, 0, 0, 0.06);
          --shadow-md: 0 4px 16px rgba(0, 0, 0, 0.08);
          --shadow-lg: 0 8px 24px rgba(76, 175, 80, 0.25);
          --transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
        }
        
        body {
          background: linear-gradient(135deg, var(--bg-light) 0%, var(--bg-green-tint) 100%);
          font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
          color: var(--text-dark);
        }

        .main-title {
          background: linear-gradient(135deg, var(--primary-green) 0%, var(--light-green) 100%);
          color: white;
          padding: 36px 48px;
          margin: -15px -15px 36px -15px;
          border-radius: 0 0 24px 24px;
          box-shadow: var(--shadow-lg);
          text-align: center;
          font-weight: 800;
          font-size: 36px;
          letter-spacing: -0.8px;
          position: relative;
          overflow: hidden;
        }

        .main-subtitle {
          font-size: 17px;
          font-weight: 400;
          margin-top: 10px;
          opacity: 0.96;
          letter-spacing: 0.3px;
        }

        .section-title {
          color: var(--primary-green);
          font-weight: 700;
          margin-bottom: 28px;
          font-size: 30px;
          letter-spacing: -0.5px;
          display: flex;
          align-items: center;
          gap: 12px;
        }

        .section-title::before {
          content: '';
          width: 6px;
          height: 32px;
          background: linear-gradient(180deg, var(--primary-green), var(--lighter-green));
          border-radius: 3px;
        }

        .small-box {
          border-radius: 16px;
          box-shadow: var(--shadow-md);
          transition: var(--transition);
          overflow: hidden;
        }

        .small-box:hover {
          transform: translateY(-4px);
          box-shadow: 0 12px 32px rgba(0, 0, 0, 0.12);
        }

        .box {
          border-radius: 16px;
          box-shadow: var(--shadow-md);
          border: none;
          margin-bottom: 24px;
        }

        .box-header {
          background: linear-gradient(135deg, var(--light-green) 0%, var(--lighter-green) 100%);
          color: white;
          border-radius: 16px 16px 0 0;
          padding: 20px 24px;
          font-weight: 700;
          font-size: 19px;
        }

        .box-body {
          padding: 24px;
          background: white;
          border-radius: 0 0 16px 16px;
        }

        .modal-image-viewer .modal-content {
          background: rgba(15, 15, 15, 0.95);
          border-radius: 20px;
          padding: 20px;
        }

        .close-modal {
          position: absolute;
          top: 14px;
          right: 20px;
          background: transparent;
          border: none;
          color: #ffffff;
          font-size: 42px;
          cursor: pointer;
        }
      "))
    ),
    
    tags$script(HTML("
      function mostrarImagen(src) {
        $('#modal-img').attr('src', src);
        $('#modal-imagen').modal('show');
      }
    ")),
    
    # Modal para mostrar imágenes
    tags$div(
      id = "modal-imagen",
      class = "modal fade modal-image-viewer",
      tabindex = "-1",
      role = "dialog",
      tags$div(
        class = "modal-dialog modal-dialog-centered modal-xl",
        tags$div(
          class = "modal-content",
          tags$button(
            type = "button",
            class = "close-modal",
            "×",
            onclick = "$('#modal-imagen').modal('hide')"
          ),
          tags$div(
            class = "modal-body text-center",
            tags$img(
              id = "modal-img",
              src = "",
              class = "modal-img-zoom"
            )
          )
        )
      )
    ),
    
    # Título principal con logo
    div(
      style = "display: flex; align-items: center; justify-content: center; gap: 20px; margin-top: 20px;",
      tags$img(
        src = "aguas_recreativas.jpg",
        height = "250px"
      ),
      div(
        style = "display: flex; flex-direction: column; align-items: center;",
        div(
          class = "main-title",
          "Calidad de Agua - Paraná, Entre Ríos"
        ),
        div(
          class = "main-subtitle",
          "Secretaría de Recursos Hídricos y Gestión Ambiental · Paraná"
        )
      )
    ),
    
    tabItems(
      tabItem(
        tabName = "dashboard",
        fluidRow(
          valueBoxOutput("kpi_total", 3),
          valueBoxOutput("kpi_aptos", 3),
          valueBoxOutput("kpi_alerta", 3),
          valueBoxOutput("kpi_no_aptos", 3)
        ),
        fluidRow(
          box(plotlyOutput("grafico_resumen_estados", height = 300), width = 6),
          box(leafletOutput("mapa_resumen", height = 300), width = 6)
        ),
        box(
          title = "Balnearios en estado crítico", 
          width = 12,
          DTOutput("tabla_criticos")
        )
      ),
      
      tabItem(
        tabName = "mapa",
        box(leafletOutput("mapa_principal", height = 600), width = 12),
        box(uiOutput("leyenda_semaforo"), width = 12)
      ),
      
      tabItem(
        tabName = "series",
        box(plotlyOutput("grafico_ecoli", height = 400), width = 12),
        box(plotlyOutput("grafico_coliformes", height = 400), width = 12),
        box(plotlyOutput("grafico_media_geometrica", height = 400), width = 12)
      ),
      
      
      tabItem(
        tabName = "tabla",
        downloadButton("descargar_csv", "CSV"),
        downloadButton("descargar_excel", "Excel"),
        DTOutput("tabla_completa")
      ),
      
      tabItem(
        tabName = "meteorologia",
        box(
          title = "Monitoreo Meteorológico Continuo (Horario)",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          plotlyOutput("grafico_meteo_horario", height = 400)
        ),
        box(
          title = "Resumen Meteorológico Diario",
          status = "success",
          solidHeader = TRUE,
          width = 12,
          plotlyOutput("grafico_meteo_diario", height = 400)
        )
      ),
      
      tabItem(
        tabName = "normativa",
        box(
          title = "Normativa Vigente de Calidad de Agua",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          tags$iframe(
            style = "width:100%; height:800px; border:none;",
            src = "Resolución084.pdf"
          )
        )
      )
    )
  )
)