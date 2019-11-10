#' The US Hourly Demand and Supply for Electricity
#'
#' @description  The total hourly demand and supply (generation) for electricity in the US since July 2015
#'
#' Units: megawatthours
#'
#' Time zone: UTC
#'
#'
#' @format A tsibble object with hourly intervals
#' @source US Energy Information Administration (Nov 2019) \href{https://www.eia.gov/}{website}
#' @keywords datasets, time-series
#' @details The dataset contains the hourly demand and supply (generation) for electricity in the US (megawatthours).
#' The `type` column describe the type of the series (demand or generation)
#' @examples
#'
#' data(US_elec)
#'
#' library(plotly)
#'
#' plot_ly(data = US_elec,
#'         x = ~ date_time,
#'         y = ~ series,
#'         color = ~ type,
#'         type = "scatter",
#'         mode = "lines")
#'
