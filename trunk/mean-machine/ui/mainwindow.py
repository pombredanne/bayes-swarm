#!/usr/bin/python
# -*- coding: UTF-8 -*-

# Licensed under the Apache2 License.

__copyright__ = 'BayesFor Association'
__author__    = 'Matteo Zandi <matteo.zandi@bayesfor.eu>'

import os
import gtk
from components.core import get_components
from notebookwithclosebuttonontabs import NotebookWithCloseButtonOnTabs
import xapian

import logging
format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
logging.basicConfig(level=logging.DEBUG, format=format)
logging = logging.getLogger('ui.mainwindow')

class MMSearchForm(gtk.HBox):
    def __init__(self):
        gtk.HBox.__init__(self, False, 12)
        self.set_border_width(6)
        
        self.entry = gtk.Entry()

        self.start_button = gtk.Button()
        self.start_button.set_label('Search')
        self.start_button.set_flags(gtk.CAN_DEFAULT)
        # TODO: set grab_default() when it is packed into the window
                
        self.combobox = gtk.combo_box_new_text()
        self.combobox.append_text('it')
        self.combobox.append_text('en')
        self.combobox.set_active(0)

        self.selected_language = 'it'
        
        self.progressbar = gtk.ProgressBar()
        self.progressbar.set_size_request(100,-1)

        self.pack_start(gtk.Label("Query:"), False, False, 0)
        self.pack_start(self.entry, True, True, 0)
        self.pack_start(self.start_button, False, False, 0)
        self.pack_start(gtk.Label("Language:"), False, False, 0)
        self.pack_start(self.combobox, False, False, 0)
        self.pack_start(self.progressbar, False, False, 0)

class MMMainFrame(gtk.VBox):
    def __init__(self, component):
        gtk.VBox.__init__(self)
        
        self.selected_language = 'it'
        
        self.resultbox = gtk.VBox(False, 0)
        self.searchform = MMSearchForm()
        self.set_component(component)
        
        self.pack_start(self.resultbox, True, True, 0)
        self.pack_start(self.searchform, False, False, 0)

        self.searchform.combobox.connect('changed', self.on_lang_menu_selected)
        self.searchform.start_button.connect('clicked', self.on_start_button_clicked)

    def set_component(self, component):
        self.component = component()
        self.component.ui = self.component.ui(self.resultbox, self.searchform)

    def on_lang_menu_selected(self, combobox):
        model = combobox.get_model()
        index = combobox.get_active()

        self.selected_language = model[index][0]

    def on_start_button_clicked(self, button):
        self.searchform.set_sensitive(False)
        self.refresh_results()

    def refresh_results(self):
        stemmer = xapian.Stem(self.selected_language)

        # FIXME: pass db as parameter
        #db = xapian.Database("/home/matteo/Development/pagestore/renzi_xap_20081220")
        db = xapian.Database("/home/matteo/Development/pagestore/us2008_xap")

        qp = xapian.QueryParser()
        qp.set_stemmer(stemmer)
        qp.set_database(db)
        qp.set_stemming_strategy(xapian.QueryParser.STEM_SOME)

        query1 = qp.parse_query(self.searchform.entry.get_text(), xapian.QueryParser.FLAG_BOOLEAN)
        query2 = xapian.Query(xapian.Query.OP_VALUE_RANGE, 0, self.selected_language, self.selected_language)
        query = xapian.Query(xapian.Query.OP_AND, query1, query2)
        
        logging.debug("Setting query: %s" % query.get_description())
        
        enquire = xapian.Enquire(db)
        enquire.set_query(query)

        self.component.run_and_display(enquire, self.selected_language, db, self.searchform.progressbar)
        self.searchform.set_sensitive(True)

class MainMachine(object):
    def __init__(self):
        components = get_components()
        
        w = gtk.Window()
        w.connect('destroy', gtk.main_quit)
        w.set_size_request(600, 600)
        #w.set_border_width(12)

        hbox = gtk.HBox(False, 12)
        hbox.set_border_width(6)
        for component_name, component_class in components.items():
            button = gtk.Button("New %s" % component_name)
            hbox.pack_start(button, False, False, 0)
            # TODO: change tab label according to what user types in search
            button.connect("clicked", self.new_tab, component_name, component_class)

        box = gtk.VBox(False, 6)
        box.pack_start(hbox, False, False, 0)
        
        self.notebook = NotebookWithCloseButtonOnTabs()
        self.notebook.set_scrollable(True)
        self.notebook.set_property('homogeneous', True)    
        box.pack_start(self.notebook, True, True, 0)

        w.add(box)
        w.show_all()
        gtk.main()

    def new_tab(self, widget, component_name, component_class):
        child = MMMainFrame(component_class)
        child.show_all()
        
        tab_label = gtk.Label(component_name)
        tab_label.show()
        
        nbpages = self.notebook.get_n_pages()
        self.notebook.append_page(child, tab_label)
        self.notebook.set_current_page(nbpages)
