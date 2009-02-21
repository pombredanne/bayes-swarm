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

import gtk
from core import MMComponent, MMEsetFilter, stopwords
from .ui.search import MMResultSearch

class MMSearchComponent(MMComponent):
    is_mm_component = True
    name = "search"
    description = """Searchs for given terms and returns matching documents
together with the cloud of most frequent terms"""
    ui = MMResultSearch
    has_additional_actions = False
    
    def run(self, search_options, progressbar=None):
        logging.debug('Getting MSet')
        progressbar.set_text('0%')
        while gtk.events_pending():
            gtk.main_iteration()
        mset = search_options['enquire'].get_mset(0,
                                search_options['n_mset'],
                                0,
                                None,
                                #MMMatchDeciderAlwaysTrue(progressbar, 1/float(n_mset + n_eset)))
                                #MMMatchDeciderAlwaysTrue())
                                None)

        # Results
        docs = []
        rset = xapian.RSet()
        logging.debug('Getting RSet')
        progressbar.set_fraction(0.33)
        progressbar.set_text('33%')
        while gtk.events_pending():
            gtk.main_iteration()
        for y, m in enumerate(mset):
            if y < search_options['n_mset']:
                rset.add_document(m[xapian.MSET_DID])
            name = m[xapian.MSET_DOCUMENT].get_data()
            docs.append([m[xapian.MSET_PERCENT], name, m, ''])

        # Obtain the "Expansion set" for the search: the n most relevant terms that
        # match the filter
        logging.debug('Getting ESet')
        progressbar.set_fraction(0.66)
        progressbar.set_text('66%')
        while gtk.events_pending():
            gtk.main_iteration()
        eset = search_options['enquire'].get_eset(search_options['n_eset'], 
                                rset, 
                                #xapian.Enquire.INCLUDE_QUERY_TERMS, 
                                #1, 
                                #MMRsetFilter(stopwords[lang], [], progressbar, 1/float(n_mset + n_eset)))
                                MMEsetFilter(stopwords[search_options['selected_language']], search_options['eset_white_list']))
        
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

    def run_and_display(self, search_options, progressbar=None):
        progressbar.set_fraction(0.0)
        docs, tags = self.run(search_options, progressbar)
        self.display(docs, tags)
        progressbar.set_fraction(1.0)
        progressbar.set_text('Done')

    def clear_results(self):
        self.ui.clear()

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
