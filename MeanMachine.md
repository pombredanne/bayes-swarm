# Introduction #

Mean Machine is an experimental sub-project, named as the famous Sugar Ray's song, it allows to perform queries on the database and plot data accordingly.

# Details #

Before using the graphical frontend, data has to be indexed with the [Xapian](http://www.xapian.org) library, this can be performed with xapian\_index.rb script, found in our spidering library named [Pulsar](Pulsar.md).

**Xapian** not only saves which words belong to which text, but also their position in the text, this allows to patterns like "clinton NEAR health" or even more complex ones.

# Visualization #

There are currently two different components, which perform different plots.

## search ##
![![](http://bayes-swarm.googlecode.com/svn/images/mm_svn437_search_obama20080828_small.png)](http://bayes-swarm.googlecode.com/svn/images/mm_svn437_search_obama20080828.png)

The user can insert terms to be searched, as a result the most relevant documents are presented together with a cloud of the most relevant words. Clicking on the words allows to deepen the search and find the documents which match both words (to be precise the two terms are ORed, so documents which match both are given a higher score).

## graph ##
![![](http://bayes-swarm.googlecode.com/svn/images/mm_svn437_graph_obama_small.png)](http://bayes-swarm.googlecode.com/svn/images/mm_svn437_graph_obama.png) ![![](http://bayes-swarm.googlecode.com/svn/images/mm_svn437_graph_mccain-iraq_small.png)](http://bayes-swarm.googlecode.com/svn/images/mm_svn437_graph_mccain-iraq.png)

The user can insert terms to be searched, the program plots a graph of the most connected words, ie the words which are more likely found with what the user entered. By adjusting the two sliders, it is possible to include/exclude other terms according to their weight in the search or the strenght to which they are connected to others.

Graphs can be exported in different formats.

# What do I need to try it? #
  * [Mean-Machine](http://bayes-swarm.googlecode.com/files/mean-machine-r529.zip)
  * xapian indexed db ([sample db](http://bayes-swarm.googlecode.com/files/150italia.zip))
  * python
  * xapian library with python bindings
  * pygtk, [igraph](http://cneurocvs.rmki.kfki.hu/igraph/) (graph component)

## Ubuntu ##
Install xapian, its python bindings and igraph (enable Ubuntu repository from igraph homepage). Pygtk is already installed
```
sudo apt-get install python-xapian python-igraph
```

Get the source code
```
cd ~
svn checkout http://bayes-swarm.googlecode.com/svn/trunk/mean-machine mean-machine
```

Download and uncompress the [sample db](http://bayes-swarm.googlecode.com/files/150italia.zip)

Finally run it!
```
cd ~/mean-machine
python mean-machine.py
```

## Windows ##
Install python, pygtk, xapian and igraph:
  * [python](http://www.python.org/ftp/python/2.7.2/python-2.7.2.msi)
  * [pygtk](http://ftp.gnome.org/pub/GNOME/binaries/win32/pygtk/2.24/pygtk-all-in-one-2.24.2.win32-py2.7.msi)
  * [xapian](http://www.flax.co.uk/xapian/128/xapian-python-bindings%20for%20Python%202.7.0%20-1.2.8.win32.exe)
  * [igraph](http://pypi.python.org/packages/2.7/p/python-igraph/python-igraph-0.5.4.win32-py2.7.msi)

Uncompress [Mean-Machine](http://bayes-swarm.googlecode.com/files/mean-machine-r529.zip) and the [sample db](http://bayes-swarm.googlecode.com/files/150italia.zip), run it!

## OSX ##
The easiest way to install all the dependencies seems to be using macports, which itself requires xcode and other stuff:

- X11 should be already installed if have a recent system, otherwise check http://guide.macports.org/#installing.x11)

- Install Xcode tools http://guide.macports.org/#installing.xcode

- Install MacPorts http://guide.macports.org/#installing.macports

- Make sure the paths are configured in your shell profile http://guide.macports.org/#installing.shell
```
export PATH=/opt/local/bin:/opt/local/sbin:$PATH
```
List the available pythons to select from:
```
port select --list python
```

to choose a specific port (eg python27):
```
port select python python27
```

- install python, xapian, python-gtkhtml2, python-igraph
```
sudo port install xapian-bindings
sudo port install py27-gtkhtml2 py27-gtk
sudo port install py27-igraph
```

select xapian python bindings

```
sudo port -v install xapian-bindings +python27
```