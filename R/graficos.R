# Gráficos y formato ----------------------------------------------------------

library(ggplot2)

pct_es <- function(x, acc = 1) {
  ifelse(is.na(x), "–", scales::percent(x, accuracy = acc, decimal.mark = ",", big.mark = "."))
}
num_es <- function(x, acc = 1) {
  ifelse(is.na(x), "–", scales::number(x, accuracy = acc, decimal.mark = ",", big.mark = "."))
}

sin_datos <- function(texto = "Aún no hay encuestas completas") {
  ggplot() +
    annotate("text", x = 0, y = 0, label = texto, colour = COLORES$tenue, size = 4.5) +
    theme_void() +
    theme(plot.background = element_rect(fill = COLORES$superficie, colour = NA))
}

# Barra: n observado. Marca negra: n límite de la cuota.
g_cuotas <- function(tab) {
  if (is.null(tab) || sum(tab$n) == 0) return(sin_datos())
  tab$categoria <- factor(tab$categoria, levels = rev(levels(tab$categoria)))
  tope <- max(c(tab$n, tab$n_meta))
  ggplot(tab, aes(y = categoria)) +
    geom_col(aes(x = n), fill = COLORES$serie1, width = 0.62) +
    geom_errorbar(aes(xmin = n_meta, xmax = n_meta), width = 0.85, linewidth = 1,
                  colour = COLORES$tinta) +
    geom_text(aes(x = pmax(n, n_meta) + tope * 0.04,
                  label = sprintf("%s de %s (%s)", num_es(n), num_es(n_meta), pct_es(n / n_meta))),
              hjust = 0, size = 3.2, colour = COLORES$tinta2) +
    scale_x_continuous(limits = c(0, tope * 1.9), expand = expansion(mult = c(0, 0))) +
    labs(x = NULL, y = NULL) +
    theme_minimal(base_size = 12) +
    theme(
      plot.background = element_rect(fill = COLORES$superficie, colour = NA),
      panel.grid = element_blank(),
      axis.text.x = element_blank(),
      axis.text.y = element_text(colour = COLORES$tinta2),
      plot.margin = margin(8, 12, 8, 8)
    )
}
