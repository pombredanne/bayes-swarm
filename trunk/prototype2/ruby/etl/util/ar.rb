# = ETL Utilities : ActiveRecord management
# This file is part of the ETL package. It contains general purpose utilities related
# to the ActiveRecord framework.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.

require 'active_record'
require 'etl/util/log'

module ARHelper
  include Log
  
  # Opens a connection to the database. It does not return it (if needed, connections can be retrieved
  # directly from ActiveRecord entries).
  # This method reads parameters both from arguments list and from the <tt>@props</tt> Hash. Arguments list
  # takes precedence. The relevant keys to be used as params are +adapter+, +host+ , +username+ , +password+ , +database+ .
  def open_connection(params = {})
    ActiveRecord::Base.establish_connection(params)
  end
  
  # Closes the database connection. This method can be safely invoked multiple times.
  def close_connection
    ActiveRecord::Base.clear_active_connections!
  end
  
  # Executes the block passed as parameter with an open connection to the database and closes it at the
  # end of the blocks
  def with_connection(params={})
    begin
      open_connection(params)
      conn = ActiveRecord::Base.connection
      yield conn
    rescue ActiveRecordError => e
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