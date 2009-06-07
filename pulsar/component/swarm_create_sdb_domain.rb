# = Bayes : SimpleDB Domain creator
# A simple script to create an Amazon SDB Domain.
#
# Run with
#
#   ruby runner.rb -c swarm_shoal_options.yml \
#       -f component/swarm_create_sdb_domain -d <domain_name>
#
# See swarm_mysql_to_sdb.rb for more information about the way Bayes-Swarm
# uses Amazon SDB.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2009 - bayes-swarm project.
# Licensed under the GNU General Public License v2.

require 'right_aws'
require 'util/log'

include Pulsar::Log

domain = get_opt("-d")
log "Opening SDB Connection"
sdb_opts = Pulsar::Runner.opts['sdb']
sdb = RightAws::SdbInterface.new(sdb_opts[:access_key], sdb_opts[:secret_key])
sdb.create_domain domain
log "Created domain #{domain}"
