library(ggplot2)
library(dplyr)
library(magrittr)
library(ggthemes)
library(rtweet)
library(gganimate)
library(gifski)
library(purrr)
library(tidyr)

token <- create_token(
  app = Sys.getenv("TWITTER_APP_NAME"),
  consumer_key = Sys.getenv("TWITER_CONSUMER_KEY"),
  access_token = Sys.getenv("TWITER_ACCESS_TOKEN"),
  consumer_secret = Sys.getenv("TWITER_CONSUMER_SECRET"),
  access_secret = Sys.getenv("TWITER_ACCESS_SECRET")
)

dates <- readLines("dates.txt")

activity_by_day <- read.csv("most_active.csv")

activity_by_day <- activity_by_day %>%
  mutate(weekday = ifelse(weekday == 1, 7, weekday - 1))

week_days <- c(
  "Poniedziałek",
  "Wtorek",
  "Środa",
  "Czwartek",
  "Piątek",
  "Sobota",
  "Niedziela"
)


week_days <- factor(week_days, levels = week_days)


tweets_for_func <- tibble(
  week_num = 1:7,
  dzien_tyg = week_days
) %>%
  mutate(tbl = map(
    week_num,
    function(week_num) {
      activity_by_day %>%
        filter(weekday <= week_num) %>%
        group_by(name, party, screen_name, color) %>% 
        summarise(n = sum(n)) %>% 
        ungroup() %>% 
        arrange(desc(n)) %>%
        slice(1:7)
    }
  ))

ranked_by_day <- tweets_for_func %>%
  unnest(tbl) %>%
  group_by(week_num) %>%
  mutate(rank = 1:n())

cols = ranked_by_day %>% ungroup() %>% select(party, color) %>% unique()
cols = setNames(cols$color, cols$party)

my_plot <- ranked_by_day %>% 
  ggplot() +  
  aes(xmin = 0 ,  
      xmax = n ) +  
  aes(ymin = rank - .45,  
      ymax = rank + .45,  
      y = rank) + 
  facet_wrap(~ dzien_tyg) +  
  geom_rect(alpha = .7) +  
  aes(fill = party)+
  scale_fill_manual(values = cols)+
  scale_x_continuous(
    limits = c(-2100, 1400),
    breaks = c(0, 400, 800, 1200))+
  geom_text(col = "gray13",
            hjust = "right",
            aes(label = name),
            x = -50)+
  scale_y_reverse()+
  labs(fill = NULL)+
  labs(title = 'Najbardziej aktywni posłowie ',
       subtitle = sprintf('Łączba liczba wpisów, odpowiedzi i retweetów od %s do %s ',dates[1],dates[2]),
       caption = 'Więcej na @sejm__watch') +
  theme_fivethirtyeight() +
  theme(axis.text.y = element_blank()) +
  theme(panel.grid.major.y = element_blank())


anim <- my_plot +
  facet_null() +
  geom_text(
    x = 900 ,
    y = -7,
    family = "Verdana",
    aes(label = as.character(dzien_tyg)),
    size = 5,
    col = "grey18"
  ) +
  aes(group = name) +
  transition_states(week_num,
                    transition_length = 2.5,
                    state_length = 1.25)+
  enter_fade()+
  exit_fade()

animate(anim, 
        nframes = 200,
        fps = 20,
        width = 1280/2, 
        height = 1080/3,
        duration = 21,renderer = gifski_renderer())


media0 <- glue::glue("Twitter_Bot/most_active_plot_{dates[2]}.gif")

anim_save(here::here(media0))

ranked_by_day %>% filter(week_num==7) -> most_active

status0 <- glue::glue("Najbardziej aktywni posłowie od {dates[1]} do {dates[2]} \
                      @{paste(most_active$screen_name, collapse = ' @')}")
print(status0)
