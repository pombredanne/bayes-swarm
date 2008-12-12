#!/usr/bin/xapian

# calculate distance between the provided term and the most frequent
# ones among those documents which are more relevant for term

import xapian

stopwords = {'it': ["ad", "al", "allo", "ai", "agli", "all", "agl", "alla", "alle", "con", "col", "coi", "da", "dal", "dallo", "dai", "dagli", "dall", "dagl", "dalla", "dalle", "di", "del", "dello", "dei", "degli", "dell", "degl", "della", "delle", "in", "nel", "nello", "nei", "negli", "nell", "negl", "nella", "nelle", "su", "sul", "sullo", "sui", "sugli", "sull", "sugl", "sulla", "sulle", "per", "tra", "contro", "io", "tu", "lui", "lei", "noi", "voi", "loro", "mio", "mia", "miei", "mie", "tuo", "tua", "tuoi", "tue", "suo", "sua", "suoi", "sue", "nostro", "nostra", "nostri", "nostre", "vostro", "vostra", "vostri", "vostre", "mi", "ti", "ci", "vi", "lo", "la", "li", "le", "gli", "ne", "il", "un", "uno", "una", "ma", "ed", "se", "perch\303\251", "anche", "come", "dov", "dove", "che", "chi", "cui", "non", "pi\303\271", "quale", "quanto", "quanti", "quanta", "quante", "quello", "quelli", "quella", "quelle", "questo", "questi", "questa", "queste", "si", "tutto", "tutti", "a", "c", "e", "i", "l", "o", "ho", "hai", "ha", "abbiamo", "avete", "hanno", "abbia", "abbiate", "abbiano", "avr\303\262", "avrai", "avr\303\240", "avremo", "avrete", "avranno", "avrei", "avresti", "avrebbe", "avremmo", "avreste", "avrebbero", "avevo", "avevi", "aveva", "avevamo", "avevate", "avevano", "ebbi", "avesti", "ebbe", "avemmo", "aveste", "ebbero", "avessi", "avesse", "avessimo", "avessero", "avendo", "avuto", "avuta", "avuti", "avute", "sono", "sei", "\303\250", "siamo", "siete", "sia", "siate", "siano", "sar\303\262", "sarai", "sar\303\240", "saremo", "sarete", "saranno", "sarei", "saresti", "sarebbe", "saremmo", "sareste", "sarebbero", "ero", "eri", "era", "eravamo", "eravate", "erano", "fui", "fosti", "fu", "fummo", "foste", "furono", "fossi", "fosse", "fossimo", "fossero", "essendo", "faccio", "fai", "facciamo", "fanno", "faccia", "facciate", "facciano", "far\303\262", "farai", "far\303\240", "faremo", "farete", "faranno", "farei", "faresti", "farebbe", "faremmo", "fareste", "farebbero", "facevo", "facevi", "faceva", "facevamo", "facevate", "facevano", "feci", "facesti", "fece", "facemmo", "faceste", "fecero", "facessi", "facesse", "facessimo", "facessero", "facendo", "sto", "stai", "sta", "stiamo", "stanno", "stia", "stiate", "stiano", "star\303\262", "starai", "star\303\240", "staremo", "starete", "staranno", "starei", "staresti", "starebbe", "staremmo", "stareste", "starebbero", "stavo", "stavi", "stava", "stavamo", "stavate", "stavano", "stetti", "stesti", "stette", "stemmo", "steste", "stettero", "stessi", "stesse", "stessimo", "stessero", "stando"], 'en': ["a", "about", "above", "after", "again", "against", "all", "am", "an", "and", "any", "are", "aren't", "as", "at", "be", "because", "been", "before", "being", "below", "between", "both", "but", "by", "cannot", "can't", "could", "couldn't", "did", "didn't", "do", "does", "doesn't", "doing", "don't", "down", "during", "each", "few", "for", "from", "further", "had", "hadn't", "has", "hasn't", "have", "haven't", "having", "he", "he'd", "he'll", "her", "here", "here's", "hers", "herself", "he's", "him", "himself", "his", "how", "how's", "i", "i'd", "if", "i'll", "i'm", "in", "into", "is", "isn't", "it", "its", "it's", "itself", "i've", "let's", "me", "more", "most", "mustn't", "my", "myself", "no", "nor", "not", "of", "off", "on", "once", "only", "or", "other", "ought", "our", "ours", "ourselves", "out", "over", "own", "same", "shan't", "she", "she'd", "she'll", "she's", "should", "shouldn't", "so", "some", "such", "than", "that", "that's", "the", "their", "theirs", "them", "themselves", "then", "there", "there's", "these", "they", "they'd", "they'll", "they're", "they've", "this", "those", "through", "to", "too", "under", "until", "up", "very", "was", "wasn't", "we", "we'd", "we'll", "were", "we're", "weren't", "we've", "what", "what's", "when", "when's", "where", "where's", "which", "while", "who", "whom", "who's", "why", "why's", "with", "won't", "would", "wouldn't", "you", "you'd", "you'll", "your", "you're", "yours", "yourself", "yourselves", "you've", "one", "every", "least", "less", "many", "now", "ever", "never", "say", "says", "said", "also", "get", "go", "goes", "just", "made", "make", "put", "see", "seen", "whether", "like", "well", "back", "even", "still", "way", "take", "since", "another", "however", "two", "three", "four", "five", "first", "second", "new", "old", "high", "long"]}

