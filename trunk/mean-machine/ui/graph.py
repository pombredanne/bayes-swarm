#!/usr/bin/python
# -*- coding: UTF-8 -*-

# Licensed under the Apache2 License.

__copyright__ = 'BayesFor Association'
__author__    = 'Matteo Zandi <matteo.zandi@bayesfor.eu>'

from math import exp
import gtk
import igraph
from igraphdrawingarea import IGraphDrawingArea
from selectdialog import MMSelectDialog

import logging
format = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
logging.basicConfig(level=logging.DEBUG, format=format)
logging = logging.getLogger('ui.graph')

def log_scale(x):
    return (exp(x)-1)/(exp(1)-1)

class MMResultGraph():
    def __init__(self, box, searchform):
        vbox = gtk.VBox(False, 0)
        vbox.set_border_width(6)
        
        self.adj = gtk.Adjustment(0.50, 0, 1, 0.01, 0.1, 0)
        self.slider = gtk.HScale(self.adj)
        self.slider.set_digits(2)

        self.adj2 = gtk.Adjustment(0.50, 0, 1, 0.01, 0.1, 0)
        self.slider2 = gtk.HScale(self.adj2)
        self.slider2.set_digits(2)

        self.adj.connect("value_changed", self.cb_threshold_changed)
        self.adj2.connect("value_changed", self.cb_threshold_changed)
        
        self.igraph_drawing_area = IGraphDrawingArea()
        #self.cb_threshold_changed(self.adj)

        hbox_buttons = gtk.HBox(True, 0)
        self.filter_checkbutton = gtk.CheckButton("Filter vertex manually")
        self.filter_checkbutton.connect("toggled", self.on_filter_checkbutton_changed)
        self.isolated_button = gtk.CheckButton("Show only not-isolated vertex")
        self.isolated_button.connect("toggled", self.cb_threshold_changed)
        hbox_buttons.pack_start(self.filter_checkbutton, False, True, 0)
        hbox_buttons.pack_end(self.isolated_button, False, True, 0)
        
        table = gtk.Table(2, 2, False)
        table.set_row_spacings(6)
        table.set_col_spacings(12)
        # child, left_attach, right_attach, top_attach, bottom_attach, xoptions=gtk.EXPAND|gtk.FILL, yoptions=gtk.EXPAND|gtk.FILL, xpadding=0, ypadding=0)
        label1 = gtk.Label("Edge weight")
        label1.set_alignment(0, 0.5)
        table.attach(label1, 0, 1, 0, 1, gtk.FILL)
        table.attach(self.slider, 1, 2, 0, 1)
        label2 = gtk.Label("Vertex size")
        label2.set_alignment(0, 0.5)
        table.attach(label2, 0, 1, 1, 2, gtk.FILL)
        table.attach(self.slider2, 1, 2, 1, 2)
        
        vbox.pack_start(self.igraph_drawing_area, True, True, 0)
        vbox.pack_start(table, False, True, 0)
        vbox.pack_start(hbox_buttons, False, False, 0)
        
        box.add(vbox)

    def display(self, distances_list, terms):
        labels_id = {}
        labels = []
        edges = []
        weights = []
        sizes = []

        count = 0
        for i, row in enumerate(distances_list):
            w = 1/float(row[2])
            keyword1 = row[0]
            keyword2 = row[1]
            if not labels_id.has_key(keyword1):
                labels_id[keyword1] = count
                labels.append(keyword1)
                sizes.append(float(row[3]))
                count += 1
            if not labels_id.has_key(keyword2):
                labels_id[keyword2] = count
                labels.append(keyword2)
                sizes.append(float(row[4]))
                count += 1
            edges.append((labels_id[keyword1], labels_id[keyword2]))
            weights.append(w)

        g = igraph.Graph(edges, directed=False)
        min_w = min(weights)
        max_w = max(weights)    
        g.es['weight'] = [(i - min_w) / float(max_w - min_w) for i in weights]
        g.vs['label'] = labels

        min_size = min(sizes)
        max_size = max(sizes)
        g.vs['size'] = [(i - min_size) / float(max_size - min_size) for i in sizes]

        g.vs['is_term'] = [False for l in labels] # FIXME: how do you set an attribute for all vertex?
        for term in terms:
            v = g.vs.select(label_eq=term)
            if len(v) == 1: 
                v['color'] = ['blue']
                v['is_term'] = [True]

        #fixed = [False for i in range(len(sizes)-1)]
        #fixed.append(True)
        #g.vs['fixed'] = fixed

        g.vs['fr_seed_coords'] = g.layout_circle()

        self.g = g

        self.cb_threshold_changed(None)

    def cb_threshold_changed(self, adj):
        # keep only edges where weight > threshold
        g = self.g - self.g.es.select(weight_lt=log_scale(self.adj.value))
        
        # keep only vertex where size > threshold
        g = g.subgraph(g.vs.select(size_gt=log_scale(self.adj2.value)))
        
        self.terms_list = []
        for v in g.vs:
            self.terms_list.append([v['label'], v['label']])

        if self.filter_checkbutton.get_active():
            # remove unchecked terms
            g = g.subgraph(g.vs.select(label_in=self.selected_terms))

        if self.isolated_button.get_active():
            # remove non isolated vertex (except terms)
            g = g - g.vs.select(_degree_eq=0, is_term_eq=False)
        
        self.changed_graph = g
        self.igraph_drawing_area.change_graph(g)

    def on_filter_checkbutton_changed(self, widget):
        if widget.get_active():
            # open list
            try:
                already_selected_terms = self.selected_terms
                d = MMSelectDialog('Terms', self.terms_list, already_selected_terms)
            except:
                d = MMSelectDialog('Terms', self.terms_list, None)
            
            if d.run() == gtk.RESPONSE_CANCEL:
                #logging.debug('User canceled terms selection dialog, unchecking filter checkbutton')
                widget.set_active(0)
            else:
                if d.return_id_list == []:
                    #logging.debug('User selected None, unchecking filter checkbutton')
                    widget.set_active(0)
                elif len(d.return_id_list) == len(self.terms_list):
                    #logging.debug("User selected all sources, selecting 'all'")
                    widget.set_active(0)
                else:
                    #logging.debug('User selected sources: %s' % ', '.join(d.return_id_list))
                    self.selected_terms = d.return_id_list
        else:
            # do nothing, checkbutton state is enough
            pass
        
        # refresh visualization
        self.cb_threshold_changed(None)

    def clear(self):
        self.igraph_drawing_area.change_graph(None)

    def export(self):
        dialog = gtk.FileChooserDialog(title='Save as..', action=gtk.FILE_CHOOSER_ACTION_SAVE,
                                        buttons=(gtk.STOCK_CANCEL,gtk.RESPONSE_CANCEL,gtk.STOCK_SAVE,gtk.RESPONSE_OK))
        dialog.set_default_response(gtk.RESPONSE_OK)

        response = dialog.run()
        if response == gtk.RESPONSE_OK:
            f = dialog.get_filename()
            try:
                self.changed_graph.write(f)
                logging.info('%s saved' % f)
            except IOError, e:
                logging.error(e)
                message = 'Error: %s\n\nIf you specified and invalid format, use one of the following extensions:\n\n%s' % (e, '\n'.join(igraph.Graph._format_mapping.keys()))
                errordialog = gtk.MessageDialog(dialog, type=gtk.MESSAGE_ERROR,                
                                       buttons=gtk.BUTTONS_CLOSE, message_format=message)
                errordialog.run()
                errordialog.destroy()
        elif response == gtk.RESPONSE_CANCEL:
            pass
        dialog.destroy()
        
