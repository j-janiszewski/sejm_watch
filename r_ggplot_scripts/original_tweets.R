library(ggplot2)
library(dplyr)
library(magrittr)
library(ggthemes)
library(rtweet)

token <- create_token(
  app = Sys.getenv("TWITTER_APP_NAME"),
  consumer_key = Sys.getenv("TWITER_CONSUMER_KEY"),
  access_token = Sys.getenv("TWITER_ACCESS_TOKEN"),
  consumer_secret = Sys.getenv("TWITER_CONSUMER_SECRET"),
  access_secret = Sys.getenv("TWITER_ACCESS_SECRET")
)

dates=readLines("dates.txt")

top_pms = read.csv("original_tweets.csv")

cols = top_pms %>% select(party, color) %>% unique()
cols = setNames(cols$color, cols$party)


top_pms %>%
  mutate(name = reorder(name, n)) %>%
  ggplot(aes(
    y = name,
    x = n
  )) +
  geom_col(aes(fill = party)) +
  geom_label(aes(
    label = n,
    color = party,
    x = n - 2
  )) +
  labs(
    fill = "Klub parlamentarny",
    title = "Posłowie z największą liczbą oryginalnych wpisów",
    subtitle = sprintf(
      "Liczba twittów bez cytowań, retweetów i odpowiedzi od %s do %s ",
       dates[1], dates[2]
    ),
    x = "Liczba odpowiedzi",
    y = "", caption = "Więcej na @sejm__watch"
  ) +
  theme_fivethirtyeight() +
  theme(
    panel.grid.major.y = element_blank(),
    axis.text.y = element_text( color = "black", size = 12, hjust = 1)
  ) +
  guides(color = F) +
  scale_color_manual(values = cols) +
  scale_fill_manual(values = cols)


temp_file <- tempfile(fileext = ".png")

ggsave("plot.png", device = "png", width = 12, height = 12)

status0 <- glue::glue("Posłowie z największą liczbą oryginalnych wpisów od {dates[1]} do {dates[2]} \
                      @{paste(top_pms$screen_name, collapse = ' @')}")
print(status0)

post_tweet(status = status0, media = temp_file, media_alt_text= "Wykres najczęściej piszących oryginalne tweety posłów ", token = token)