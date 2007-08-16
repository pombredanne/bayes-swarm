#!/usr/bin/env python

import os
import tempfile

import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg
from matplotlib.figure import Figure

def plottimeseries(data):
    """ make a chart 
    
    data is a list of 3-tuples containing for each variable:
    - label
    - dates
    - values"""
    
    params = {'backend': 'Agg',
              'axes.titlesize': 8,
              'axes.labelsize': 6,
              'axes.linewidth': 0.5, 
              'text.fontsize': 6,
              'xtick.labelsize': 6,
              'ytick.labelsize': 6,
              'legend.fontsize': 6,
              'figure.figsize': (6,4)}
    matplotlib.rcParams.update(params)
    
    fig = Figure()
    # add an axes at left, bottom, width, height; by making the bottom
    # at 0.3, we save some extra room for tick labels
    ax = fig.add_axes([0.2, 0.3, 0.7, 0.6]) #ie set sides of chart box
    
    #now we make the plots
    for var in data:
        (label, dates, values) = var
        line,  = ax.plot(dates, values, markerfacecolor='g',label=label, linewidth=2)
    
    ax.legend(loc = 'best') #stick in a legend
    # add some text decoration
    ax.set_title('Stems time series')
    ax.set_ylabel('Average counts on selected pages')
    
    # FIXME: convert date numbers to strings and show them
    #ax.set_xticklabels([1, 2]) #set these the same as x input into plot
    #ax.set_yticklabels([1, 2])
    #labels = ax.set_xticklabels(('2006-01-01', '2006-01-15', '2006-02-01', '2006-03-01'))
    canvas = FigureCanvasAgg(fig)

    #now let's handle the temp file stuff and print the output
    tempfilenum,tempfilename=tempfile.mkstemp(suffix='.png') #function print_figure below requires a suffix
    canvas.print_figure(tempfilename, dpi=150)
    imagefile=file(tempfilename,'rb')
    
    #image_buffer = "Content-type: image/png\n"
    imagefile.seek(0)
    image_buffer = imagefile.read()
    imagefile.close()
    os.close(tempfilenum) #close what tempfile.mkstemp opened
    os.remove(tempfilename) #clean up by removing this temp file
    
    return image_buffer
