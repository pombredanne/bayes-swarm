This document describes the entity-relationship schema that stores the data extracted from websites. The following entities are defined :

  * Source : a source can be associated with a website, or more generally, a place that hosts a number of pages
  * Pages : a page is a document which collects words. A page belongs to a source
  * Words : a word is a token extracted from a page. It can be a dictionary word or a stem, depending on the type of lexical analysis performed during the extraction phase. A word has a weight which describes its relevance within the page.
  * Associations : an association is a link between two words. An association has an associated weight which describes the strength of the association (for example it may refer to the distance-in-words between two words in a paragraph )

![http://bayes-swarm.googlecode.com/svn/images/database_schema.png](http://bayes-swarm.googlecode.com/svn/images/database_schema.png)

The complete database schema is available on SVN,  [following this lik](http://bayes-swarm.googlecode.com/svn/trunk/db/schema_latest.sql) .