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
import gtkhtml2

if len(sys.argv) == 3:
    PATH_TO_XAPIAN_DB = sys.argv[1]
    PATH_TO_PAGESTORE = sys.argv[2]
elif len(sys.argv) == 2:
    PATH_TO_XAPIAN_DB = sys.argv[1]
else:
    print >> sys.stderr, "Usage: %s PATH_TO_XAPIAN_DB [PATH_TO_PAGESTORE]" % sys.argv[0]
    sys.exit(1)

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

    def strip_leading_caps(string):
        result = string
        while result[0].isupper():
            result = result[1:]
        return result

    terms = [strip_leading_caps(term) for term in query]
    # Results
    docs = []
    rset = xapian.RSet()
    for y, m in enumerate(mset):
        rset.add_document(m[xapian.MSET_DID])
        name = m[xapian.MSET_DOCUMENT].get_data()
        docs.append([m[xapian.MSET_PERCENT], name, m, ''])

    class Filter(xapian.ExpandDecider):
        def __call__(self, term):
            #return (term[0].islower() or term[:2] == "XT") and term not in STOPWORDS
            return term[0].islower()

    # This is the "Expansion set" for the search: the 50 most relevant terms that
    # match the filter
    eset = enquire.get_eset(50, rset, Filter())
    
    # Get the first 100 documents and scan their tags
    tagscores = dict()
    for item in eset:
        relevance = item.weight
        tag = item.term
        
        # FIXME: check also if tag is a stopword
        if tag in terms:
            continue
        else:
            tagscores[tag] = relevance

    tags = []
    if tagscores != dict():
        maxscore = max(tagscores.itervalues())
        for k in tagscores.iterkeys():
            tags.append((tagscores[k] * 100 / maxscore, k))

    return docs, tags

def mark_text_up(result_list):
    # 0-100 score, key (facet::tag), description
    document = gtkhtml2.Document()
    document.clear()
    document.open_stream("text/html")
    document.write_stream("""<html><head>
<style type="text/css">
a { text-decoration: none; color: black; }
</style>
</head><body>""")
    for score, tag in result_list:
        document.write_stream('<a href="%s" style="font-size: %d%%">%s</a> ' % (tag, 30+score*3, tag))
        #print '<a href="%s" style="font-size: %d%%">%s</a> ' % (tag, score*3, desc)
    document.write_stream("</body></html>")
    document.close_stream()
    return document   

class Demo:
    query = None
    terms = None
    def __init__(self):
        w = gtk.Window()
        w.connect('destroy', gtk.main_quit)

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
        vpaned = gtk.VPaned()
        vpaned.add(scrolledwin)

        scrolledwin2 = gtk.ScrolledWindow()
        scrolledwin2.set_policy(gtk.POLICY_NEVER, gtk.POLICY_AUTOMATIC)

        document = gtkhtml2.Document()
        document.clear()
        document.open_stream("text/html")
        document.write_stream("<html><body>Welcome, enter some text to start searching!</body></html>")
        document.close_stream()
        self.view = gtkhtml2.View()
        self.view.set_size_request(-1, 200)
        self.view.set_document(document)
        
        scrolledwin2.add(self.view)
        vpaned.add(scrolledwin2)

        vbox = gtk.VBox(False, 0)
        vbox.pack_start(vpaned, True, True, 0)

        self.entry = gtk.Entry()
        self.entry.connect('changed', self.on_entry_changed)
        
        combobox = gtk.combo_box_new_text()
        combobox.append_text('it')
        combobox.append_text('en')
        combobox.connect('changed', self.on_lang_menu_selected)
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
            docs, tags = EnquireDB(query)
            self.model.clear()
            for item in docs:
                self.model.append(item)
        
        gtkhtml2_doc = mark_text_up(tags)
        gtkhtml2_doc.connect('link_clicked', self.on_tag_clicked)
        self.view.set_document(gtkhtml2_doc)

    def on_tag_clicked(self, document, link):
        self.entry.set_text(self.entry.get_text().rstrip() + " " + link)

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
    
    def on_lang_menu_selected(self, combobox):
        model = combobox.get_model()
        index = combobox.get_active()
        #if index:
        self.selected_language = model[index][0]
        self.refresh_results()

if __name__ == "__main__":
    demo = Demo()
