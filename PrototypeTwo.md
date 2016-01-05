# Warning #

Prototype2 has been declared obsolete and it is **not** in active use for daily extractions. See PrototypeOne for further info. Ideas which have been tested in prototype2 have been declared not 100% useful for bayes-swarm. Some pieces have been reused for the development of [Pulsar](Pulsar.md) ( that implements the [Architecture](Architecture.md) design ).

**The source code and the documentation in this page remain here for consultation purposes, but are no longer maintained.**

# Introduction #

Prototype 2 is a structured approach to page data extraction. It models the extraction approach as a standard [ETL](http://en.wikipedia.org/wiki/Extract%2C_transform%2C_load) process .

## Extract Transform and Load ##

The page extraction process is divided into three phases ;

  * Extract : the data is unloaded from the remote web pages to be processed locally.
  * Transform : the data is, optionally, processed and cleaned (for example, this phase may discard non-relevant stopwords from the whole set of extracted words).
  * Load : the data is stored into the program database, or other sort of persistent storage

When we refer to data, we usually think about words and sentences found in the analyzed page.

The whole process is modular and composable. That is

  * you can define the whole process as a composition of different extractors, transformers and loaders .
  * Every single extractor, transformer and loader acts as a **module** of the process and exchanges data with other modules via standard [DTO](http://en.wikipedia.org/wiki/Data_Transfer_Object) recognized by all the modules.
  * Since modules are composable, different ETL paths may be built to analyize a single source in multiple ways.

### Extract ###
The Extract phase is responsible for unloading page data from the web. It is also responsible for the initial page cleaning which involves :

  * rebuild the webpage DOM
  * identify words and their positioning within the page (in headers, paragraphs, captions ... )
  * extract such words and associate them with a weight which describes their positioning ( headers are more important than simple paragraphs )

Since webpage analysis can become quite complex due to the very dynamic nature of today's websites, we choosed to use [Selenium](http://openqa.org/selenium-rc/) which allows us to reuse an existing browser (aka Firefox) and leverage all its parsing capabilities. We can then analyze the parsed DOM via XPath queries.

### Transform ###

Once the words have been extracted, we transform them to perform :

  * Stemming
  * Stop-word elimination

This happens in the same way of PrototypeOne , using Ferret.

### Load ###

The load phase simply dumps everything on the database.

## DTO ##

Extractors, transformers and loaders agree on the following DTO format to exchange data between themselves :

```
TODO - insert DTO format here
```

# Pros and Cons #

The proposed approach has several pros and cons :

  * Pros :
    * modular, parallelizable approach
    * easy replacement of a single module whenever a new technique arises
  * Cons :
    * using browser-guidance with Selenium reduces performances
    * it requires a GUI environment for a batch process, which could otherwise be executed on a headless server.

# Requirements #

  * [Selenium Remote Control](http://openqa.org/selenium-rc/) for the extract phase
  * [Ferret](http://ferret.davebalmain.com/trac/) for the transform phase
  * [Ruby/Mysql](http://dev.mysql.com/downloads/ruby.html) for the load phase