source("bayesfor_data_retrieve.r")

china_id <- 1
india_id <- 2

stems_data <- bayesfor_ts(c(1,2))

pdf(file="timeseries_chinaindia.pdf", width=4, height=4)
  par(cex.axis=1, cex.lab=1, mar=c(4.1, 3.1, 2.1, 2.1))
  plot(stems_data$china ~ stems_data$date, 
    main="time series", xlab="time", 
    ylab="average count on selected pages", yaxt = "n",
    mgp=c(2,1,0),
    type="l", lwd=3, col="blue")
  lines(stems_data$india ~ stems_data$date, lwd=3, col="green")
  legend("topright",c("china","india"), col=c("blue","green"),
    lty=1, lwd=3)
dev.off()

pdf(file="scatterplot_chinaindia.pdf", width=4, height=4)
  par(cex.axis=1, cex.lab=1, mar=c(4.1, 3.1, 2.1, 2.1))
  plot(stems_data$china ~ stems_data$india,
    main="scatter plot", xlab="china", 
    ylab="india", xaxt = "n", yaxt = "n",
    mgp=c(2,1,0))
  abline(lm(stems_data$india ~ stems_data$china), col="red")
dev.off()
