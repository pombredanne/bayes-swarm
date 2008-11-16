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

stopwords = {'it': ["ad", "al", "allo", "ai", "agli", "all", "agl", "alla", "alle", "con", "col", "coi", "da", "dal", "dallo", "dai", "dagli", "dall", "dagl", "dalla", "dalle", "di", "del", "dello", "dei", "degli", "dell", "degl", "della", "delle", "in", "nel", "nello", "nei", "negli", "nell", "negl", "nella", "nelle", "su", "sul", "sullo", "sui", "sugli", "sull", "sugl", "sulla", "sulle", "per", "tra", "contro", "io", "tu", "lui", "lei", "noi", "voi", "loro", "mio", "mia", "miei", "mie", "tuo", "tua", "tuoi", "tue", "suo", "sua", "suoi", "sue", "nostro", "nostra", "nostri", "nostre", "vostro", "vostra", "vostri", "vostre", "mi", "ti", "ci", "vi", "lo", "la", "li", "le", "gli", "ne", "il", "un", "uno", "una", "ma", "ed", "se", "perch\303\251", "anche", "come", "dov", "dove", "che", "chi", "cui", "non", "pi\303\271", "quale", "quanto", "quanti", "quanta", "quante", "quello", "quelli", "quella", "quelle", "questo", "questi", "questa", "queste", "si", "tutto", "tutti", "a", "c", "e", "i", "l", "o", "ho", "hai", "ha", "abbiamo", "avete", "hanno", "abbia", "abbiate", "abbiano", "avr\303\262", "avrai", "avr\303\240", "avremo", "avrete", "avranno", "avrei", "avresti", "avrebbe", "avremmo", "avreste", "avrebbero", "avevo", "avevi", "aveva", "avevamo", "avevate", "avevano", "ebbi", "avesti", "ebbe", "avemmo", "aveste", "ebbero", "avessi", "avesse", "avessimo", "avessero", "avendo", "avuto", "avuta", "avuti", "avute", "sono", "sei", "\303\250", "siamo", "siete", "sia", "siate", "siano", "sar\303\262", "sarai", "sar\303\240", "saremo", "sarete", "saranno", "sarei", "saresti", "sarebbe", "saremmo", "sareste", "sarebbero", "ero", "eri", "era", "eravamo", "eravate", "erano", "fui", "fosti", "fu", "fummo", "foste", "furono", "fossi", "fosse", "fossimo", "fossero", "essendo", "faccio", "fai", "facciamo", "fanno", "faccia", "facciate", "facciano", "far\303\262", "farai", "far\303\240", "faremo", "farete", "faranno", "farei", "faresti", "farebbe", "faremmo", "fareste", "farebbero", "facevo", "facevi", "faceva", "facevamo", "facevate", "facevano", "feci", "facesti", "fece", "facemmo", "faceste", "fecero", "facessi", "facesse", "facessimo", "facessero", "facendo", "sto", "stai", "sta", "stiamo", "stanno", "stia", "stiate", "stiano", "star\303\262", "starai", "star\303\240", "staremo", "starete", "staranno", "starei", "staresti", "starebbe", "staremmo", "stareste", "starebbero", "stavo", "stavi", "stava", "stavamo", "stavate", "stavano", "stetti", "stesti", "stette", "stemmo", "steste", "stettero", "stessi", "stesse", "stessimo", "stessero", "stando"], 'en': ["a", "about", "above", "after", "again", "against", "all", "am", "an", "and", "any", "are", "aren't", "as", "at", "be", "because", "been", "before", "being", "below", "between", "both", "but", "by", "cannot", "can't", "could", "couldn't", "did", "didn't", "do", "does", "doesn't", "doing", "don't", "down", "during", "each", "few", "for", "from", "further", "had", "hadn't", "has", "hasn't", "have", "haven't", "having", "he", "he'd", "he'll", "her", "here", "here's", "hers", "herself", "he's", "him", "himself", "his", "how", "how's", "i", "i'd", "if", "i'll", "i'm", "in", "into", "is", "isn't", "it", "its", "it's", "itself", "i've", "let's", "me", "more", "most", "mustn't", "my", "myself", "no", "nor", "not", "of", "off", "on", "once", "only", "or", "other", "ought", "our", "ours", "ourselves", "out", "over", "own", "same", "shan't", "she", "she'd", "she'll", "she's", "should", "shouldn't", "so", "some", "such", "than", "that", "that's", "the", "their", "theirs", "them", "themselves", "then", "there", "there's", "these", "they", "they'd", "they'll", "they're", "they've", "this", "those", "through", "to", "too", "under", "until", "up", "very", "was", "wasn't", "we", "we'd", "we'll", "were", "we're", "weren't", "we've", "what", "what's", "when", "when's", "where", "where's", "which", "while", "who", "whom", "who's", "why", "why's", "with", "won't", "would", "wouldn't", "you", "you'd", "you'll", "your", "you're", "yours", "yourself", "yourselves", "you've", "one", "every", "least", "less", "many", "now", "ever", "never", "say", "says", "said", "also", "get", "go", "goes", "just", "made", "make", "put", "see", "seen", "whether", "like", "well", "back", "even", "still", "way", "take", "since", "another", "however", "two", "three", "four", "five", "first", "second", "new", "old", "high", "long"]}

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

