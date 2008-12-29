#!/usr/bin/python
# -*- coding: UTF-8 -*-

# Licensed under the Apache2 License.

__copyright__ = 'BayesFor Association'
__author__    = 'Matteo Zandi <matteo.zandi@bayesfor.eu>'

from math import exp
import gtk
import igraph
from igraphdrawingarea import IGraphDrawingArea

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

        vbox.pack_start(self.igraph_drawing_area, True, True, 0)
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
        vbox.pack_start(table, False, True, 0)
        
        box.add(vbox)

    def display(self, distances_list):
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

        fixed = [False for i in range(len(sizes)-1)]
        fixed.append(True)
        g.vs['fixed'] = fixed

        g.vs['fr_seed_coords'] = g.layout_circle()

        self.g = g

        self.cb_threshold_changed(None)

    def cb_threshold_changed(self, adj):
        # keep only edges where weight > threshold
        g2 = self.g - self.g.es.select(weight_lt=log_scale(self.adj.value))
        
        # keep only non isolated vertex
        # g3 = g2.subgraph(g2.vs.select(_degree_gt=0))
        
        # keep only vertex where size > threshold
        g3 = g2.subgraph(g2.vs.select(size_gt=log_scale(self.adj2.value)))

        self.igraph_drawing_area.change_graph(g3)
