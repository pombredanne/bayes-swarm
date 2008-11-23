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

from sgmlparser import MMBaseHTMLParser

if len(sys.argv) != 3:
    print >> sys.stderr, "Usage: %s PATH_TO_XAPIAN_DB PATH_TO_PAGESTORE" % sys.argv[0]
    sys.exit(1)
else:
    PATH_TO_XAPIAN_DB = sys.argv[1]
    PATH_TO_PAGESTORE = sys.argv[2]

def extract_date_from_path(dir):
    # convenience function for recursively splitting a path in order to
    # obtain a [y, m, d] list
    # dir = './2008/7/20/3f8727b909614b6dd20d67a888e16264'
    # dir = './2008/7/20/7de6d3247461164f8b09b6654afe38ed/a84f1bbf68b8287ab3974a56ae7b0184'
    splitted_dir = []
    while dir != '.':
        dir, dir2 = os.path.split(dir)
        splitted_dir.insert(0, dir2)
    return splitted_dir[:3]

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
            hash, url, id, kind, language = page
            if kind in ['url', 'rssitem']:
                date_list = extract_date_from_path(dir)
                
                doc = xapian.Document()
                doc.set_data(url)
                doc.add_value(0, language)
                doc.add_value(1, hash)
                doc.add_value(2, date_list[0])
                doc.add_value(3, date_list[1])
                doc.add_value(4, date_list[2])
                doc.add_value(5, dir)

                stemmer = xapian.Stem(language)
                indexer.set_stemmer(stemmer)
                indexer.set_document(doc)
                f = open(os.path.join(dir, hash, 'contents.html'))
                
                htmldoc = MMBaseHTMLParser()
                htmldoc.feed(f.read())
                f.close()
                htmldoc.close()
                
                indexer.index_text(htmldoc.text)

                # Add the document to the database.
                database.add_document(doc)
    #except StopIteration:
    except:
        print "Unexpected error:", sys.exc_info()[0]
        raise


# Open the database for update, creating a new database if necessary.
database = xapian.WritableDatabase(PATH_TO_XAPIAN_DB, xapian.DB_CREATE_OR_OVERWRITE)

os.chdir(PATH_TO_PAGESTORE)

nMETA = 0
print 'Counting META files..',
for dir, subfolder, files in os.walk("."):
    # index only META files of single html pages or single rss items
    if 'META' in files:
        #print files, subfolder
        nMETA += 1
        print '.',

i = 0
print '\nIndexing files..',
for dir, subfolder, files in os.walk('.'):
    if 'META' in files:
        xapian_index(database, dir)
        i += 1
        print "%2.1f" % (i/float(nMETA)*100),
