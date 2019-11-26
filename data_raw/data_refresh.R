#----------- Data refresh function -----------

dt_refresh <- function(end_time){

  end_time_old <- us_elec_old <- us_elec_old1 <- NULL
  us_source_old <- us_source_old1 <- us_source_new <- NULL
  cal_elec_old <- cal_elec_old1 <- cal_elec_new <-NULL
  start_time <- NULL
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

  # Pulling multiple series by series catalog number
  reg_elec <- function(catalog, end_time){
    region_df <- lapply(1:nrow(catalog), function(i){
      df <- df1 <- df2 <- NULL
      print(catalog$series_id[i])
      df <- eia_series(api_key = api_key, series_id = catalog$series_id[i])

      if(!"error" %in% names(df$data)){

        df1 <- df %>%
          dplyr::arrange(date_time)

        start_time <- min(df1$date_time)

        df2 <- data.frame(date_time = seq.POSIXt(from = start_time, to = end_time, by = "hour")) %>%
          dplyr::left_join(df1, by = "date_time") %>%
          dplyr::mutate(operator = catalog$operator[i],
                        status = "ok")


      } else {

        #### Need to update ####
        warning(paste("The series", catalog$series_id[i], "return error"))
        df2 <- data.frame(date_time = NA,
                          series = NA,
                          operator = catalog$operator[i],
                          status = "error")
        #### Need to update ####
      }
      return(df2)
    }) %>% dplyr::bind_rows()

    region_temp <- region_df %>% dplyr::filter(status == "ok")

    if(nrow(region_temp) == 0){
      stop("No valid observations were found")
    } else {
      region_total <- region_temp %>%
        dplyr::group_by(date_time) %>%
        dplyr::summarise(series = sum(series, na.rm = any(!is.na(series)))) %>%
        dplyr::mutate(operator = "Total",
                      status = "ok")

      region_df <- dplyr::bind_rows(region_df, region_total)
    }
    return(region_df)
  }


  #--- load saved datasets ---#
  us_elec_old <- USgrid::US_elec
  us_source_old <- USgrid::US_source
  cal_elec_old <- USgrid::Cal_elec

  end_time_old <- base::min(base::max(us_elec_old$date_time),
                            base::max(us_source_old$date_time),
                            base::max(cal_elec_old$date_time))

  start_time <- end_time_old + lubridate::hours(1)


  if(start_time > end_time){
    stop("The 'start_time' is greater than the 'end_time")
  }


  #--- Pulling US_elec series ---#
  us_demand1<- eia_series(api_key = api_key, series_id  = "EBA.US48-ALL.D.H") %>%
    dplyr::mutate(type = "demand") %>%
    dplyr::arrange(date_time)
  us_elec_start <- base::min(us_elec_old$date_time)
  us_demand <- data.frame(date_time = seq.POSIXt(from = us_elec_start, to = end_time, by = "hour")) %>%
    dplyr::left_join(us_demand1,  by = "date_time")


  us_gen1 <- eia_series(api_key = api_key, series_id  = "EBA.US48-ALL.NG.H") %>%
    dplyr::mutate(type = "generation") %>%
    dplyr::arrange(date_time)

  head(us_gen1)


  us_gen <- data.frame(date_time = seq.POSIXt(from = us_elec_start, to = end_time, by = "hour")) %>%
    dplyr::left_join(us_gen1,  by = "date_time")

  us_elec_new <- dplyr::bind_rows(us_demand, us_gen) %>%
    tsibble::as_tsibble(key = type, index = date_time)


  # Valdidate the dataset

  us_elec_old1 <- us_elec_new %>% dplyr::filter(date_time <= end_time_old)

  if(!base::identical(us_elec_old, us_elec_old1)){
    stop("It seems like the new pull is not match to the old one for the 'US_elec' series")
  }

  #--- Pulling US_source series ---#
  energy_source_cat <- tsAPI::eia_query(api_key = api_key,category_id = 3390105)$category$childseries %>%
    dplyr::mutate(flag = grepl("UTC time", name)) %>%
    dplyr::filter(flag) %>%
    dplyr::select(-flag) %>%
    dplyr::mutate(operator = lapply(name, function(i){
      trimws(strsplit(strsplit(i, split = c("from"))[[1]][2], split = "for")[[1]][1])}) %>%
        unlist)


  us_source_new <- reg_elec(catalog = energy_source_cat, end_time = end_time)



  if(base::all(us_source_new$status == "ok")){
    us_source_new <- us_source_new %>%
      dplyr::filter(operator != "Total") %>%
      dplyr::select(date_time, series, source = operator) %>%
      tsibble::as_tsibble(key = source, index = date_time)
  } else {
    warning("Some observations do not have 'ok' status, check the series")
  }

  # Valdidate the dataset
  us_source_old1 <- us_source_new %>% dplyr::filter(date_time <= end_time_old)

  if(!base::identical(us_source_old, us_source_old1)){
    stop("It seems like the new pull is not match to the old one for the 'US_source' series")
  }

  #--- Pulling Cal_elec series ---#

  cal_cat <- tsAPI::eia_query(api_key = api_key,category_id = 3390291)$category$childseries %>%
    dplyr::mutate(flag = grepl("UTC time", name)) %>%
    dplyr::filter(flag) %>%
    dplyr::select(-flag) %>%
    dplyr::mutate(operator = trimws(sapply(strsplit(name, split = ","),function(x) x[length(x) - 1])))

  cal_elec_new <- reg_elec(catalog = cal_cat, end_time = end_time)

  if(all(cal_elec_new$status == "ok")){
    cal_elec_new <- cal_elec_new %>%
      dplyr::select(-status) %>%
      tsibble::as_tsibble(key = operator, index = date_time)
  } else {
    warning("Some observations do not have 'ok' status, check the series")
  }

  # Valdidate the dataset
  cal_elec_old1 <- cal_elec_new %>% dplyr::filter(date_time <= end_time_old)

  if(!base::identical(cal_elec_old, cal_elec_old1)){
    stop("It seems like the new pull is not match to the old one for the 'Cal_elec' series")
  }


  #--- Saving the series ---#
  # US_elec
  base::print(plotly::plot_ly(data = us_elec_new,
                  x = ~ date_time,
                  y = ~ series,
                  color = ~ type,
                  type = "scatter",
                  mode = "lines"))


  base::cat(base::paste(" US_elec series summary", "\n",
                        "----------------------", "\n",
                        "Start time:", base::min(us_elec_new$date_time), "\n",
                        "End time:", base::max(us_elec_new$date_time), "\n",
                        "Missing values:", base::any(base::is.na(us_elec_new$series))))


  q <- readline("Do you want to save the updated US_elec series? [Y/n]")
  if(q == "" | base::tolower(q) == "y"){
    US_elec <- us_elec_new
    usethis::use_data(US_elec, overwrite = TRUE)
  }

  # US_source
  base::print(plotly::plot_ly(data = us_source_new,
                  x = ~ date_time,
                  y = ~ series,
                  color = ~ source,
                  type = "scatter",
                  mode = "lines"))


  base::cat(base::paste(" US_source series summary", "\n",
                        "-------------------------", "\n",
                        "Start time:", base::min(us_source_new$date_time), "\n",
                        "End time:", base::max(us_source_new$date_time), "\n",
                        "Missing values:", base::any(base::is.na(us_source_new$series))))


  q <- readline("Do you want to save the updated US_source series? [Y/n]")
  if(q == "" | base::tolower(q) == "y"){
    US_source <- us_source_new
    usethis::use_data(US_source, overwrite = TRUE)
  }

  # Cal_elec
  base::print(plotly::plot_ly(data = cal_elec_new,
                  x = ~ date_time,
                  y = ~ series,
                  color = ~ operator,
                  type = "scatter",
                  mode = "lines"))

  base::cat(base::paste(" Cal_elec series summary", "\n",
                        "-----------------------", "\n",
                        "Start time:", base::min(cal_elec_new$date_time), "\n",
                        "End time:", base::max(cal_elec$date_time), "\n",
                        "Missing values:", base::any(base::is.na(cal_elec_new$series))))


  q <- readline("Do you want to save the updated Cal_elec series? [Y/n]")
  if(q == "" | base::tolower(q) == "y"){
    Cal_elec <- cal_elec_new
    usethis::use_data(Cal_elec, overwrite = TRUE)
  }



}




