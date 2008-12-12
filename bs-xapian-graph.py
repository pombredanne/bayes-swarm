#!/usr/bin/env python

import sys
import gtk
import gtk.gdk

import xapian
import xdot

stopwords = {'it': ["ad", "al", "allo", "ai", "agli", "all", "agl", "alla", "alle", "con", "col", "coi", "da", "dal", "dallo", "dai", "dagli", "dall", "dagl", "dalla", "dalle", "di", "del", "dello", "dei", "degli", "dell", "degl", "della", "delle", "in", "nel", "nello", "nei", "negli", "nell", "negl", "nella", "nelle", "su", "sul", "sullo", "sui", "sugli", "sull", "sugl", "sulla", "sulle", "per", "tra", "contro", "io", "tu", "lui", "lei", "noi", "voi", "loro", "mio", "mia", "miei", "mie", "tuo", "tua", "tuoi", "tue", "suo", "sua", "suoi", "sue", "nostro", "nostra", "nostri", "nostre", "vostro", "vostra", "vostri", "vostre", "mi", "ti", "ci", "vi", "lo", "la", "li", "le", "gli", "ne", "il", "un", "uno", "una", "ma", "ed", "se", "perch\303\251", "anche", "come", "dov", "dove", "che", "chi", "cui", "non", "pi\303\271", "quale", "quanto", "quanti", "quanta", "quante", "quello", "quelli", "quella", "quelle", "questo", "questi", "questa", "queste", "si", "tutto", "tutti", "a", "c", "e", "i", "l", "o", "ho", "hai", "ha", "abbiamo", "avete", "hanno", "abbia", "abbiate", "abbiano", "avr\303\262", "avrai", "avr\303\240", "avremo", "avrete", "avranno", "avrei", "avresti", "avrebbe", "avremmo", "avreste", "avrebbero", "avevo", "avevi", "aveva", "avevamo", "avevate", "avevano", "ebbi", "avesti", "ebbe", "avemmo", "aveste", "ebbero", "avessi", "avesse", "avessimo", "avessero", "avendo", "avuto", "avuta", "avuti", "avute", "sono", "sei", "\303\250", "siamo", "siete", "sia", "siate", "siano", "sar\303\262", "sarai", "sar\303\240", "saremo", "sarete", "saranno", "sarei", "saresti", "sarebbe", "saremmo", "sareste", "sarebbero", "ero", "eri", "era", "eravamo", "eravate", "erano", "fui", "fosti", "fu", "fummo", "foste", "furono", "fossi", "fosse", "fossimo", "fossero", "essendo", "faccio", "fai", "facciamo", "fanno", "faccia", "facciate", "facciano", "far\303\262", "farai", "far\303\240", "faremo", "farete", "faranno", "farei", "faresti", "farebbe", "faremmo", "fareste", "farebbero", "facevo", "facevi", "faceva", "facevamo", "facevate", "facevano", "feci", "facesti", "fece", "facemmo", "faceste", "fecero", "facessi", "facesse", "facessimo", "facessero", "facendo", "sto", "stai", "sta", "stiamo", "stanno", "stia", "stiate", "stiano", "star\303\262", "starai", "star\303\240", "staremo", "starete", "staranno", "starei", "staresti", "starebbe", "staremmo", "stareste", "starebbero", "stavo", "stavi", "stava", "stavamo", "stavate", "stavano", "stetti", "stesti", "stette", "stemmo", "steste", "stettero", "stessi", "stesse", "stessimo", "stessero", "stando"], 'en': ["a", "about", "above", "after", "again", "against", "all", "am", "an", "and", "any", "are", "aren't", "as", "at", "be", "because", "been", "before", "being", "below", "between", "both", "but", "by", "cannot", "can't", "could", "couldn't", "did", "didn't", "do", "does", "doesn't", "doing", "don't", "down", "during", "each", "few", "for", "from", "further", "had", "hadn't", "has", "hasn't", "have", "haven't", "having", "he", "he'd", "he'll", "her", "here", "here's", "hers", "herself", "he's", "him", "himself", "his", "how", "how's", "i", "i'd", "if", "i'll", "i'm", "in", "into", "is", "isn't", "it", "its", "it's", "itself", "i've", "let's", "me", "more", "most", "mustn't", "my", "myself", "no", "nor", "not", "of", "off", "on", "once", "only", "or", "other", "ought", "our", "ours", "ourselves", "out", "over", "own", "same", "shan't", "she", "she'd", "she'll", "she's", "should", "shouldn't", "so", "some", "such", "than", "that", "that's", "the", "their", "theirs", "them", "themselves", "then", "there", "there's", "these", "they", "they'd", "they'll", "they're", "they've", "this", "those", "through", "to", "too", "under", "until", "up", "very", "was", "wasn't", "we", "we'd", "we'll", "were", "we're", "weren't", "we've", "what", "what's", "when", "when's", "where", "where's", "which", "while", "who", "whom", "who's", "why", "why's", "with", "won't", "would", "wouldn't", "you", "you'd", "you'll", "your", "you're", "yours", "yourself", "yourselves", "you've", "one", "every", "least", "less", "many", "now", "ever", "never", "say", "says", "said", "also", "get", "go", "goes", "just", "made", "make", "put", "see", "seen", "whether", "like", "well", "back", "even", "still", "way", "take", "since", "another", "however", "two", "three", "four", "five", "first", "second", "new", "old", "high", "long"]}

