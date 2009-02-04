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
from selectdialog import MMSelectDialog
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
        self.component = component
        self.component.ui = self.component.ui(self.resultbox, self.searchform)

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
        self.searchform.combobox_sources.connect('changed', self.on_combobox_sources_changed)
        self.searchform.start_button.connect('clicked', self.on_start_button_clicked)
        self.searchform.connect_button.connect('clicked', self.on_connect_button_clicked)
        self.searchform.filtered_model_db.set_visible_func(self.visible_dbs_cb)
        self.searchform.filtered_model_db.refilter()

        # assign self.db, self.sources_list, self.allsources
        self.on_db_selected(self.searchform.comboboxentry_db, self.selected_localdb)
        self.on_combobox_sources_changed(self.searchform.combobox_sources)

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
            # FIXME: this works only if one entry for each type (local, remote) is always present
            if model.get_value(iter, MODEL_DB_IS_LOCAL) == self.selected_localdb:
                #print self.searchform.model_db.get_value(iter, MODEL_DB_URL)
                break
            iter = model.iter_next(iter)
        self.searchform.comboboxentry_db.set_active(model.get_path(iter)[0])

    def get_sources_list(self, db_url):
        if self.selected_localdb:
            db = xapian.Database(db_url)
        else:
            db_host, port = db_url.split(':')
            db = xapian.remote_open(db_host, int(port))
        query = xapian.Query(xapian.Query.OP_VALUE_RANGE, 0, 'a', 'z')
        qp = xapian.QueryParser()
        qp.set_database(db)
        enquire = xapian.Enquire(db)
        enquire.set_query(query)
        enquire.set_collapse_key(MODEL_DOC_SOURCEID)
        mset = enquire.get_mset(0, 100, 0)
        list = []
        for m in mset:
            list.append([m[xapian.MSET_DOCUMENT].get_value(4), m[xapian.MSET_DOCUMENT].get_value(5)])
        return list
        #return [['1', 'quotidiani'], ['2', 'aggregatori'], ['3', 'pagine personali']]
        
    def is_db_valid(self, entered_db):
        # - returns True if db can be opened by Xapian
        # - changes image_connected
        try:
            logging.debug('Checking if db %s is valid' % entered_db)
            # FIXME: use self.db instead of db, so that we avoid repeating
            # the opening. use keep_alive if remote
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
                self.sources_list = self.get_sources_list(self.selected_db)
                self.searchform.set_all_controls_sensitive_except(True, combobox)
                self.set_image_connected(True)
            else:
                self.searchform.set_all_controls_sensitive_except(False, combobox)
                self.set_image_connected(False)
        else:
            self.searchform.set_all_controls_sensitive_except(False, combobox)
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

    def on_combobox_sources_changed(self, combobox):
        self.clear_results()
        model = combobox.get_model()
        index = combobox.get_active()
        self.allsources = model[index][0]
        if self.allsources == True:
            logging.debug('Selecting all sources')
        else:
            logging.debug('Selecting selected sources')
            
            try:
                already_selected_ids = self.selected_sources
                d = MMSelectDialog('Sources', self.sources_list, already_selected_ids)
            except:
                d = MMSelectDialog('Sources', self.sources_list, None)
            
            if d.run() == gtk.RESPONSE_CANCEL:
                logging.debug('User canceled sources selection dialog')
                combobox.set_active(0)
            else:
                if d.return_id_list == []:
                    logging.debug('User selected None, selecting all sources')
                    combobox.set_active(0)
                elif len(d.return_id_list) == len(self.sources_list):
                    logging.debug("User selected all sources, selecting 'all'")
                    combobox.set_active(0)
                else:
                    logging.debug('User selected sources: %s' % ', '.join(d.return_id_list))
                    self.selected_sources = d.return_id_list

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
        if self.allsources == False:
            for i, id in enumerate(self.selected_sources):
                if i == 0:
                    query_sources = xapian.Query(xapian.Query.OP_VALUE_RANGE, MODEL_DOC_SOURCEID, id, id)
                else:
                    query_source_id = xapian.Query(xapian.Query.OP_VALUE_RANGE, MODEL_DOC_SOURCEID, id, id)
                    query_sources = xapian.Query(xapian.Query.OP_OR, query_sources, query_source_id)
            query = xapian.Query(xapian.Query.OP_AND, query, query_sources)

        logging.debug("Setting query: %s" % query.get_description())

        enquire = xapian.Enquire(db)
        enquire.set_query(query)

        self.component.run_and_display(enquire, 
                                       self.selected_language, 
                                       int(self.searchform.mset_entry.get_text()), 
                                       int(self.searchform.eset_entry.get_text()), 
                                       db, 
                                       self.searchform.progressbar)

    def clear_results(self):
        self.component.clear_results()
        self.searchform.progressbar.set_fraction(0.0)
        self.searchform.progressbar.set_text('Ready')

