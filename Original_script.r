library(ggplot2)
library(tidyverse)
library(lubridate)
library(magrittr)
library(boot)

tDataEx2 <- readRDS('data_ex2_20170101-20170110.rds')
tDataEx3 <- readRDS('data_ex3_20170704-20170710.rds')
tDataEx4 <- readRDS('data_ex4_20170711-20170713.rds')

# function to bootstrap-calc 95% CI and return as data frame (ready for dplyr)
fCalcBootstrapCI <- function(.tData) {
  b <- boot(.tData, function(.tDataSub, .i) sum(.tDataSub$bHelplineShown[.i])/sum(.tDataSub$bResultsReached[.i]), 1000)
  ci <- boot.ci(b, type='perc')
  return(data.frame(
    n = sum(.tData$bResultsReached),
    helpline = 100*sum(.tData$bHelplineShown)/sum(.tData$bResultsReached),
    ci_l = 100*ci$percent[4],
    ci_u = 100*ci$percent[5]
  ))
}


# study 1: comparison between Germany and the US
tDataEx2 %>% 
  group_by(eLocation) %>%
  summarise(n=n())

tDataEx2 %>%
  mutate(Group=factor(eType,
                      levels=c('helpful', 'harmful', 'unrelated'),
                      labels=c('helpful', 'harmful', 'unrelated'))) %>%
  group_by(eLocation, dDay, Group) %>%
  do(fCalcBootstrapCI(.)) %>%
  ggplot(aes(dDay, helpline, group=Group, linetype=Group, shape=Group, fill=Group, color=Group)) +
  geom_ribbon(aes(ymin=ci_l, ymax=ci_u), fill='grey90', color=NA) +
  geom_line(size=.7) +
  geom_point(size=3.3) +
  facet_grid(eLocation ~ .) +
  scale_x_date(date_labels='%m/%d', date_breaks='1 day', name=' \nDate') +
  scale_y_continuous(limits=c(0, 100), breaks=seq(0, 100, 10), name='Share of results displaying the suicide prevention result [%]\n ') +
  theme_bw() +
  theme(legend.position = 'bottom') +
  scale_colour_brewer(palette='Paired')
ggsave('ex2_percentage-over-time_countrywise.png', device='png', width=10)

# study 2: comparison across the globe (main language only)
tDataEx3 %>% nrow
tDataEx3 %>%
  group_by(dDay = as.Date(dCreate), eGroup) %>%
  do(fCalcBootstrapCI(.)) %>%
  ggplot(aes(dDay, helpline, color=eGroup)) +
    geom_line() +
    geom_point() +
    geom_ribbon(aes(ymin=ci_l, ymax=ci_u), alpha=.2, color=NA)

fCalcBootstrapCI(tDataEx3 %>% filter(eGroup == 'harmful'))
fCalcBootstrapCI(tDataEx3 %>% filter(eGroup == 'helpful'))

tDataEx3 %>%
  group_by(eCountry, eGroup) %>%
  do(fCalcBootstrapCI(.)) %>%
  arrange(eGroup, desc(relative)) %>%
  View

