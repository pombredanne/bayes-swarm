# = UnitTest : ActiveRecord - JSON interaction
# This file is part of the unit tests for the ETL package
#
# == Description
# The tests in this file verify interactions between ActiveRecord and JSON 
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.
#

require 'test/unit'
require 'json'
require 'dto/ardto'
require 'etl/util/ar'

class TestArJson < Test::Unit::TestCase
  include ARHelper
  
  def setup
    open_connection :adapter => 'mysql' , :host => 'localhost' , :username => 'root' , :database => 'swarm_development'
  end
  
  def teardown
    close_connection
  end
    
  # Verifies serialization to JSON and restore of a single AR entity
  def test_ar_read_and_serialize
    s = Source.find(1)
    assert_not_nil(s)
    
    s_json = JSON.generate(s)
    
    assert_match(/json_class/,s_json)
    assert_match(/Source/,s_json)

    s2 = JSON.parse(s_json)
    assert_equal(s2.class.name,Source.name)
  end
  
  # Verifies serialization to JSON and restore of a hierarchy of AR entities
  def test_ar_read_with_childs
    s = Source.find(1)
    assert_not_nil(s)
    
    s_json = JSON.generate(s)
    assert_match(/\"json_class\":\"Page\"/,s_json)
    
    s2 = JSON.parse(s_json)
    assert_equal(s2.class.name,Source.name)
    assert s2.pages.length > 0 
    assert !s2.pages[0].new_record?
    # p s2
    # s2.pages[0].last_scantime = Time.now
    # s2.pages[0].url = "new_url"
    # p s2
    # 
    # s2.pages[0].save
  end
  
end 