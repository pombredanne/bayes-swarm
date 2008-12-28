#!/usr/bin/python
# -*- coding: UTF-8 -*-

# Licensed under the Apache2 License.

__copyright__ = 'BayesFor Association'
__author__    = 'Matteo Zandi <matteo.zandi@bayesfor.eu>'

from math import exp
import gtk, gobject, gtkhtml2
import igraph
from igraphdrawingarea import IGraphDrawingArea

def mark_text_up(result_list):
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
    document.write_stream("</body></html>")
    document.close_stream()
    return document 

class MMResultSearch(object):
    is_mm_ui = True
    name = 'resultsearch'
    def __init__(self, box, searchform):
        '''box is where this widget is packed'''
        self.searchform = searchform
        
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

        treeview.set_size_request(-1, 200)
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
        self.view.set_size_request(-1, 150)
        self.view.set_document(document)
        
        scrolledwin2.add(self.view)
        screlledwin2_inner_vbox = gtk.VBox(False, 0)
        screlledwin2_inner_vbox.pack_start(gtk.Label("Terms cloud"), False, False, 0)
        screlledwin2_inner_vbox.pack_start(scrolledwin2)
        vpaned.add(screlledwin2_inner_vbox)

        self.vbox = gtk.VBox(False, 0)
        self.vbox.pack_start(gtk.Label("Matched documents list"), False, False, 0)
        self.vbox.pack_start(vpaned, True, True, 0)

        box.add(self.vbox)

    def display(self, docs, tags):
        self.model.clear()
        for item in docs:
            self.model.append(item)
    
        gtkhtml2_doc = mark_text_up(tags)
        gtkhtml2_doc.connect('link_clicked', self.on_tag_clicked)
        self.view.set_document(gtkhtml2_doc)

    def on_tag_clicked(self, document, link):
        self.searchform.entry.set_text(self.searchform.entry.get_text().rstrip() + " " + link)

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

def log_scale(x):
    return (exp(x)-1)/(exp(1)-1)

class MMResultGraph():
    def __init__(self, box, searchform):
        vbox = gtk.VBox(False, 0)
        vbox.set_border_width(6)
        
        self.adj = gtk.Adjustment(0.50, 0, 1, 0.01, 0.1, 0)
        self.slider = gtk.HScale(self.adj)
        self.slider.set_digits(2)

        self.adj2 = gtk.Adjustment(0.50, 0, 1, 0.01, 0.1, 0)
        self.slider2 = gtk.HScale(self.adj2)
        self.slider2.set_digits(2)

        self.adj.connect("value_changed", self.cb_threshold_changed)
        self.adj2.connect("value_changed", self.cb_threshold_changed)
        
        self.igraph_drawing_area = IGraphDrawingArea()
        #self.cb_threshold_changed(self.adj)

        vbox.pack_start(self.igraph_drawing_area, True, True, 0)
        table = gtk.Table(2, 2, False)
        table.set_row_spacings(6)
        table.set_col_spacings(12)
        # child, left_attach, right_attach, top_attach, bottom_attach, xoptions=gtk.EXPAND|gtk.FILL, yoptions=gtk.EXPAND|gtk.FILL, xpadding=0, ypadding=0)
        label1 = gtk.Label("Edge weight")
        label1.set_alignment(0, 0.5)
        table.attach(label1, 0, 1, 0, 1, gtk.FILL)
        table.attach(self.slider, 1, 2, 0, 1)
        label2 = gtk.Label("Vertex size")
        label2.set_alignment(0, 0.5)
        table.attach(label2, 0, 1, 1, 2, gtk.FILL)
        table.attach(self.slider2, 1, 2, 1, 2)
        vbox.pack_start(table, False, True, 0)
        
        box.add(vbox)

    def display(self, distances_list):
        labels_id = {}
        labels = []
        edges = []
        weights = []
        sizes = []

        count = 0
        for i, row in enumerate(distances_list):
            w = 1/float(row[2])
            keyword1 = row[0]
            keyword2 = row[1]
            if not labels_id.has_key(keyword1):
                labels_id[keyword1] = count
                labels.append(keyword1)
                sizes.append(float(row[3]))
                count += 1
            if not labels_id.has_key(keyword2):
                labels_id[keyword2] = count
                labels.append(keyword2)
                sizes.append(float(row[4]))
                count += 1
            edges.append((labels_id[keyword1], labels_id[keyword2]))
            weights.append(w)

        g = igraph.Graph(edges, directed=False)
        min_w = min(weights)
        max_w = max(weights)    
        g.es['weight'] = [(i - min_w) / float(max_w - min_w) for i in weights]
        g.vs['label'] = labels

        min_size = min(sizes)
        max_size = max(sizes)
        g.vs['size'] = [(i - min_size) / float(max_size - min_size) for i in sizes]

        fixed = [False for i in range(len(sizes)-1)]
        fixed.append(True)
        g.vs['fixed'] = fixed

        g.vs['fr_seed_coords'] = g.layout_circle()

        self.g = g

        self.cb_threshold_changed(None)

    def cb_threshold_changed(self, adj):
        # keep only edges where weight > threshold
        g2 = self.g - self.g.es.select(weight_lt=log_scale(self.adj.value))
        
        # keep only non isolated vertex
        # g3 = g2.subgraph(g2.vs.select(_degree_gt=0))
        
        # keep only vertex where size > threshold
        g3 = g2.subgraph(g2.vs.select(size_gt=log_scale(self.adj2.value)))

        self.igraph_drawing_area.change_graph(g3)
