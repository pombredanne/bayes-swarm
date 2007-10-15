# = ETL Utilities : Database management
# This file is part of the ETL package. It contains general purpose utilities related
# to database management, Data Access Objects (DAO) and database interfacing in general
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.
require 'mysql'
require 'etl/util/log'

# A module that can be included in classes to enrich them with database management methods
module DatabaseHelper
  include Log
  
  # Opens a connection to the database. It both returns it and stores it the class variable <tt>@conn</tt>
  # This method reads parameters both from arguments list and from the <tt>@props</tt> Hash. Arguments list
  # takes precedence. The relevant keys to be used as params are +host+ , +user+ , +pass+ , +db+ .
  def open_connection(params = {})
    params ||= @props
    @conn = Mysql.real_connect(params["host"],params["username"],params["password"],params["database"])
  end
  
  # Closes the database connection. This method can be safely invoked multiple times.
  def close_connection
    @conn.close if @conn
    @conn = nil
  end
  
  # Executes the block passed as parameter with an open connection to the database. The connection
  # is passed as block parameter. The connection opening happens in the same way as the <tt>open_connection</tt>
  # method. Connection is always closed at the end of this call.  
  def with_connection(params={})
    begin
      conn = open_connection(params)
      yield conn
    rescue Mysql::Error => me
      log "Mysql Error: #{me}"
      raise me
    rescue Exception => e
      log "Generic Error: #{e}"
      raise e
    ensure
      close_connection
    end
  end

end