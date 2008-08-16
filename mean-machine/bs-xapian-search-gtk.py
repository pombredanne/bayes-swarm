#!/usr/bin/env python
# 
# Mean Machine: gtk front end for querying xapian db
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

import gtk, gobject
import gnomevfs

if len(sys.argv) < 2:
    path = './bsdb'
    print >> sys.stderr, "Using default path: %s" % path
else:
    PATH_TO_XAPIAN_DB = sys.argv[1]
# Open the database for searching.
database = xapian.Database(PATH_TO_XAPIAN_DB)

def CreateQuery(input_terms, lang):
    if input_terms == None:
        # No text given: abort
        return
    
    qp = xapian.QueryParser()
    stemmer = xapian.Stem("english")
    qp.set_stemmer(stemmer)
    qp.set_database(database)
    qp.set_stemming_strategy(xapian.QueryParser.STEM_SOME)
    try:
        query1 = qp.parse_query(input_terms, xapian.QueryParser.FLAG_BOOLEAN)
    except xapian.QueryParserError:
        print 'Query parser error'
        return

    query2 = xapian.Query(xapian.Query.OP_VALUE_RANGE, 0, lang, lang)
    query = xapian.Query(xapian.Query.OP_AND, query1, query2)
    
    print "Parsed query is: %s" % query.get_description()
    terms = [term for pos, term in enumerate(query)]
    print "Terms: %s" % ', '.join(terms)
    return query

def EnquireDB(query):
    # Start an enquire session.
    enquire = xapian.Enquire(database)
    
    # Find the top 10 results for the query.
    enquire.set_query(query)
    # Retrieve as many results as we can show
    size = 100
    mset = enquire.get_mset(0, size - 1)

    # FIXME: add status bar
    # Header
    #self.win.addstr(0, 0, "%i results found." % mset.get_matches_estimated(), curses.A_BOLD)

    # Results
    result = []
    for y, m in enumerate(mset):
        name = m[xapian.MSET_DOCUMENT].get_data()
        
        # Print the match, together with the short description
        result.append([m[xapian.MSET_PERCENT], name, m, ''])
    return result

class Demo:
    query = None
    terms = None
    def __init__(self):
        w = gtk.Window()
        w.connect('destroy', lambda w: gtk.main_quit())

        self.model = gtk.ListStore(int, str, gobject.TYPE_PYOBJECT, str)

        scrolledwin = gtk.ScrolledWindow()
        scrolledwin.set_policy(gtk.POLICY_NEVER, gtk.POLICY_AUTOMATIC)

        treeview = gtk.TreeView()
        treeview.set_model(self.model)

        cell_pct = gtk.CellRendererText()
        column_pct = gtk.TreeViewColumn ("Percent", cell_pct, text=0)
        #column_pct.set_sort_column_id(0)
        treeview.append_column(column_pct)

        cell_name = gtk.CellRendererText()
        column_name = gtk.TreeViewColumn ("Name", cell_name, text=1)
        #column_name.set_sort_column_id(0)
        treeview.append_column(column_name)

        def get_celldata_date(column, cell, model, iter):
            doc = model[iter][2].document
            cell.set_property('text', doc.get_value(2))
        cell_date = gtk.CellRendererText()
        column_date = gtk.TreeViewColumn ("Date", cell_date)
        #column_summary.set_sort_column_id(0)
        column_date.set_cell_data_func(cell_date, get_celldata_date)
        treeview.append_column(column_date)

        treeview.set_size_request(-1, 300)
        treeview.connect('row-activated', self.on_row_activated)
        treeview.set_headers_clickable(True)
        treeview.set_reorderable(True)
        #treeview.set_property('has-tooltip', True)
        treeview.set_tooltip_column(3)
        treeview.connect('query-tooltip', self.on_query_tooltip)
        
        scrolledwin.add(treeview)
        vbox = gtk.VBox(False, 0)
        vbox.pack_start(scrolledwin, True, True, 0)

        self.entry = gtk.Entry()
        self.entry.connect('changed', self.on_entry_changed)
        
        combobox = gtk.combo_box_new_text()
        combobox.append_text('it')
        combobox.append_text('en')
        combobox.connect('changed', self.cb_lang_menu_select)
        combobox.set_active(0)

        self.selected_language = 'it'
        
        hbox = gtk.HBox(False, 0)
        hbox.pack_start(combobox, False, False, 0)
        hbox.pack_start(self.entry, True, True, 0)
        vbox.pack_start(hbox, False, False, 0)

        w.add(vbox)
        w.show_all()
        gtk.main()

    def refresh_results(self):
        query = CreateQuery(self.entry.get_text(), self.selected_language)
        if query is not None:
            res = EnquireDB(query)
            self.model.clear()
            for item in res:
                self.model.append(item)

    def on_entry_changed(self, widget, *args):
        self.refresh_results()

    def on_query_tooltip(self, widget, x, y, keyboard_mode, tooltip, *args):
        pass
        
    def on_row_activated(self, treeview, path, view_column):
        iter = treeview.get_model().get_iter(path)
        doc = treeview.get_model().get_value(iter, 2).document
        hash = doc.get_value(1)
        d = doc.get_value(2)
        # FIXME: user should specify PATH_TO_PAGESTORE
        path = os.path.join('.', '2008', '1', d, hash, 'contents.html')
        import webbrowser
        webbrowser.open(path)
    
    def cb_lang_menu_select(self, combobox):
        model = combobox.get_model()
        index = combobox.get_active()
        #if index:
        self.selected_language = model[index][0]
        self.refresh_results()

if __name__ == "__main__":
    demo = Demo()
