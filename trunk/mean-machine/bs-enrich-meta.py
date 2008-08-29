#!/usr/bin/env python
# 
# Mean Machine: enrich pagestore META file
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

from storm.locals import *

if len(sys.argv) != 2:
    print >> sys.stderr, "Usage: %s PATH_TO_PAGESTORE" % sys.argv[0]
    sys.exit(1)
else:
    PATH_TO_PAGESTORE = sys.argv[1]

class Page(object):
    __storm_table__ = "pages"
    id = Int(primary=True)
    language_id = Int()
    kind_id = Int()
    url = Unicode()

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

database = create_database("mysql://testuser:test@localhost/bayesswarm022")
store = Store(database)

def enrich_meta(meta_file, rss_father_url=None):
    enriched_meta = []
    
    f = open(meta_file)
    for line in f:
        hash, url = line.split()
        if rss_father_url is not None: url = rss_father_url
        #print url
        page, lang, kind = store.find((Page, Language, Kind),
                                       Page.url == unicode(url),
                                       Page.language_id == Language.id,
                                       Page.kind_id == Kind.id).one()
        enriched_meta.append([hash, page.url, str(page.id), kind.kind, lang.name()])
        #print [page.url, page.id, kind.kind, lang.name()]
    f.close()
    
    f = open(meta_file, 'w')
    for enriched_line in enriched_meta:
        #print enriched_meta
        f.write(' '.join(enriched_line))
        f.write('\n')
    f.close()

def get_rss_father_url(hash, meta_file):
    f = open(meta_file)
    for line in f:
        lhash, url, id, kind, lang = line.split()
        if lhash == hash:
            return url
            f.close()
    f.close()

for dir, subfolder, files in os.walk(PATH_TO_PAGESTORE):    
    if 'META' in files:
        print "%s:: %s: %s" % (dir, subfolder, files)
        if 'contents.html' not in files:
            enrich_meta(os.path.join(dir, 'META'))
        else:
            updir, hash = os.path.split(dir)
            rss_father_url = get_rss_father_url(hash, os.path.join(updir, 'META'))
            enrich_meta(os.path.join(dir, 'META'), rss_father_url)
