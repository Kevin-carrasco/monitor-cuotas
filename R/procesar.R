# Variables derivadas, indicadores y cuotas -----------------------------------

a_fecha <- function(x) {
  x[!nzchar(x)] <- NA
  as.POSIXct(x, tz = "UTC", format = "%Y-%m-%d %H:%M:%S")
}

respondida <- function(x) !is.na(x) & nzchar(x)

preparar <- function(d) {
  d$inicio <- a_fecha(d$time_start)
  d$fin <- a_fecha(d$time_end)

  # Solo el campo: desde INICIO_CAMPO (sin fecha de inicio, según la de término)
  en_campo <- ifelse(is.na(d$inicio), !is.na(d$fin) & d$fin >= INICIO_CAMPO, d$inicio >= INICIO_CAMPO)
  d <- d[en_campo, , drop = FALSE]

  d$fecha <- as.Date(format(d$inicio, tz = ZONA_HORARIA))
  d$acepta <- d$consent_understand == "yes"
  d$completa <- d$acepta & Reduce(`|`, lapply(VARS_FIN, function(v) respondida(d[[v]])))
  con_filtro <- !is.na(d$inicio) & d$inicio >= INICIO_FILTRO_CALIDAD
  d$completa <- d$completa & (!con_filtro | d$filtro_calidad == "ok")
  d$duracion_min <- ifelse(d$completa & !is.na(d$fin) & !is.na(d$inicio),
                           as.numeric(difftime(d$fin, d$inicio, units = "mins")), NA)

  anio <- suppressWarnings(as.integer(d$year_of_birth))
  d$edad <- as.integer(format(d$inicio, "%Y")) - anio
  d$tramo_edad <- cut(d$edad, c(17, 29, 44, 59, Inf), labels = c("18-29", "30-44", "45-59", "60+"))
  d$sexo_cuota <- unname(c("0" = "Hombre", "1" = "Mujer")[d$sexo])
  d$educ_cuota <- unname(EDUC_CUOTA[d$education])

  nq <- EDUC_NETQUEST
  cod <- nq$codigo[match(d$ticket, nq$ticket, incomparables = "")]
  por_id <- nq$codigo[match(tolower(d$id_user), tolower(nq$id_user), incomparables = "")]
  cod[is.na(cod)] <- por_id[is.na(cod)]
  d$educ_netquest <- unname(EDUC_NETQUEST_CUOTA[as.character(cod)])
  d
}

indicadores <- function(d) {
  hoy <- as.Date(format(Sys.time(), tz = ZONA_HORARIA))
  acep <- d[d$acepta, , drop = FALSE]
  list(
    entradas = nrow(d),
    aceptan = nrow(acep),
    completas = sum(acep$completa),
    tasa = if (nrow(acep) > 0) mean(acep$completa) else NA,
    hoy = sum(acep$completa & acep$fecha %in% hoy),
    hoy_entradas = sum(d$fecha %in% hoy),
    duracion_mediana = stats::median(acep$duracion_min, na.rm = TRUE),
    ultima = if (nrow(d) > 0) max(d$inicio, na.rm = TRUE) else NA
  )
}

# n observado por categoría contra el n límite. `marco` indica qué cuota del
# marco usar (educ_netquest se compara con la cuota educ_cuota).
cuotas <- function(d, var, marco = var) {
  m <- MARCO_CUOTAS[MARCO_CUOTAS$variable == marco, ]
  x <- d[[var]]
  obs <- table(factor(as.character(x[!is.na(x)]), levels = m$categoria))
  data.frame(
    categoria = factor(m$categoria, levels = m$categoria),
    n = as.integer(obs),
    n_meta = m$n_meta,
    sin_dato = sum(is.na(x))
  )
}
