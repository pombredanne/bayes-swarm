# Introduction #

After the initial experiments with PrototypeOne and PrototypeTwo, [Pulsar](Pulsar.md) represents the latest implementation of the bayes-swarm [Architecture](Architecture.md). It defines the component model that is used to extract and analyze the data spidered from the web.

## Code Location ##

Pulsar code is located in [svn/trunk/pulsar](http://code.google.com/p/bayes-swarm/source/browse/#svn/trunk/pulsar).

## Details ##

Pulsar code is structured on the concept of **components**. A component is an execution unit in the bayes-swarm processing chain. For example, the extractor that spiders the web and saves the data in a local filesystem is a component.

The code is divided into the following folders and files:

  * **runner.rb** : the 'main' file. It bootstraps pulsar and executes components. It is driven by command-line parameters and an options file
  * **swarm\_shoal\_options.yml** : the default YAML file that contains configuration data accessed by components (such as database credentials and filesystem locations)
  * **component/** : contains the actual components that can be executed, such as SwarmWave and SwarmShoal.
  * **util/** : utility classes and shared code that it is used by the components (e.g.: logging, active record bindings etc ...)
  * **test/** : test classes and stubs
  * **bayes/** : code specific to the bayes-swarm needs, such as the actual ActiveRecord classes tailored for the bayes-swarm database.

## Development of a new component ##

To develop a new component, start by copying one of the stubs into the components folder:
```
cd pulsar/
cp test/noop.rb component/myNewComponent.rb
```

You can either use **test/noop.rb** or **test/arnoop.rb** as stubs respectively for components that respectively do not access the database, or access it via ActiveRecord.

When developing a component, you write code just like in any ruby script. It will be executed from top to bottom by **runner.rb** when you execute it. As an example you can check the [swarm\_wave](http://code.google.com/p/bayes-swarm/source/browse/trunk/pulsar/component/swarm_wave.rb) component.

## Execution ##

Once your component is finished, you can execute it with the following command:
```
cd pulsar/
ruby runner.rb -c optionsFile.yml -f myComponent
```

For example:
```
cd pulsar/
ruby runner.rb -c swarm_shoal_options.yml -f test/noop
```

(notice the missing _.rb_ extension from the component name.

## Components ##

The following main components are actually defined:
  * **SwarmWave** : this is the web spider, responsible for navigating websites, extracting their contents and saving them locally. It supports plain web pages and rss feeds. It stores the spidered data on a filesystem using a specific structure, described in FileStorage.
  * **SwarmShoal** : it analyzes the contents in the FileStorage and creates a relational database structure suitable for word analysis ( see EntityRelationShipDiagram ). It performs various operations to increase the quality of the information retrieval: stemming, elimination of stop-words, identification of words and their relative importance in the  webpage ( titles, links, headings ... ). It uses a back-propagation mechanism, enriching the list of tracked words depending on their abundance in analyzed pages.