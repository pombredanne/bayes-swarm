#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# Licensed under the GNU General Public License v2.

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

class MMMainFrame(gtk.VBox):
    def __init__(self, component):
        gtk.VBox.__init__(self)

        self.resultbox = gtk.VBox(False, 0)
        self.searchform = MMSearchForm()
        self.component = component
        self.component.ui = self.component.ui(self.resultbox, self.searchform)

        self.pack_start(self.resultbox, True, True, 0)
        self.pack_start(self.searchform, False, False, 0)

    def refresh_results(self, search_options):
        stemmer = xapian.Stem(search_options['selected_language'])

        if search_options['selected_localdb']:
            db = xapian.Database(search_options['selected_db'])
        else:
            db_host, port = search_options['selected_localdb'].split(':')
            db = xapian.remote_open(db_host, int(port))

        qp = xapian.QueryParser()
        qp.set_stemmer(stemmer)
        qp.set_database(db)
        qp.set_stemming_strategy(xapian.QueryParser.STEM_SOME)

        date_processor = xapian.DateValueRangeProcessor(MODEL_DOC_DATE)
        qp.add_valuerangeprocessor(date_processor)

        # FIXME: handle xapian.QueryParserError, xapian.NetworkTimeoutError
        # show error message in statusbar, user should be able to clear search with 'stop'
        query_search = qp.parse_query(search_options['entry_text'], xapian.QueryParser.FLAG_BOOLEAN)
        query_lang = xapian.Query(xapian.Query.OP_VALUE_RANGE, 
                                  MODEL_DOC_LANG, 
                                  search_options['selected_language'], 
                                  search_options['selected_language'])
        query = xapian.Query(xapian.Query.OP_AND, query_search, query_lang)
        if search_options['allsources'] == False:
            for i, id in enumerate(search_options['selected_sources']):
                if i == 0:
                    query_sources = xapian.Query(xapian.Query.OP_VALUE_RANGE, MODEL_DOC_SOURCEID, id, id)
                else:
                    query_source_id = xapian.Query(xapian.Query.OP_VALUE_RANGE, MODEL_DOC_SOURCEID, id, id)
                    query_sources = xapian.Query(xapian.Query.OP_OR, query_sources, query_source_id)
            query = xapian.Query(xapian.Query.OP_AND, query, query_sources)

        #logging.debug("Setting query: %s" % query.get_description())

        enquire = xapian.Enquire(db)
        enquire.set_query(query)

        search_options['enquire'] = enquire
        search_options['db'] = db

        self.component.run_and_display(search_options,
                                       self.searchform.progressbar)

    def clear_results(self):
        self.component.clear_results()

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
      <separator/>
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

        self.w = gtk.Window()
        self.w.connect('destroy', self.quit_cb)
        self.w.set_size_request(700, 600)

        vbox = gtk.VBox(False, 0)

        # Create a UIManager instance
        self.uimanager = gtk.UIManager()
        self.merge_id = 0        
        # Add the accelerator group to the toplevel window
        accelgroup = self.uimanager.get_accel_group()
        self.w.add_accel_group(accelgroup)

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

        self.w.add(vbox)
        self.w.show_all()
        gtk.main()

    def new_tab(self, component):
        child = MMMainFrame(component)
        child.show_all()
        child.searchform.advancedbox.hide()

        #self.w.set_default(child.searchform.start_button) #FIXME: doesn't work
        
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

        current_searchform = self.notebook.get_nth_page(self.notebook.get_current_page()).searchform
        self.actiongroup.add_toggle_actions([('ToggleAdvancedBox%i' % component.id, 
                                              gtk.STOCK_PREFERENCES,
                                              '_Advanced options', 
                                              '<Control>a',
                                              'Show advanced options', 
                                              current_searchform.toggle_show_advancedbox)])

#    def on_page_added(self, notebook, child, page_num):
#        pass

    def switch_page(self, notebook, page, page_num):
        active_component = notebook.get_nth_page(page_num).component
        logging.debug('Selecting page %i (%s)' % (page_num, active_component.name))

        # remove any previous left addictional actions
        if self.merge_id:
            self.uimanager.remove_ui(self.merge_id)
            self.merge_id = 0
        
        if active_component.has_additional_actions:
            # set additional actions if present and common actions
            # FIXME: common actions should be entirely handled here and not inside each
            # component
            self.merge_id = active_component.set_uimanager_for_additional_actions(self.uimanager)
        else:
            # set only common actions
            self.merge_id = self.uimanager.add_ui_from_string(self.common_action_ui % ('ToggleAdvancedBox%i' % active_component.id))

    def quit_cb(self, b):
        logging.info("Quitting Mean-Machine")
        gtk.main_quit()