if len(sys.argv) == 2:
    PATH_TO_XAPIAN_DB = sys.argv[1]
else:
    print >> sys.stderr, "Usage: %s PATH_TO_XAPIAN_DB" % sys.argv[0]
    sys.exit(1)

# Open the database for searching.
database = xapian.Database(PATH_TO_XAPIAN_DB)

def EnquireDB(input_terms, lang):
    stemmer = xapian.Stem(lang)
    tags_dict = {}
    
    for input_term in input_terms.split():
        qp = xapian.QueryParser()
        qp.set_stemmer(stemmer)
        qp.set_database(database)
        qp.set_stemming_strategy(xapian.QueryParser.STEM_SOME)
        try:
            query1 = qp.parse_query(input_term, xapian.QueryParser.FLAG_BOOLEAN)
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
        size = 20
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
        rset = xapian.RSet()
        for y, m in enumerate(mset):
            rset.add_document(m[xapian.MSET_DID])

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
        eset = enquire.get_eset(10, rset, Filter(terms, stopwords[lang]))
        
        # Get the first 100 documents and scan their tags
        tagscores = dict()
        for item in eset:
            tag = item.term
            tagscores[tag] = item.weight

        tags = []
        if tagscores != dict():
            maxscore = max(tagscores.itervalues())
            minscore = min(tagscores.itervalues())
            range = maxscore - minscore
            for k in tagscores.iterkeys():
                tags.append(((tagscores[k] - minscore) * 6 / range + 1, k))

        tags_dict[input_term] = tags
    return tags_dict

class MyDotWindow(xdot.DotWindow):
    def __init__(self):
        gtk.Window.__init__(self)

        self.graph = xdot.Graph()

        window = self

        window.set_title('Dot Viewer')
        window.set_default_size(512, 512)
        vbox = gtk.VBox()
        window.add(vbox)

        self.widget = xdot.DotWidget()

        # Create a UIManager instance
        uimanager = self.uimanager = gtk.UIManager()

        # Add the accelerator group to the toplevel window
        accelgroup = uimanager.get_accel_group()
        window.add_accel_group(accelgroup)

        # Create an ActionGroup
        actiongroup = gtk.ActionGroup('Actions')
        self.actiongroup = actiongroup

        # Create actions
        actiongroup.add_actions((
            ('Open', gtk.STOCK_OPEN, None, None, None, self.on_open),
            ('ZoomIn', gtk.STOCK_ZOOM_IN, None, None, None, self.widget.on_zoom_in),
            ('ZoomOut', gtk.STOCK_ZOOM_OUT, None, None, None, self.widget.on_zoom_out),
            ('ZoomFit', gtk.STOCK_ZOOM_FIT, None, None, None, self.widget.on_zoom_fit),
            ('Zoom100', gtk.STOCK_ZOOM_100, None, None, None, self.widget.on_zoom_100),
        ))

        # Add the actiongroup to the uimanager
        uimanager.insert_action_group(actiongroup, 0)

        # Add a UI descrption
        uimanager.add_ui_from_string(self.ui)

        # Create a Toolbar
        toolbar = uimanager.get_widget('/ToolBar')
        vbox.pack_start(toolbar, False)

        vbox.pack_start(self.widget)
        self.set_focus(self.widget)
        self.widget.connect('clicked', self.on_url_clicked)

        self.entry = gtk.Entry()
        self.entry.set_text('')
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

        self.show_all()

    def on_entry_changed(self, widget, *args):
        self.refresh_results()

    def refresh_results(self):
        if self.entry.get_text().strip() != '' and self.entry.get_text().strip() is not None:
            tags = EnquireDB(self.entry.get_text(), self.selected_language)
            self.set_dotcode(make_dotcode(tags))
            
    def on_url_clicked(self, widget, url, event):
        self.entry.set_text(self.entry.get_text().rstrip() + " " + url)

    def on_lang_menu_selected(self, combobox):
        model = combobox.get_model()
        index = combobox.get_active()
        #if index:
        self.selected_language = model[index][0]
        self.refresh_results()

def make_dotcode(term_w_tagsscores):
    #{'query_term': [[score, tag], [score, tag], ..], ..}
    nodes = set()
    edges = []
    for query_term in term_w_tagsscores.iterkeys():
        tagsscores = term_w_tagsscores[query_term]
        nodes.add(query_term)
        for score, tag in tagsscores:
            nodes.add(tag)
            edges.append((query_term, tag, score))
    nodes_dotcode = '\n'.join(['%s [URL="%s"]' % (x,x) for x in nodes])
    edges_dotcode = '\n'.join(['%s -> %s [style="setlinewidth(%i)"]' % (x[0],x[1],int(x[2])) for x in edges])
    
    dotcode = "digraph G {\n%s\n%s\n}" % (nodes_dotcode, edges_dotcode)
    return dotcode

def main():
    window = MyDotWindow()
    window.connect('destroy', gtk.main_quit)
    gtk.main()

if __name__ == '__main__':
    main()
