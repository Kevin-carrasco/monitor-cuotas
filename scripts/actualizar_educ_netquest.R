# Convierte el Excel de Netquest con el nivel educativo del perfil de cada
# panelista (columnas ticket, id_user y CL_education_level) en
# config/educacion_netquest.csv, que lee la app. Después hay que volver a
# publicar la app.
#
# Uso (desde la carpeta monitor-cuotas):
#   Rscript scripts/actualizar_educ_netquest.R [ruta del Excel]

args <- commandArgs(trailingOnly = TRUE)
ARCHIVO <- if (length(args) > 0) args[1] else "../monitor-jusmer/scripts/educacion-netquest.xlsx"

x <- readxl::read_excel(ARCHIVO, col_types = "text")
stopifnot(all(c("ticket", "id_user", "CL_education_level") %in% names(x)))
salida <- data.frame(
  ticket = x$ticket,
  id_user = x$id_user,
  codigo = sub("\\.0+$", "", x$CL_education_level)
)
salida <- salida[!is.na(salida$codigo), ]
dir.create("config", showWarnings = FALSE)
utils::write.csv(salida, "config/educacion_netquest.csv", row.names = FALSE, na = "")
cat("Casos con nivel educativo Netquest:", nrow(salida), "\n")
print(table(salida$codigo))
