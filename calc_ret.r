setwd("/home/nick/model_check/currencies")

library(quantmod)
library(PerformanceAnalytics)
library(tawny)

index_1999 <- read.csv("currency_1999.csv", header = TRUE, stringsAsFactors=FALSE)

idx_1999_xts <- xts (index_1999[ , 2:dim(index_1999)[2]], 
                order.by = as.Date(as.character(index_1999$Date), 
                "%m/%d/%Y"))

ret_1999_xts <- Return.calculate(idx_1999_xts, method="compound")
write.zoo(ret_1999_xts, file= "ret_1999.csv", sep=",")

index_1986 <- read.csv("currency_1986.csv", header = TRUE, stringsAsFactors=FALSE)

idx_1986_xts <- xts (index_1986[ , 2:dim(index_1986)[2]], 
                order.by = as.Date(as.character(index_1986$Date), 
                "%m/%d/%Y"))

ret_1986_xts <- Return.calculate(idx_1986_xts, method="compound")
write.zoo(ret_1986_xts, file= "ret_1986.csv", sep=",")