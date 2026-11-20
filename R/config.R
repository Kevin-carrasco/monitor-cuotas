# Configuración del monitor de cuotas ------------------------------------------

ZONA_HORARIA <- "America/Santiago"

# Inicio del campo: las sesiones anteriores son pruebas internas
INICIO_CAMPO <- as.POSIXct("2026-10-30 00:00:00", tz = ZONA_HORARIA)

META_N <- as.integer(Sys.getenv("MONITOR_META_N", "4500"))
REFRESCO_SEG <- as.integer(Sys.getenv("MONITOR_REFRESCO_SEG", "60"))

# Un caso es completo si aceptó participar y respondió alguna variable de la
# última página. Desde INICIO_FILTRO_CALIDAD además debe haber pasado el filtro
# de calidad de la encuesta (filtro_calidad == "ok").
VARS_FIN <- c("salud_prov", "educ_prov")
INICIO_FILTRO_CALIDAD <- as.POSIXct("2026-11-12 00:00:00", tz = ZONA_HORARIA)

COLORES <- list(
  marca      = "#841414",
  serie1     = "#2a78d6",
  tinta      = "#0b0b0b",
  tinta2     = "#52514e",
  tenue      = "#898781",
  grilla     = "#e1e0d9",
  superficie = "#ffffff"
)

# Cuotas de la Ola 1: n límite de cada categoría (meta de 4.500 completas)
MARCO_CUOTAS <- data.frame(
  variable = c(rep("sexo", 2), rep("tramo_edad", 4), rep("educ_cuota", 4)),
  categoria = c(
    "Hombre", "Mujer",
    "18-29", "30-44", "45-59", "60+",
    "Básica o menos", "Media", "Técnica superior", "Universitaria o más"
  ),
  n_meta = c(2150, 2350, 990, 1352, 1034, 1124, 555, 1865, 1070, 1010)
)

# Nivel educativo declarado en la encuesta (variable education)
EDUC_CUOTA <- c(
  "0" = "Básica o menos", "1" = "Básica o menos", "2" = "Básica o menos",
  "3" = "Media", "4" = "Media",
  "5" = "Técnica superior", "6" = "Técnica superior",
  "7" = "Universitaria o más", "8" = "Universitaria o más", "9" = "Universitaria o más"
)

# Nivel educativo del perfil Netquest (CL_education_level). El código 7 junta
# técnica completa y universitaria incompleta: se cuenta como técnica superior.
ARCHIVO_EDUC_NETQUEST <- "config/educacion_netquest.csv"
EDUC_NETQUEST_CUOTA <- c(
  "1" = "Básica o menos", "2" = "Básica o menos", "3" = "Básica o menos",
  "4" = "Media", "5" = "Media",
  "6" = "Técnica superior", "7" = "Técnica superior",
  "8" = "Universitaria o más", "9" = "Universitaria o más"
)
EDUC_NETQUEST <- if (file.exists(ARCHIVO_EDUC_NETQUEST)) {
  utils::read.csv(ARCHIVO_EDUC_NETQUEST, colClasses = "character", na.strings = "")
} else {
  data.frame(ticket = character(), id_user = character(), codigo = character())
}
