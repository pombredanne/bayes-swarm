#!/usr/bin/env python
#
# Mean Machine: index B4 pagestore in order to obtain a xapian db
#
# == Author
# Matteo Zandi [matteo.zandi@bayesfor.eu]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the GNU General Public License v2.
# USA

import os
import sys
import xapian

from sgmlparser import MMBaseHTMLParser

from storm.locals import *

class Page(object):
    __storm_table__ = "pages"
    id = Int(primary=True)
    language_id = Int()
    kind_id = Int()
    source_id = Int()
    url = Unicode()

class Source(object):
    __storm_table__ = 'sources'
    id = Int(primary=True)
    name = Unicode()

class Kind(object):
    __storm_table__ = "kinds"
    id = Int(primary=True)
    kind = Unicode()

class Language(object):
    __storm_table__ = "globalize_languages"
    id = Int(primary=True)
    iso_639_1 = Unicode()
    
    def name(self):
        return self.iso_639_1

mysql_db = create_database("mysql://testuser:test@localhost/renzi")
store = Store(mysql_db)

#source = store.find((Source), Source.id == 1).one()
#print source.id, source.name

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
    return '%.4d%.2d%.2d' % tuple(int(x) for x in splitted_dir[:3])

def xapian_index(db, dir):
    indexer = xapian.TermGenerator()

    pages = []
    f = open(os.path.join(dir, 'META'))
    # some url contain '\n', since split can be mangled, we use 'try'
    try:
        for line in f:
            pages.append(line.split())
    finally:
        f.close()

    for page in pages:
        # example: a792188bd1e8a2d91109197dff2a4009 http://news.google.com 1 url en
        hash, url, id, kind, language = page
        if kind in ['url', 'rssitem']:
            doc = xapian.Document()
            doc.set_data(url)
            doc.add_value(0, language)
            doc.add_value(1, hash)
            doc.add_value(2, extract_date_from_path(dir))
            doc.add_value(3, dir)
            source, page = store.find((Source, Page), Source.id == Page.source_id, Page.id == int(id)).one()
            doc.add_value(4, str(source.id))
            doc.add_value(5, source.name)

            stemmer = xapian.Stem(language)
            indexer.set_stemmer(stemmer)
            indexer.set_document(doc)
            f = open(os.path.join(dir, hash, 'contents.html'))

            htmldoc = MMBaseHTMLParser()
            htmldoc.feed(f.read())
            f.close()
            htmldoc.close()

            try:
                doc_text = htmldoc.text
                indexer.index_text(doc_text)
            except:
                print "Unexpected error:", sys.exc_info()[0]

            # Add the document to the database.
            database.add_document(doc)

# Open the database for update, creating a new database if necessary.
database = xapian.WritableDatabase(PATH_TO_XAPIAN_DB, xapian.DB_CREATE_OR_OVERWRITE)

os.chdir(PATH_TO_PAGESTORE)

nMETA = 0
print 'Counting META files..',
for dir, subfolder, files in os.walk("."):
    if 'META' in files:
        nMETA += 1
        print '.',

i = 0
print '\nIndexing files..',
for dir, subfolder, files in os.walk('.'):
    if 'META' in files:
        xapian_index(database, dir)
        i += 1
        print "%2.1f" % (i/float(nMETA)*100),
