# = Test : ActiveRecord No-Op
# A simple component designed to verify that
# the ActiveReport bindings are working properly. Run with
#
#   ruby runner.rb -c swarm_shoal_options.yml -f test/arnoop
#
# If everything is fine, it should print the list of pages stored in
# the database
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the Apache2 License.

require 'util/log'
require 'util/ar'
require 'bayes/ar'

include Pulsar::Log
include Pulsar::AR

with_connection do
  Page.find(:all).each { |page| log "#{page.kind_name} #{page.url}" }
end