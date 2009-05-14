# = Utilities : ActiveRecord management
# Contains general purpose utilities related to the ActiveRecord framework.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the GNU General Public License v22 License.

require 'active_record'
require 'util/log'

module Pulsar
  
  # The AR module provide connection-based capalities to operate with an 
  # ActiveRecord framework with the bayes-swarm execution chain.
  module AR
    include Pulsar::Log
  
    # Opens a connection to the database. It does not return it (if needed, connections can be retrieved
    # directly from ActiveRecord entries).
    # This method reads parameters from the Runner global options.
    def open_connection
      db_opts = Pulsar::Runner.opts['database']
      @db_host = db_opts[:host]
      @db_user = db_opts[:user]
      @db_pass = db_opts[:pass]
      @db_name = db_opts[:db]

      ActiveRecord::Base.establish_connection(
        :adapter  => "mysql",
        :host     => @db_host,
        :username => @db_user,
        :password => @db_pass,
        :database => @db_name
      )
    end
  
    # Closes the database connection. This method can be safely invoked multiple times.
    def close_connection
      ActiveRecord::Base.clear_active_connections!
    end
  
    # Executes the block passed as parameter with an open connection to the database and closes it at the
    # end of the blocks
    def with_connection
      begin
        open_connection
        conn = ActiveRecord::Base.connection
        yield conn
      rescue ActiveRecord::ActiveRecordError => e
        log "ActiveRecord Error: #{e}"
        raise e
      rescue Exception => e
        log "Generic Error: #{e}"
        raise e
      ensure
        close_connection
      end
    end  

  end
end
