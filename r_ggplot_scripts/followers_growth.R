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

gains = read.csv("followers_growth.csv")

gains$gain <- gains$ending_num - gains$starting_num
gains$growth <- round(gains$gain / gains$starting_num * 100, digits = 1)
gains %>%
  arrange(-growth) %>%
  slice(1:7) -> gains

cols = gains %>% select(party, color) %>% unique()
cols = setNames(cols$color, cols$party)

gains %>%
  mutate(name = reorder(name, growth)) %>%
  ggplot(aes(
    y = name,
    x = growth
  )) +
  geom_col(aes(fill = party)) +
  geom_label(aes(
    label = glue::glue("{growth} %"),
    color = party,
    x = growth 
  )) +
  labs(
    fill = "Klub parlamentarny",
    title = "Wschodzące sejmowe gwiazdy twittera",
    subtitle = sprintf(
      "Procentowy wzrost liczby obserwujących pomiędzy %s i %s ",
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
  guides(color = "none") +
  scale_color_manual(values = cols) +
  scale_fill_manual(values = cols)

temp_file <- tempfile(fileext = ".png")

ggsave(temp_file, device = "png", width = 12, height = 12)

status0 <- glue::glue("Największy procentowy wzrost liczby obserwujących pomiędzy {dates[1]} do {dates[2]} \
                      @{paste(gains$screen_name, collapse = ' @')}")

print(status0)

post_tweet(status = status0, media = temp_file, media_alt_text= "Wykres największego wzrostu liczby obserwujących wśród obecnych na twitterze posłów ", token = token)
