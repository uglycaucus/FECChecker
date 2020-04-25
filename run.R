source("fec_checker.R")

data <- get_menchies() %>% 
  bind_rows() %>%
  split(seq(nrow(.))) %>%
  map(build_fec_request) %>%
  map(reply_with_image)

time <- strftime(Sys.time(), format = "%Y-%m-%d_%H%M%S")

data %>% 
  bind_rows() %>%
  write_csv(paste0("./data/JobRun", time, ".csv"))
