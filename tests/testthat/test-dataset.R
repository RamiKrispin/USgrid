context("Test the datasets attributes")

test_that(desc = "Test US_elec dataset",
          {
            start_time <- base::min(US_elec$date_time)
            max_time <- base::max(US_elec$date_time)
            expect_equal(start_time == base::as.POSIXct("2015-07-01 05:00:00", tz = "UTC"), TRUE)
            expect_equal(max_time >= base::as.POSIXct("2019-11-24 23:00:00", tz = "UTC"), TRUE)
            expect_equal(tsibble::is_tsibble(US_elec), TRUE)
            expect_equal(tsibble::index(US_elec) == "date_time", TRUE)
            expect_equal(tsibble::key(US_elec) == "type", TRUE)
            expect_equal(lubridate::is.POSIXct(US_elec$date_time), TRUE)
          })


test_that(desc = "Test US_source dataset",
          {
            start_time <- base::min(US_source$date_time)
            max_time <- base::max(US_source$date_time)
            expect_equal(start_time == base::as.POSIXct("2018-07-01 05:00:00", tz = "UTC"), TRUE)
            expect_equal(max_time >= base::as.POSIXct("2019-11-24 23:00:00", tz = "UTC"), TRUE)
            expect_equal(tsibble::is_tsibble(US_source), TRUE)
            expect_equal(tsibble::index(US_source) == "date_time", TRUE)
            expect_equal(tsibble::key(US_source) == "source", TRUE)
            expect_equal(lubridate::is.POSIXct(US_source$date_time), TRUE)
          })


test_that(desc = "Test Cal_elec dataset",
          {
            start_time <- base::min(Cal_elec$date_time)
            max_time <- base::max(Cal_elec$date_time)
            expect_equal(start_time == base::as.POSIXct("2018-07-01 08:00:00", tz = "UTC"), TRUE)
            expect_equal(max_time >= base::as.POSIXct("2019-11-24 23:00:00", tz = "UTC"), TRUE)
            expect_equal(tsibble::is_tsibble(Cal_elec), TRUE)
            expect_equal(tsibble::index(Cal_elec) == "date_time", TRUE)
            expect_equal(tsibble::key(Cal_elec) == "operator", TRUE)
            expect_equal(lubridate::is.POSIXct(Cal_elec$date_time), TRUE)
          })
