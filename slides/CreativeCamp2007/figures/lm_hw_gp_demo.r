# load some data, contains:
# 1 - china
# 2 - india
# 8 - bush
# 21 - russia
# 25 - korea
# 26 - japan
load("some_data.Rdata")

stem_id <- 8

# number of points to predict
ahead <- 10

stem_data = data.frame(count=subset(data, id==stem_id, select=num)[,1], 
 date=as.Date(subset(data, id==stem_id, select=data)[,1]))
n <- dim(stem_data)[1]
stem_data <- stem_data[20:n,]

n <- dim(stem_data)[1]
x <- 1:n

pdf(file="lm_hw_gp.pdf", width=9, height=3)
  par(mfrow=c(1,3), cex.axis=1, cex.lab=1,
    mar=c(4.1, 3.1, 2.1, 2.1), mgp=c(2,1,0))
  
  # least squares
  
  plot(count ~ date, stem_data, 
    xlim=c(stem_data$date[1],stem_data$date[n]+ahead), main="least squares",
    yaxt = "n", xlab="time", ylab="bush")
  abline(v=stem_data$date[n], col="darkgrey", lty="dashed")
  lines(count ~ date, stem_data)
  abline(lm(count ~ date, stem_data), col="red")

  # Holt Winters exponential smoothing
  
  plot(count ~ date, stem_data, 
    xlim=c(stem_data$date[1],stem_data$date[n]+ahead), main="exponential smoothing",
    yaxt = "n", xlab="time", ylab="bush")
  abline(v=stem_data$date[n], col="darkgrey", lty="dashed")
  lines(count ~ date, stem_data)
  # exponential smoothing with stagionality = 0
  stem_data.hw <- HoltWinters(stem_data$count, gamma=0)

  lines(stem_data.hw$fitted[,1] ~ stem_data$date[start(stem_data.hw$fitted)[1]:n],
    col="red")

  # find the index of last element in stem_data.hw
  last_xhw = end(stem_data.hw$fitted)[1]-start(stem_data.hw$fitted[,1])[1]+1
  # predict() only deals from last_xhw+1, let's create a ts
  # which begins at last_xhw so that we don't end up with a missing
  # line in the graph
  stem_data.hw_predict = ts(rbind(stem_data.hw$fitted[last_xhw], predict(stem_data.hw, n.ahead=ahead)),
    start = end(stem_data.hw$fitted)[1],
    end = end(stem_data.hw$fitted)[1] + ahead
    )
  lines(stem_data.hw_predict[,1] ~ seq.Date(stem_data$date[n],by="day", length.out=ahead+1),
    col="red", lty="dashed")

  # gaussian process

  library(tgp)
  stem_data.bgp <- bgp(X = stem_data$date,
    XX=stem_data$date[1]:stem_data$date[n]+ahead,
    Z = stem_data$count, verb = 0)
  plot(stem_data.bgp, layout = "surf",
    xlim=c(stem_data$date[1],stem_data$date[n]+ahead), main = "gaussian process, ",
    xaxt="n", yaxt = "n", xlab="time", ylab="bush")
  # for some reasons, plot.tgp doesn't like having dates on x axis
  Axis(side=1, seq.Date(stem_data$date[1],by="day", length.out=ahead+1))
  abline(v=stem_data$date[n], col="darkgrey", lty="dashed")
  lines(count ~ date, stem_data)
dev.off()
