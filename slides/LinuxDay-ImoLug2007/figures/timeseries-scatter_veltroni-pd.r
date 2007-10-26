ts = read.csv("some_data_ita.csv", header=TRUE)
ts$date = as.Date(ts$date)

pdf(file="timeseries-scatter_veltroni-pd.pdf", width=8, height=4)
  par(mfrow=c(1,2), cex.axis=1, cex.lab=1, mar=c(4.1, 3.1, 2.1, 2.1))
  plot(veltroni ~ date, ts,
    main="", xlab="time",
    ylab="average count on selected pages", yaxt = "n",
    mgp=c(2,1,0), ylim=c(0,3),
    type="l", lwd=3, col="blue")
  lines(pd ~ date, ts, lwd=3, col="red")
  legend("topleft",c("veltroni","pd"), col=c("blue","red"),
    lty=1, lwd=3)
    
  plot(veltroni ~ pd, ts,
    mgp=c(2,1,0), 
    yaxt = "n", xaxt = "n")
  abline(lm(veltroni ~ pd, ts), col="red")
dev.off()
