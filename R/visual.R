
#' Make Bins for y values based on x
#'
#' @param x x values
#' @param y y values
#' @param nbin expected number of data point in each bin
#'
#' @return a data frame with binned data frame
#' @export
#'
#' @examples x = runif(600, 1, 60)
#' y = rnorm(600)
#' make_bins(x,y,20)
make_bins = function(x, y, nbin) {
  if (nbin == 0)
    nbin <- floor(sqrt(length(x)))

  df <-
    data.frame(y = y,
               breaks = Hmisc::cut2(x, m = nbin, levels.mean = TRUE))
  df <- df |> na.omit() |>
    dplyr::group_by(breaks) |>
    dplyr::summarize(mean = mean(y),
                     std = sd(y),
                     cnt = dplyr::n()) |> dplyr::mutate("y_min" = mean - 1.96 * std /
                                                          sqrt(cnt),
                                                        y_max = mean + 1.96 * std / sqrt(cnt))

  df$breaks <- as.numeric(as.character(df$breaks))

  df

}


#' Plot multiple Bins
#'
#' @param df_list a list contains data frames
#' @param xlab x-axis label
#' @param ylab x-axis label
#' @param is_facet Boolean flag to decide create facets
#'
#' @return plots binned data
#' @export
#'
#' @importFrom stats na.omit sd
#' @examples dflist = list( "norm"=make_bins(x=runif(600, 1, 60) ,y=rnorm(600),nbin=60),
#'                          "romm"=make_bins(x=runif(600, 1, 60) ,y=runif(600, -1, 1),nbin=60))
#' plot_bins2(dflist,is_facet = FALSE)
plot_bins2 = function(df_list,
           xlab = "x",
           ylab = "Binned y",
           is_facet = TRUE) {
    df <- do.call("rbind", df_list)
    df$Model <-
      rep(names(df_list), each = nrow(df_list[[1]]))

    g <-
      ggplot2::ggplot(df, ggplot2::aes(breaks, mean, color = Model)) +  ggplot2::geom_point(size=1.5) +
      ggplot2::geom_errorbar(ggplot2::aes(ymin = y_min, ymax = y_max)) +
      ggplot2::geom_smooth(ggplot2::aes(breaks, mean), method = "loess",
                  formula=y~x,
                  se = FALSE) +
      ggplot2::scale_color_manual(
        values = c(
          "#E69F00",
          "#56B4E9",
          "#009E73",
          "#F0E442",
          "#0072B2",
          "#D55E00",
          "#CC79A7"
        )
      ) +
      ggplot2::ylab(ylab) + ggplot2::xlab(xlab) +
      ggplot2::theme_minimal()
    if (is_facet) {
      g <- g + ggplot2::facet_grid(cols = ggplot2::vars(Model))
    }

    g

  }

