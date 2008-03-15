# = UnitTest : ActiveRecord
# This file is part of the unit tests for the ETL package
#
# == Description
# The tests in this file verify the correct definition of the ActiveRecord relationships
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2007 - bayes-swarm project.
# Licensed under the Apache2 License.
#
require 'test/unit'
require 'etl/util/ar'
require 'plugins/bayes_ardto'

class TestAr < Test::Unit::TestCase
  include ARHelper
  
  def setup
    open_connection :adapter => 'mysql' , :host => 'localhost' , :username => 'root' , :database => 'swarm_development'
  end
  
  def teardown
    close_connection
  end
    
  def test_hierarchy
    s = Source.find(1)
    assert_not_nil s
    
    assert_equal 3 , s.pages.length
    
    p = s.pages.find(1)
    assert_equal "http://news.google.com" , p.url
    
    assert_equal "eng" ,  p.language.language
    assert_equal "url" ,  p.kind.kind
    
    assert_equal 2 , p.words.length
    
    w = p.words.find(1)
    assert_equal 1 , w.count
    
    iw = IntWord.find(w.id)
    assert_equal "china" , iw.name
    
  end
  
end