load("some_data.Rdata")

china_id <- 1
india_id <- 2

china <- matrix(subset(data, id==china_id, select=num)[,1])
india <- matrix(subset(data, id==india_id, select=num)[,1])

n <- dim(china)[1]
x <- 1:n

pdf(file="timeseries_chinaindia.pdf", width=4, height=4)
  par(cex.axis=1, cex.lab=1, mar=c(3.1, 3.1, 2.1, 2.1))
  plot(china ~ x, 
    main="time series", xlab="time", 
    ylab="average count on selected pages", xaxt = "n", yaxt = "n",
    mgp=c(1,1,0),
    type="l", lwd=3, col="blue")
  lines(india, lwd=3, col="green")
  legend("topright",c("china","india"), col=c("blue","green"),
    lty=1, lwd=3)
dev.off()

pdf(file="scatterplot_chinaindia.pdf", width=4, height=4)
  par(cex.axis=1, cex.lab=1, mar=c(3.1, 3.1, 2.1, 2.1))
  plot(china, india,
    main="scatter plot", xlab="china", 
    ylab="india", xaxt = "n", yaxt = "n",
    mgp=c(1,1,0))
  abline(lm(india ~ china), col="red")
dev.off()
