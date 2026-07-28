---
editor_options: 
  markdown: 
    wrap: 72
---

# Guía de Inicio Rápido - Dashboard de Calidad de Agua

## ¿Qué es este sistema?

El **Dashboard de Monitoreo de Calidad de Agua** es una plataforma web
que permite visualizar en tiempo real el estado sanitario de los
balnearios de Entre Ríos según la **Resolución N° 084 SMA**.

------------------------------------------------------------------------

## Inicio en 5 Minutos

### Paso 1: Instalar R y RStudio

1.  Descargar R desde: <https://cran.r-project.org/>
2.  Descargar RStudio desde:
    <https://posit.co/download/rstudio-desktop/>

### Paso 2: Instalar Paquetes

Abrir RStudio y ejecutar:

``` r
install.packages(c(
  "shiny", "shinydashboard", "leaflet", "ggplot2", 
  "plotly", "DT", "dplyr", "lubridate", "httr", 
  "jsonlite", "writexl"
))
```

### Paso 3: Descargar el Proyecto

Descargar y extraer el proyecto en una carpeta.

### Paso 4: Ejecutar

1.  Abrir `app.R` en RStudio
2.  Clic en **"Run App"** (arriba derecha)
3.  ¡Listo! El dashboard se abre en tu navegador

------------------------------------------------------------------------

## Primeros Pasos

### 1️⃣ Modo Desarrollo vs. Producción

**Primera vez**: El sistema inicia en **modo desarrollo** con datos
simulados.

**Para usar datos reales**: - Editar `app.R` línea 17:
`MODO <- "produccion"` - Configurar nombre de proyecto Epicollect5 en
línea 20

### 2️⃣ Navegar por el Dashboard

#### Panel Principal

-   Vista general del estado de todos los balnearios
-   KPIs: Total, Aptos, Alerta, No Aptos
-   Mapa resumen
-   Tabla de balnearios críticos

#### Mapa Interactivo

-   Puntos coloreados según estado sanitario
-   Click en cada punto para ver detalles
-   Vista de calles o satélite

#### Series Temporales

-   Seleccionar un balneario específico
-   Ver evolución de E. coli y Coliformes
-   Líneas de límites normativos

#### Tabla Técnica

-   Historial completo de muestras
-   Exportar a CSV o Excel
-   Filtros por columna

### 3️⃣ Interpretar el Semáforo

🟢 **VERDE - APTO** - ✅ Cumple Art. 8 - ✅ Habilitado para baño - 📋
Acción: Monitoreo semanal

🟡 **AMARILLO - ALERTA** - ⚠️ Cumple pero cerca del límite - ✅
Habilitado con precaución - 📋 Acción: Monitoreo reforzado (48-72hs)

🔴 **ROJO - NO APTO** - ❌ Incumplimiento - 🚫 NO habilitado - 📋
Acción: Prohibir baño inmediatamente

⚪ **GRIS - SIN DATOS** - ℹ️ Datos insuficientes (\< 5 muestras) - 📋
Acción: Aumentar frecuencia de muestreo

------------------------------------------------------------------------

## Flujo de Trabajo Típico

### Para Técnicos de Laboratorio

1.  **Cargar muestra en Epicollect5** (en campo, desde teléfono)
    -   Ubicación GPS
    -   Valores de E. coli y Coliformes
    -   Variables complementarias
2.  **Dashboard actualiza automáticamente** (cada 1 hora)
    -   O manualmente con botón "Actualizar"
3.  **Revisar Panel Principal**
    -   Ver si hay balnearios en rojo
    -   Identificar alertas
4.  **Analizar Series Temporales**
    -   Verificar tendencias
    -   Detectar patrones
5.  **Exportar Tabla** (si se requiere informe)
    -   CSV para Excel
    -   XLSX para análisis

### Para Autoridades Municipales

1.  **Acceder al Dashboard**
    -   URL proporcionada por la Secretaría
2.  **Cambiar a Modo Público**
    -   Vista simplificada
    -   Sin datos técnicos sensibles
3.  **Consultar Estado de Balnearios**
    -   Mapa rápido
    -   Estado claro (semáforo)
4.  **Tomar Decisiones**
    -   Verde → Mantener habilitación
    -   Amarillo → Reforzar monitoreo + señalización
    -   Rojo → Cerrar balneario + comunicado

### Para Comunicación Pública

1.  **Generar Comunicado**

    -   Basado en estados del mapa

2.  **Información Clave**:

    ```         
    Balneario X: 🟢 APTO para baño
    Última verificación: [Fecha]
    Próximo monitoreo: [Fecha estimada]
    ```

3.  **Balneario en Rojo**:

    ```         
    Balneario X: 🔴 CERRADO temporalmente
    Motivo: Niveles elevados de E. coli
    Se realizarán análisis adicionales
    Se informará reapertura oportunamente
    ```

------------------------------------------------------------------------