class MainMachine(object):
    ui = '''<ui>
    <menubar name="MenuBar">
      <menu action="File">
        <menuitem action="Quit"/>
      </menu>
      <menu action="Components">
      </menu>
    </menubar>
    <toolbar name="Toolbar">
      <placeholder name="Components">
      </placeholder>
      <separator/>
      <placeholder name="Common Actions">
      </placeholder>
      <separator/>
      <placeholder name="Additional Actions">
      </placeholder>      
      <toolitem action="Quit"/>
    </toolbar>
    </ui>'''
    
    component_ui = '''<ui>
    <menubar name="MenuBar">
      <menu action="Components">
        <menuitem action="%s"/>
      </menu>
    </menubar>
    <toolbar name="Toolbar">
      <placeholder name="Components">
        <toolitem action="%s"/>
      </placeholder>
    </toolbar>
    </ui>'''

    common_action_ui = '''<ui>
    <menubar name="MenuBar">
      <menu action="Components">
      </menu>
    </menubar>
    <toolbar name="Toolbar">
      <placeholder name="Common Actions">
        <toolitem action="%s"/>
      </placeholder>
    </toolbar>
    </ui>'''

    def __init__(self):
        logging.info("Starting Mean-Machine")
        self.components = get_components()

        w = gtk.Window()
        w.connect('destroy', self.quit_cb)
        w.set_size_request(700, 600)

        vbox = gtk.VBox(False, 0)

        # Create a UIManager instance
        self.uimanager = gtk.UIManager()
        self.merge_id = 0        
        # Add the accelerator group to the toplevel window
        accelgroup = self.uimanager.get_accel_group()
        w.add_accel_group(accelgroup)

        # Create an ActionGroup
        self.actiongroup = gtk.ActionGroup('MMUIManager')

        # Create actions
        self.actiongroup.add_actions([('Quit', gtk.STOCK_QUIT, '_Quit', None,
                                  'Quit the Program', self.quit_cb),
                                 ('File', None, '_File'),
                                 ('Components', None, '_Components')])
        self.actiongroup.get_action('Quit').set_property('short-label', '_Quit')

        # Add the actiongroup to the uimanager
        self.uimanager.insert_action_group(self.actiongroup, 0)
        # Add a UI description
        self.uimanager.add_ui_from_string(self.ui)
        # Create a MenuBar
        menubar = self.uimanager.get_widget('/MenuBar')
        vbox.pack_start(menubar, False)
        # Create a Toolbar
        toolbar = self.uimanager.get_widget('/Toolbar')
        vbox.pack_start(toolbar, False)

        self.new_component_id = 0
        for component_name, component_class in self.components.items():
            self.actiongroup.add_actions([(component_name, 
                                      gtk.STOCK_NEW, 
                                      '_' + component_name, 
                                      '<Control>%s' % component_name[0],
                                      component_class.description, 
                                      self.start_component_cb)])
            self.uimanager.add_ui_from_string(self.component_ui % (component_name, component_name))

        self.notebook = NotebookWithCloseButtonOnTabs()
        self.notebook.set_scrollable(True)
        self.notebook.set_property('homogeneous', True)
        self.notebook.connect('switch-page', self.switch_page)
#        self.notebook.connect('page-added', self.on_page_added)
        vbox.pack_start(self.notebook, True, True, 0)

        w.add(vbox)
        w.show_all()
        gtk.main()

    def new_tab(self, component):
        child = MMMainFrame(component)
        child.show_all()
        child.searchform.advancedbox.hide()

        # TODO: change tab label according to what user types in search
        tab_label = gtk.Label(component.name)
        tab_label.show()

        nbpages = self.notebook.get_n_pages()
        self.notebook.append_page(child, tab_label)
        self.notebook.set_current_page(nbpages)

    def start_component_cb(self, action):
        component = self.components[action.get_name()]()

        self.new_component_id += 1
        component.id = self.new_component_id
        self.new_tab(component)

        if component.has_additional_actions:
            logging.debug('Loading additional actions for %s component' % component.name)
            component.set_additional_actions(self.actiongroup)

        
#    def on_page_added(self, notebook, child, page_num):
#        pass

    def switch_page(self, notebook, page, page_num):
        active_component = notebook.get_nth_page(page_num).component
        logging.debug('Selecting page %i (%s)' % (page_num, active_component.name))

        # remove any previous left addictional actions
        if self.merge_id:
            self.uimanager.remove_ui(self.merge_id)
            self.merge_id = 0
        # set additional actions if present
        if active_component.has_additional_actions:
            self.merge_id = active_component.set_uimanager_for_additional_actions(self.uimanager)

    def quit_cb(self, b):
        logging.info("Quitting Mean-Machine")
        gtk.main_quit()
