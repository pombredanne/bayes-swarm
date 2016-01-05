# Introduction #

Prototype1 is an early technology preview about data extraction from webpages.

# Requirements #

Prototype1 depends on :
  * Ferret : a search library / indexer / stemmer for the ruby language
  * Tidy : a markup cleaner for HTML pages
  * ActiveRecord : to interact with the database where extracted data is stored.

# How it works #
Prototype1 works as follows :
  * extracts web page contents from the URL passed as parameter
  * cleans the content fixing up invalid markup with tidy
  * strips html tags and entities
  * performs stemming of the remaining words (the page content)
  * returns the most frequent stems ( this is what Prototype1 considers the 'page relevant informations' ) and/or interesting stems ( stems that have been pre-selected by a human being ) if available
  * optionally stores the contents of the webpage for future reference.

# Stemmer details #
section to be completed

# File Storage #
See FileStorage for further info.

# Test cases #
Works well with wikipedia pages (high content cohesion, minimun garbage and noise)
Works bad with newspapers (low content cohesion) or general purpose sites (lots of noise)

# Improvements #
Consider other ways to perform content extraction : identify html headers and / or content positioning within the page.
Consider removal of 'context-words' ( such as 'news', 'newspaper', 'article' for an online news site ) and keep only 'rare' words.