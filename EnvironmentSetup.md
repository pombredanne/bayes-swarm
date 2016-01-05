Please, spend some seconds reading the [Architecture](Architecture.md) document before.

# Software Requirements #
You need the following softwares and elements to get started on the project :

  * a relational database, [MySql](http://www.mysql.com/) ( version 5 or later ) is recommended.
  * a [ruby](http://www.ruby-lang.org/en/) interpreter. We are currently using version 1.8.6 or later
  * the [rubygems](http://rubygems.org/) packaging system, to install the additional required libraries
  * optionally, the [R](http://www.r-project.org/) environment if you want to perform extra analyses on the data. You may want to consider the [RMySQL](http://cran.r-project.org/src/contrib/Descriptions/RMySQL.html) library to connect R directly with the MySql database.
  * the FreeDataset, a publicly available version of the bayes-swarm dataset, that you can use to get started with bayes-swarm development. See DatabaseSetup for info on how to setup such dataset.

# Install Instructions #

## Linux: Ubuntu ##

### MySql ###
Install mysql with apt-get:
```
sudo apt-get install mysql-server-5.0 mysql-client-5.0
```

### Ruby ###
Install ruby, rubygems and the required gems (the list shown below is incomplete):

```
sudo apt-get install ruby irb ri rdoc ruby1.8-dev rubygems tidy
sudo gem update --system
sudo gem install rails
sudo gem install ferret
sudo gem install hpricot
sudo gem install mechanize
...
```

mysql/ruby bindings :
```
sudo apt-get install libmysql-ruby1.8
```

### R ###
```
sudo apt-get install r-base
```

**warning**: you need to use R commands to install RMySql package (http://cran.r-project.org/src/contrib/Descriptions/RMySQL.html)

## Mac Os X ##

### MySql ###
Download one of the available MySql packages for Mac Os X directly from the www.mysql.com website . Install it by double-clicking on the package and following the onscreen instructions.

### Ruby ###
You may follow this guide to set up your ruby / mysql environment :
  * Mac Os 10.4 : http://hivelogic.com/articles/2007/02/ruby-rails-mongrel-mysql-osx
  * Mac Os 10.5 : http://hivelogic.com/articles/2008/02/ruby-rails-leopard

Once you have installed ruby and rubygems, you should have the binaries installed in `/usr/local/bin` . You can then update your installation to the most recent version and install the required libraries :

```
sudo gem update --system
sudo gem install rails
sudo gem install ferret
sudo gem install hpricot
sudo gem install mechanize
```

### R ###
To install R, just use the official dmg provided at http://www.r-project.org/ .

## Windows ##
**TODO** : this section is still missing.

# Database Setup #
Now that your local development environment is ready, you can populate it with the FreeDataset . You can tune your Mysql installation using the instructions in DatabaseSetup .

# Source code checkout #
bayes-swarm uses [Subversion](http://subversion.tigris.org) to manage the source code for the project. Once you have installed subversion on your machine, you can download a copy of the source code executing the following command from the command line of your OS:

```
svn checkout http://bayes-swarm.googlecode.com/svn/trunk/ bayes-swarm
```

It will create a folder named `bayes-swarm` which will contain all the project sources.