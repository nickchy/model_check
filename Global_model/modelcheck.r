library(quantmod)
library(PerformanceAnalytics)
library(tawny)

#change working directory
setwd("/home/nick/model_check")

#clear variables
rm(list = ls())

#read return and wts timesreis
returns <- read.csv("returns.csv", header = TRUE, stringsAsFactors=FALSE)
# _g for global, _i for international
ret_xts_g <- xts (returns[ , 2:dim(returns)[2]], 
                order.by = as.Date(as.character(returns$Date), 
                "%m/%d/%Y"))
ret_xts_i <- ret_xts_g
ret_xts_i$US =NULL

wts <- read.csv("wts.csv", header = TRUE, stringsAsFactors=FALSE)
wts_xts_g <- xts (wts[ , 2:dim(wts)[2]], 
                order.by = as.Date(as.character(wts$Date), 
                "%m/%d/%Y"))

wts_xts_i <- wts_xts_g
wts_xts_i$US =NULL

#benchmark
bm<- read.csv("benchmark.csv", header = TRUE, stringsAsFactors=FALSE)
bm_xts <- xts (bm[ , 2:3], 
			order.by = as.Date(as.character(bm[,1]),
			 "%m/%d/%Y"))

# FUNCTION used to calculate cross sectional std
rowsd <- function(xtsobj)
{
	rollsd <- rep(0, dim(xtsobj)[1] )

	for (i in 1 : dim(xtsobj)[1])
	{
		rollsd[i] <- sd(as.vector(xtsobj[i, ] ) )
	}
	rollsd
}

# FUNCTION used to calculate adjust weights
wtsadj <- function(xtsobj)
{
	wtsadj <-mat.or.vec(dim(xtsobj)[1],dim(xtsobj)[2])
	for (i in 1: dim(xtsobj)[1])
	{
		for (j in 1: dim(xtsobj)[2])
		{
			if (xtsobj[i,j] <= -1.5)
			{
				wtsadj[i,j] = -0.1
			}
			else if(xtsobj[i,j] <= -1) 
			{
				wtsadj[i,j] = -0.075
			}
			else if(xtsobj[i,j] <= -0.5) 
			{
				wtsadj[i,j] = -0.05
			}
			else if(xtsobj[i,j] <= 0.5) 
			{
				wtsadj[i,j] = 0
			}
			else if(xtsobj[i,j] <= 1) 
			{
				wtsadj[i,j] = 0.05
			}			
			else if(xtsobj[i,j] <= 1.5) 
			{
				wtsadj[i,j] = 0.075
			}
			else
			{
				wtsadj[i,j] = 0.1
			}
		}
	}
	wtsadj
}

