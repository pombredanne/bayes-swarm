#!/usr/bin/env python

import os
import tempfile

import matplotlib
from matplotlib.backends.backend_agg import FigureCanvasAgg
from matplotlib.figure import Figure
from matplotlib.dates import DateFormatter
from pylab import xticks, num2date, subplot, plot

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
              'figure.figsize': (4,3)}
    matplotlib.rcParams.update(params)

    fig = Figure()
    # add an axes at left, bottom, width, height; by making the bottom
    # at 0.3, we save some extra room for tick labels
    ax = fig.add_axes([0.1, 0.1, 0.85, 0.8]) #ie set sides of chart box

    # extract data from passed arg
    for var in data:
        (label, dates, values) = var
        line,  = ax.plot(dates, values, markerfacecolor='g',label=label, linewidth=2)

    ax.legend(loc = 'best') #stick in a legend
    # add some text decoration
    ax.set_title('Stems time series')
    ax.set_ylabel('Average counts on selected pages')

    # Convert date numbers to strings and show them
    # return locs, labels where locs is an array of tick locations and
    # labels is an array of tick labels.
    locs = ax.get_xticks()
    labels_date = []
    for loc in locs:
        labels_date.append(num2date(loc))
    ax.set_xticklabels(labels_date)

    yearsFmt = DateFormatter('%Y-%m-%d')
    ax.xaxis.set_major_formatter(yearsFmt)

    canvas = FigureCanvasAgg(fig)

    # now let's handle the temp file stuff and print the output
    tempfilenum,tempfilename=tempfile.mkstemp(suffix='.png') #function print_figure below requires a suffix
    canvas.print_figure(tempfilename, dpi=150)
    imagefile=file(tempfilename,'rb')

    # image_buffer = "Content-type: image/png\n"
    imagefile.seek(0)
    image_buffer = imagefile.read()
    imagefile.close()
    os.close(tempfilenum) #close what tempfile.mkstemp opened
    os.remove(tempfilename) #clean up by removing this temp file

    return image_buffer

def plotmultiscatter(data):
    """ make a multi-scatter chart

    data is a list of 2-tuples containing for each variable:
    - label
    - values (list of values)

    plotmultiscatter will take care of making a 2-side table out of
    the passed list
    """

    params = {'backend': 'Agg',
              'axes.titlesize': 8,
              'axes.labelsize': 6,
              'axes.linewidth': 0.5,
              'text.fontsize': 6,
              'xtick.labelsize': 6,
              'ytick.labelsize': 6,
              'legend.fontsize': 6,
              'figure.figsize': (4,3)}
    matplotlib.rcParams.update(params)

    fig = Figure()
    # add an axes at left, bottom, width, height
    # save some extra room for main label and tick labels
    #ax = fig.add_axes([0.1, 0.1, 0.85, 0.8])

    n_vars = len(data)
    plot_num = 0
    for i, x_var in enumerate(data):
        (x_label, x_dates, x_values) = x_var
        for j, y_var in enumerate(data):
            #if i!=j:
            (y_label, y_dates, y_values) = y_var
            plot_num += 1
            scat = fig.add_subplot(n_vars, n_vars, plot_num)

            # match only points wich belong to the same date
            x_values_dict = {}
            for i, date in enumerate(x_dates):
                x_values_dict[date] = x_values[i]

            y_values_dict = {}
            for i, date in enumerate(y_dates):
                y_values_dict[date] = y_values[i]

            x_values_intersect, y_values_intersect = [], []
            for date in y_values_dict:
                if x_values_dict.has_key(date):
                    x_values_intersect.append(x_values_dict[date])
                    y_values_intersect.append(y_values_dict[date])

            scatter,  = scat.plot(x_values_intersect, y_values_intersect, 'o', markerfacecolor='g')
            scat.set_xlabel(x_label)
            scat.set_ylabel(y_label)
            # no legenda, togli i ticks e tutto il resto

    canvas = FigureCanvasAgg(fig)

    # now let's handle the temp file stuff and print the output
    tempfilenum,tempfilename=tempfile.mkstemp(suffix='.png') #function print_figure below requires a suffix
    canvas.print_figure(tempfilename, dpi=150)
    imagefile=file(tempfilename,'rb')

    # image_buffer = "Content-type: image/png\n"
    imagefile.seek(0)
    image_buffer = imagefile.read()
    imagefile.close()
    os.close(tempfilenum) #close what tempfile.mkstemp opened
    os.remove(tempfilename) #clean up by removing this temp file

    return image_buffer
