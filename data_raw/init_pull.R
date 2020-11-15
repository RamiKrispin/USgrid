#----------- Pulling the demand for electricity -----------

`%>%` <- magrittr::`%>%`

eia_series <- function(api_key, series_id){
  `%>%` <- magrittr::`%>%`

  url <- base::paste("http://api.eia.gov/series/?",
                     "api_key=", api_key,
                     "&series_id=", series_id,
                     "&out=json", sep = "")




  command <- base::paste("curl", " '",url, "' | jq -r '.series[].data[] | @tsv'", sep = "")

  output <- utils::read.table(text = system(command = command, intern = TRUE), sep = "\t") %>%
    stats::setNames(c("timestamp", "series")) %>%
    dplyr::mutate(date_time = lubridate::ymd_h(timestamp, tz = "UTC")) %>%
    dplyr::select(date_time, series) %>%
    dplyr::arrange(date_time)
  return(output)
}

#----------- Set a uniform end time for all series -----------
end_time <- as.POSIXct("2020-11-14 00:00:00", tz = "UTC") - lubridate::hours(1)
#----- Series 1 - Total Demand and Generation-----
source("/Users/ramikrispin/R/packages/APIs/eia.R")
tsAPI::eia_query(api_key = api_key,category_id = 2123635)


# US Demand
tsAPI::eia_query(api_key = api_key,category_id = 2122628)
tsAPI::eia_query(api_key = api_key,category_id = 3389935)

us_demand1<- eia_series(api_key = api_key, series_id  = "EBA.US48-ALL.D.H") %>%
  dplyr::mutate(type = "demand") %>%
  dplyr::arrange(date_time)

head(us_demand1)
tail(us_demand1)
table(is.na(us_demand1$series))

start_time <- NULL
start_time <- min(us_demand1$date_time)

us_demand <- data.frame(date_time = seq.POSIXt(from = start_time, to = end_time, by = "hour")) %>%
  dplyr::left_join(us_demand1,  by = "date_time")

# US Generation
tsAPI::eia_query(api_key = api_key,category_id = 2122629)
tsAPI::eia_query(api_key = api_key,category_id = 3390020)

us_gen1 <- eia_series(api_key = api_key, series_id  = "EBA.US48-ALL.NG.H") %>%
  dplyr::mutate(type = "generation") %>%
  dplyr::arrange(date_time)

head(us_gen1)

table(is.na(us_gen1$series))

start_time <- NULL
start_time <- min(us_gen1$date_time)

us_gen <- data.frame(date_time = seq.POSIXt(from = start_time, to = end_time, by = "hour")) %>%
  dplyr::left_join(us_gen1,  by = "date_time")

US_elec <- dplyr::bind_rows(us_demand, us_gen) %>%
  tsibble::as_tsibble(key = type, index = date_time)


head(US_elec)
tail(US_elec)

usethis::use_data(US_elec, overwrite = TRUE)

plotly::plot_ly(data = US_elec,
                x = ~ date_time,
                y = ~ series,
                color = ~ type,
                type = "scatter",
                mode = "lines")


#----- Demand by BA subregion - get catalog -----
tsAPI::eia_query(api_key = api_key,category_id = 2123635)
x <- tsAPI::eia_query(api_key = api_key,category_id = 3390016)

sub_df <- data.frame(category_ids = x$category$childcategories$category_id,
                     subregions = sub(" subregions", "",x$category$childcategories$name))

#----- Demand by BA subregion - function to pull the region data -----
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



#----- Demand by BA subregion - California -----
cal_cat <- tsAPI::eia_query(api_key = api_key,category_id = 3390291)$category$childseries %>%
  dplyr::mutate(flag = grepl("UTC time", name)) %>%
  dplyr::filter(flag) %>%
  dplyr::select(-flag) %>%
  dplyr::mutate(operator = trimws(sapply(strsplit(name, split = ","),function(x) x[length(x) - 1])))

Cal_elec <- reg_elec(catalog = cal_cat, end_time = end_time)
table(Cal_elec$status)

if(all(Cal_elec$status == "ok")){
  Cal_elec <- Cal_elec %>%
    dplyr::select(-status) %>%
    tsibble::as_tsibble(key = operator, index = date_time)
} else {
  warning("Some observations do not have 'ok' status, check the series")
}

plotly::plot_ly(data = Cal_elec,
                x = ~ date_time,
                y = ~ series,
                color = ~ operator,
                type = "scatter",
                mode = "lines")


usethis::use_data(Cal_elec, overwrite = TRUE)

#----- Net generation by energy source -----

energy_source_cat <- tsAPI::eia_query(api_key = api_key,category_id = 3390105)$category$childseries %>%
  dplyr::mutate(flag = grepl("UTC time", name)) %>%
  dplyr::filter(flag) %>%
  dplyr::select(-flag) %>%
  dplyr::mutate(operator = lapply(name, function(i){
    trimws(strsplit(strsplit(i, split = c("from"))[[1]][2], split = "for")[[1]][1])}) %>%
      unlist)


US_source <- reg_elec(catalog = energy_source_cat, end_time = end_time)



if(all(US_source$status == "ok")){
  US_source <- US_source %>%
    dplyr::filter(operator != "Total") %>%
    dplyr::select(date_time, series, source = operator) %>%
    tsibble::as_tsibble(key = source, index = date_time)
} else {
  warning("Some observations do not have 'ok' status, check the series")
}

head(US_source)

plotly::plot_ly(data = US_source,
                x = ~ date_time,
                y = ~ series,
                color = ~ source,
                type = "scatter",
                mode = "lines")

usethis::use_data(US_source, overwrite = TRUE)
