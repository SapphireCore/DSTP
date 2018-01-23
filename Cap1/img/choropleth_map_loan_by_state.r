# Make loan amount and volume by state
# Output to C:/Users/Anna/Desktop/DSTP/Cap1/img

#install.packages("choroplethr")
#install.packages("choroplethrMaps")
#install.packages("tidyverse")
setwd("C:/Users/Anna/Desktop/DSTP/Cap1/img")

library(choroplethr)
library(choroplethrMaps)
library(tidyverse)

st <- read.csv("state_mapping.csv", header=TRUE)

amount <- read.csv("loan_by_state_amount.csv", header=TRUE) %>% 
          left_join(st, by=c("addr_state"="Abbreviation")) %>%
          select(State, funded_amnt) %>%
          mutate(State=tolower(State)) %>%
          rename(region=State, value=funded_amnt)

volume <- read.csv("loan_by_state_volume.csv", header=TRUE) %>%
          left_join(st, by=c("addr_state"="Abbreviation")) %>%
          select(State, funded_amnt) %>%
          mutate(State=tolower(State)) %>%
          rename(region=State, value=funded_amnt)


state_choropleth(amount, title="Total Loan Amount by State", legend="Amount[$]", num_colors=1)
state_choropleth(volume, title="Total Loan Volume by State", legend="Volume", num_colors=1)
