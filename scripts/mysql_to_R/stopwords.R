library(RMySQL)
mycon <- dbConnect(MySQL(), user='testuser', dbname='martina',
                   host='localhost', password='test')

find_id <- function(name) {
    query <- dbSendQuery(mycon, paste("select id
                                       from intwords
                                       where name='", name,"' and language_id=2600;", sep=''))

    data <- fetch(query, n = -1)
    data
}

# ita
#stopwords = c('ad', 'a', 'e', 'i', 'o', 'con', 'da', 'di', 'in', 'su', 'per', 'tra', 'è', 'sono', 'lo', 'la', 'li', 'le', 'gli', 'ne', 'il', 'un', 'uno', 'una', 'ed', 'se', 'perché', 'come', 'che', 'chi', 'cui', 'non', 'quale', 'quanto', 'quanti', 'quanta', 'quante', 'quello', 'quelli', 'quella', 'quelle', 'questo', 'questi', 'questa', 'queste', 'si', 'no', 'sono')

# end
stopwords =  c('a', 'did', 'her', 'do', 'him', 'after', 'his', 'down', 'to', 'for', 'and', 'from', 'are', 'get', 'up', 'as', 'go', 'man', 'see', 'us', 'at', 'she', 'very', 'was', 'be', 'some', 'because', 'we', 'if', 'went', 'but', 'in', 'not', 'that', 'of', 'the', 'what', 'is', 'off', 'their', 'when', 'came', 'it', 'on', 'them', 'will', 'can', 'had', 'one', 'then', 'with', 'could', 'have', 'there', 'would', 'he', 'out', 'they')

stopwords_ids = data.frame(NA)
count = 1
for (i in 1:length(stopwords)) {
    id = find_id(stopwords[i])
    
    if (dim(id)[1]!=0) {
        stopwords_ids[count,1] = stopwords[i]
        stopwords_ids[count,2] = id[1,1]
        count = count + 1
    }
}

colnames(stopwords_ids) = c('stopword', 'id')

stopwords_ids_list = ''
for (i in 1:dim(stopwords_ids)[1]) {
    stopwords_ids_list = paste(stopwords_ids_list, stopwords_ids[i,2], sep=', ')
}
