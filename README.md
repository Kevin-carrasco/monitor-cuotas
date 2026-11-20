# Monitor de cuotas · JusMer Ola 1

Versión mínima del monitor de la encuesta JusMer (Ola 1), pensada para compartir con Netquest. Lee en vivo la tabla de respuestas en Supabase, se actualiza cada 60 segundos y solo muestra agregados.

## Qué muestra

Todo se cuenta desde el inicio del campo, el 30/10/2026; las sesiones anteriores son pruebas internas.

| Indicador | Definición |
|---|---|
| Entradas | Sesiones iniciadas |
| Completas | Aceptaron participar y respondieron la última página. Desde el 12/11, además pasaron el filtro de calidad de la encuesta (`filtro_calidad == "ok"`). Incluye el avance sobre la meta de 4.500 |
| Completas hoy | Completas iniciadas hoy (hora de Chile) |
| Tasa de término | Completas sobre quienes aceptaron participar |
| Tiempo mediano | Mediana de la duración de las completas, en minutos |

Las cuotas comparan las completas con el n límite de cada categoría (`MARCO_CUOTAS` en `R/config.R`):

- Sexo y tramo de edad.
- Nivel educativo declarado en la encuesta.
- Nivel educativo según el perfil del panel Netquest. Netquest junta técnica completa y universitaria incompleta en un mismo código, que se cuenta como técnica superior.

## Estructura

```
app.R                               interfaz y servidor
R/config.R                          fechas, meta, cuotas y códigos educativos
R/datos.R                           lectura de Supabase (solo las columnas necesarias)
R/procesar.R                        variables derivadas, indicadores y cuotas
R/graficos.R                        gráfico de cuotas y formato
scripts/actualizar_educ_netquest.R  genera config/educacion_netquest.csv
```

## Credenciales

Las variables `SD_HOST`, `SD_PORT`, `SD_DBNAME`, `SD_USER`, `SD_PASSWORD` y `SD_TABLE` se leen del entorno o de un archivo `.env` en la carpeta de la app. El `.env` está en `.gitignore` y nunca debe subirse.

## Nivel educativo según Netquest

`config/educacion_netquest.csv` (ticket, id_user y código de Netquest) se genera desde el Excel que entrega Netquest:

```
Rscript scripts/actualizar_educ_netquest.R ruta/al/excel.xlsx
```

El archivo tiene identificadores de panelistas, por eso está en `.gitignore`; se sube solo junto con la app al publicarla. Las completas que entren después del último Excel aparecen como "sin información de Netquest" hasta que se actualice y se vuelva a publicar.

## Correr localmente

```r
shiny::runApp()
```
