# TODO: Jim Liew's Stat Arb class HW1.1
# 
# Author: alain
###############################################################################
# load libraries
library(quantmod)
library(PerformanceAnalytics)
library(tawny)

# clean workspace
rm(list = ls())

# Make sure the working directory in R is the location of all the scritps
source("Constants.R")

# get all the datafiles
dataFiles <- system(paste("ls ", dataDirectory), intern = TRUE)

# empty xts data object
prices <- xts()
# Read all the data in
for (file in dataFiles){
    filePath <- paste(dataDirectory, file, sep = "/")
    symbol <- unlist(strsplit(file, split = "\\."))[1]
    mktData <- read.csv(filePath, header = FALSE, stringsAsFactors=FALSE)
    colnames(mktData) <- dataHeader
    #convert to zoo object
    mkt_zoo <- zoo(mktData[ , 2:dim(mktData)[2]], order.by=as.Date(as.character(mktData$YYYYMMDD), "%Y%m%d"))
    # convert to xts object but only use Close
    mkt_xts <- xts(mkt_zoo)[, "Close"]
    # Rename the close price with the symbol
    colnames(mkt_xts) <- c(symbol)
    # add a new column to the dataset
    prices <- cbind(prices, mkt_xts[2:anylength(mkt_xts)])
}
# store the number of assets in my data set
totalAssets <- dim(prices)[2]

# filled forward
filled <- na.locf(prices)
# Write prices out
write.csv(as.data.frame(filled), file = "prices.csv")
# calculate the returns
returns_xts <- Return.calculate(filled, method="simple")[-1, ]
# Set any NA to zero if there is one
returns_xts[is.na(returns_xts)] <- 0

totalReturns <- dim(prices)[1]
# graph the cumulative returns (need to perfect the graph)
jpeg(file="CumulativeReturns.jpg", width = 1280, height = 1024)
chart.CumReturns(returns_xts, legend.loc = "topleft", main = "Cumulative Returns")
dev.off()

# get the latest 3000 observations
ret3000 <- returns_xts[(totalReturns - 3000):totalReturns, ]

# work with 3000 observations 
totalReturns<- 3000
# portfolio of equal weights = 1/40 or 1 / number of assets
portfEW <- rep(1/totalAssets, totalAssets)
# Calculate portfolio returns for the equal weighted portfolio
portfEWreturns <- Return.portfolio(ret3000, weights = portfEW)
# graph the cumulative returns for the equal weighted portfolio
jpeg(file="EW_PortfolioCumulativeReturs.jpg", width = 1280, height = 1024)
chart.CumReturns(portfEWreturns, legend.loc = "topleft", main = "Equal Weighted Portfolio Cumulative Returns")
dev.off()

# 60 day standard deviations over each TS
stdDevs <- rollapply(ret3000, width = 60, FUN = "sd")
# Equal-Risk-Weighted portfolio of weights = sigma(i) / sum(sigma(i))
portfERW <- apply(stdDevs, 1, FUN = function(x) { x / sum(x)})
# Calculate portfolio returns for the Equal-Risk-Weighted portfolio
portfERWreturns <- Return.rebalancing(ret3000, weights = portfERW)
# graph the cumulative returns for the equal risk weighted portfolio
jpeg(file="ERW_PortfolioCumulativeReturs.jpg", width = 1280, height = 1024)
chart.CumReturns(portfERWreturns, legend.loc = "topleft", main = "Equal Risk Weighted Portfolio Cumulative Returns")
dev.off()

#####