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

MODEL_DB_URL, MODEL_DB_PORT, MODEL_DB_IS_LOCAL, MODEL_DB_VALIDITY = range(4)
FLAG_DB_NOT_CHECKED, FLAG_DB_IS_VALID, FLAG_DB_IS_NOT_VALID = [gtk.STOCK_DIALOG_QUESTION, gtk.STOCK_YES, gtk.STOCK_NO]

class MMSearchForm(gtk.VBox):
    def __init__(self):
        gtk.VBox.__init__(self, False, 6)

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

        self.upperbox.pack_start(gtk.Label("Query:"), False, False, 0)
        self.upperbox.pack_start(self.entry, True, True, 0)
        self.upperbox.pack_start(self.start_button, False, False, 0)
        self.upperbox.pack_start(gtk.Label("Language:"), False, False, 0)
        self.upperbox.pack_start(self.combobox, False, False, 0)
        self.upperbox.pack_start(self.progressbar, False, False, 0)

        hbox2 = gtk.HBox(False, 12)

        def set_local_or_remote(tvcolumn, cell, model, iter):
            is_local = model.get_value(iter, 0)
            if is_local == True:
                label = 'local'
            else:
                label = 'remote'
            cell.set_property('text', label)
            return

        # combobox for selecting local/remote db
        model = gtk.ListStore('gboolean')
        self.combobox_dblocal = gtk.ComboBox(model)
        cell = gtk.CellRendererText()
        self.combobox_dblocal.pack_start(cell, True)
        self.combobox_dblocal.set_cell_data_func(cell, set_local_or_remote)
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
        self.model_db.append(['/home/matteo/Development/pagestore/renzi_xap_20081220', 0, True, FLAG_DB_NOT_CHECKED])
        self.model_db.append(['/home/matteo/Development/pagestore/us2008_xap', 0, True, FLAG_DB_NOT_CHECKED])
        self.model_db.append(['10.0.2.2:3333', 0, False, FLAG_DB_NOT_CHECKED])
        self.model_db.append(['localhost:3333', 0, False, FLAG_DB_NOT_CHECKED])
        self.comboboxentry_db.set_active(0)

        self.image_connected = gtk.Image()

        self.connect_button = gtk.Button()
        self.connect_button.set_label('Connect')

        hbox2.pack_start(gtk.Label('Database:'), False, False, 0)
        hbox2.pack_start(self.combobox_dblocal, False, False, 0)
        hbox2.pack_start(self.comboboxentry_db, True, True, 0)
        hbox2.pack_start(self.image_connected, False, False, 0)
        hbox2.pack_start(self.connect_button, False, False, 0)

        self.pack_start(self.upperbox, False, False, 0)
        self.pack_start(hbox2, False, False, 0)

