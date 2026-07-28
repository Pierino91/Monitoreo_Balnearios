# 🚀 INICIO INMEDIATO - 3 Pasos

## Paso 1: Instalar R y Paquetes (5 minutos)

### A. Instalar R y RStudio

1. Descargar e instalar **R**: https://cran.r-project.org/
2. Descargar e instalar **RStudio**: https://posit.co/download/rstudio-desktop/

### B. Instalar Paquetes Necesarios

Abrir RStudio y copiar/pegar este código en la consola:

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

Presionar ENTER y esperar (2-3 minutos).

---

## Paso 2: Descargar y Extraer el Proyecto (1 minuto)

1. Descargar el archivo **epicollect5_dashboard.zip**
2. Extraer en una carpeta (ejemplo: `C:/Proyectos/` o `~/Proyectos/`)
3. Abrir RStudio
4. En RStudio: File → Open Project → Navegar a la carpeta → Seleccionar `app.R`

---

## Paso 3: Ejecutar el Dashboard (30 segundos)

1. Con `app.R` abierto en RStudio
2. Buscar el botón **"Run App"** arriba a la derecha del editor
3. Hacer clic en **"Run App"**
4. ¡El dashboard se abre en tu navegador! 🎉

---

## ✅ ¿Funcionó?

Deberías ver:

- Una interfaz con título "Calidad de Agua - Entre Ríos"
- Un mapa con puntos de colores
- KPIs en la parte superior (Total, Aptos, Alerta, No Aptos)
- Datos simulados de balnearios

---

## 🎯 Siguiente: Configurar con Datos Reales

### Opción A: Ya tengo un proyecto Epicollect5

1. Abrir `app.R`
2. Buscar línea 17: `MODO <- "desarrollo"`
3. Cambiar a: `MODO <- "produccion"`
4. Buscar línea 20: `EPICOLLECT_PROJECT <- "balnearios-entre-rios"`
5. Cambiar a: `EPICOLLECT_PROJECT <- "tu-nombre-de-proyecto"`
6. Guardar y ejecutar de nuevo

### Opción B: Necesito crear el proyecto Epicollect5

Ver: `docs/guia_inicio_rapido.md` sección "Configurar Epicollect5"

---

## 📚 Documentación Completa

- **README.md**: Documentación técnica completa
- **RESUMEN_EJECUTIVO.md**: Visión general del proyecto
- **docs/guia_inicio_rapido.md**: Guía para usuarios finales
- **docs/guia_visual.md**: Diseño y wireframes
- **tests/test_sistema.R**: Suite de pruebas

---

## 🆘 Problemas Comunes

### Error: "package 'X' is not available"

**Solución**: Actualizar R a versión >= 4.2.0

### Error al ejecutar app

**Solución**: 
1. Verificar que todos los paquetes se instalaron correctamente
2. Ejecutar: `source("R/api_epicollect5.R")`
3. Si hay error, revisar mensaje

### El mapa no carga

**Solución**: Verificar conexión a internet (mapas requieren tiles online)

---

## 📞 Contacto

Para soporte técnico o consultas, revisar la documentación incluida.

---

**¡Listo para comenzar!** 🎊

El sistema está completamente funcional con datos simulados.
Puedes explorar todas las funcionalidades antes de conectar con Epicollect5.
