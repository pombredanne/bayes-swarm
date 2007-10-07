# PURPOSE : Extracting Data from prototype 0.2
# bayesfor
# DATE    : 07-10-07
# how to :
# 1) download http://kate.homeunix.net/~matteo/bayesfor/bayes-swarm_r-0.2.sql

# 2) run this mysql code to upload the sql database :

# drop database bayesfor ;
# create database bayesfor ;
# GRANT ALL ON bayesfor.* TO 'testuser'@'localhost' IDENTIFIED BY 'test' ;
# GRANT SELECT, INSERT ON bayesfor.* TO 'webuser'@'localhost' IDENTIFIED BY 'test' ;
# use bayesfor ;
# source bayes-swarm_r-0.2.sql ;

# 3) now you are ready to play with prototype.02
# 4) enjoy


library(RMySQL)
library(zoo)


velid <- 98
binid <- 99
rutid <- 114
berid <- 115
bosid <- 116
finid <- 117
casid <- 118
proid <- 111
aleid <- 112
letid <- 100
text <- paste( velid,binid,rutid,berid,bosid,finid,casid,proid,aleid,letid,sep=",")

mycon <- dbConnect(MySQL(), user='testuser', dbname="bayesfor", host="localhost", password="test")
query <- dbSendQuery(mycon, paste("SELECT a.id, c.name, avg(a.count) as num, date(a.scantime) as data
                                   FROM words a, int_words c, pages b
                                   WHERE a.id = c.id
                                     AND a.page_id = b.id
                                     AND a.id in (",text,")
                                   GROUP BY a.id, c.name, date(a.scantime);"))
data <- fetch(query, n = -1)

# use zoo class, so that we can easily deal with eventaul missing values and merge the two series
let= zoo(as.matrix(subset(data, id==letid, select=num)))#, as.matrix(subset(data, id==letid, select=data)))
pro= zoo(as.matrix(subset(data, id==proid, select=num)))#, as.matrix(subset(data, id==proid, select=data)))
ale= zoo(as.matrix(subset(data, id==aleid, select=num)))#, as.matrix(subset(data, id==aleid, select=data)))
vel= zoo(as.matrix(subset(data, id==velid, select=num)))#, as.matrix(subset(data, id==velid, select=data)))
bin= zoo(as.matrix(subset(data, id==binid, select=num)))#, as.matrix(subset(data, id==binid, select=data)))
rut= zoo(as.matrix(subset(data, id==rutid, select=num)))#, as.matrix(subset(data, id==rutid, select=data)))
ber= zoo(as.matrix(subset(data, id==berid, select=num)))#, as.matrix(subset(data, id==berid, select=data)))
bos= zoo(as.matrix(subset(data, id==bosid, select=num)))#, as.matrix(subset(data, id==bosid, select=data)))
fin= zoo(as.matrix(subset(data, id==finid, select=num)))#, as.matrix(subset(data, id==finid, select=data)))
cas= zoo(as.matrix(subset(data, id==casid, select=num)))#, as.matrix(subset(data, id==casid, select=data)))

date=zoo(as.matrix(subset(data, id==casid, select=data)))

# merge x and y so that we make sure we only deal with pillars with same date
m <- merge(ale,pro,vel, bin,rut,let,ber,bos,fin,cas, all = FALSE)

plot(m,type="b",lwd=2)
