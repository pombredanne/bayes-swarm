#!/usr/bin/env python
# 
# Mean Machine: plot graphs of nearest terms obtained by a xapian
# search with bs-xapian-nearest.py
#
# == Author
# Matteo Zandi [matteo.zandi@bayesfor.eu]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the Apache2 License.
# USA

import sys
import csv
import igraph

import gtk
from igraphdrawingarea import IGraphDrawingArea

if len(sys.argv) == 2:
    PATH_TO_CSV_FILE = sys.argv[1]
else:
    print >> sys.stderr, "Usage: %s PATH_TO_CSV_FILE" % sys.argv[0]
    sys.exit(1)

class Demo():
    def __init__(self, g):
        window = gtk.Window()
        vbox = gtk.VBox(False, 0)
        
        adj = gtk.Adjustment(0.50, 0, 1, 0.01, 0.1, 0)
        adj.connect("value_changed", self.cb_value_changed)
        self.slider = gtk.HScale(adj)
        self.slider.set_digits(2)

        g2 = self.update_graph(g, adj.value)
        self.igraph_drawing_area = IGraphDrawingArea(g2)

        vbox.pack_start(self.igraph_drawing_area, True, True, 0)
        vbox.pack_start(self.slider, False, False, 0)
        
        window.add(vbox)
        window.connect("destroy", gtk.main_quit)
        window.show_all()

        gtk.main()

    def update_graph(self, g, threshold):
        # keep only edges where wheight > threshold
        g2 = g - g.es.select(weight_lt=threshold)
        # keep only non isolated vertex
        g3 = g2.subgraph(g2.vs.select(_degree_gt=0))
        return g3
        
    def cb_value_changed(self, adj):
        updated_graph = self.update_graph(g, adj.value)
        self.igraph_drawing_area.change_graph(updated_graph)

if __name__ == "__main__":
    labels_id = {}
    labels = []
    edges = []
    weights = []
    sizes = []

    count = 0
    r = csv.reader(open(PATH_TO_CSV_FILE,'r'))
    for i, row in enumerate(r):
        # skip first row which contains headers
        if i != 0:
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
    g.vs['sizes'] = [(i - min_size) / float(max_size - min_size) * 20 + 7 for i in sizes]
    
    fixed = [False for i in range(len(sizes)-1)]
    fixed.append(True)
    g.vs['fixed'] = fixed
    
    g.vs['fr_seed_coords'] = g.layout_circle()
    
    Demo(g)
