# Dashboard de Monitoreo de Calidad de Agua - Entre Ríos

## Descripción General

Sistema de monitoreo en tiempo real de la calidad microbiológica del agua en balnearios de la Provincia de Entre Ríos, basado en la **Resolución N° 084 SMA**.

### Características Principales

- ✅ Integración completa con **Epicollect5**
- ✅ Cálculo automático de **medias geométricas** (ventana móvil 30 días)
- ✅ **Sistema de semáforo sanitario** (Verde/Amarillo/Rojo)
- ✅ Validación automática según **Art. 8** de la Resolución 084
- ✅ Mapas interactivos georreferenciados
- ✅ Series temporales con límites normativos
- ✅ Exportación de datos (CSV/Excel)
- ✅ Dos modos de visualización: Técnico y Público

---

## Requisitos del Sistema

### Software Necesario

- **R** >= 4.2.0
- **RStudio** (recomendado)
- **Navegador web** moderno (Chrome, Firefox, Edge)

### Paquetes de R Requeridos

```r
# Instalar todos los paquetes necesarios
install.packages(c(
  "shiny",
  "shinydashboard",
  "leaflet",
  "ggplot2",
  "plotly",
  "DT",
  "dplyr",
  "lubridate",
  "httr",
  "jsonlite",
  "writexl"
))
```

---

## Instalación

### 1. Clonar o Descargar el Proyecto

```bash
git clone https://github.com/tu-organizacion/epicollect5-dashboard.git
cd epicollect5-dashboard
```

### 2. Estructura de Directorios

```
epicollect5-dashboard/
├── app.R                    # Aplicación principal
├── R/
│   ├── api_epicollect5.R   # Conexión API
│   ├── normativa.R          # Funciones normativas
│   ├── semaforo.R           # Sistema de clasificación
│   └── server_outputs.R     # Outputs adicionales
├── config/
│   └── config.yml           # Configuración (crear)
├── data/                    # Datos locales (opcional)
└── README.md                # Este archivo
```

### 3. Configurar Epicollect5

#### a) Crear Proyecto en Epicollect5

1. Ir a https://five.epicollect.net
2. Crear nuevo proyecto: **"balnearios-entre-rios"**
3. Diseñar formulario con estos campos mínimos:

| Campo | Tipo | Nombre en Epicollect5 |
|-------|------|----------------------|
| ID Balneario | TEXT | `1_Balneario_ID` |
| Nombre Balneario | TEXT | `2_Nombre_del_Balneario` |
| Municipio | DROPDOWN | `3_Municipio` |
| Ubicación | LOCATION | `4_Ubicacion` |
| Fecha Muestreo | DATE | `5_Fecha_de_Muestreo` |
| Hora | TIME | `6_Hora` |
| E. coli | DECIMAL | `7_E_coli_UFC_100ml` |
| Coliformes Termotel. | DECIMAL | `8_Coliformes_Termotolerantes_UFC_100ml` |
| Temperatura Agua | DECIMAL | `9_Temperatura_Agua_C` |
| pH | DECIMAL | `10_pH` |
| Lluvias 72h | RADIO | `11_Lluvias_72h_Previas` |
| Altura Río | DECIMAL | `12_Altura_Rio_cm` |

#### b) Obtener Credenciales API (Opcional - Para Proyectos Privados)

1. En Epicollect5, ir a **"Manage App"**
2. Generar **Client ID** y **Client Secret**
3. Guardar en variables de entorno:

```bash
# Linux/Mac
export EPICOLLECT_CLIENT_ID="tu_client_id"
export EPICOLLECT_CLIENT_SECRET="tu_client_secret"

# Windows (PowerShell)
$env:EPICOLLECT_CLIENT_ID="tu_client_id"
$env:EPICOLLECT_CLIENT_SECRET="tu_client_secret"
```

### 4. Configurar la Aplicación

Editar `app.R` líneas 17-19:

```r
# MODO: "produccion" o "desarrollo"
MODO <- "produccion"  # Cambiar a producción cuando esté listo

# Configuración Epicollect5
EPICOLLECT_PROJECT <- "balnearios-entre-rios"  # Tu nombre de proyecto real
```

