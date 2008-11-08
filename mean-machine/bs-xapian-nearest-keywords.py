#!/usr/bin/xapian

# calculate distance between the provided terms among the N first
# documents in the xapian db

import xapian

keywords = ['obama', 'mccain', 'war', 'iraq', 'jobs', 'health'
  'afghanistan', 'poverty', 'security', 'hope', 'change', 'middle-class', 
  'care', 'people', 'terrorist', 'retirement', 'market', 'patriotism',
  'dignity', 'homes', 'wages', 'future', 'families', 'education']

lang = "en"

db = xapian.Database("/home/matteo/Development/pagestore/agosto_xap")

query = xapian.Query(xapian.Query.OP_VALUE_RANGE, 0, lang, lang)

enquire = xapian.Enquire(db)
enquire.set_query(query)
size = 500
mset = enquire.get_mset(0, size)

print "keyword, keyword2, distance"
for ki, keyword in enumerate(keywords):
    for oi, other in enumerate(keywords):
        if ki < oi:
            distances = []
            for m in mset:
                docid = m[xapian.MSET_DID]
                try:
                    s1 = set(db.positionlist(docid, keyword))
                    s2 = set(db.positionlist(docid, other))
                    count = []
                    for i in s1:
                        for j in s2:
                            count.append(abs(i-j))
                    distances.append(min(count))
                except xapian.RangeError:
                    pass
            
            if distances != []:
                #print ",".join([keyword, other, "%f" % (sum(distances)/float(len(distances)))])
                print ",".join([keyword, other, "%f" % (sum(distances)/500.0)])
                print ",".join([other, keyword, "%f" % (sum(distances)/500.0)])
                
#for ki, keyword in enumerate(keywords):
#   print ",".join([keyword, keyword, "%f" % (max(distances))])
