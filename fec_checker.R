library(tidyverse)
library(httr)
library(rvest)
library(keyring)
library(gridExtra)
library(rtweet)
library(lubridate)


get_menchies <- function(){

token <- create_token(app = "FECChecker", 
                      consumer_key = key_get(service = "fec_checker", 
                            username = "twitter_api_key"),
                    consumer_secret = key_get(service = "fec_checker", 
                            username = "twitter_api_secret"),
                    access_token = key_get(service = "fec_checker", 
                            username = "twitter_access_token"),
                    access_secret = key_get(service = "fec_checker", 
                            username = "twitter_token_secret")
                    )
  
  
account_mentions <- get_mentions() %>% 
  filter(created_at >= Sys.time() - minutes(15)) %>% 
  split(seq(nrow(.))) 




extract_haters <- function(x){

user <- x$in_reply_to_screen_name %>%
  lookup_users()

user_name <- str_split(user$name, " ") %>%
  unlist()

user_location <- user$location

data <- tibble(tweet_id = x$status_id,
       name = user$name,
       first_name = user_name[1], 
       last_name = user_name[length(user_name)],
       location = user_location,
       text = x$text,
       requests = str_extract_all(x$text, 
                                  pattern = "[:alpha:]*\\?"),
       replies = as.character(str_extract_all(x$text,
                                 pattern = "\\@.* ")))

requests <- data$requests %>% 
  unlist()

if(length(requests) > 0){
  
  data <- data %>%
    unnest(requests) %>%
    mutate(requests = str_remove(requests, "\\?"))
    
  
} else {
  
  data$requests <- ""
  
}

  return(data)

}


account_mentions %>%
  map(extract_haters) %>%
  return()

}


build_fec_request <- function(data){
  
  
  results <- GET(url = modify_url('https://api.open.fec.gov/v1/schedules/schedule_a/',
                      query = list(contributor_type = "individual",
                                  # contributor_state = location,
                                   contributor_name = data$name,
                                   api_key = key_get("fec_checker", username = "fec_api_key"))
      )) %>%
    content() %>%
    .$results 
  
if(length(results) > 0){
  
 results <- results %>%
    map(map, discard, .p = is.list) %>%
    map(purrr::flatten) %>%
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
                     contribution_receipt_amount)

 if(data$requests != ""){
  
 results <- results %>%
     filter(str_detect(toupper(campaign_name), toupper(data$requests)) | str_detect(toupper(memo_text), toupper(data$requests)))
  
} 
 
if(nrow(results) > 0){
   
results <- results %>%
    group_by(campaign_name, contributor_first_name, 
             contributor_last_name, memo_text) %>%
    summarize(total = sum(contribution_receipt_amount)) %>% 
      arrange(desc(total)) %>%
   ungroup() %>%
   slice(1:5)
      
 
 data %>% 
   mutate(results = list(results),
          status = "success") %>%
    return()
 
} else {
  
  data %>% mutate(status = "fail") %>%
    return()
  
}
 
  } else {
    
    data %>% mutate(status = "fail") %>% return()
  
    }
  
}


reply_with_image <- function(data){
 
  if(is.null(data)){
    
    stop()
    
  }
  
  
  if(data$status == "success"){
  
  
    ggsave(filename = paste0("./", data$name, ".png"), 
           plot = data$results[[1]] %>%
             mutate(Name = paste(contributor_first_name, contributor_last_name, sep = " "),
                    Amount = paste0("$", total),
                    Note = str_trunc(str_remove(memo_text, "EARMARKED FOR "), 20, side = "right"),
                    Campaign = str_trunc(campaign_name, 20, side = "right")) %>%
             select(Name, Campaign, Note, Amount) %>%
             grid.table(),
           device = "png")
  
  
    
    
   post_tweet(status = paste0(" Here are the top 5 individual campaign contributions matching the name ", data$name, ". We can't guarantee this is the same person!"),
          media = paste0("./", data$name, ".png"),
          in_reply_to_status_id = data$tweet_id,
          auto_populate_reply_metadata = TRUE)
  
   file.remove(paste0("./", data$name, ".png"))
   
  } else if(data$requests != ""){
    
    post_tweet(status = "Sorry, we can't find any donations to that candidate matching this name.",
               in_reply_to_status_id = data$tweet_id,
               auto_populate_reply_metadata = TRUE)
    
  } else {
    
    post_tweet(status = "Sorry, we can't find any donations matching this name.",
               in_reply_to_status_id = data$tweet_id,
               auto_populate_reply_metadata = TRUE)
    
  }
   
    return(data)
  
}


  