get_wtd_adj_ret <-function (ret_xts_i,ret_xts_g, bm_xts, yrwd) {
#rolling window size
wdsz <- yrwd * 12

#f <-periodReturn(e,period='yearly')

#rolling cumulative returns 
roll_ret_xts_i <- rollapply(ret_xts_i, width = wdsz, FUN = function(x) {cumprod(1 +x)[wdsz, ] } )
roll_ret_xts_g <- rollapply(ret_xts_g, width = wdsz, FUN = function(x) {cumprod(1 +x)[wdsz, ] } )
#write.zoo(d, file = "demo1.csv", sep=",")

#rolling avg
mean_ret_g <- rowMeans(roll_ret_xts_g)
mean_ret_i <- rowMeans(roll_ret_xts_i)
#rolling std
std_ret_xts_i <- rowsd(roll_ret_xts_i)
std_ret_xts_g <- rowsd(roll_ret_xts_g)

#rolling z-score
z_ret_g <- (roll_ret_xts_g - mean_ret_g) / std_ret_xts_g
z_ret_i <- (roll_ret_xts_i - mean_ret_i) / std_ret_xts_i

#adjusted weights
##wts change
adjwts_g<-wtsadj(z_ret_g)
adjwts_i<-wtsadj(z_ret_i)
## pue adj wts
adjwts_xts_g <- wts_xts_g[wdsz:dim(wts_xts_g)[1], ] + adjwts_g
adjwts_xts_i <- wts_xts_i[wdsz:dim(wts_xts_i)[1], ] + adjwts_i
## no less than zero
adjwts_xts_g <- pmax(as.matrix(adjwts_xts_g),0)
adjwts_xts_i <- pmax(as.matrix(adjwts_xts_i),0)
## rescale to 100% in total
adjwts_xts_g <- t(apply(adjwts_xts_g,1, FUN=function(x) {x / as.double(sum(x))}))
adjwts_xts_i <- t(apply(adjwts_xts_i,1, FUN=function(x) {x / as.double(sum(x))}))

#wtd return
wtd_ret_xts_g <- ret_xts_g[wdsz:dim(wts_xts_g)[1], ] * adjwts_xts_g
wtd_ret_xts_i <- ret_xts_i[wdsz:dim(wts_xts_i)[1], ] * adjwts_xts_i

#total model return
model_ret_g <- rowSums(wtd_ret_xts_g)
model_ret_i <- rowSums(wtd_ret_xts_i)

#create index 
idx_ret_xts_g <- xts(cumprod(1 + model_ret_g),order.by = index(wtd_ret_xts_g))
idx_ret_xts_i <- xts(cumprod(1 + model_ret_i),order.by = index(wtd_ret_xts_i))
colnames(idx_ret_xts_g)<- 'Global'
colnames(idx_ret_xts_i)<-'International'

#convert to annual return
model_ann_ret_g <- periodReturn(idx_ret_xts_g,period='yearly')
model_ann_ret_i <- periodReturn(idx_ret_xts_i,period='yearly')

model_ann_ret_g <-merge(model_ann_ret_g,bm_xts$'Global')
colnames(model_ann_ret_g) <- c('global_return','benchmark')
active_ann_ret_g <- model_ann_ret_g$'global_return'- model_ann_ret_g$'benchmark'
IR_g <- format(SharpeRatio.annualized(active_ann_ret_g, 
			Rf = 0, scale = 1, geometric=FALSE), 3)

model_ann_ret_i <- merge(model_ann_ret_i,bm_xts$'Inter')
colnames(model_ann_ret_i) <- c('inter_return','benchmark')
active_ann_ret_i <- (model_ann_ret_i$'inter_return'- model_ann_ret_g$'benchmark')

IR_i <- format(SharpeRatio.annualized(active_ann_ret_i, 
			Rf = 0, scale = 1, geometric=FALSE), 3)
#plot
#X11(width=12,height=8);
jpeg(file=paste(wdsz/12, "Yr_Global.jpg", sep = "_"), width = 1280, height = 1024)
barplot(active_ann_ret_g, yaxp = c(-0.3,0.7,10), cex.axis=0.7, 
		las =2, col = 'blue', names.arg=format(index(active_ann_ret_g), "%Y"))
legend('topright',legend = paste("IR: ",IR_g, sep= ""),lty = 1:2, cex = 1, text.col = "red")
title('Global_Model_Active_Return')

dev.off()

#X11(width=12,height=8);
jpeg(file=paste(wdsz/12, "Yr_International.jpg", sep = "_"), width = 1280, height = 1024)
barplot(active_ann_ret_i, yaxp = c(-0.3,0.7,10), cex.axis=0.7, 
		las =2, col = 'blue', names.arg=format(index(active_ann_ret_i), "%Y"))
legend('topright',legend = paste("IR: ",IR_i, sep= ""),cex = 1, text.col = "red")
title('International_Model_Active_Return')

dev.off();

write.zoo(merge(active_ann_ret_g,active_ann_ret_i),file= paste(wdsz/12, "Yr_ret_data.csv", sep = "_"), sep= ",")
}

for (i in c(1,3,5) ) 
{
	get_wtd_adj_ret(ret_xts_i,ret_xts_g, bm_xts, i)
}


