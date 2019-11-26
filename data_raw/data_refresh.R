#----------- Data refresh function -----------

dt_ref <- function(end_time){

  end_time_old <- us_elec_old <- us_source_old <- cal_elec_old <- NULL

  # Error handling
  if(!lubridate::is.POSIXct(end_time)){
    stop("The 'end_time' argument is not POSIXct")
  }




  #--- Set functions ---#

  # Add pipe function
  `%>%` <- magrittr::`%>%`

  # Set function to pull data from eia API
  eia_series <- function(api_key, series_id){

    url <- base::paste("http://api.eia.gov/series/?",
                       "api_key=", api_key,
                       "&series_id=", series_id,
                       "&out=json", sep = "")
    # Parse the data with jq
    command <- base::paste("curl", " '",url, "' | jq -r '.series[].data[] | @tsv'", sep = "")

    output <- utils::read.table(text = system(command = command, intern = TRUE), sep = "\t") %>%
      stats::setNames(c("timestamp", "series")) %>%
      dplyr::mutate(date_time = lubridate::ymd_h(timestamp, tz = "UTC")) %>%
      dplyr::select(date_time, series) %>%
      dplyr::arrange(date_time)
    return(output)
  }


  #--- load saved datasets ---#
  us_elec_old <- USgrid::US_elec
  us_source_old <- USgrid::US_source
  cal_elec_old <- USgrid::Cal_elec

  end_time_old <- base::min(base::max(us_elec_old$date_time),
                          base::max(us_source_old$date_time),
                          base::max(cal_elec_old$date_time))

  start_time <- end_time_old + lubridate::hours(1)


  #--- Pulling US_elec series ---#



}