### 5. Ajustar Mapeo de Campos (Si es Necesario)

Si los nombres de tus campos en Epicollect5 difieren, editar `R/api_epicollect5.R` líneas 101-119:

```r
mapeo_campos <- list(
  balneario_id = "TU_CAMPO_ID",
  balneario_nombre = "TU_CAMPO_NOMBRE",
  # ... resto de campos
)
```

---

## Ejecución

### Modo Desarrollo (Datos Simulados)

```r
# Abrir RStudio
# Abrir app.R
# Clic en "Run App" o ejecutar:
shiny::runApp()
```

La app se abrirá en el navegador con datos simulados para pruebas.

### Modo Producción (Datos Reales de Epicollect5)

1. Asegurar que `MODO <- "produccion"` en `app.R`
2. Verificar que `EPICOLLECT_PROJECT` tenga el nombre correcto
3. Ejecutar:

```r
shiny::runApp()
```

La app descargará automáticamente los datos desde Epicollect5.

---

## Uso del Dashboard

### Panel Principal

- **KPIs superiores**: Resumen de balnearios por estado
- **Gráfico de torta**: Distribución de estados sanitarios
- **Mapa resumen**: Vista rápida georreferenciada
- **Tabla críticos**: Balnearios que requieren atención inmediata

### Mapa Interactivo

- **Puntos coloreados** según estado sanitario
- **Popups** con información detallada al hacer clic
- **Capas**: Vista de calles o satélite

### Series Temporales

1. Seleccionar un balneario específico en el filtro lateral
2. Ver evolución de E. coli y Coliformes
3. Líneas punteadas marcan límites normativos

### Tabla Técnica

- **Modo Institucional**: Todas las variables
- **Modo Público**: Vista simplificada
- **Exportación**: Botones CSV y Excel

### Filtros Laterales

- **Municipio**: Filtrar por uno o varios municipios
- **Balneario**: Vista individual
- **Rango de fechas**: Periodo de análisis
- **Actualizar**: Refrescar datos manualmente

---

## Lógica Normativa Implementada

### Artículo 8 - Límites Microbiológicos

#### E. coli
- ✅ Media geométrica (30 días) < 300 UFC/100ml
- ✅ Ninguna muestra individual ≥ 800 UFC/100ml

#### Coliformes Termotolerantes
- ✅ Media geométrica (30 días) < 600 UFC/100ml
- ✅ Ninguna muestra individual ≥ 1000 UFC/100ml

### Requisitos de Datos
- **Mínimo**: 5 muestras en ventana de 30 días
- Sin datos suficientes → Estado "GRIS" (Sin Datos)

---

## Sistema de Semáforo Sanitario

### 🟢 VERDE - APTO (Habilitado)

**Condiciones:**
- Cumple ambas medias geométricas
- Sin excedencias críticas
- Margen de seguridad adecuado

**Acción:** Mantener monitoreo semanal de rutina

### 🟡 AMARILLO - ALERTA (Habilitado con Monitoreo Reforzado)

**Condiciones:**
- Cumple normativa pero valores ≥ 90% del límite
- O valores individuales altos (no críticos)

**Acción:** Monitoreo cada 48-72 horas + señalización preventiva

### 🔴 ROJO - NO APTO (No Habilitado)

**Condiciones:**
- Incumplimiento de media geométrica
- O presencia de excedencias críticas

**Acción:** Prohibir baño + investigar fuentes de contaminación

### ⚪ GRIS - SIN DATOS

**Condiciones:**
- Menos de 5 muestras en 30 días

**Acción:** Aumentar frecuencia de muestreo

---

## Personalización

### Cambiar Colores del Semáforo

Editar `R/semaforo.R`:

```r
# Líneas 67-71
return(list(
  estado = "VERDE",
  color = "#TU_COLOR_HEX",
  # ...
))
```

### Ajustar Umbrales de Alerta

Editar `R/semaforo.R` líneas 36-37:

