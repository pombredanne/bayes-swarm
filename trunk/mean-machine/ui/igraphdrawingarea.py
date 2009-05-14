#!/usr/bin/env python
# 
# Mean Machine: subclass gtk.DrawingArea in order to plot a graph
#
# == Author
# Matteo Zandi [matteo.zandi@bayesfor.eu]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the GNU General Public License v22 License.
# USA

import gtk
from gtk import gdk
import cairo
import igraph

class IGraphDrawingArea(gtk.DrawingArea):
    def __init__(self):
        gtk.DrawingArea.__init__(self)
        #self.set_size_request(300, 300)
        self.connect("expose_event", self.expose)
        self.g = None

    def expose(self, widget, event):
        context = widget.window.cairo_create()

        # set a clip region for the expose event
        context.rectangle(event.area.x, event.area.y,
                          event.area.width, event.area.height)
        context.clip()
        self.draw(context)

        return False

    def draw(self, context):
        rect = self.get_allocation()
        context.set_source_rgb(255, 255, 255)
        
        # FIXME: leave blank background while adding igraph plot
        if self.g is not None:
            surface = cairo.ImageSurface (cairo.FORMAT_ARGB32,
                            rect.width,
                            rect.height)

            plot = igraph.drawing.Plot(surface, (0, 0, rect.width, rect.height))
            seed_layout = self.g.layout("fr", seed = self.g.vs['fr_seed_coords'])
            plot.add(self.g, layout=seed_layout, margin=(20,20,20,20), weights = self.g.es['weight'], vertex_size=[s * 20 + 7 for s in self.g.vs['size']]) #, fixed = self.g.vs['fixed'])
            plot.redraw()
            
            context.set_source_surface (surface)
        context.paint()
        
        return False

    def redraw_canvas(self):
        if self.window:
            alloc = self.get_allocation()
            rect = gdk.Rectangle(0, 0, alloc.width, alloc.height)
            self.window.invalidate_rect(rect, True)
            self.window.process_updates(True)

    def change_graph(self, g):
        self.g = g
        self.redraw_canvas()
