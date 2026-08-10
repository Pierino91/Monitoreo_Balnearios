# app.R
# ============================================================================
# Dashboard de Monitoreo de Calidad de Agua
# Resolución 084/SMA - Provincia de Entre Ríos
# ============================================================================

# ---- MÓDULOS ----



source("global.R")


# ---- UI & SERVER ----
source("ui.R")
source("server.R")

# ---- RUN ----
# rsconnect::deployApp(appName="Monitoreo_Balnearios")