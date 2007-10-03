load("some_data.Rdata")

stem_id <- 8

stem_data <- matrix(subset(data, id==stem_id, select=num)[,1])
n <- dim(stem_data)[1]
attributes(stem_data)$colnames[1] = subset(data, id==stem_id, select=name)[1]

n <- length(stem_data)[1]
x <- 1:n

pdf(file="timeseries_bush.pdf", width=5, height=5)
  par(cex.axis=1, cex.lab=1, mar=c(3.1, 3.1, 2.1, 2.1))
  plot(stem_data ~ x, 
    main="", xlab="time", 
    ylab="average count on selected pages", xaxt = "n", yaxt = "n",
    mgp=c(1,1,0),
    type="l", lwd=3, col="violet")
dev.off()
