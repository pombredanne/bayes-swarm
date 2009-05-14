#!/usr/bin/python
# -*- coding: UTF-8 -*-

# Licensed under the GNU General Public License v2.

__copyright__ = 'BayesFor Association'
__author__    = 'Matteo Zandi <matteo.zandi@bayesfor.eu>'

import gtk

class MMSelectDialog:
    def __init__(self, name, sources_list, id_true_list=None):
        # sources_list = [['1', 'quotidiani'], ['2', 'aggregatori'], ['3', 'pagine personali']]
        # id_true_list = ['1', '2']
        #
        # if id_true_list is not passed, all sources are set as True, otherwise
        # they are set True only if id is found in id_true_list
        #
        # returns gtk.RESPONSE_OK or gtk.RESPONSE_CANCEL, if OK return_id_list 
        # contains ['2', '3'] which corresponds to the ids selected by user
        
        self.dialog = gtk.Dialog('%s list' % name,
            None,
            gtk.DIALOG_MODAL,
            (gtk.STOCK_OK, gtk.RESPONSE_OK, gtk.STOCK_CANCEL, gtk.RESPONSE_CANCEL))

        upper_vbox = gtk.VBox(False, 8)
        upper_vbox.set_border_width(5)
        
        l = gtk.Label()
        l.set_markup('<span weight="bold">%s</span>' % name)
        
        scrolledwin = gtk.ScrolledWindow()
        treeview = gtk.TreeView()
        scrolledwin.add(treeview)
        scrolledwin.set_policy(gtk.POLICY_NEVER, gtk.POLICY_AUTOMATIC)
        treeview.set_size_request(250, 300)
        treeview.set_headers_clickable(True)
        treeview.set_reorderable(True)

        upper_vbox.pack_start(l, expand=False, fill=False, padding=10)
        upper_vbox.pack_start(scrolledwin, expand=False, fill=False, padding=0)
        self.dialog.vbox.pack_start(upper_vbox)

        # model = id, name, checked
        self.model = gtk.ListStore(str, str, 'gboolean')
        treeview.set_model(self.model)
        
        #def set_cell_pb(column, cell, model, iter):
        #    if model[iter][1] == 0:
        #        pb = gtk.gdk.pixbuf_new_from_file_at_size(join(invest.ART_DATA_DIR, "invest-16_neutral.png"), -1,-1)
        #    else:
        #        pb = self.treeview.render_icon(stock_id=getattr(gtk, 'STOCK_DND'),
        #            size=gtk.ICON_SIZE_MENU,
        #            detail=None)
        #    cell.set_property('pixbuf', pb)

        #cell_pb = gtk.CellRendererPixbuf ()
        #column_description = gtk.TreeViewColumn (_("Type"), cell_pb)
        #column_description.set_cell_data_func(cell_pb, set_cell_pb)
        #self.treeview.append_column(column_description)
        
        toggle = gtk.CellRendererToggle()
        toggle.set_property('activatable', True)
        toggle.connect('toggled', self.on_toggle_toggled, self.model)
        column = gtk.TreeViewColumn("Selected", toggle)
        column.add_attribute(toggle, 'active', 2)
        treeview.append_column(column)

        cell = gtk.CellRendererText()
        column = gtk.TreeViewColumn("Name", cell)
        column.add_attribute(cell, 'text', 1)
        treeview.append_column(column)

        for id, name in sources_list:
            if id_true_list == None:
                self.model.append([id, name, True])
            else:
                if id in id_true_list:
                    self.model.append([id, name, True])
                else:
                    self.model.append([id, name, False])

    def on_toggle_toggled(self, cell, path, model):
        model[path][2] = not model[path][2]

    def run(self):
        self.dialog.show_all()
        res = self.dialog.run()
        self.dialog.destroy()
        
        if res != gtk.RESPONSE_CANCEL:
            self.return_id_list = []
            for i in self.model:
                if i[2] == True:
                    self.return_id_list.append(i[0])
        return res

if __name__ == "__main__":
    import xapian

    db = xapian.Database('/home/matteo/Development/pagestore/renzi_xap_20090101_sources')

    query = xapian.Query(xapian.Query.OP_VALUE_RANGE, 0, 'it', 'it')

    qp = xapian.QueryParser()
    qp.set_database(db)

    enquire = xapian.Enquire(db)
    enquire.set_query(query)

    enquire.set_collapse_key(4)

    mset = enquire.get_mset(0, 1000, 0)

    list = []
    for m in mset:
        list.append([m[xapian.MSET_DOCUMENT].get_value(4), m[xapian.MSET_DOCUMENT].get_value(5)])
    
    d = MMSelectDialog(list, ['1', '2'])

    if d.run() == gtk.RESPONSE_CANCEL:
        print 'cancelled'
    else:
        print 'ok'
        print d.return_id_list
