#!/usr/bin/python
# -*- coding: UTF-8 -*-

# Licensed under the Apache2 License.

__copyright__ = 'BayesFor Association'
__author__    = 'Matteo Zandi <matteo.zandi@bayesfor.eu>'

import gtk

import logging
format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
logging.basicConfig(format=format)
logging = logging.getLogger('ui.searchform')

MODEL_DB_URL, MODEL_DB_PORT, MODEL_DB_IS_LOCAL, MODEL_DB_VALIDITY = range(4)
FLAG_DB_NOT_CHECKED, FLAG_DB_IS_VALID, FLAG_DB_IS_NOT_VALID = [gtk.STOCK_DIALOG_QUESTION, gtk.STOCK_YES, gtk.STOCK_NO]

class MMSearchForm(gtk.Frame):
    def __init__(self):
        gtk.Frame.__init__(self)
        self.set_label("Search options")
        vbox = gtk.VBox(False, 6)
        vbox.set_border_width(3)
        
        self.upperbox = gtk.HBox(False, 12)
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

        self.progressbar = gtk.ProgressBar()
        self.progressbar.set_size_request(100,-1)
        self.progressbar.set_text('Ready')

        self.upperbox.pack_start(gtk.Label("Query:"), False, False, 0)
        self.upperbox.pack_start(self.entry, True, True, 0)
        self.upperbox.pack_start(self.start_button, False, False, 0)
        self.upperbox.pack_start(gtk.Label("Language:"), False, False, 0)
        self.upperbox.pack_start(self.combobox, False, False, 0)
        self.upperbox.pack_start(self.progressbar, False, False, 0)

        lowerbox = gtk.HBox(False, 12)

        # combobox for selecting all/some sources
        modelsources = gtk.ListStore('gboolean')
        self.combobox_sources = gtk.ComboBox(modelsources)
        cell = gtk.CellRendererText()
        self.combobox_sources.pack_start(cell, True)
        self.combobox_sources.set_cell_data_func(cell, self.set_allsources_or_selected)
        modelsources.append([True])
        modelsources.append([False])
        self.combobox_sources.set_active(0)
        
        # combobox for selecting local/remote db
        model = gtk.ListStore('gboolean')
        self.combobox_dblocal = gtk.ComboBox(model)
        cell = gtk.CellRendererText()
        self.combobox_dblocal.pack_start(cell, True)
        self.combobox_dblocal.set_cell_data_func(cell, self.set_local_or_remote)
        model.append([True])
        model.append([False])
        self.combobox_dblocal.set_active(0)

        # db comboboxentry
        # model = MODEL_DB_URL, MODEL_DB_PORT, MODEL_DB_IS_LOCAL, MODEL_DB_VALIDITY
        # MODEL_DB_VALIDITY = FLAG_DB_NOT_CHECKED, FLAG_DB_IS_VALID, FLAG_DB_IS_NOT_VALID
        self.model_db = gtk.ListStore(str, int, 'gboolean', str)
        self.filtered_model_db = self.model_db.filter_new()
        self.comboboxentry_db = gtk.ComboBoxEntry(self.filtered_model_db)
        cellpb = gtk.CellRendererPixbuf()
        self.comboboxentry_db.pack_start(cellpb, False)
        self.comboboxentry_db.add_attribute(cellpb, 'stock_id', MODEL_DB_VALIDITY)
        #cell = gtk.CellRendererText()
        #self.comboboxentry_db.pack_start(cell, True)
        #self.comboboxentry_db.add_attribute(cell, 'text', MODEL_DB_IS_LOCAL)
        self.model_db.append(['/home/matteo/Development/pagestore/renzi_xap_20090101_sources', 0, True, FLAG_DB_NOT_CHECKED])
        self.model_db.append(['/home/matteo/Development/pagestore/us2008_xap', 0, True, FLAG_DB_NOT_CHECKED])
        self.model_db.append(['10.0.2.2:3333', 0, False, FLAG_DB_NOT_CHECKED])
        self.model_db.append(['localhost:3333', 0, False, FLAG_DB_NOT_CHECKED])
        self.comboboxentry_db.set_active(0)

        self.image_connected = gtk.Image()

        self.connect_button = gtk.Button()
        self.connect_button.set_label('Connect')

        lowerbox.pack_start(gtk.Label('Sources:'), False, False, 0)
        lowerbox.pack_start(self.combobox_sources, False, False, 0)
        lowerbox.pack_start(gtk.Label('Database:'), False, False, 0)
        lowerbox.pack_start(self.combobox_dblocal, False, False, 0)
        lowerbox.pack_start(self.comboboxentry_db, True, True, 0)
        lowerbox.pack_start(self.image_connected, False, False, 0)
        lowerbox.pack_start(self.connect_button, False, False, 0)

        self.advancedbox = gtk.HBox(False, 12)
        self.advancedbox.pack_start(gtk.Label('Max matching documents:'), False, False, 0)
        self.mset_entry = gtk.Entry()
        self.mset_entry.set_text('20')
        self.mset_entry.set_width_chars(3)
        self.mset_entry.connect('changed', self.on_mset_entry_changed)
        self.advancedbox.pack_start(self.mset_entry, False, False, 0)
        self.advancedbox.pack_start(gtk.Label('Max expansion terms:'), False, False, 0)
        self.eset_entry = gtk.Entry()
        self.eset_entry.set_text('50')
        self.eset_entry.set_width_chars(3)
        self.eset_entry.connect('changed', self.on_eset_entry_changed)
        self.advancedbox.pack_start(self.eset_entry, False, False, 0)

        vbox.pack_start(self.upperbox, False, False, 0)
        vbox.pack_start(self.advancedbox, False, False, 0)
        vbox.pack_start(lowerbox, False, False, 0)
        self.add(vbox)

    def set_all_controls_sensitive_except(self, sensitivity, skipped_control):
        if sensitivity == False:
            self.progressbar.set_text('Error')
        controls = [self.entry, self.combobox, self.start_button, self.combobox_sources, 
                    self.mset_entry, self.eset_entry, self.combobox_dblocal, self.comboboxentry_db]
        for control in controls:
            if control != skipped_control:
                control.set_sensitive(sensitivity)

    def set_local_or_remote(self, tvcolumn, cell, model, iter):
        is_local = model.get_value(iter, 0)
        if is_local == True:
            label = 'local'
        else:
            label = 'remote'
        cell.set_property('text', label)
        return
        
    def set_allsources_or_selected(self, tvcolumn, cell, model, iter):
        is_local = model.get_value(iter, 0)
        if is_local == True:
            label = 'all'
        else:
            label = 'select'
        cell.set_property('text', label)
        return

    def on_mset_entry_changed(self, entry):
        try:
            int(entry.get_text())
            self.set_all_controls_sensitive_except(True, entry)
        except:
            self.set_all_controls_sensitive_except(False, entry)

    def on_eset_entry_changed(self, entry):
        try:
            int(entry.get_text())
            self.set_all_controls_sensitive_except(True, entry)
        except:
            self.set_all_controls_sensitive_except(False, entry)
