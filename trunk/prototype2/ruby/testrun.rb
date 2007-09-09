require 'rubygems'
require 'etl/runner'
require 'etl/mysql'
require 'etltest'

$-v = true
e = ETLRunner.new("etl_sample.yml")
e.run