## FAQ - Preguntas Frecuentes

### ¿Cada cuánto se actualizan los datos?

**Automáticamente cada 1 hora** desde Epicollect5. También se puede
refrescar manualmente.

### ¿Qué significa "Media Geométrica"?

Es un promedio especial (no aritmético) usado en microbiología que da
menos peso a valores extremos aislados. Es el método establecido en la
Resolución 084.

### ¿Por qué un balneario está en GRIS?

Faltan muestras. Se necesitan **mínimo 5 muestras en los últimos 30
días** para calcular la media geométrica.

### ¿Puede un balneario VERDE pasar a ROJO rápidamente?

Sí, si: - Una nueva muestra excede 800 E. coli - O la media geométrica
supera 300 por acumulación de valores altos

Por eso es importante el monitoreo continuo.

### ¿Cómo exporto un reporte?

1.  Ir a **Tabla Técnica**
2.  Aplicar filtros (balneario, fechas)
3.  Clic en **Descargar CSV** o **Descargar Excel**

### ¿Funciona en celular?

Sí, el dashboard es responsive. En celular el menú lateral se convierte
en menú hamburguesa (☰).

### ¿Puedo ver históricos de años anteriores?

Sí, ajustando el rango de fechas en el filtro lateral. Los datos quedan
almacenados en Epicollect5.

------------------------------------------------------------------------

## Solución de Problemas Comunes

### No se ven datos

**Verificar**: - ¿Está en modo "produccion" o "desarrollo"? - ¿El nombre
del proyecto Epicollect5 es correcto? - ¿Hay datos en el proyecto
Epicollect5?

### Gráficos en blanco

**Causa**: No hay balneario seleccionado

**Solución**: En filtro lateral, seleccionar un balneario específico

### Error "No se obtuvieron datos"

**Causa**: Proyecto Epicollect5 vacío o nombre incorrecto

**Solución**: 1. Verificar nombre en `app.R` línea 20 2. Verificar que
el proyecto tenga registros

### El mapa no carga

**Verificar conexión a internet** (se requiere para tiles de mapa)

------------------------------------------------------------------------

## Mejores Prácticas

### Frecuencia de Muestreo

**Temporada alta (Dic-Mar)**: - Balnearios habilitados: 1 vez por
semana - Balnearios en alerta: Cada 2-3 días - Balnearios críticos:
Diario hasta normalización

**Resto del año**: - Quincenal o mensual

### Carga de Datos en Epicollect5

✅ **Hacer**: - Cargar datos el mismo día del muestreo - Verificar
ubicación GPS antes de enviar - Revisar valores antes de confirmar

❌ **Evitar**: - Cargar muestras de fechas muy antiguas sin contexto -
Dejar campos obligatorios vacíos - Duplicar registros

### Interpretación de Resultados

⚠️ **No tomar decisiones con una sola muestra**

La Resolución 084 requiere: - Mínimo 5 muestras en 30 días - Media
geométrica (no valores puntuales)

Una muestra alta aislada NO necesariamente significa clausura, pero SÍ
requiere muestreo adicional inmediato.

------------------------------------------------------------------------

## Contactos y Recursos

**Soporte Técnico**: [email técnico]

**Secretaría de Medio Ambiente**: [email institucional]

**Epicollect5**: <https://five.epicollect.net>

**Documentación Completa**: Ver `README.md` en el proyecto

**Resolución 084 SMA**: [link al BOE]

------------------------------------------------------------------------

## Checklist de Implementación

Para técnicos que van a poner en producción:

-   [ ] R y RStudio instalados
-   [ ] Todos los paquetes instalados sin errores
-   [ ] Proyecto Epicollect5 creado y configurado
-   [ ] Al menos 5 muestras de prueba en Epicollect5
-   [ ] `app.R` configurado con nombre correcto de proyecto
-   [ ] Modo cambiado a "produccion"
-   [ ] Dashboard ejecuta sin errores
-   [ ] Datos reales se visualizan correctamente
-   [ ] Mapas cargan puntos correctamente
-   [ ] Exportación CSV/Excel funciona
-   [ ] Personal capacitado en uso del sistema
-   [ ] URL de acceso documentada y compartida
-   [ ] Plan de respaldo de datos establecido

------------------------------------------------------------------------

## Próximos Pasos Recomendados

1.  **Semana 1**: Familiarizarse con datos simulados
2.  **Semana 2**: Configurar proyecto Epicollect5 real
3.  **Semana 3**: Cargar datos históricos si existen
4.  **Semana 4**: Poner en producción
5.  **Mes 2**: Evaluar y ajustar umbrales si fuera necesario
6.  **Mes 3**: Capacitar a todo el personal involucrado

------------------------------------------------------------------------

¡Listo para comenzar! 🚀

El dashboard está diseñado para ser intuitivo y robusto. Ante cualquier
duda, consultar la documentación completa o contactar soporte técnico.
