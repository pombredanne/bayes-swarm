# = Test : No-Op
# A simple component designed to verify that
# the Runner and component system are setup properly. Run with
#
#   ruby runner.rb -c swarm_shoal_options.yml -f test/noop
#
# If everything is fine, it should just print a log line saying +NoOp.+
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the GNU General Public License v22 License.

require 'util/log'

include Pulsar::Log

log "NoOp."