#!/usr/bin/python
# -*- coding: UTF-8 -*-

# Licensed under the GNU General Public License v2.

__copyright__ = 'BayesFor Association'
__author__    = 'Matteo Zandi <matteo.zandi@bayesfor.eu>'

import gtk, gobject, pango
import os

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

        self.cloud_label = gtk.Label()
        self.cloud_label.connect("size-allocate", self.cb_allocate)
        self.cloud_label.connect("activate-link", self.cb_activate_link)
        
        scrolledwin2.add(self.cloud_label)
        scrolledwin2_inner_vbox = gtk.VBox(False, 0)
        scrolledwin2_inner_vbox.pack_start(gtk.Label("Terms cloud"), False, False, 3)
        scrolledwin2_inner_vbox.pack_start(scrolledwin2)
        vpaned.add(scrolledwin2_inner_vbox)

        self.vbox = gtk.VBox(False, 0)
        self.vbox.pack_start(gtk.Label("Matched documents list"), False, False, 3)
        self.vbox.pack_start(vpaned, True, True, 0)

        box.add(self.vbox)

    def display(self, docs, result_list):
        self.model.clear()
        for item in docs:
            self.model.append(item)
    
        marked_text = ''
        for tag, score in result_list:
            marked_text = ' '.join([marked_text, '<span size="%d"><a href="%s">%s</a></span>'
            	% (score*100, tag, tag)])
        self.cloud_label.set_text(marked_text)
        self.cloud_label.set_use_markup(True)
        self.cloud_label.set_line_wrap(True)
        self.cloud_label.set_justify(gtk.JUSTIFY_CENTER)

    def cb_allocate(self, label, allocation):
        label.set_size_request(allocation.width - 2, -1)

    def cb_activate_link(self, label, uri):
        self.searchform.entry.set_text(self.searchform.entry.get_text().rstrip() + " " + uri)
        return True

    def clear(self):
        self.model.clear()
        
        self.cloud_label.set_text('')

#    def on_query_tooltip(self, widget, x, y, keyboard_mode, tooltip, *args):
#        pass
        
    def on_row_activated(self, treeview, path, view_column):
        iter = treeview.get_model().get_iter(path)
        doc = treeview.get_model().get_value(iter, 2).document
        PATH_TO_PAGESTORE = '/home/matteo/Development/pagestore/renzi_pagestore_20090109'
        path = os.path.join(PATH_TO_PAGESTORE, 
                            doc.get_value(3),
                            doc.get_value(1),
                            'contents.html')

        import webbrowser
        webbrowser.open(path)
