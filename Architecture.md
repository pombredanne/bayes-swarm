**NOTE** : this document describes the actual state of the engine, codenamed [Pulsar](Pulsar.md).

# Phases #

**Bayes-Swarm** divides  the process of analyzing web sources into different phases. Each phase is handled by a different component :

  * **Extraction** : during this phase, contents are extracted from the web and stored in their native format, without  any further processing.
  * **Storage** : this phase is intermixed with the previous one and collects all the operations required to stored the spidered contents into a form which is as close to the original documents as possible.
  * **Refinement** : after the storage phase, multiple refinement phases can occur. Each refinement phase is responsible for analyzing, consolidating and elaborate the raw data extracted to provide projections and analytics on all or parts of the data. For example, one of the refinements phases is the consolidation of the spidered data into a relational database to simplify access from a web application.
  * **Publication** : the publication phase is responsible for publicating the refined data and make them generally available in various forms ( websites, graphs, reports ).

# Components #

The bayes-swarm engine is structured in terms of modular components :
  * **Extractor** ( SwarmWave ) : the extractor is responsible for navigating through the web and store the relevant pages locally. SwarmWave is the codename for the extractor and you'll find it referenced with this name through the code.
  * **PageStore** : PageStore is the component, file format and filesystem structure responsible for storing the raw extracted data. Read some [technical details](FileStorage.md).
  * Refiners : we currently have two refiners that analyze and consolidate data stored in the PageStore: the first one, SwarmShoal, is responsible for reducing and consolidating the raw data into a mysql database. The amount of information stored is limited (we basically keep only the words' count for each word found in the raw data ) and it is mainly used by the website. The second refiner, called **MeanMachine** and currently under development by Matteo Zandi, applies search and indexing criterias on the raw data.
  * **Database** : a Mysql database is used to store a normalized version of the raw data, and is accessed by the Bayes-Swarm website.
  * Bayes-Swarm **website** : the [bayes-swarm website](http://www.bayes-swarm.com) provides a publicly accessible version of the stored data, and allows user to extract timeseries and other simple charts from the data.
  * **TimeMachine** : TimeMachine is a particular feature of the website that talks directly to the PageStore and allows users to see raw webpages in the exact form they were when originally spidered by the engine.
  * additional analyzers : additional or specialized analyzers are usually written in R and developed for specific purposes or to perform on-demand analysis on the data. They are eventually translated into ruby and released to the public once their reach the required maturity status.

# Technical Details #

We are currently using the following technologies to keep bayes-swarm up and running.

## Database ##
The database of choice is [MySql](http://www.mysql.com/) .

The production version is 4.1.22, but locally we use 5.x, since our design does not leverage any feature specific for version 5.

You may want to use some database management tool to work with it. We suggest [DBVisualizer](http://www.minq.se/products/dbvis/) , or [MySql GUI Tools](http://dev.mysql.com/downloads/gui-tools/5.0.html) .

## Backend engines and web site ##
The engine which performs data extraction, initial analysis and database storage is written in [ruby](http://www.ruby-lang.org/en/).
In addition to ruby, you may require some additional libraries, therefore you should also install the [rubygems](http://rubygems.org/) packaging system.

The website is currently powered by [Ruby on Rails](http://www.rubyonrails.org/) .

The project relies on the following gems, in addition to the ones provided by the standard library:
  * Hpricot
  * Mechanize
  * Ferret

A good introduction to ruby is Rolling with Ruby on Rails (revisited)
http://www.onlamp.com/pub/a/onlamp/2005/01/20/rails.html

## Analysis Engine ##
In addition to code written in **ruby**, the language of choice for prototypes and additional analysis is [R](http://www.r-project.org/), wich provides, among other nice things like time series and cluster analysis, [RMySQL](http://cran.r-project.org/src/contrib/Descriptions/RMySQL.html) an interface to MySql databases.

## MeanMachine ##

MeanMachine is developed in **python** and relies on additional libraries, such as the [Xapian](http://xapian.org/) indexing library and [PyGTK](http://www.pygtk.org/) GUI library.