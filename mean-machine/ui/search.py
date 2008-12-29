#!/usr/bin/python
# -*- coding: UTF-8 -*-

# Licensed under the Apache2 License.

__copyright__ = 'BayesFor Association'
__author__    = 'Matteo Zandi <matteo.zandi@bayesfor.eu>'

from math import exp
import gtk, gobject, gtkhtml2

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
            cell.set_property('text', doc.get_value(2))
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