class MMMainFrame(gtk.VBox):
    def __init__(self, component):
        gtk.VBox.__init__(self)

        self.resultbox = gtk.VBox(False, 0)
        self.searchform = MMSearchForm()
        self.set_component(component)

        self.pack_start(self.resultbox, True, True, 0)
        self.pack_start(self.searchform, False, False, 0)

        # assign self.selected_language, self.selected_localdb
        self.on_lang_selected(self.searchform.combobox)
        self.on_dblocal_changed(self.searchform.combobox_dblocal)

        self.searchform.combobox.connect('changed', self.on_lang_selected)
        self.searchform.combobox_dblocal.connect('changed', self.on_dblocal_changed)
        self.searchform.comboboxentry_db.connect('changed', self.on_db_selected)
        self.searchform.comboboxentry_db.child.connect('changed', self.on_db_manually_entered)
        self.searchform.start_button.connect('clicked', self.on_start_button_clicked)
        self.searchform.connect_button.connect('clicked', self.on_connect_button_clicked)
        self.searchform.filtered_model_db.set_visible_func(self.visible_dbs_cb)
        self.searchform.filtered_model_db.refilter()

        # assign self.db
        self.on_db_selected(self.searchform.comboboxentry_db, self.selected_localdb)

    def set_component(self, component):
        self.component = component()
        self.component.ui = self.component.ui(self.resultbox, self.searchform)

    def on_lang_selected(self, combobox):
        model = combobox.get_model()
        index = combobox.get_active()
        self.selected_language = model[index][0]

    def visible_dbs_cb(self, model, iter):
        logging.debug('Is db %s local? %s, therefore is db shown? %s' % (model.get_value(iter, MODEL_DB_URL), model.get_value(iter, MODEL_DB_IS_LOCAL), model.get_value(iter, MODEL_DB_IS_LOCAL) == self.selected_localdb))
        return model.get_value(iter, MODEL_DB_IS_LOCAL) == self.selected_localdb

    def on_dblocal_changed(self, combobox):
        model = combobox.get_model()
        index = combobox.get_active()
        self.selected_localdb = model[index][0]
        logging.debug('Selecting local db? %s' % self.selected_localdb)
        self.searchform.connect_button.set_sensitive(not self.selected_localdb) # set sensitive only if remote selected
        self.searchform.filtered_model_db.refilter() # show only local/remote dbs in comboboxentry

        model = self.searchform.comboboxentry_db.get_model()
        iter = model.get_iter_root()
        while (iter):
            # FIXME: this implies that entries both local and remote are always present
            if model.get_value(iter, MODEL_DB_IS_LOCAL) == self.selected_localdb:
                #print self.searchform.model_db.get_value(iter, MODEL_DB_URL)
                break
            iter = model.iter_next(iter)
        self.searchform.comboboxentry_db.set_active(model.get_path(iter)[0])

    def is_db_valid(self, entered_db):
        # - returns True if db can be opened by Xapian
        # - changes image_connected
        try:
            logging.debug('Checking %s' % entered_db)
            if self.selected_localdb:
                db = xapian.Database(entered_db)
            else:
                db_host, port = entered_db.split(':')
                db = xapian.remote_open(db_host, int(port))
        except xapian.DatabaseOpeningError, e:
            logging.error('Error while opening %s (%s)' % (entered_db, e))
            return False
        except xapian.NetworkError, e:
            logging.error('Error while opening %s (%s)' % (entered_db, e))
            return False
        #except:
        #    logging.error('Error while opening %s' % entered_db)
        #    self.searchform.image_connected.set_from_stock(gtk.STOCK_DISCONNECT, gtk.ICON_SIZE_MENU)
        #    return False
        else:
            return True

    def add_db_to_model(self, model, entered_db):
        'adds user specified db to model only if not already present'
        iter = model.get_iter_root()
        unique = True
        while (iter):
            unique = unique and model.get_value(iter, MODEL_DB_URL) != entered_db
            iter = model.iter_next(iter)
        if unique == True:
            model.append([entered_db, 0, self.selected_localdb, FLAG_DB_IS_VALID])

    def check_db_if_needed(self, combobox, do_check, entry=None):
        model = combobox.get_model()
        index = combobox.get_active()

        # if we're editing comboboxentry set MODEL_DB_IS_LOCAL = self.selected_localdb
        if index == -1:
            if entry is not None:
                selected_db_is_local = self.selected_localdb
                db_url = entry.get_text()
                logging.debug("Running 'check_db_if_needed' on %s, triggered by manual insertion (entry=%s)." % (db_url, entry))
            else:
                return
        else:
            selected_db_is_local = model[index][MODEL_DB_IS_LOCAL]
            db_url = model[index][MODEL_DB_URL]
            logging.debug("Running 'check_db_if_needed' on %s, triggered by combobox selection (entry=%s)." % (db_url, entry))

        # Avoid stupid timeouts, check only if we pass True to do_check (triggered by connect button)
        # or local is selected. In any case, check only current type (local or remote) of dbs
        #logging.debug('index: %d, do_check: %s, selected_localdb: %s, is_local: %s' % (index, do_check, self.selected_localdb, selected_db_is_local))
        if (do_check or self.selected_localdb) and (selected_db_is_local == self.selected_localdb):
            # check if db is valid and disable search button accordingly
            if self.is_db_valid(db_url):
                self.selected_db = db_url
                if index == -1:
                    self.add_db_to_model(self.searchform.model_db, db_url)
                else:
                    iter_filtered_model = model.get_iter((index,))
                    iter_full_model = model.convert_iter_to_child_iter(iter_filtered_model)
                    self.searchform.model_db.set_value(iter_full_model, MODEL_DB_VALIDITY, FLAG_DB_IS_VALID)
                self.searchform.upperbox.set_sensitive(True)
                self.set_image_connected(True)
            else:
                self.searchform.upperbox.set_sensitive(False)
                self.set_image_connected(False)
        else:
            self.searchform.upperbox.set_sensitive(False)
            self.set_image_connected(False)

    def on_db_selected(self, combobox, do_check=False):
        # on_db_selected is triggered when user selects something with the
        # combobox, but after calling on_db_manually_entered
        logging.debug('on_db_selected')
        self.check_db_if_needed(combobox, do_check, None)

    def on_db_manually_entered(self, entry, do_check=False):
        # on_db_manually_entered is triggered when user edits the 
        # comboboxentry, but after calling on_db_selected
        logging.debug('on_db_manutally_entered')
        self.check_db_if_needed(self.searchform.comboboxentry_db, do_check, entry)

    def on_start_button_clicked(self, button):
        self.searchform.set_sensitive(False)
        self.refresh_results()

    def set_image_connected(self, state):
        # state = True (connected), False (disconnected)
        tooltips = gtk.Tooltips()
        if state == True:
            self.searchform.image_connected.set_from_stock(gtk.STOCK_CONNECT, gtk.ICON_SIZE_MENU)
            tooltips.set_tip(self.searchform.image_connected, 'Connected')
        else:
            self.searchform.image_connected.set_from_stock(gtk.STOCK_DISCONNECT, gtk.ICON_SIZE_MENU)
            tooltips.set_tip(self.searchform.image_connected, 'Disconnected')

    def on_connect_button_clicked(self, button):
        # TODO: set_sensitive(False) on remote/local combo + db combo
        # trigger db check (force avoidcheck as True)
        self.on_db_manually_entered(self.searchform.comboboxentry_db.child, True)

    def refresh_results(self):
        stemmer = xapian.Stem(self.selected_language)

        if self.selected_localdb:
            db = xapian.Database(self.selected_db)
        else:
            db_host, port = self.selected_db.split(':')
            db = xapian.remote_open(db_host, int(port))

        qp = xapian.QueryParser()
        qp.set_stemmer(stemmer)
        qp.set_database(db)
        qp.set_stemming_strategy(xapian.QueryParser.STEM_SOME)

        date_processor = xapian.DateValueRangeProcessor(2)
        qp.add_valuerangeprocessor(date_processor)

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
        w.set_size_request(700, 600)
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
