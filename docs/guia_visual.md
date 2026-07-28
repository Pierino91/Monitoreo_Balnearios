# Guía Visual del Dashboard - Propuesta de Layout

## Vista General del Dashboard

```
┌─────────────────────────────────────────────────────────────────────────┐
│  CALIDAD DE AGUA - ENTRE RÍOS          [Institucional ▼]  [🔄 Actualizar]│
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐               │
│  │    8     │  │    5     │  │    2     │  │    1     │               │
│  │ TOTAL    │  │  APTOS   │  │  ALERTA  │  │ NO APTOS │               │
│  │Balnearios│  │  🟢      │  │  🟡      │  │   🔴     │               │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘               │
│                                                                          │
│  ┌───────────────────────────┐  ┌───────────────────────────────┐     │
│  │ DISTRIBUCIÓN DE ESTADOS   │  │   MAPA DE SITUACIÓN GENERAL    │     │
│  │                           │  │                                │     │
│  │      🟢 Apto 62%         │  │        [MAPA INTERACTIVO]     │     │
│  │      🟡 Alerta 25%       │  │                                │     │
│  │      🔴 No Apto 13%      │  │     🟢  🟢  🟡                │     │
│  │                           │  │          🟢                    │     │
│  │  [Gráfico de Torta]       │  │   🔴          🟡              │     │
│  │                           │  │        🟢  🟢                 │     │
│  └───────────────────────────┘  └───────────────────────────────┘     │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐│
│  │ ⚠️  BALNEARIOS CRÍTICOS (Requieren Atención)                       ││
│  ├────────────┬──────────────┬───────┬──────────┬──────────────────────┤│
│  │ Balneario  │ Municipio    │Estado │ E.coli MG│ Acción Requerida     ││
│  ├────────────┼──────────────┼───────┼──────────┼──────────────────────┤│
│  │ La Toma    │ Concordia    │ 🔴    │   425    │ Prohibir baño        ││
│  │ Costa Sol  │ Colón        │ 🟡    │   275    │ Monitoreo reforzado  ││
│  └────────────┴──────────────┴───────┴──────────┴──────────────────────┘│
└─────────────────────────────────────────────────────────────────────────┘
```

## Panel de Filtros Lateral

```
┌─────────────────────────┐
│ 📊 PANEL PRINCIPAL      │
│ 🗺️  MAPA INTERACTIVO    │
│ 📈 SERIES TEMPORALES    │
│ 📋 TABLA TÉCNICA        │
│ ⚖️  NORMATIVA           │
├─────────────────────────┤
│ MODO DE VISUALIZACIÓN   │
│ ◉ Institucional         │
│ ○ Público               │
├─────────────────────────┤
│ FILTROS                 │
│                         │
│ Municipio:              │
│ [▼ Seleccionar]         │
│   ☑ Concordia           │
│   ☐ Colón               │
│   ☐ Gualeguaychú        │
│                         │
│ Balneario:              │
│ [▼ Todos]               │
│                         │
│ Rango de Fechas:        │
│ [01/12/2025] a          │
│ [05/02/2026]            │
│                         │
│ [🔄 ACTUALIZAR DATOS]   │
├─────────────────────────┤
│ ℹ️  Sistema según       │
│    Resolución 084/SMA   │
│    Datos: Epicollect5   │
└─────────────────────────┘
```

## Vista de Mapa Interactivo

```
┌─────────────────────────────────────────────────────────────────────────┐
│  🗺️  MAPA INTERACTIVO DE BALNEARIOS                                     │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  [Capas: ◉ Calles  ○ Satélite]                                         │
│                                                                          │
│    ┌────────────────────────────────────────────────────┐              │
│    │                                                     │              │
│    │     RÍO URUGUAY                                    │              │
│    │           🟢 Balneario Thompson                    │              │
│    │                                                     │              │
│    │  🟡 Camping La Delfina                            │              │
│    │                                                     │              │
│    │        🟢 Playa Ubajay                             │              │
│    │                                                     │              │
│    │              🔴 Balneario La Toma                  │              │
│    │                   (Click para detalles)            │              │
│    │                                                     │              │
│    │  🟢 Costa del Sol                                  │              │
│    │                                                     │              │
│    └────────────────────────────────────────────────────┘              │
│                                                                          │
│  ┌────────────────────────────────────────────────────────────────────┐│
│  │ LEYENDA DEL SEMÁFORO SANITARIO                                     ││
│  ├──────────┬──────────────┬──────────────┬─────────────────┐        ││
│  │🟢 VERDE  │🟡 AMARILLO   │🔴 ROJO       │⚪ GRIS          │        ││
│  │APTO      │ALERTA        │NO APTO       │SIN DATOS        │        ││
│  │Cumple    │Cumple pero   │Incumplimiento│< 5 muestras     │        ││
│  │Art. 8    │en zona alerta│Art. 8        │en 30 días       │        ││
│  └──────────┴──────────────┴──────────────┴─────────────────┘        ││
│  └────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────┘
```

