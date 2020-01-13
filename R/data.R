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
#' @source US Energy Information Administration (Dec 2019) \href{https://www.eia.gov/}{website}
#' @keywords datasets time-series
#' @details The dataset contains the hourly demand and supply (generation) for electricity in the US (megawatthours).
#' The `type` column describes the type of the series (demand or generation)
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

"US_elec"


#' The US Hourly Net Generation by Energy Source

#' @description The net generation of electricity in the US by energy source (i.e., natural gas, coal, solar, etc.) since July 2018.
#'
#' Units: megawatthours
#'
#' Time zone: UTC
#'
#'
#' @format A tsibble object with hourly intervals
#' @source US Energy Information Administration (Dec 2019) \href{https://www.eia.gov/}{website}
#' @keywords datasets time-series
#' @details The dataset contains the hourly net generation of electricity in the US (megawatthours) by energy source
#' The `source` column describes the type of the energy source
#' @examples
#'
#' data(US_source)
#'
#' library(plotly)
#'
#' plot_ly(data = US_source,
#'         x = ~ date_time,
#'         y = ~ series,
#'         color = ~ source,
#'         type = "scatter",
#'         mode = "lines")
#'

"US_source"

#' Demand for California Independent System Operator (CISO)

#' @description The demand for electricity in California subregion since July 2018 by operator.
#'
#' Units: megawatthours
#'
#' Time zone: UTC
#'
#'
#' @format A tsibble object with hourly intervals
#' @source US Energy Information Administration (Dec 2019) \href{https://www.eia.gov/}{website}
#' @keywords datasets time-series
#' @details The dataset contains the hourly demand for electricity in the California subregion (megawatthours).
#' The `operator` column describes the name of operator provider
#' @examples
#'
#' data(Cal_elec)
#'
#' library(plotly)
#'
#' plot_ly(data = Cal_elec,
#'         x = ~ date_time,
#'         y = ~ series,
#'         color = ~ operator,
#'         type = "scatter",
#'         mode = "lines")
#'

"Cal_elec"

