source('stopwords.R')

library(RMySQL)
mycon <- dbConnect(MySQL(), user='testuser', dbname='martina',
                   host='localhost', password='test')
query <- dbSendQuery(mycon, paste("select date(scantime) as date, s.id as source_id, page_id, intword_id, count
                                   from words w, pages p, sources s 
                                   where w.page_id=p.id 
                                         and p.source_id = s.id 
                                         and w.intword_id in (3, 200, 67103, 1, 11238, 4323, 885, 62, 16114, 27, 5512, 13360, 25, 2831, 45, 24, 11106, 21, 69826, 65732, 69019, 65195, 4, 12600, 91, 5132, 49113, 42, 2376, 300, 66920, 65343, 9958, 71786, 65595, 2576, 65145, 321, 335, 336, 59208, 9302, 14659, 3579, 330, 51151, 18288, 8, 5248, 32532", stopwords_ids_list,")
                                         and date(scantime) between '2008-08-01' and '2008-11-30';"))

data <- fetch(query, n = -1)

query <- dbSendQuery(mycon, paste("select id, name
                                   from intwords
                                   where id in (3, 200, 67103, 1, 11238, 4323, 885, 62, 16114, 27, 5512, 13360, 25, 2831, 45, 24, 11106, 21, 69826, 65732, 69019, 65195, 4, 12600, 91, 5132, 49113, 42, 2376, 300, 66920, 65343, 9958, 71786, 65595, 2576, 65145, 321, 335, 336, 59208, 9302, 14659, 3579, 330, 51151, 18288, 8, 5248", stopwords_ids_list,");"))
intwords <- fetch(query, n = -1)

library(reshape)

melt_data <- melt(data, id=c("date", "source_id", "page_id", "intword_id"), measured=c(count))

save(melt_data, intwords, file="dati_martina_full.RData")

# esempi

# serie storica iraq su tutte le fonti
#cast(melt_data, date~variable, fun=sum, subset=intword_id==3)

# serie storica iraq su tutte le fonti, disaggregato per pagina
#cast(melt_data, date+page_id~variable, fun=sum, subset=intword_id==3)

# series storica iraq solo per la fonte 1
#cast(melt_data, date~variable, fun=sum, subset=intword_id==3&source_id==1)
