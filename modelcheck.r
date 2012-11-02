library(quantmod)
library(PerformanceAnalytics)
library(tawny)

#change working directory
setwd("F:/Works/QuantGlobal")

#rolling window size
wdsz <- 5
wdsz <- wdsz * 12

#read return and wts timesreis
returns <- read.csv("returns.csv", header = TRUE, stringsAsFactors=FALSE)
# _g for global, _i for international
ret_xts_g <- xts (returns[ , 2:dim(returns)[2]], 
                order.by = as.Date(as.character(returns$Date), 
                "%m/%d/%Y"))
ret_xts_i <- ret_xts_g
ret_xts_i$US =NULL

wts <- read.csv("wts.csv", header = TRUE, stringsAsFactors=FALSE)
wts_xts_g <- xts (wts[ , 2:dim(returns)[2]], 
                order.by = as.Date(as.character(wts$Date), 
                "%m/%d/%Y"))

wts_xts_i <- wts_xts_g
wts_xts_i$US =NULL

#create index 
idx_ret_xts_i <- cumprod(1 + ret_xts_i)
idx_ret_xts_g <- cumprod(1 + ret_xts_g)

#f <-periodReturn(e,period='yearly')

#rolling returns 
d <- rollapply(ret_xts_g, width = wdsz, FUN = function(x) {x - 1 } )