#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# calculate distance between the provided term and the most frequent
# ones among those documents which are more relevant for term

import xapian

import logging
logging = logging.getLogger('components.graph')

import gtk
from core import MMComponent, MMEsetFilter, stopwords
from ui.graph import MMResultGraph

class MMSearchComponent(MMComponent):
    is_mm_component = True
    name = "graph"
    description = """Graphs the net obtained by a set of documents where the 
given terms are most relevant"""
    ui = MMResultGraph

    has_additional_actions = True
    
    def run(self, search_options, progressbar=None):
        logging.debug('Getting MSet')
        progressbar.set_text('0%')
        while gtk.events_pending():
            gtk.main_iteration()
        mset = search_options['enquire'].get_mset(0,
            search_options['n_mset'],
            0,
            None,
            #MMMatchDeciderAlwaysTrue(progressbar, 1/float(self.n_mset + self.n_eset + self.n_eset*self.n_eset)))
            #MMMatchDeciderAlwaysTrue())
            None)

        logging.debug('Getting RSet')
        progressbar.set_fraction(0.25)
        progressbar.set_text('25%')
        while gtk.events_pending():
            gtk.main_iteration()
        rset = xapian.RSet()
        for y, m in enumerate(mset):
            rset.add_document(m.docid)

        logging.debug('Getting ESet')
        progressbar.set_fraction(0.5)
        progressbar.set_text('50%')
        while gtk.events_pending():
            gtk.main_iteration()
        eset = search_options['enquire'].get_eset(search_options['n_eset']+1, 
            rset, 
            search_options['eset_showqueryterms'], # 0 = exclude query terms in eset; 1 = include query terms in eset
            1, 
            MMEsetFilter(stopwords[search_options['selected_language']],
                search_options['eset_white_list']))

        logging.debug('Calculating distances on %i terms' % len(eset))
        progressbar.set_fraction(0.75)
        progressbar.set_text('75%')
        while gtk.events_pending():
            gtk.main_iteration()

        positions_matrix = {}
        for ki, keyword in enumerate(eset):
            positions_arrays = {}
            for m in mset:
                docid = m.docid
                try:
                    positions_array = set(search_options['db'].positionlist(docid, keyword.term))
                except xapian.RangeError:
                    positions_array = []
                positions_arrays[docid] = positions_array
            positions_matrix[ki] = positions_arrays

            if progressbar is not None: 
                fraction = progressbar.get_fraction() + 0.125/float(search_options['n_eset'])
                progressbar.set_fraction(fraction)
                progressbar.set_text('%.0f%%' % (fraction*100))
                while gtk.events_pending():
                    gtk.main_iteration()

        distances_list = []
        for ki, keyword in enumerate(eset):
            for oi, other in enumerate(eset):
                if ki < oi:
                    distances = []
                    for m in mset:
                        docid = m.docid
                        count = []
                        for i in positions_matrix[ki][docid]:
                            for j in positions_matrix[oi][docid]:
                                count.append(abs(i-j))
                        if count != []:
                            distances.append(min(count))

                    if distances != []:
                        #print ",".join([keyword, other, "%f" % (sum(distances)/float(len(distances)))])
                        
                        f = lambda x: 1/float(sum(x)/float(search_options['n_mset']))
                        
                        distances_list.append([keyword.term, 
                                               other.term, 
                                               f(distances), 
                                               keyword.weight,
                                               other.weight])
                        #distances_list.append([other.term, 
                        #                       keyword.term, 
                        #                       f(distances),
                        #                       other.weight,
                        #                       keyword.weight])
                if progressbar is not None:
                    fraction = progressbar.get_fraction() + 0.125/float(search_options['n_eset'] * search_options['n_eset'])
                    progressbar.set_fraction(fraction)
                    progressbar.set_text('%.0f%%' % (fraction*100))
                    while gtk.events_pending():
                        gtk.main_iteration()
                
        return distances_list
        
    def display(self, distances_list, terms):
        logging.debug('Display results')
        if distances_list != []:
            self.ui.display(distances_list, terms)

    def run_and_display(self, search_options, progressbar=None):
        progressbar.set_fraction(0.0)
        distances_list = self.run(search_options, progressbar)
        terms = [term for pos, term in enumerate(search_options['enquire'].get_query())]
        self.display(distances_list, terms)
        progressbar.set_fraction(1.0)
        progressbar.set_text('Done')

    def clear_results(self):
        self.ui.clear()

    def export_cb(self, action):
        self.ui.export()

    def set_additional_actions(self, actiongroup):
        actiongroup.add_actions([('ExportGraph%i' % self.id, 
                           gtk.STOCK_SAVE,
                           '_Export Graph', 
                           '<Control>e',
                           'Exports the current graph to file', 
                           self.export_cb)])
                           
    def set_uimanager_for_additional_actions(self, uimanager):
        ui = '''<ui>
<menubar name="MenuBar">
  <menu action="Components">
  </menu>
</menubar>
<toolbar name="Toolbar">
  <placeholder name="Common Actions">
    <toolitem action="%s"/>
  </placeholder>
  <placeholder name="Additional Actions">
    <toolitem action="%s"/>
  </placeholder>
</toolbar>
</ui>'''
        # FIXME: this is ugly, common actions should be added in mainwindow.py
        # when selecting the right tab
        return uimanager.add_ui_from_string(ui % ('ToggleAdvancedBox%i' % self.id,
                                                  'ExportGraph%i' % self.id))