## Popup del Mapa (al hacer click en un punto)

```
┌──────────────────────────────────────┐
│ 🔴 BALNEARIO LA TOMA                │
├──────────────────────────────────────┤
│ Municipio: Concordia                 │
│ Estado: NO APTO - No Habilitado      │
├──────────────────────────────────────┤
│ ÚLTIMA MUESTRA: 03/02/2026           │
│ E. coli: 450 UFC/100ml               │
│ Coliformes: 720 UFC/100ml            │
├──────────────────────────────────────┤
│ MEDIA GEOMÉTRICA (30 días):          │
│ E. coli: 425 UFC/100ml ❌ (>300)    │
│ Coliformes: 650 UFC/100ml ❌ (>600) │
│ Muestras: 12                         │
├──────────────────────────────────────┤
│ ⚠️  ACCIÓN:                          │
│ Prohibir baño - Investigar           │
│ fuentes de contaminación             │
└──────────────────────────────────────┘
```

## Vista de Series Temporales

```
┌─────────────────────────────────────────────────────────────────────────┐
│  📈 EVOLUCIÓN TEMPORAL - BALNEARIO LA TOMA                               │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  E. COLI (UFC/100ml)                                                    │
│    ┌────────────────────────────────────────────────────────┐          │
│ 800│- - - - - - - - - - - - Límite Crítico (800) - - - - - -│          │
│    │                                                         │          │
│ 600│                                          ●              │          │
│    │                               ●                         │          │
│ 400│                    ●     ●         ●                    │          │
│ 300│- - - - - - - Límite Media Geométrica (300) - - - - - - │          │
│ 200│         ●     ●                              ●          │          │
│    │    ●                                              ●     │          │
│   0└────────────────────────────────────────────────────────┘          │
│     Dic   Dic   Ene   Ene   Ene   Feb   Feb                            │
│     15    22    01    08    15    01    05                             │
│                                                                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  COLIFORMES TERMOTOLERANTES (UFC/100ml)                                 │
│    ┌────────────────────────────────────────────────────────┐          │
│1000│- - - - - - - - - - - Límite Crítico (1000) - - - - - - │          │
│    │                                                         │          │
│ 800│                                              ●          │          │
│    │                         ●         ●                     │          │
│ 600│- - - - - - Límite Media Geométrica (600) - - - - - - - │          │
│    │              ●     ●                   ●                │          │
│ 400│    ●    ●                                        ●      │          │
│    │                                                         │          │
│   0└────────────────────────────────────────────────────────┘          │
│     Dic   Dic   Ene   Ene   Ene   Feb   Feb                            │
│     15    22    01    08    15    01    05                             │
│                                                                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  MEDIA GEOMÉTRICA MÓVIL (30 días)                                       │
│    ┌────────────────────────────────────────────────────────┐          │
│ 700│                                                         │          │
│ 600│━━━━━━━━━━━━━━━━━ Límite Coliformes (600) ━━━━━━━━━━━━ │          │
│ 500│                                        ╱──────          │          │
│ 400│                              ╱────────╱                 │          │
│ 300│━━━━━━━━━━━━━━━━━ Límite E. coli (300) ━━━━━━━━━━━━━━ │          │
│ 200│             ╱────────                                    │          │
│ 100│────────────╱                                            │          │
│   0└────────────────────────────────────────────────────────┘          │
│     Dic   Dic   Ene   Ene   Ene   Feb   Feb                            │
│     15    22    01    08    15    01    05                             │
│                                                                          │
│     ━━━ E. coli MG    ━━━ Coliformes MG                                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

## Vista de Tabla Técnica

```
┌─────────────────────────────────────────────────────────────────────────┐
│  📋 TABLA TÉCNICA - HISTORIAL DE MUESTRAS                                │
├─────────────────────────────────────────────────────────────────────────┤
│  [⬇ Descargar CSV]  [⬇ Descargar Excel]                                │
│                                                                          │
│  [Filtrar: ]  [Filtrar: ]  [Filtrar: ]  [Filtrar: ]                   │
│                                                                          │
│  ┌─────────────────┬────────────┬────────┬────────┬──────────┬──────┐ │
│  │ Balneario       │ Municipio  │ Fecha  │E. coli │Coliformes│ pH   │ │
│  ├─────────────────┼────────────┼────────┼────────┼──────────┼──────┤ │
│  │ La Toma         │ Concordia  │05/02/26│  450   │   720    │ 7.2  │ │
│  │ Thompson        │ Concordia  │05/02/26│  180   │   350    │ 7.5  │ │
│  │ La Delfina      │ Colón      │04/02/26│  290   │   580    │ 7.1  │ │
│  │ Playa Ubajay    │ Ubajay     │04/02/26│  150   │   280    │ 7.4  │ │
│  │ Costa del Sol   │ C. Uruguay │03/02/26│  120   │   240    │ 7.6  │ │
│  │ La Toma         │ Concordia  │03/02/26│  380   │   650    │ 7.0  │ │
│  │ Thompson        │ Concordia  │02/02/26│  200   │   380    │ 7.3  │ │
│  │ ...             │ ...        │ ...    │  ...   │   ...    │ ...  │ │
│  └─────────────────┴────────────┴────────┴────────┴──────────┴──────┘ │
│                                                                          │
│  Mostrando 1-10 de 250 registros  [◀ Anterior] [Página 1 de 25] [▶]   │
└─────────────────────────────────────────────────────────────────────────┘
```

## Vista de Normativa

```
┌─────────────────────────────────────────────────────────────────────────┐
│  ⚖️  MARCO NORMATIVO - RESOLUCIÓN 084/SMA                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  📜 ARTÍCULO 8 - LÍMITES DE CALIDAD MICROBIOLÓGICA                      │
│  ┌────────────────────────────────────────────────────────────────────┐│
│  │ ESCHERICHIA COLI (E. coli)                                         ││
│  │                                                                     ││
│  │ • Media geométrica (30 días): < 300 UFC/100ml                      ││
│  │ • Valor crítico individual: Ninguna muestra ≥ 800 UFC/100ml        ││
│  │                                                                     ││
│  │ COLIFORMES TERMOTOLERANTES                                          ││
│  │                                                                     ││
│  │ • Media geométrica (30 días): < 600 UFC/100ml                      ││
│  │ • Valor crítico individual: Ninguna muestra ≥ 1000 UFC/100ml       ││
│  └────────────────────────────────────────────────────────────────────┘│
│                                                                          │
│  📋 REQUISITOS DE MUESTREO                                              │
│  ┌────────────────────────────────────────────────────────────────────┐│
│  │ • Mínimo 5 muestras en ventana de 30 días                          ││
│  │ • Frecuencia recomendada: semanal en temporada alta                ││
│  │ • Análisis por método estándar (NMP o UFC)                         ││
│  └────────────────────────────────────────────────────────────────────┘│
│                                                                          │
│  🚦 CLASIFICACIÓN DEL SEMÁFORO SANITARIO                                │
│  ┌────────────────────────────────────────────────────────────────────┐│
│  │ 🟢 VERDE - APTO                                                    ││
│  │ Cumple todos los requisitos del Art. 8.                            ││
│  │ Balneario habilitado para uso recreativo.                          ││
│  │                                                                     ││
│  │ 🟡 AMARILLO - ALERTA                                               ││
│  │ Cumple normativa pero con valores próximos a límites.              ││
│  │ Requiere monitoreo reforzado cada 48-72 horas.                     ││
│  │                                                                     ││
│  │ 🔴 ROJO - NO APTO                                                  ││
│  │ Incumplimiento de Art. 8.                                          ││
│  │ Balneario NO habilitado. Prohibición de baño.                      ││
│  │                                                                     ││
│  │ ⚪ GRIS - SIN DATOS                                                ││
│  │ Datos insuficientes para evaluación (< 5 muestras en 30 días).    ││
│  └────────────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────┘
```

## Paleta de Colores del Sistema

```
VERDE (Apto):         #28a745  ████████
AMARILLO (Alerta):    #ffc107  ████████
ROJO (No Apto):       #dc3545  ████████
GRIS (Sin Datos):     #999999  ████████

Primario (UI):        #007bff  ████████
Secundario:           #6c757d  ████████
Fondo:                #f8f9fa  ████████
Texto:                #212529  ████████
```

## Tipografía

- **Títulos**: Roboto Bold, 18-24px
- **Subtítulos**: Roboto Medium, 14-16px
- **Cuerpo**: Roboto Regular, 12-14px
- **Datos numéricos**: Roboto Mono, 14px

## Iconografía

- 🟢 🟡 🔴 ⚪ : Estados del semáforo
- 📊 : Dashboard
- 🗺️  : Mapa
- 📈 : Gráficos/Series
- 📋 : Tabla
- ⚖️  : Normativa
- 🔄 : Actualizar
- ⬇  : Descargar
- ⚠️  : Alerta/Advertencia
- ℹ️  : Información
- ✅ : Cumple
- ❌ : No cumple

## Responsive Breakpoints

- Desktop: > 1200px
- Tablet: 768px - 1200px
- Mobile: < 768px

En mobile, el sidebar se convierte en menú hamburguesa.
