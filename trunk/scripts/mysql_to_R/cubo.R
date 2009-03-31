source('stopwords.R')

library(RMySQL)
mycon <- dbConnect(MySQL(), user='testuser', dbname='martina',
                   host='localhost', password='test')
query <- dbSendQuery(mycon, paste("select date(scantime) as date, s.id as source_id, page_id, intword_id, count
                                   from words w, pages p, sources s 
                                   where w.page_id=p.id 
                                         and p.source_id = s.id 
                                         and w.intword_id in (65217, 24, 3, 67103, 5868, 885, 200, 62, 51712, 27, 21, 5132, 25, 1", stopwords_ids_list,")
                                         and date(scantime) between '2008-08-01' and '2008-11-30';"))
data <- fetch(query, n = -1)

query <- dbSendQuery(mycon, paste("select id, name
                                   from intwords
                                   where id in (65217, 24, 3, 67103, 5868, 885, 200, 62, 51712, 27, 21, 5132, 25, 1", stopwords_ids_list,");"))
intwords <- fetch(query, n = -1)

query <- dbSendQuery(mycon, "select date(scantime) as date, s.id as source_id, page_id, count(*) as count 
                             from words w, pages p, sources s 
                             where w.page_id=p.id and p.source_id = s.id 
                                   and date(scantime) between '2008-08-01' and '2008-11-30'
                             group by date(scantime), s.id, page_id;")
datanorm <- fetch(query, n = -1)

library(reshape)
melt_data <- melt(data, id=c("date", "source_id", "page_id", "intword_id"), measured=c(count))
melt_datanorm <- melt(datanorm, id=c("date", "source_id", "page_id"), measured=c(count))

save(melt_data, melt_datanorm, intwords, file="dati_martina_full.RData")

# esempi

# serie storica iraq su tutte le fonti
#cast(melt_data, date~variable, fun=sum, subset=intword_id==3)

# serie storica iraq su tutte le fonti, disaggregato per pagina
#cast(melt_data, date+page_id~variable, fun=sum, subset=intword_id==3)

# series storica iraq solo per la fonte 1
#cast(melt_data, date~variable, fun=sum, subset=intword_id==3&source_id==1)
