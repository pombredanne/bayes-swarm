#!/usr/bin/python
# -*- coding: UTF-8 -*-

# Licensed under the Apache2 License.

__copyright__ = 'BayesFor Association'
__author__    = 'Matteo Zandi <matteo.zandi@bayesfor.eu>'

import os
import gtk
from components.core import get_components
from notebookwithclosebuttonontabs import NotebookWithCloseButtonOnTabs
from searchform import MMSearchForm
import xapian

import logging
format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
logging.basicConfig(format=format)
logging = logging.getLogger('ui.mainwindow')

MODEL_DOC_LANG, MODEL_DOC_HASH, MODEL_DOC_DATE, MODEL_DOC_DIR, MODEL_DOC_SOURCEID, MODEL_DOC_SOURCE = range(6)
# FIXME: these should be defined only once!
MODEL_DB_URL, MODEL_DB_PORT, MODEL_DB_IS_LOCAL, MODEL_DB_VALIDITY = range(4)
FLAG_DB_NOT_CHECKED, FLAG_DB_IS_VALID, FLAG_DB_IS_NOT_VALID = [gtk.STOCK_DIALOG_QUESTION, gtk.STOCK_YES, gtk.STOCK_NO]

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

        self.searchform.entry.connect('changed', self.on_entry_changed)
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

    def on_entry_changed(self, entry):
        self.clear_results()

    def on_lang_selected(self, combobox):
        self.clear_results()
        model = combobox.get_model()
        index = combobox.get_active()
        self.selected_language = model[index][0]

    def visible_dbs_cb(self, model, iter):
        #logging.debug('Is db %s local? %s, therefore is db shown? %s' % (model.get_value(iter, MODEL_DB_URL), model.get_value(iter, MODEL_DB_IS_LOCAL), model.get_value(iter, MODEL_DB_IS_LOCAL) == self.selected_localdb))
        return model.get_value(iter, MODEL_DB_IS_LOCAL) == self.selected_localdb

    def on_dblocal_changed(self, combobox):
        self.clear_results()
        model = combobox.get_model()
        index = combobox.get_active()
        self.selected_localdb = model[index][0]
        if self.selected_localdb == True:
            logging.debug('Selecting local db')
        else:
            logging.debug('Selecting remote db')
        self.searchform.connect_button.set_sensitive(not self.selected_localdb) # set sensitive only if remote selected
        self.searchform.filtered_model_db.refilter() # show only local/remote dbs in comboboxentry

        # Filter dbs according to what user selected
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
            logging.debug('Checking if db %s is valid' % entered_db)
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
            logging.info('Db %s is valid' % entered_db)
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
                #logging.debug("Running 'check_db_if_needed' on %s, triggered by manual insertion (entry=%s)." % (db_url, entry))
            else:
                return
        else:
            selected_db_is_local = model[index][MODEL_DB_IS_LOCAL]
            db_url = model[index][MODEL_DB_URL]
            #logging.debug("Running 'check_db_if_needed' on %s, triggered by combobox selection (entry=%s)." % (db_url, entry))

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
                self.searchform.set_controls_sensitive(True)
                self.set_image_connected(True)
            else:
                self.searchform.set_controls_sensitive(False)
                self.set_image_connected(False)
        else:
            self.searchform.set_controls_sensitive(False)
            self.set_image_connected(False)

    def on_db_selected(self, combobox, do_check=False):
        # on_db_selected is triggered when user selects something with the
        # combobox, but after calling on_db_manually_entered
        self.clear_results()
        self.check_db_if_needed(combobox, do_check, None)

    def on_db_manually_entered(self, entry, do_check=False):
        # on_db_manually_entered is triggered when user edits the 
        # comboboxentry, but after calling on_db_selected
        self.clear_results()
        self.check_db_if_needed(self.searchform.comboboxentry_db, do_check, entry)

    def on_start_button_clicked(self, button):
        self.searchform.set_sensitive(False)
        self.refresh_results()
        self.searchform.set_sensitive(True)

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

        date_processor = xapian.DateValueRangeProcessor(MODEL_DOC_DATE)
        qp.add_valuerangeprocessor(date_processor)

        # FIXME: handle xapian.QueryParserError, xapian.NetworkTimeoutError
        # show error message in statusbar, user should be able to clear search with 'stop'
        query_search = qp.parse_query(self.searchform.entry.get_text(), xapian.QueryParser.FLAG_BOOLEAN)
        query_lang = xapian.Query(xapian.Query.OP_VALUE_RANGE, MODEL_DOC_LANG, self.selected_language, self.selected_language)
        query = xapian.Query(xapian.Query.OP_AND, query_search, query_lang)
        if self.searchform.allsources == False:
            query_sources = xapian.Query(xapian.Query.OP_VALUE_RANGE, MODEL_DOC_SOURCEID, '1', '1')
            query = xapian.Query(xapian.Query.OP_AND, query, query_sources)

        logging.debug("Setting query: %s" % query.get_description())

        enquire = xapian.Enquire(db)
        enquire.set_query(query)

        self.component.run_and_display(enquire, self.selected_language, db, self.searchform.progressbar)

    def clear_results(self):
        self.component.clear_results()
        self.searchform.progressbar.set_fraction(0.0)
        self.searchform.progressbar.set_text('Ready')

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
