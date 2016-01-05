# Introduction #

**Quasar** is the design for the next generation bayes-swarm visualization frontend.

We want to overcome the current limitations in term of flexibility and scalability. The view we currently provide over the bayes-swarm dataset is too restricted, does not scale well and provides too few insights into the amount of data we have collected so far.

The goal is to provide a frontend service that:
  * exposes multiple dimensions of analysis on the bayes-swarm datacube,
  * is easily extensible to expose a new raw dimension or aggregated information (dataplane) to users,
  * adopts smart ACLs to define what part of the datacube a user can access and how much of it (some users may have access only to part of the data, while others may be able to see bigger chunks of the cube),
  * exports data in multiple formats/APIs, so that they can be embedded in third-party properties and client applications. The html frontend will only be one of the possible ways to explore the data,
  * supports monetization of the data we have collected.

# Details #

![http://bayes-swarm.googlecode.com/svn/images/quasar_model.png](http://bayes-swarm.googlecode.com/svn/images/quasar_model.png)

The above drawing shows the proposed structure for the frontend. It will be packaged as a Rails application.

The main sources of data will be the MySql database and the PageStore currently managed by [Pulsar](Pulsar.md). They collect both the raw crawled page data and calculated statistics and counters over the raw data.

A Rails Model layer will expose the primitives to access the data. Data aggregations will be performed at this level, so that everything that comes out of this layer is a ready-to-go visualization dataset. Each visualization request will be modeled as a specific method call to the Model layer.

The ACL layer will sit on top of this. It will dictate who can see what according to this signals:
  * user performing the request ( or guest if not authenticated )
  * specific data aggregation requested ( e.g. : time series, pie aggregation etc ... )
  * amount of data the user has already accessed in the current session / timeslot ( for data exposure throttling )
  * requesting source and format (e.g. : csv exports vs web views)

Data returned by the model will be exposed in multiple ways, to maximize interoperability. The following will be supported initially:
  * a [Google Visualization](http://code.google.com/apis/visualization/) Datasource. This is fundamental for 2 purposes. It allows us to reuse [dozens of existing visualizations](http://code.google.com/apis/visualization/documentation/gallery.html) and allows external third-parties to easily plug into our data sources. We simply cannot manually scale to the level that we can achieve by reusing GViz. Refer to the [GVizDatasource](http://code.google.com/apis/visualization/documentation/dev/implementing_data_source.html) document on how to expose custom data as a GViz datasource. It will become trivial to create dashboards over the bayes-swarm dataset.
  * an HTML frontend, suitable for web access, inspired the current bayes-swarm.com website. It will resemble a dashboard-like application, where users can define what aggregations and dataplanes visualize on their page, and customize their appearance. It will reuse the above source for its own visualizations.
  * eventually, a set of customized access APIs and formats, to expose the bayes-swarm dataset to custom and/or native applications (such as mobile ones).