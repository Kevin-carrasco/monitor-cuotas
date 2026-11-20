# Monitor de cuotas · Encuesta JusMer, Ola 1
#
# Versión mínima del monitor para compartir con Netquest: avance del campo y
# cuotas de sexo, edad y nivel educativo (declarado y según Netquest). Solo
# muestra agregados; nunca escribe en la base.
#
# Los archivos de R/ se cargan automáticamente al iniciar la app.
# Correr localmente: shiny::runApp()

library(shiny)
library(bslib)
library(ggplot2)

if (file.exists(".env")) readRenviron(".env")

tarjeta <- function(titulo, ..., nota = NULL) {
  card(
    full_screen = TRUE,
    card_header(titulo),
    card_body(..., fillable = TRUE),
    if (!is.null(nota)) card_footer(nota, class = "nota-tarjeta")
  )
}

estilos <- tags$style(HTML(sprintf("
  body { background: #f9f9f7; }
  .card { border: 1px solid rgba(11,11,11,0.10); box-shadow: none; }
  .card-header { font-weight: 600; background: transparent; border-bottom: 1px solid #ecebe6; }
  .nota-tarjeta { font-size: 0.82rem; color: %s; background: transparent; }
  .bslib-value-box .value-box-title { font-size: 0.9rem; color: %s; }
  .bslib-value-box .value-box-value { font-size: 1.9rem; font-weight: 600; color: %s; }
  .bslib-value-box p { font-size: 0.85rem; color: %s; margin-bottom: 0; }
  .progreso { height: 6px; background: #e1e0d9; border-radius: 3px; margin-top: 6px; overflow: hidden; }
  .progreso > div { height: 100%%; background: %s; }
  .pie { font-size: 0.85rem; color: %s; margin: 4px 2px 12px; }
  .error { background: #fbe4e4; border: 1px solid #e8a0a0; border-radius: 6px; padding: 8px 10px; }
",
  COLORES$tenue, COLORES$tinta2, COLORES$tinta, COLORES$tenue, COLORES$serie1, COLORES$tenue
)))

NOTA_CUOTA <- "Barra: encuestas completas. Marca negra: n límite de la cuota."

ui <- page_fillable(
  title = "Monitor de cuotas JusMer",
  theme = bs_theme(
    version = 5, primary = COLORES$marca, fg = COLORES$tinta, bg = "#ffffff",
    base_font = font_collection("system-ui", "-apple-system", "Segoe UI", "Roboto", "sans-serif")
  ),
  fillable = FALSE,
  estilos,
  h4("Encuesta JusMer · Ola 1 · Monitor de cuotas", style = "margin: 6px 2px 0;"),
  uiOutput("pie"),
  layout_column_wrap(
    width = 1 / 5, fill = FALSE,
    uiOutput("vb_entradas"), uiOutput("vb_completas"), uiOutput("vb_hoy"),
    uiOutput("vb_tasa"), uiOutput("vb_duracion")
  ),
  layout_column_wrap(
    width = 1 / 2, fill = FALSE, heights_equal = "row",
    tarjeta("Sexo", plotOutput("g_sexo", height = "190px"), nota = NOTA_CUOTA),
    tarjeta("Edad", plotOutput("g_edad", height = "190px"), nota = NOTA_CUOTA)
  ),
  layout_column_wrap(
    width = 1 / 2, fill = FALSE, heights_equal = "row",
    tarjeta("Nivel educativo declarado", plotOutput("g_educ", height = "190px"),
            nota = paste("Respuesta en la encuesta.", NOTA_CUOTA)),
    tarjeta("Nivel educativo según Netquest", plotOutput("g_educ_nq", height = "190px"),
            nota = uiOutput("nota_nq", inline = TRUE))
  )
)

server <- function(input, output, session) {
  datos <- reactiveVal(NULL)
  error <- reactiveVal(NULL)
  leido <- reactiveVal(NULL)

  observe({
    invalidateLater(REFRESCO_SEG * 1000, session)
    r <- tryCatch(preparar(leer_base()), error = function(e) e)
    if (inherits(r, "error")) {
      error(conditionMessage(r))
    } else {
      error(NULL)
      datos(r)
      leido(Sys.time())
    }
  })

  todo <- reactive({ req(datos()); datos() })
  completas <- reactive(todo()[todo()$completa, , drop = FALSE])
  ind <- reactive(indicadores(todo()))

  output$pie <- renderUI({
    if (!is.null(error())) return(div(class = "error", tags$strong("Error al leer los datos: "), error()))
    req(leido())
    div(class = "pie", sprintf(
      "Desde el %s · actualizado %s · se actualiza cada %d segundos",
      format(INICIO_CAMPO, "%d/%m/%Y"), format(leido(), "%d/%m %H:%M", tz = ZONA_HORARIA), REFRESCO_SEG
    ))
  })

  output$vb_entradas <- renderUI({
    i <- ind()
    value_box(title = "Entradas", value = num_es(i$entradas),
              tags$p(sprintf("%s aceptaron participar", num_es(i$aceptan))))
  })
  output$vb_completas <- renderUI({
    i <- ind()
    avance <- i$completas / META_N
    value_box(
      title = "Completas", value = num_es(i$completas),
      tags$p(sprintf("%s de la meta (%s)", pct_es(avance, 0.1), num_es(META_N))),
      div(class = "progreso", div(style = sprintf("width:%s%%", min(100, round(100 * avance, 1)))))
    )
  })
  output$vb_hoy <- renderUI({
    i <- ind()
    value_box(title = "Completas hoy", value = num_es(i$hoy),
              tags$p(sprintf("%s entradas hoy", num_es(i$hoy_entradas))))
  })
  output$vb_tasa <- renderUI({
    i <- ind()
    value_box(title = "Tasa de término", value = pct_es(i$tasa, 0.1),
              tags$p("Completas sobre quienes aceptaron"))
  })
  output$vb_duracion <- renderUI({
    i <- ind()
    value_box(
      title = "Tiempo mediano",
      value = if (is.na(i$duracion_mediana)) "–" else paste(num_es(i$duracion_mediana, 0.1), "min"),
      tags$p("Encuestas completas")
    )
  })

  grafico <- function(f) renderPlot(f(), bg = COLORES$superficie, res = 96)
  output$g_sexo <- grafico(function() g_cuotas(cuotas(completas(), "sexo_cuota", marco = "sexo")))
  output$g_edad <- grafico(function() g_cuotas(cuotas(completas(), "tramo_edad")))
  output$g_educ <- grafico(function() g_cuotas(cuotas(completas(), "educ_cuota")))
  output$g_educ_nq <- grafico(function() g_cuotas(cuotas(completas(), "educ_netquest", marco = "educ_cuota")))

  output$nota_nq <- renderUI({
    sin <- sum(is.na(completas()$educ_netquest))
    paste0("Perfil del panel Netquest. Técnica completa y universitaria incompleta vienen juntas y se ",
           "cuentan como técnica superior. ",
           if (sin > 0) sprintf("%s completas aún sin información de Netquest. ", num_es(sin)),
           NOTA_CUOTA)
  })
}

shinyApp(ui, server)
