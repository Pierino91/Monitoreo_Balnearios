# ui.R
ui <- dashboardPage(
  skin = "blue",
  
  dashboardHeader(
    title = "Calidad de Agua - Paraná,  Entre Ríos",
    titleWidth = 300
  ),
  
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      id = "tabs",
      
      menuItem("Panel Principal", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Mapa Interactivo", tabName = "mapa", icon = icon("map-marked-alt")),
      menuItem("Series Temporales", tabName = "series", icon = icon("chart-line")),
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
      
      hr(),
      
      actionButton(
        "btn_actualizar",
        "Actualizar Datos",
        icon = icon("sync"),
        width = "100%",
        class = "btn-primary"
      )
    )
  ),
  
  dashboardBody(
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
        box(title = "Balnearios en estado crítico", 
            width = 12,
            DTOutput("tabla_criticos"))
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
        tabName = "normativa",
        box(
          title = "Normativa Vigente de Calidad de Agua",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          tags$iframe(
            style = "width:100%; height:800px; border:none;",
            src = "Resolución084.pdf" # Nombre del archivo dentro de la carpeta www/
          )
        )
      )
    )
  )
)