```r
UMBRAL_ALERTA_ECOLI <- 300 * 0.85  # 85% en vez de 90%
UMBRAL_ALERTA_COLIF <- 600 * 0.85
```

### Modificar Intervalo de Actualización

Editar `app.R` línea 27:

```r
INTERVALO_ACTUALIZACION <- 1800  # 30 minutos (en segundos)
```

---

## Troubleshooting

### Error: "No se obtuvieron datos del proyecto"

**Causa:** Nombre de proyecto incorrecto o proyecto vacío

**Solución:**
1. Verificar que `EPICOLLECT_PROJECT` coincida exactamente con el nombre en Epicollect5
2. Asegurar que el proyecto tenga al menos 1 registro

### Error: "Error al obtener token OAuth2"

**Causa:** Credenciales incorrectas

**Solución:**
1. Re-generar Client ID/Secret en Epicollect5
2. Actualizar variables de entorno
3. Reiniciar R/RStudio

### Error: "Campo 'X' no encontrado"

**Causa:** Nombres de campos no coinciden

**Solución:**
Ajustar `mapeo_campos` en `R/api_epicollect5.R` con los nombres exactos de tu formulario

### Gráficos no se muestran

**Causa:** Falta seleccionar balneario

**Solución:**
Para series temporales y MG, seleccionar un balneario específico en el filtro lateral

---

## Despliegue en Servidor

### shinyapps.io (Más simple)

```r
# Instalar rsconnect
install.packages("rsconnect")

# Configurar cuenta
rsconnect::setAccountInfo(
  name = "tu_cuenta",
  token = "tu_token",
  secret = "tu_secret"
)

# Desplegar
rsconnect::deployApp(appDir = ".")
```

### Shiny Server (Servidor propio)

1. Instalar Shiny Server en Ubuntu/Debian:

```bash
sudo apt-get install gdebi-core
wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.20.1002-amd64.deb
sudo gdebi shiny-server-1.5.20.1002-amd64.deb
```

2. Copiar app a `/srv/shiny-server/`

```bash
sudo cp -R /path/to/epicollect5-dashboard /srv/shiny-server/
```

3. Acceder vía http://tu-servidor:3838/epicollect5-dashboard

---

## Mantenimiento

### Actualización de Datos

- **Automática**: Cada 1 hora (configurable)
- **Manual**: Botón "Actualizar Datos" en el sidebar

### Respaldo de Datos

Recomendado: exportar datos semanalmente vía tabla técnica

```r
# Script de respaldo automático (ejecutar vía cron)
library(dplyr)
source("R/api_epicollect5.R")

datos <- cargar_datos_epicollect5("balnearios-entre-rios")
write.csv(datos, paste0("backups/datos_", Sys.Date(), ".csv"))
```

### Logs

Shiny genera logs automáticamente. Para verlos:

```r
# Durante desarrollo
options(shiny.trace = TRUE)

# En producción (Shiny Server)
tail -f /var/log/shiny-server.log
```

---

## Soporte y Contacto

**Organismo:** Secretaría de Medio Ambiente - Provincia de Entre Ríos

**Desarrollador:** [Tu Nombre/Organización]

**Repositorio:** https://github.com/tu-org/epicollect5-dashboard

**Documentación Normativa:** Resolución N° 084 SMA

---

## Licencia

Este proyecto es de código abierto para uso de organismos públicos de la Provincia de Entre Ríos.

---

## Changelog

### Versión 1.0.0 (2026-02-05)
- ✅ Integración inicial con Epicollect5
- ✅ Sistema de semáforo sanitario
- ✅ Cálculo de medias geométricas
- ✅ Mapas interactivos
- ✅ Series temporales
- ✅ Exportación de datos

---

## Próximas Mejoras

- [ ] Notificaciones automáticas por email
- [ ] Reportes PDF automatizados
- [ ] Comparación interanual
- [ ] Predicción con modelos ML
- [ ] App móvil nativa
- [ ] Integración con sistemas meteorológicos
"# Monitoreo_Balnearios" 
