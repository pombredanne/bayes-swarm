require 'rubygems'
require 'etl/runner'

# $-v = true
e = ETLRunner.new("etl_sample.yml")
e.run