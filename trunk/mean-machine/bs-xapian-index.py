#!/usr/bin/env python
# 
# Mean Machine: index B4 pagestore in order to obtain a xapian db
#
# == Author
# Matteo Zandi [matteo.zandi@bayesfor.eu]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the Apache2 License.
# USA

import os
import sys
import xapian

from sgmlparser import BaseHTMLParser

if len(sys.argv) != 3:
    print >> sys.stderr, "Usage: %s PATH_TO_XAPIAN_DB PATH_TO_PAGESTORE" % sys.argv[0]
    sys.exit(1)
else:
    PATH_TO_XAPIAN_DB = sys.argv[1]
    PATH_TO_PAGESTORE = sys.argv[2]

def xapian_index(db, dir):
    indexer = xapian.TermGenerator()

    pages = []
    f = open(os.path.join(dir, 'META'))
    try:
        for line in f:
            pages.append(line.split())
    finally:
        f.close()

    try:
        for page in pages:
            # example: a792188bd1e8a2d91109197dff2a4009 http://news.google.com 1 url en
            print page
            hash, url, id, kind, language = page
            print id, url
            doc = xapian.Document()
            doc.set_data(url)
            doc.add_value(0, language)
            doc.add_value(1, hash)
            doc.add_value(2, '15')

            stemmer = xapian.Stem(language)
            indexer.set_stemmer(stemmer)
            indexer.set_document(doc)
            f = open(os.path.join(dir, hash, 'contents.html'))
            
            htmldoc = BaseHTMLParser()
            htmldoc.feed(f.read())
            f.close()
            htmldoc.close()
            
            indexer.index_text(htmldoc.text)

            # Add the document to the database.
            database.add_document(doc)
    #except StopIteration:
    except:
        pass

# Open the database for update, creating a new database if necessary.
database = xapian.WritableDatabase(PATH_TO_XAPIAN_DB, xapian.DB_CREATE_OR_OVERWRITE)

for dir, subfolder, files in os.walk(PATH_TO_PAGESTORE):
    print "%s:: %s: %s" % (dir, subfolder, files)
    if 'META' in files:
        xapian_index(database, dir)
