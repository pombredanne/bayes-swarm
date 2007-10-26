ts = read.csv("some_data_ita.csv", header=TRUE)
ts$date = as.Date(ts$date)

norm_ts <- ts[,c(2,3,4)] / apply(ts[,c(2,3,4)], 1, sum, na.rm = TRUE)

pdf(file="pie_veltroni-bindi-letta.pdf", width=8, height=4)
  par(mfrow=c(1,2), cex.axis=1, cex.lab=1, mar=c(4.1, 3.1, 2.1, 2.1))

  ufficiali <- c(veltroni=75.81, bindi=12.88, letta=11.07, adinolfi=0.17, gawronski=0.07)
  pie(ufficiali, col=c("blue", "violet", "green", "grey", "salmon"),
    main="risultati ufficiali")

  stima <- apply(as.matrix(norm_ts), 2, mean, na.rm = TRUE)
  pie(stima, col=c("blue","violet","green"), main="stima bayes-swarm")
dev.off()
