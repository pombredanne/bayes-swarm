load("some_data.Rdata")

stem_id <- 8

stem_data = data.frame(count=subset(data, id==stem_id, select=num)[,1], 
 date=as.Date(subset(data, id==stem_id, select=data)[,1]))

pdf(file="timeseries_bush.pdf", width=5, height=5)
  par(cex.axis=1, cex.lab=1, mar=c(4.1, 3.1, 2.1, 2.1))
  plot(count ~ date, stem_data,
    main="", xlab="time",
    ylab="average count on selected pages", yaxt = "n",
    mgp=c(2,1,0),
    type="l", lwd=3, col="violet")
dev.off()
