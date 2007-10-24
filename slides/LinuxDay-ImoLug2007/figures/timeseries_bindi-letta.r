ts = read.csv("some_data_ita.csv", header=TRUE)
ts$date = as.Date(ts$date)

pdf(file="timeseries_bindi-letta.pdf", width=5, height=5)
  par(cex.axis=1, cex.lab=1, mar=c(4.1, 3.1, 2.1, 2.1))
  plot(bindi ~ date, ts,
    main="", xlab="time",
    ylab="average count on selected pages", yaxt = "n",
    mgp=c(2,1,0),
    type="l", lwd=3, col="violet")
  lines(ts$letta ~ ts$date, lwd=3, col="green")
  legend("topright",c("bindi","letta"), col=c("violet","green"),
    lty=1, lwd=3)

dev.off()