keywords = ['mccain', 'war', 'iraq', 'jobs', 'health'
  'afghanistan', 'poverty', 'security', 'hope', 'change', 'middle-class', 
  'care', 'people', 'terrorist', 'retirement', 'market', 'patriotism',
  'dignity', 'homes', 'wages', 'future', 'families', 'education']

term = "obama"
lang = "en"

db = xapian.Database("/home/matteo/Development/pagestore/us2008_xap")

stemmer = xapian.Stem(lang)

qp = xapian.QueryParser()
qp.set_stemmer(stemmer)
qp.set_database(db)
qp.set_stemming_strategy(xapian.QueryParser.STEM_SOME)

query1 = qp.parse_query(term, xapian.QueryParser.FLAG_BOOLEAN)
query2 = xapian.Query(xapian.Query.OP_VALUE_RANGE, 0, lang, lang)
query = xapian.Query(xapian.Query.OP_AND, query1, query2)

enquire = xapian.Enquire(db)
enquire.set_query(query)
n_docs = 1000
mset = enquire.get_mset(0, n_docs)

rset = xapian.RSet()
for y, m in enumerate(mset):
    rset.add_document(m[xapian.MSET_DID])

class Filter(xapian.ExpandDecider):
    def __init__(self, stopwords, excluded_terms, keywords=None):
        xapian.ExpandDecider.__init__(self)
        self.excluded_terms = excluded_terms
        self.stopwords = stopwords
        self.keywords = keywords
        
    def __call__(self, term):
        if keywords is None:
            return term[0].islower() and term not in self.excluded_terms and term not in self.stopwords and '_' not in term
        else:
            return term in self.keywords

eset = enquire.get_eset(50, rset, Filter(stopwords[lang], [term], keywords))

print "keyword, keyword2, distance, weight, weight2"
for ki, keyword in enumerate(eset):
    for oi, other in enumerate(eset):
        if ki < oi:
            distances = []
            for m in mset:
                docid = m[xapian.MSET_DID]
                try:
                    s1 = set(db.positionlist(docid, keyword.term))
                    s2 = set(db.positionlist(docid, other.term))
                    count = []
                    for i in s1:
                        for j in s2:
                            count.append(abs(i-j))
                    distances.append(min(count))
                except xapian.RangeError:
                    pass
            
            if distances != []:
                #print ",".join([keyword, other, "%f" % (sum(distances)/float(len(distances)))])
                print ",".join([keyword.term, other.term, "%f" % (sum(distances)/float(n_docs)), "%f" % keyword.weight, "%f" % other.weight])
                print ",".join([other.term, keyword.term, "%f" % (sum(distances)/float(n_docs)), "%f" % other.weight, "%f" % keyword.weight])
