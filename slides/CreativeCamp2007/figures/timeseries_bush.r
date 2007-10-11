source("bayesfor_data_retrieve.r")

stem_id <- 8

stem_data <- bayesfor_ts(stem_id, infile="some_data.Rdata")

pdf(file="timeseries_bush.pdf", width=5, height=5)
  par(cex.axis=1, cex.lab=1, mar=c(4.1, 3.1, 2.1, 2.1))
  plot(bush ~ date, stem_data,
    main="", xlab="time",
    ylab="average count on selected pages", yaxt = "n",
    mgp=c(2,1,0),
    type="l", lwd=3, col="violet")
dev.off()
