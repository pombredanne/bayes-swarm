# = UnitTest : JSON
# This file is part of the unit tests for the ETL package
#
# == Description
# The tests in this file verify the correct functioning of JSON mapping for
# special types such as Time and BigDecimal
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.
#

require 'test/unit'
require 'dto/dto'

class TestJSON < Test::Unit::TestCase
  
  def test_bigdecimal
    b = BigDecimal.new("1.125")
    b2 = JSON.parse(JSON.generate(b))
    
    assert_equal BigDecimal , b2.class
    assert_equal 1.125 , b2.to_f
  end
end