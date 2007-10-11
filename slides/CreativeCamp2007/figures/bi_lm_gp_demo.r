source("bayesfor_data_retrieve.r")

library(tgp)

india_id <- 2
russia_id <- 21

ir <- bayesfor_ts(c(india_id, russia_id), infile="some_data.Rdata")

pdf(file="bi_lm_gp.pdf", width=8, height=4)
  par(mfrow=c(1,2), cex.axis=1, cex.lab=1,
    mar=c(3.1, 3.1, 2.1, 2.1), mgp=c(1,1,0))
  plot(ir$russia ~ ir$india, xlim=c(2,15), ylim=c(2,15),
    main="least squares", xlab="india", ylab="russia",
    xaxt = "n", yaxt = "n")
  abline(lm(ir$russia ~ ir$india), xlim=c(2,15), ylim=c(2,15))

  ir.bgp <- bgp(X = ir$india, Z = ir$russia, m0r1 = TRUE, verb = 0)
  plot(ir.bgp, layout="surf", xlim=c(2,15), ylim=c(2,15), 
    main="gaussian process,", xlab="india", ylab="russia",
    xaxt = "n", yaxt = "n")
  #title(main="ciao")
dev.off()