def EnquireDB(input_terms, lang):
    if input_terms == None:
        # No text given: abort
        return
    
    qp = xapian.QueryParser()
    stemmer = xapian.Stem(lang)
    qp.set_stemmer(stemmer)
    qp.set_database(database)
    qp.set_stemming_strategy(xapian.QueryParser.STEM_SOME)
    try:
        query1 = qp.parse_query(input_terms, xapian.QueryParser.FLAG_BOOLEAN) #xapian.QueryParser.FLAG_PHRASE
    except xapian.QueryParserError:
        print 'Query parser error'
        return

    query2 = xapian.Query(xapian.Query.OP_VALUE_RANGE, 0, lang, lang)
    query = xapian.Query(xapian.Query.OP_AND, query1, query2)
    
    print "Parsed query is: %s" % query.get_description()
    terms = [term for pos, term in enumerate(query)]
    print "Terms: %s" % ', '.join(terms)

    # Start an enquire session.
    enquire = xapian.Enquire(database)
    
    # Find the top 10 results for the query.
    enquire.set_query(query)
    # Retrieve as many results as we can show
    size = 300
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
        if y < 300:
            rset.add_document(m[xapian.MSET_DID])
        name = m[xapian.MSET_DOCUMENT].get_data()
        docs.append([m[xapian.MSET_PERCENT], name, m, ''])

    class Filter(xapian.ExpandDecider):
        def __init__(self, query_terms, stopwords):
            xapian.ExpandDecider.__init__(self)
            self.query_terms = query_terms
            self.stopwords = stopwords
            
        def __call__(self, term):
            # FIXME: do not index stopwords
            return term[0].islower() and term not in self.query_terms and term not in self.stopwords and '_' not in term

    # This is the "Expansion set" for the search: the 50 most relevant terms that
    # match the filter
    eset = enquire.get_eset(50, rset, Filter(terms, stopwords[lang]))
    
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
    for tag, score in result_list:
        document.write_stream('<a href="%s" style="font-size: %d%%">%s</a> ' % (tag.encode('latin-1'), score, tag.encode('latin-1')))
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
        w.set_size_request(500, -1)

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
            cell.set_property('text', '%s.%s.%s' % (doc.get_value(4),doc.get_value(3),doc.get_value(2)))
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
#        treeview.set_tooltip_column(3)
#        treeview.connect('query-tooltip', self.on_query_tooltip)
        
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
        screlledwin2_inner_vbox = gtk.VBox(False, 0)
        screlledwin2_inner_vbox.pack_start(gtk.Label("Terms cloud"), False, False, 0)
        screlledwin2_inner_vbox.pack_start(scrolledwin2)
        vpaned.add(screlledwin2_inner_vbox)

        vbox = gtk.VBox(False, 0)
        vbox.pack_start(gtk.Label("Matched documents list"), False, False, 0)
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
        hbox.pack_start(gtk.Label("Language:"), False, False, 0)
        hbox.pack_start(combobox, False, False, 0)
        hbox.pack_start(gtk.Label("Search:"), False, False, 0)
        hbox.pack_start(self.entry, True, True, 0)
        vbox.pack_start(hbox, False, False, 0)

        w.add(vbox)
        w.show_all()
        gtk.main()

    def refresh_results(self):
        if self.entry.get_text().strip() != '' and self.entry.get_text().strip() is not None:
            docs, tags = EnquireDB(self.entry.get_text(), self.selected_language)
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

#    def on_query_tooltip(self, widget, x, y, keyboard_mode, tooltip, *args):
#        pass
        
    def on_row_activated(self, treeview, path, view_column):
        iter = treeview.get_model().get_iter(path)
        doc = treeview.get_model().get_value(iter, 2).document
        path = os.path.join(PATH_TO_PAGESTORE, 
                            doc.get_value(5),
                            doc.get_value(1),
                            'contents.html')

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
