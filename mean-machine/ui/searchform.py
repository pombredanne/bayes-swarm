#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# Licensed under the GNU General Public License v2.

__copyright__ = 'BayesFor Association'
__author__    = 'Matteo Zandi <matteo.zandi@bayesfor.eu>'

import gtk
from selectdialog import MMSelectDialog

import xapian
import logging
logging = logging.getLogger('ui.searchform')

MODEL_DOC_LANG, MODEL_DOC_HASH, MODEL_DOC_DATE, MODEL_DOC_DIR, MODEL_DOC_SOURCEID, MODEL_DOC_SOURCE = range(6)
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
        #self.entry.set_activates_default(True) #FIXME: doesn't work

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
        self.model_db.append(['/Users/matteozandi/Development/pagestore/parisi_120201_xap', 0, True, FLAG_DB_NOT_CHECKED])
        self.model_db.append(['/home/matteo/Development/pagestore/parisi_120201_xap', 0, True, FLAG_DB_NOT_CHECKED])
        self.model_db.append(['/Users/matteozandi/Dropbox/xap_db', 0, True, FLAG_DB_NOT_CHECKED])
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
        self.filterterms_checkbutton = gtk.CheckButton("Set ESet white list")
        self.advancedbox.pack_start(self.filterterms_checkbutton, False, False, 0)
        self.showqueryterms_checkbutton = gtk.CheckButton("Include query terms in ESet")
        self.advancedbox.pack_start(self.showqueryterms_checkbutton, False, False, 0)
        
        # assign self.selected_language, self.selected_localdb
        self.search_options = {}
        self.on_lang_selected(self.combobox)
        self.on_dblocal_changed(self.combobox_dblocal)

        self.entry.connect('changed', self.on_entry_changed)
        self.combobox.connect('changed', self.on_lang_selected)
        self.combobox_dblocal.connect('changed', self.on_dblocal_changed)
        self.comboboxentry_db.connect('changed', self.on_db_selected)
        self.comboboxentry_db.child.connect('changed', self.on_db_manually_entered)
        self.combobox_sources.connect('changed', self.on_combobox_sources_changed)
        self.start_button.connect('clicked', self.on_start_button_clicked)
        self.connect_button.connect('clicked', self.on_connect_button_clicked)
        self.filtered_model_db.set_visible_func(self.visible_dbs_cb)
        self.filtered_model_db.refilter()
        self.filterterms_checkbutton.connect("toggled", self.on_filterterms_checkbutton_changed)
        self.showqueryterms_checkbutton.connect("toggled", self.on_showqueryterms_checkbutton_changed)

        # assign self.db, self.sources_list, self.allsources
        self.on_db_selected(self.comboboxentry_db, self.search_options['selected_localdb'])
        self.on_combobox_sources_changed(self.combobox_sources)
        self.on_mset_entry_changed(self.mset_entry)
        self.on_eset_entry_changed(self.eset_entry)
        self.on_filterterms_checkbutton_changed(self.filterterms_checkbutton)
        self.on_showqueryterms_checkbutton_changed(self.showqueryterms_checkbutton)
        
        vbox.pack_start(self.upperbox, False, False, 0)
        vbox.pack_start(self.advancedbox, False, False, 0)
        vbox.pack_start(lowerbox, False, False, 0)
        self.add(vbox)

    def clear_results(self):
        if self.get_parent() != None:
            self.get_parent().clear_results()

    def clear_progressbar(self):
        self.progressbar.set_fraction(0.0)
        self.progressbar.set_text('Ready')

    def on_entry_changed(self, entry):
        self.clear_progressbar()
        self.search_options['entry_text'] = entry.get_text()
        self.clear_results()

    def on_lang_selected(self, combobox):
        self.clear_results()
        model = combobox.get_model()
        index = combobox.get_active()
        self.search_options['selected_language'] = model[index][0]

    def visible_dbs_cb(self, model, iter):
        #logging.debug('Is db %s local? %s, therefore is db shown? %s' % (model.get_value(iter, MODEL_DB_URL), model.get_value(iter, MODEL_DB_IS_LOCAL), model.get_value(iter, MODEL_DB_IS_LOCAL) == self.search_options['selected_localdb']))
        return model.get_value(iter, MODEL_DB_IS_LOCAL) == self.search_options['selected_localdb']

    def on_dblocal_changed(self, combobox):
        self.clear_results()
        model = combobox.get_model()
        index = combobox.get_active()
        self.search_options['selected_localdb'] = model[index][0]
        if self.search_options['selected_localdb'] == True:
            logging.debug('Selecting local db')
        else:
            logging.debug('Selecting remote db')
        self.connect_button.set_sensitive(not self.search_options['selected_localdb']) # set sensitive only if remote selected
        self.filtered_model_db.refilter() # show only local/remote dbs in comboboxentry

        # Filter dbs according to what user selected
        model = self.comboboxentry_db.get_model()
        iter = model.get_iter_root()
        while (iter):
            # FIXME: this works only if one entry for each type (local, remote) is always present
            if model.get_value(iter, MODEL_DB_IS_LOCAL) == self.search_options['selected_localdb']:
                #print self.model_db.get_value(iter, MODEL_DB_URL)
                break
            iter = model.iter_next(iter)
        self.comboboxentry_db.set_active(model.get_path(iter)[0])

    def get_sources_list(self, db_url):
        if self.search_options['selected_localdb']:
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
            list.append([m.document.get_value(4), m.document.get_value(5)])
        return list
        #return [['1', 'quotidiani'], ['2', 'aggregatori'], ['3', 'pagine personali']]
        
    def is_db_valid(self, entered_db):
        # - returns True if db can be opened by Xapian
        # - changes image_connected
        try:
            logging.debug('Checking if db %s is valid' % entered_db)
            # FIXME: use self.db instead of db, so that we avoid repeating
            # the opening. use keep_alive if remote
            if self.search_options['selected_localdb']:
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
        except e:
            logging.error('Unknown error (%s)' % e)
            return False
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
            model.append([entered_db, 0, self.search_options['selected_localdb'], FLAG_DB_IS_VALID])

    def check_db_if_needed(self, combobox, do_check, entry=None):
        model = combobox.get_model()
        index = combobox.get_active()

        # if we're editing comboboxentry set MODEL_DB_IS_LOCAL = self.search_options['selected_localdb']
        if index == -1:
            if entry is not None:
                selected_db_is_local = self.search_options['selected_localdb']
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
        #logging.debug('index: %d, do_check: %s, selected_localdb: %s, is_local: %s' % (index, do_check, self.search_options['selected_localdb'], selected_db_is_local))
        if (do_check or self.search_options['selected_localdb']) and (selected_db_is_local == self.search_options['selected_localdb']):
            # check if db is valid and disable search button accordingly
            if self.is_db_valid(db_url):
                self.search_options['selected_db'] = db_url
                if index == -1:
                    self.add_db_to_model(self.model_db, db_url)
                else:
                    iter_filtered_model = model.get_iter((index,))
                    iter_full_model = model.convert_iter_to_child_iter(iter_filtered_model)
                    self.model_db.set_value(iter_full_model, MODEL_DB_VALIDITY, FLAG_DB_IS_VALID)
                self.search_options['sources_list'] = self.get_sources_list(self.search_options['selected_db'])
                self.set_all_controls_sensitive_except(True, combobox)
                self.set_image_connected(True)
            else:
                self.set_all_controls_sensitive_except(False, combobox)
                self.set_image_connected(False)
        else:
            self.set_all_controls_sensitive_except(False, combobox)
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
        self.check_db_if_needed(self.comboboxentry_db, do_check, entry)

    def on_start_button_clicked(self, button):
        self.set_sensitive(False)
        self.get_parent().refresh_results(self.search_options)
        self.set_sensitive(True)

    def set_image_connected(self, state):
        # state = True (connected), False (disconnected)
        tooltips = gtk.Tooltips()
        if state == True:
            self.image_connected.set_from_stock(gtk.STOCK_CONNECT, gtk.ICON_SIZE_MENU)
            tooltips.set_tip(self.image_connected, 'Connected')
        else:
            self.image_connected.set_from_stock(gtk.STOCK_DISCONNECT, gtk.ICON_SIZE_MENU)
            tooltips.set_tip(self.image_connected, 'Disconnected')

    def on_combobox_sources_changed(self, combobox):
        self.clear_results()
        model = combobox.get_model()
        index = combobox.get_active()
        self.search_options['allsources'] = model[index][0]
        if self.search_options['allsources'] == True:
            logging.debug('Selecting all sources')
        else:
            logging.debug('Selecting selected sources')
            
            try:
                already_selected_ids = self.search_options['selected_sources']
                d = MMSelectDialog('Sources', self.search_options['sources_list'], already_selected_ids)
            except:
                d = MMSelectDialog('Sources', self.search_options['sources_list'], None)
            
            if d.run() == gtk.RESPONSE_CANCEL:
                logging.debug('User canceled sources selection dialog')
                combobox.set_active(0)
            else:
                if d.return_id_list == []:
                    logging.debug('User selected None, selecting all sources')
                    combobox.set_active(0)
                elif len(d.return_id_list) == len(self.search_options['sources_list']):
                    logging.debug("User selected all sources, selecting 'all'")
                    combobox.set_active(0)
                else:
                    logging.debug('User selected sources: %s' % ', '.join(d.return_id_list))
                    self.search_options['selected_sources'] = d.return_id_list

    def on_connect_button_clicked(self, button):
        # TODO: set_sensitive(False) on remote/local combo + db combo
        # trigger db check (force avoidcheck as True)
        self.on_db_manually_entered(self.comboboxentry_db.child, True)

    def set_all_controls_sensitive_except(self, sensitivity, skipped_control):
        if sensitivity == False:
            self.progressbar.set_text('Error')
        else:
            self.progressbar.set_text('Ready')
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
            self.search_options['n_mset'] = int(entry.get_text())
            self.set_all_controls_sensitive_except(True, entry)
        except:
            self.set_all_controls_sensitive_except(False, entry)

    def on_eset_entry_changed(self, entry):
        try:
            self.search_options['n_eset'] = int(entry.get_text())
            self.set_all_controls_sensitive_except(True, entry)
        except:
            self.set_all_controls_sensitive_except(False, entry)

    def on_filterterms_checkbutton_changed(self, widget):
        if widget.get_active():
            # show file opener
            dialog = gtk.FileChooserDialog(title='Open eset white list..', 
                                           action=gtk.FILE_CHOOSER_ACTION_OPEN,
                                           buttons=(gtk.STOCK_CANCEL,gtk.RESPONSE_CANCEL,gtk.STOCK_OPEN,gtk.RESPONSE_OK))
            dialog.set_default_response(gtk.RESPONSE_OK)

            response = dialog.run()
            if response == gtk.RESPONSE_OK:
                filename = dialog.get_filename()
                try:
                    f = file(filename)
                except IOError, e:
                    logging.error(e)
                    message = 'Error while reading %s\n\n%s' % (f, e)
                    errordialog = gtk.MessageDialog(dialog, type=gtk.MESSAGE_ERROR,                
                                           buttons=gtk.BUTTONS_CLOSE, message_format=message)
                    errordialog.run()
                    errordialog.destroy()
                    widget.set_active(0)
                finally:
                    eset_white_list = []
                    for line in f:
                        if line.startswith('#'): continue
                        keys = line.split()
                        try:
                            eset_white_list.append(keys[0])
                        except IndexError:
                            continue
                    self.search_options['eset_white_list'] = eset_white_list
                    logging.info('%i terms loaded in eset white list' % len(eset_white_list))
            elif response == gtk.RESPONSE_CANCEL:
                widget.set_active(0)
            dialog.destroy()

        # double check and set as empty list if necessary
        if not widget.get_active():
            self.search_options['eset_white_list'] = []

    def on_showqueryterms_checkbutton_changed(self, widget):
        if widget.get_active():
            logging.debug('Include query terms in ESet')
            self.search_options['eset_showqueryterms'] = 1
        else:
            logging.debug('Exclude query terms in ESet')
            self.search_options['eset_showqueryterms'] = 0

    def toggle_show_advancedbox(self, action):
        if action.get_active()==False:
            self.advancedbox.hide()
        else:
            self.advancedbox.show()
