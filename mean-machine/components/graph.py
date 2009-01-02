#!/usr/bin/xapian

# calculate distance between the provided term and the most frequent
# ones among those documents which are more relevant for term

import xapian

import logging
format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
logging.basicConfig(level=logging.DEBUG, format=format)
logging = logging.getLogger('components.graph')

import gtk
from core import MMComponent, MMRsetFilter, MMMatchDeciderAlwaysTrue, stopwords
from .ui.graph import MMResultGraph

#keywords = ['mccain', 'war', 'iraq', 'jobs', 'health'
#  'afghanistan', 'poverty', 'security', 'hope', 'change', 'middle-class', 
#  'care', 'people', 'terrorist', 'retirement', 'market', 'patriotism',
#  'dignity', 'homes', 'wages', 'future', 'families', 'education']

class MMSearchComponent(MMComponent):
    is_mm_component = True
    name = "graph"
    description = """Graphs the net given by a set of documents where
                   the given term is most relevant"""
    
    ui = MMResultGraph
    
    def __init__(self, n_result_docs = 10, n_eset = 50):
        self.n_result_docs = n_result_docs
        self.n_eset = n_eset
    
    def run(self, enquire, lang, db, progressbar=None):
        logging.debug('Getting MSet')
        progressbar.set_text('Getting MSet')
        while gtk.events_pending():
            gtk.main_iteration()
        mset = enquire.get_mset(0,
                                self.n_result_docs,
                                0,
                                None,
                                #MMMatchDeciderAlwaysTrue(progressbar, 1/float(self.n_result_docs + self.n_eset + self.n_eset*self.n_eset)))
                                #MMMatchDeciderAlwaysTrue())
                                None)

        logging.debug('Getting RSet')
        progressbar.set_fraction(0.25)
        progressbar.set_text('Getting RSet')
        while gtk.events_pending():
            gtk.main_iteration()
        rset = xapian.RSet()
        for y, m in enumerate(mset):
            rset.add_document(m[xapian.MSET_DID])

        logging.debug('Getting ESet')
        progressbar.set_fraction(0.5)
        progressbar.set_text('Getting ESet')
        while gtk.events_pending():
            gtk.main_iteration()
        eset = enquire.get_eset(self.n_eset, 
                                rset, 
                                xapian.Enquire.INCLUDE_QUERY_TERMS, 
                                1, 
                                MMRsetFilter(stopwords[lang]))
                                #MMRsetFilter(stopwords[lang], [], progressbar, 1/float(self.n_result_docs + self.n_eset + self.n_eset*self.n_eset)))

        logging.debug('Calculating distances on %i terms' % len(eset))
        progressbar.set_fraction(0.75)
        progressbar.set_text('Calculating %i distances' % len(eset))
        while gtk.events_pending():
            gtk.main_iteration()

        positions_matrix = {}
        for ki, keyword in enumerate(eset):
            positions_arrays = {}
            for m in mset:
                docid = m[xapian.MSET_DID]
                try:
                    positions_array = set(db.positionlist(docid, keyword.term))
                except xapian.RangeError:
                    positions_array = []
                positions_arrays[docid] = positions_array
            positions_matrix[ki] = positions_arrays

            if progressbar is not None: 
                step = 0.25/float(self.n_eset)
                progressbar.set_fraction(progressbar.get_fraction() + step)
                while gtk.events_pending():
                    gtk.main_iteration()

        distances_list = []
        for ki, keyword in enumerate(eset):
            for oi, other in enumerate(eset):
                if ki < oi:
                    distances = []
                    for m in mset:
                        docid = m[xapian.MSET_DID]
                    #    try:
                        count = []
                        for i in positions_matrix[ki][docid]:
                            for j in positions_matrix[oi][docid]:
                                count.append(abs(i-j))
                        if count != []:
                            distances.append(min(count))
                    #    except KeyError:
                    #        pass

                    if distances != []:
                        #print ",".join([keyword, other, "%f" % (sum(distances)/float(len(distances)))])
                        
                        f = lambda x: sum(x)/float(self.n_result_docs)
                        #f = lambda x: sum(x)/float(len(x))
                        
                        distances_list.append([keyword.term, 
                                               other.term, 
                                               f(distances), 
                                               keyword.weight,
                                               other.weight])
                        distances_list.append([other.term, 
                                               keyword.term, 
                                               f(distances),
                                               other.weight,
                                               keyword.weight])
                    if progressbar is not None: 
                        step = 0.25/float(self.n_eset)
                        progressbar.set_fraction(progressbar.get_fraction() + step)
                        while gtk.events_pending():
                            gtk.main_iteration()
                
        return distances_list
        
    def display(self, distances_list):
        logging.debug('Display results')
        if distances_list != []:
            self.ui.display(distances_list)

    def run_and_display(self, enquire, lang, db, progressbar):
        progressbar.set_fraction(0.0)       
        distances_list = self.run(enquire, lang, db, progressbar)
        self.display(distances_list)
        progressbar.set_fraction(1.0)
        progressbar.set_text('Done')

    def clear_results(self):
        self.ui.clear()
