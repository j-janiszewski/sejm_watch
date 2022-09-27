library(stringr)
library(rvest)
library(aws.s3)
library(dplyr)


read_page <- function(url) {
  for (i in 1:5) {
    try({
      page <- read_html(url)
      break
    })
  }
  return(page)
}


get_table <- function(url) {
  page <- read_page(url)
  tabels <- page %>%
    html_nodes(css = "div#content") %>%
    html_nodes(css = "table.tab")
  
  table <- tabels[[1]] %>% html_table()
  return(table)
}

get_date <- function(url) {
  page <- read_page(url)
  date <- page %>%
    html_nodes(css = "div#content") %>%
    html_nodes("div") %>%
    html_text("p") %>%
    str_extract("[0-9]{2}-[0-9]{2}-[0-9]{4}")
  
  return(date)
}
get_rds_from_s3 <- function(file_name) {
  file <- get_object(glue::glue("s3://tweets-bucket1/{file_name}.rds"))
  readRDS(gzcon(rawConnection(file)))
}
get_party_table <- function(party_name) {
  page <- read_page(glue::glue("https://www.sejm.gov.pl/sejm9.nsf/klubposlowie.xsp?klub={party_name}"))
  
  deputies <- page %>%
    html_nodes("#title_content") %>%
    html_nodes("#contentBody") %>%
    html_nodes(".deputies") %>%
    html_elements("li") %>%
    html_elements(".deputyName") %>%
    html_text()
  
  return(tibble(posel = deputies, party = party_name))
}

# Reading old data from s3 ------------------------------------------------

number_of_speaches <- get_rds_from_s3("number_of_speaches")

number_of_votings <- get_rds_from_s3("number_of_votings")

number_of_interpollations <- get_rds_from_s3("number_of_interpollations")

number_of_inquires <- get_rds_from_s3("number_of_inquires")

affiliations <- get_rds_from_s3("affiliations")

prev_date <- colnames(number_of_votings) %>%
  tail(n = 1) %>%
  str_sub(nchar(.) - 9, nchar(.))

url <- "https://www.sejm.gov.pl/sejm9.nsf/agent.xsp?symbol=RWYSTAPIENIA&NrKadencji=9"
date <- get_date(url)


if (date != prev_date) {
  
  
  
  
  # Number of speeches --------------------------------------------------------
  
  
  url <- "https://www.sejm.gov.pl/sejm9.nsf/agent.xsp?symbol=RWYSTAPIENIA&NrKadencji=9"
  
  speeches <- get_table(url) %>%
    select(c(2, 4)) %>%
    rename(
      name = "Nazwisko i imię posła",
      !!glue::glue("number_of_speeches_till_{date}") := "Liczba wypowiedzi(w tym jako członka RM)"
    )
  
  
  number_of_speaches <- number_of_speaches %>% inner_join(speeches, by = "name")
  
  
  # Number of interpellations -----------------------------------------------------
  
  url <- "https://www.sejm.gov.pl/sejm9.nsf/agent.xsp?symbol=RINTERPELACJE&NrKadencji=9&Typ=INT"
  
  interpellations <- get_table(url) %>%
    select(c(2, 4, 5)) %>%
    mutate_if(is.numeric, ~ replace(., is.na(.), 0)) %>%
    mutate(!!glue::glue("number_of_interpollations_till_{date}") := .[[2]] + .[[3]]) %>%
    select(c(1, 4)) %>%
    rename(
      name = "Nazwisko i imię posła"
    )
  
  number_of_interpollations <- number_of_interpollations %>% inner_join(interpellations, by = "name")
  
  # Number of inquiries --------------------------------------------------------
  
  url <- "https://www.sejm.gov.pl/sejm9.nsf/agent.xsp?symbol=RZAPYTANIA&NrKadencji=9&Typ=ZAP"
  
  inquiries <- get_table(url) %>%
    select(c(2, 4, 5)) %>%
    mutate_if(is.numeric, ~ replace(., is.na(.), 0)) %>%
    mutate(!!glue::glue("number_of_inquiries_till_{date}") := .[[2]] + .[[3]]) %>%
    select(c(1, 4)) %>%
    rename(
      name = "Nazwisko i imię posła"
    )
  
  number_of_inquires <- number_of_inquires %>% inner_join(inquiries, by = "name")
  
  # Number of votings ---------------------------------------------------------------
  
  url <- "https://www.sejm.gov.pl/sejm9.nsf/agent.xsp?symbol=RGLOS&Nrkadencji=9&Kol=L"
  
  votings <- read_html(url) %>%
    html_node(xpath = "//*[@id=\"content\"]/table") %>%
    html_table() %>%
    select(c(2, 4, 5)) %>%
    slice(3:n()) %>%
    rename(
      name = "X2",
      !!glue::glue("number_of_votings_till_{date}") := "X4",
      !!glue::glue("peercentage_of_presence_till_{date}") := "X5"
    )
  
  number_of_votings <- number_of_votings %>% inner_join(votings, by = "name")
  
  # party affilations -------------------------------------------------------
  page <- read_page("https://www.sejm.gov.pl/sejm9.nsf/kluby.xsp")
  
  kluby <- page %>%
    html_nodes(".partie") %>%
    html_nodes(css = "a") %>%
    html_attr("href") %>%
    str_subset(pattern = "/sejm9.nsf/klub.xsp*")
  
  partie <- kluby %>%
    str_replace(".*=", "") %>%
    c("niez.")
  
  current_affiliations <- tibble()
  
  for (party_name in partie) {
    current_affiliations <- rbind(current_affiliations, get_party_table(party_name))
  }
  
  current_affiliations %>% rename(!!glue::glue("party_on_{date}") := party)
  
  affiliations <- affiliations %>% inner_join(current_affiliations)
  
  # Saving data to s3 -------------------------------------------------------
  
 # s3saveRDS(number_of_speaches, object = "number_of_speaches.rds", bucket = "tweets-bucket1")
  
 # s3saveRDS(number_of_interpollations, object = "number_of_interpollations.rds", bucket = "tweets-bucket1")
  
 # s3saveRDS(number_of_inquires, object = "number_of_inquires.rds", bucket = "tweets-bucket1")
  
 # s3saveRDS(number_of_votings, object = "number_of_votings.rds", bucket = "tweets-bucket1")
  
 # s3saveRDS(affiliations, object = "affiliations.rds", bucket = "tweets-bucket1")
}
