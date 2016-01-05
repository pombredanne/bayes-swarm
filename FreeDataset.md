**NOTE**: the db and pagestore structure underwent some changes in **November 2008**. Some issues may arise when importing the data linked in this page, as they are a bit stale.

**TODO**: update the free dataset with a more recent snapshot

# Introduction #

The [BayesFor](http://www.bayesfor.eu) association has been using the code from this project to analyze and spider various web sources ( mostly to monitor media agencies and newspapers ) since late 2007.

While the source code for the spider and the website to browse through the data is open source, the spidered data themselves are not public.

However, a part of the spidered data is available for free, to allow users to explore them and get started more easily with the bayes-swarm development. In addition, the free dataset allows you to experiment with new visualizations and data mining techniques. If you want to contribute them back, feel free to contact us at info@bayesfor.eu

# What is in the dataset #
The dataset contains part of the sources spidered in the month of **January 2008** . It contains sources in multiple languages ( italian, english ).

The sources are organized in two packages :
  * the raw spidered sources ( known as **PageStore** ) for the month of January 2008
  * a consolidated MySql database that contains aggregated information calculated from the raw data.

See the [Architecture](Architecture.md) document to understand the role played by these two components.

# Where can I get the dataset #

**Important**: The free dataset is no longer available since the shutdown of the [Bayes-Swarm](http://www.bayes-swarm.com) project.

# How to install it on my machine #

See the instructions in DatabaseSetup. If you want to contribute to bayes-swarm and not only navigate through the dataset, you may want to follow the instructions for EnvironmentSetup as well.