# Introduction #

This document describes how to setup a copy of the bayes-swarm data on your machine in a local MySql database.
Follow the instructions in EnvironmentSetup to install the MySql database engine on your machine first.

If you are one of the bayes-swarm developers you can install one of the daily database backups from the www.bayes-swarm.com website. Otherwise, you can use the data in the FreeDataset .

A rough definition of the database structure is in EntityRelationShipDiagram.

# Detailed Instructions #

Once you have downloaded a dump of the database on your local machine, follow these instructions ( they are thought for Mac Os, but similar instructions apply for Linux and Windows as well ).

### Database tuning ###

Before starting the database, you may have to tune its settings, given the size of the bayes-swarm dataset. You have to edit the `my.cnf` configuration file for MySql.  Start by using the `my-large.cnf` template.

```
sudo cp /usr/local/mysql/support-files/my-large.cnf /etc/my.cnf
```

now edit the `/etc/my.cnf` file and uncomment the following innodb options ( as recommended [here](http://dev.mysql.com/doc/refman/5.0/en/innodb-tuning.html) ) :
```
innodb_buffer_pool_size = 256M
innodb_additional_mem_pool_size = 20M
innodb_log_file_size = 64M
innodb_log_buffer_size = 8M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50
```

You can now start the database engine:
```
sudo /usr/local/mysql/bin/mysqld_safe
```

and verify that the settings have been loaded properly :
```
/usr/local/mysql/bin/mysqld --verbose --help | grep innodb
```

( once finished working with MySql, you can stop it with `sudo /usr/local/mysql/bin/mysqladmin shutdown` ).

### Import data ###
First of all, create the a database instance that will contain the data ( I assume you are using the default credentials for a locally installed MySql. Update them if you changed your installation details ) :
```
echo "create database bayesswarm022 ;" | /usr/local/mysql/bin/mysql -u root
```

Download the database dump (either from the daily backups, if you have access to them, or from the FreeDataset ) and rename it to `swarm_dump_pre.sql` . Before importing it, you have to add some optimization options, otherwise the import will take ages :

```
echo "SET FOREIGN_KEY_CHECKS=0;" >> swarm_dump.sql
echo "SET UNIQUE_CHECKS=0;" >> swarm_dump.sql
cat swarm_dump_pre.sql >> swarm_dump.sql
echo "SET UNIQUE_CHECKS=1;" >> swarm_dump.sql
echo "SET FOREIGN_KEY_CHECKS=1;" >> swarm_dump.sql
```

You are now ready to import the data :
```
/usr/local/mysql/bin/mysql -u root bayesswarm022 < swarm_dump.sql
```

After some time, depending on your machine capabilities, the `bayesswarm022` database will contain all the bayes-swarm data.

If you want to access the data from the Rails application that is part of the bayes-swarm project, you also have to create the test user that the application uses to access the data. To do so, execute the statements contained in this file:

http://code.google.com/p/bayes-swarm/source/browse/trunk/db/schema_users.sql

Happy coding !

# I need only the schema informations #
If you don't need all the data, but only the schema informations for the database, you can always find the latest ones here:

http://code.google.com/p/bayes-swarm/source/browse/trunk/db/schema_latest.sql