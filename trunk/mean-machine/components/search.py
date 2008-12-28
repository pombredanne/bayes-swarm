#!/usr/bin/python
# -*- coding: UTF-8 -*-

# Licensed under the Apache2 License.

__copyright__ = 'BayesFor Association'
__author__    = 'Matteo Zandi <matteo.zandi@bayesfor.eu>'

import os
import sys
import xapian

import logging
format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
logging.basicConfig(level=logging.DEBUG, format=format)
logging = logging.getLogger('components.search')

from core import MMComponent, MMRsetFilter, MMMatchDeciderAlwaysTrue, stopwords
from .ui.uis import MMResultSearch

class MMSearchComponent(MMComponent):
    is_mm_component = True
    name = "search"
    description = """Searchs for given terms and returns matching documents
                   together with the cloud of most frequent terms"""
    
    ui = MMResultSearch
    
    def __init__(self, n_result_docs = 100, n_result_cloud = 50):
        self.n_result_docs = n_result_docs
        self.n_result_cloud = n_result_cloud
    
    def run(self, enquire, lang, db, progressbar):
        logging.debug('Getting MSet')
        mset = enquire.get_mset(0,
                                self.n_result_docs,
                                0,
                                None,
                                MMMatchDeciderAlwaysTrue(progressbar, 1/float(self.n_result_docs + self.n_result_cloud)))
                                #MMMatchDeciderAlwaysTrue())

        # Results
        docs = []
        rset = xapian.RSet()
        logging.debug('Getting RSet')
        for y, m in enumerate(mset):
            if y < self.n_result_docs:
                rset.add_document(m[xapian.MSET_DID])
            name = m[xapian.MSET_DOCUMENT].get_data()
            docs.append([m[xapian.MSET_PERCENT], name, m, ''])

        # Obtain the "Expansion set" for the search: the n most relevant terms that
        # match the filter
        logging.debug('Getting ESet')
        eset = enquire.get_eset(self.n_result_cloud, 
                                rset, 
                                #xapian.Enquire.INCLUDE_QUERY_TERMS, 
                                #1, 
                                MMRsetFilter(stopwords[lang], [], progressbar, 1/float(self.n_result_docs + self.n_result_cloud)))
                                #MMRsetFilter(stopwords[lang], []))
        
        # Read the "Expansion set" and scan tags and their score
        tagscores = dict()
        for item in eset:
            tag = item.term
            tagscores[tag] = item.weight

        tags = []
        if tagscores != dict():
            maxscore = max(tagscores.itervalues())
            minscore = min(tagscores.itervalues())
            for k in tagscores.iterkeys():
                tags.append([k, (tagscores[k] - minscore) * 100 / (maxscore - minscore) * 3 + 75])
            # sort by tag alphabetically
            tags.sort()

        return docs, tags

    def display(self, docs, tags):
        logging.debug('Display results')
        self.ui.display(docs, tags)        

    def run_and_display(self, enquire, lang, db, progressbar=None):
        progressbar.set_fraction(0.0)
        docs, tags = self.run(enquire, lang, db, progressbar)
        self.display(docs, tags)
        progressbar.set_fraction(1.0)

if __name__ == "__main__":
    s = MMSearchComponent()
    
    term = "Matteo AND Renzi"
    lang = "it"

    stemmer = xapian.Stem(lang)

    db = xapian.Database("/home/matteo/Development/pagestore/renzi_xap_20081220")

    qp = xapian.QueryParser()
    qp.set_stemmer(stemmer)
    qp.set_database(db)
    qp.set_stemming_strategy(xapian.QueryParser.STEM_SOME)

    query1 = qp.parse_query(term, xapian.QueryParser.FLAG_BOOLEAN)
    query2 = xapian.Query(xapian.Query.OP_VALUE_RANGE, 0, lang, lang)
    query = xapian.Query(xapian.Query.OP_AND, query1, query2)
    
    enquire = xapian.Enquire(db)
    enquire.set_query(query)
    
    docs, tags = s.run(enquire)

    for d in docs:
        print d

    for t, s in tags:
        print t, s