tDataEx3 %>%
  filter(eGroup != 'control') %>%
  group_by(eCountry, eGroup) %>%
  do(fCalcBootstrapCI(.)) %>%
  mutate(
    Group = factor(eGroup, 
                   levels=c('helpful', 'harmful'),
                   labels=c('helpful', 'harmful')),
    Country = factor(eCountry,
                     levels=c('China', 'Canada', 'India', 'South Korea', 'Brazil', 'Germany', 'Japan', 'USA', 'UK', 'Australia', 'Ireland'),
                     labels=c('Singapore\n(Mandarin)', 'Canada\n(English)', 'India\n(Hindi)', 'South Korea\n(Korean)', 'Brazil\n(Portuguese)', 'Germany\n(German)', 'Japan\n(Japanese)', 'USA\n(English)', 'UK\n(English)', 'Australia\n(English)', 'Ireland\n(English)'))
  ) %>%
  ggplot(aes(Country, helpline, fill=Group)) +
    geom_bar(stat='identity', position=position_dodge(), width=.80) + #geom_bar doppelt, um Reihenfolge festzusetzen
    geom_tile(aes(x='Ireland\n(English)',    y=11/2,   width=.98, height=11, fill='suicide rate per 100,000 inhabitants'), inherit.aes=F, show.legend=T) +
    geom_tile(aes(x='Australia\n(English)',  y=10.6/2, width=.98, height=10.6, fill='suicide rate per 100,000 inhabitants'), inherit.aes=F, show.legend=T) +
    geom_tile(aes(x='UK\n(English)',         y=6.2/2,  width=.98, height=6.2, fill='suicide rate per 100,000 inhabitants'), inherit.aes=F, show.legend=T) +
    geom_tile(aes(x='USA\n(English)',        y=12.1/2, width=.98, height=12.1, fill='suicide rate per 100,000 inhabitants'), inherit.aes=F, show.legend=T) +
    geom_tile(aes(x='Japan\n(Japanese)',     y=18.5/2, width=.98, height=18.5, fill='suicide rate per 100,000 inhabitants'), inherit.aes=F, show.legend=T) +
    geom_tile(aes(x='Germany\n(German)',     y=9.2/2,  width=.98, height=9.2, fill='suicide rate per 100,000 inhabitants'), inherit.aes=F, show.legend=T) +
    geom_tile(aes(x='Brazil\n(Portuguese)',  y=5.8/2,  width=.98, height=5.8, fill='suicide rate per 100,000 inhabitants'), inherit.aes=F, show.legend=T) +
    geom_tile(aes(x='South Korea\n(Korean)', y=28.9/2, width=.98, height=28.9, fill='suicide rate per 100,000 inhabitants'), inherit.aes=F, show.legend=T) +
    geom_tile(aes(x='India\n(Hindi)',        y=21.1/2, width=.98, height=21.1, fill='suicide rate per 100,000 inhabitants'), inherit.aes=F, show.legend=T) +
    geom_tile(aes(x='Canada\n(English)',     y=9.8/2,  width=.98, height=9.8, fill='suicide rate per 100,000 inhabitants'), inherit.aes=F, show.legend=T) +
    geom_tile(aes(x='Singapore\n(Mandarin)', y=7.4/2,  width=.98, height=7.4, fill='suicide rate per 100,000 inhabitants'), inherit.aes=F, show.legend=T) +
    geom_bar(stat='identity', position=position_dodge(), width=.80) +
    geom_errorbar(aes(ymin=ci_l, ymax=ci_u), width=.5, position=position_dodge(.9)) +
    scale_x_discrete() +
    scale_y_continuous(limits=c(0, 100), breaks=seq(0, 100, 10), name=' \nShare of results displaying the suicide prevention result [%]') +
    coord_flip() +
    theme_bw() +
    theme(legend.position = 'bottom') +
    #scale_fill_brewer(palette='Paired')
    scale_fill_manual(values=c('#1f78b4', '#a6cee3', 'grey80'))
  
ggsave('ex3_percentage-per-country-and-group.png', device='png', width=10)
  


# study 3: comparison within multi-lingual country (india, china)
tDataEx4 %>% nrow
tDataEx4 %>%
  group_by(eCountry, eLanguage, eGroup) %>%
  do(fCalcBootstrapCI(.)) %>%
  View

tDataEx4 %>%
  mutate(
    dDay = as.Date(dCreate),
    eCountry = factor(eCountry,
                      levels=c('China', 'India'),
                      labels=c('Singapore', 'India'))) %>%
  group_by(eCountry, eLanguage, eGroup, dDay) %>%
  do(fCalcBootstrapCI(.)) %>%
  mutate(
    Language = eLanguage,
    Group = factor(eGroup, 
                   levels=c('harmful', 'helpful', 'control'),
                   labels=c('harmful', 'helpful', 'unrelated'))
  ) %>%
  ggplot(aes(dDay, helpline, group=Language, linetype=Language, shape=Language, fill=Language, color=Language)) +
    geom_ribbon(aes(ymin=ci_l, ymax=ci_u), fill='grey90', color=NA) +
    geom_line(size=.7) +
    geom_point(size=3.3) +
    facet_grid(eCountry ~ Group) +
    scale_x_date(date_labels='%m/%d', date_breaks='1 day', name='Date') +
    scale_y_continuous(limits=c(0, 100), breaks=seq(0, 100, 10), name='Share of results displaying the suicide prevention result [%]\n ') +
    theme_bw() +
    theme(legend.position = 'bottom') +
    scale_colour_brewer(palette='Paired')
ggsave('ex4_percentage-over-time_languagewise.png', device='png', width=10)
