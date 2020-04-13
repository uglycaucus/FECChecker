library(twitteR)
library(tidyverse)
library(httr)
library(rvest)
library(keyring)

get_menchies <- function(){

account_mentions <- mentions()

extract_haters <- function(x){

user <- x$replyToSN %>%
  getUser()



user_name <- str_split(user$name, " ") %>%
  unlist()

user_location <- user$location

tibble(tweet_id = x$id,
       first_name = user_name[1], 
       last_name = user_name[length(user_name)],
       location = user_location,
       text = x$getText()) %>%
  return()

}


account_mentions %>%
  map(extract_haters) %>%
  return()

}


build_fec_request <- function(name, location){
  
  results <- GET(url = modify_url('https://api.open.fec.gov/v1/schedules/schedule_a/',
                      query = list(contributor_type = "individual",
                                   contributor_state = location,
                                   contributor_name = name,
                                   api_key = key_get("fec_checker", username = "fec_api_key"))
      )) %>%
    content() %>%
    .$results 
  
  

  
  results %>%
    map(map, discard, .p = is.list) %>%
    map(flatten) %>%
    map(discard, .p = is.list) %>%
    map(compact) %>%
    bind_rows() %>% select(recipient_committee_designation, 
                           campaign_name = name,
                           memo_text,
                           affiliated_committee_name,
                           committee_id,
                           contributor_first_name, 
                     contributor_last_name, 
                     contributor_employer,
                     contribution_receipt_date,
                     contribution_receipt_amount) %>%
    group_by(campaign_name, contributor_first_name, contributor_last_name, memo_text) %>%
    summarize(total = sum(contribution_receipt_amount)) %>% arrange(desc(total)) %>%
    return()
  

}





