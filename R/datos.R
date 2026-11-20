# Lectura de la tabla de respuestas en Supabase ---------------------------------
#
# Credenciales: variables SD_HOST, SD_PORT, SD_DBNAME, SD_USER, SD_PASSWORD y
# SD_TABLE, desde el entorno o desde un archivo .env (nunca subirlo).
# Solo se leen las columnas necesarias para los indicadores y las cuotas.

COLUMNAS <- c(
  "session_id", "ticket", "id_user", "time_start", "time_end",
  "consent_understand", "filtro_calidad", "sexo", "year_of_birth", "education",
  VARS_FIN
)

conectar_base <- function() {
  faltan <- c("SD_HOST", "SD_DBNAME", "SD_USER", "SD_PASSWORD")
  faltan <- faltan[!nzchar(Sys.getenv(faltan))]
  if (length(faltan) > 0) stop("Faltan variables de entorno: ", paste(faltan, collapse = ", "))
  DBI::dbConnect(
    RPostgres::Postgres(),
    host       = Sys.getenv("SD_HOST"),
    port       = as.integer(Sys.getenv("SD_PORT", "5432")),
    dbname     = Sys.getenv("SD_DBNAME"),
    user       = Sys.getenv("SD_USER"),
    password   = Sys.getenv("SD_PASSWORD"),
    sslmode    = Sys.getenv("SD_SSLMODE", "require"),
    gssencmode = "disable"
  )
}

leer_base <- function() {
  con <- conectar_base()
  on.exit(DBI::dbDisconnect(con), add = TRUE)
  tabla <- Sys.getenv("SD_TABLE", "jusmer_ola1_responses")
  cols <- intersect(COLUMNAS, DBI::dbListFields(con, tabla))
  d <- DBI::dbGetQuery(con, sprintf(
    "SELECT %s FROM %s",
    paste(DBI::dbQuoteIdentifier(con, cols), collapse = ", "),
    DBI::dbQuoteIdentifier(con, tabla)
  ))
  for (v in setdiff(COLUMNAS, names(d))) d[[v]] <- rep("", nrow(d))
  d[] <- lapply(d, function(x) {
    x <- as.character(x)
    x[is.na(x)] <- ""
    x
  })
  d
}
