Bayes-Swarm's aim is to spider web sources (news portals, blogs and online newspapers) and extract correlations between such sources.

The engine will search correlations both in space (correlation among different sources) and time (correlation between the contents of a same source in different instant of times). Probabilistic theory and bayesian model will be used to extract such correlations.

The engine will extract relevant informations from correlation analysis, such as quantitative measurement of difference in opinions among sources which deal with the same argument.

![![](http://bayes-swarm.googlecode.com/svn/images/bayes-swarm_com_20080125_small.png)](http://bayes-swarm.googlecode.com/svn/images/bayes-swarm_com_20080125.png) ![![](http://bayes-swarm.googlecode.com/svn/images/bayes-swarm_com_20080125_obama_small.png)](http://bayes-swarm.googlecode.com/svn/images/bayes-swarm_com_20080125_obama.png) ![![](http://bayes-swarm.googlecode.com/svn/images/bayes-swarm_com_20080125_obama2_small.png)](http://bayes-swarm.googlecode.com/svn/images/bayes-swarm_com_20080125_obama2.png) ![![](http://bayes-swarm.googlecode.com/svn/images/bayes-swarm_com_20080125_uselections_small.png)](http://bayes-swarm.googlecode.com/svn/images/bayes-swarm_com_20080125_uselections.png)

### Architecture ###
The [Architecture](Architecture.md) document describes the architecture used by the **bayes-swarm** engine.

### Environment Setup ###
The first thing you need to do is to setup your pc to properly work with the project sources. You can follow the instructions described in EnvironmentSetup .

You can then populate it with some data from the FreeDataset , following the instructions on DatabaseSetup.

### Engines ###
Once your pc is ready, you can start trying some of our extraction and analyze engines. Here follows the list of available ones :

  * [Pulsar](Pulsar.md) : the version that implements the [Architecture](Architecture.md) design, and is currently running daily in our production environment.
  * [MeanMachine](MeanMachine.md) : a next-gen subproject that consists in indexing the Bayes-Swarm pagestore with the Xapian library.

The following are **obsolete** ones:
  * PrototypeOne : the very first approach to page data extraction. No longer in use since November 2008
  * PrototypeTwo : an ETL structured way to data extraction. Not active, some concepts have been merged into Pulsar.
Their source code has been removed from the main trunk and now lives in the [release0.3](http://code.google.com/p/bayes-swarm/source/browse/#svn/tags/release-0.3) svn tag.

The following are proposed designs for future components:
  * [Quasar](Quasar.md) : next generation visualization frontend to explore the bayes-swarm datacube.

### Data Simulation ###
**Obsolete** : The TestSupport page describes the available resources to simulate data, instead of effectively extracting them.

## Live demo ##
You can try a live demo at http://www.bayes-swarm.com/