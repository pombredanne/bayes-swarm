ts = read.csv("some_data_ita.csv", header=TRUE)
ts$date = as.Date(ts$date)

pdf(file="ts-barplot_veltroni-bindi-letta.pdf", width=8, height=4)
  par(mfrow=c(1,2), cex.axis=1, cex.lab=1, mar=c(4.1, 3.1, 2.1, 2.1))

  plot(ts$veltroni ~ ts$date,
    main="", xlab="time",
    ylab="average count on selected pages", yaxt = "n",
    mgp=c(2,1,0),
    type="l", lwd=3, col="blue")
  lines(ts$bindi ~ ts$date,
    type="l", lwd=3, col="violet")
  lines(ts$letta ~ ts$date, 
    type="l", lwd=3, col="green")

  legend("topleft",c("veltroni","bindi","letta"), col=c("blue","violet","green"),
    lty=1, lwd=3)

  norm_ts <- ts[,c(2,3,4)] / apply(ts[,c(2,3,4)], 1, sum, na.rm = TRUE)
  rownames(norm_ts ) <- as.Date(ts$date)
  barplot(t(as.matrix(norm_ts)), col=c("blue","violet","green"),
    ylab="normalized count on selected pages", mgp=c(2,1,0))

  # apparizione media sul periodo
  # apply(as.matrix(norm_ts), 2, mean, na.rm = TRUE)
dev.off()