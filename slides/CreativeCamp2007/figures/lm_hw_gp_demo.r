bayesfor_hw <- function(x, n_ahead=10)  {
  n = length(x)

  plot(x, xlim=c(0, n + n_ahead), main="exponential smoothing",
    xaxt = "n", yaxt = "n", xlab="time", ylab="bush")
  abline(v=n, col="darkgrey", lty="dashed")
  lines(1:n, x)
  # exponential smoothing with stagionality = 0
  x.hw <- HoltWinters(ts(data.matrix(x)), gamma=0)

  lines(x.hw$fitted[,1], col="red")

  # find the index of last element in x.hw
  last_xhw = end(x.hw$fitted)[1]-start(x.hw$fitted[,1])[1]+1
  # predict() only deals from last_xhw+1, let's create a ts
  # which begins at last_xhw so that we don't end up with a missing
  # line in the graph
  x.hw_predict = ts(rbind(x.hw$fitted[last_xhw], predict(x.hw, n.ahead=n_ahead)),
    start = end(x.hw$fitted)[1],
    end = end(x.hw$fitted)[1] + n_ahead
    )
  lines(x.hw_predict, col="red", lty="dashed")
}

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

#
# linear model
#

stem_data <- matrix(subset(data, id==stem_id, select=num)[,1])
n <- dim(stem_data)[1]
stem_data <- stem_data[20:n]
attributes(stem_data)$colnames[1] = subset(data, id==stem_id, select=name)[1]

n <- length(stem_data)[1]
x <- 1:n

pdf(file="lm_hw_gp.pdf", width=9, height=3)
  par(mfrow=c(1,3), cex.axis=1, cex.lab=1,
    mar=c(3.1, 3.1, 2.1, 2.1), mgp=c(1,1,0))
  plot(stem_data ~ x, xlim=c(0,n+ahead), main="least squares",
    xaxt = "n", yaxt = "n", xlab="time", ylab="bush")
  abline(v=n, col="darkgrey", lty="dashed")
  lines(x, stem_data)
  abline(lm(stem_data ~ x), col="red")

  # Holt Winters
  bayesfor_hw(stem_data, ahead)

  # gaussian process

  library(tgp)
  stem_data.bgp <- bgp(X = x, XX=1:n+ahead, Z = stem_data, verb = 0)
  plot(stem_data.bgp, xlim=c(0,n+ahead), main = "gaussian process, ", layout = "surf",
    xaxt = "n", yaxt = "n", xlab="time", ylab="bush")
  abline(v=n, col="darkgrey", lty="dashed")
  lines(x, stem_data)
dev.off()
