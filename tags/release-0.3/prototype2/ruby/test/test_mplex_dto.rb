# = UnitTest : Multiplex DTOs
# This file is part of the unit tests for the ETL package
#
# == Description
# The tests in this file verify the correct functioning of multiplex dtos, both 
# lazy and not. 
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
require 'dto/mplex'
require 'etl/mplex'

class TestMplexDto < Test::Unit::TestCase
  
  def setup
    @context = {}
  end
  
  def teardown
    @context = nil
  end
    
  def test_mplex_dto
    mockup = MockupMultiplexETL.new
    mockup.extract("mockupdto",@context)
    
    assert_equal MultiplexDTO , @context[:dto].class
    assert_equal 0, @context[:dto].execpointer
    
    count = 0
    while (@context[:dto].cur) do
      count += 1
      @context[:dto].increment_exec(nil)
    end
    
    assert_equal 3 , count
  end
  
  def test_lazy_mplex_dto
    mockup = LazyMockupMultiplexETL.new
    mockup.extract("mockupdto",@context)
    
    assert_equal LazyMultiplexDTO , @context[:dto].class
    assert_equal 0 , @context[:dto].execpointer
    
    count = 0
    while (@context[:dto].cur) do
      count += 1
      curdto = @context[:dto].cur
      curdto.i -= 1
      @context[:dto].increment_exec(curdto)
    end
    
    assert_equal 0 , mockup.test_support_dto.i
    assert_equal 2 , mockup.test_support_dto.next.next.i
  end
  
end

class MockupMultiplexETL
  include MultiplexETL
  
  def mplex(dto,context)
    dtos = []
    3.times { dtos << "#{dto}"}
    return dtos
  end
end

class LazyDTO
  
  attr_accessor :i

  def initialize(i,nextdto)
    @i = i
    @nextdto = nextdto
  end
  
  def next
    @nextdto
  end
  
  def adjust(dto)
    @i = dto.i
  end
end

class LazyMockupMultiplexETL
  include MultiplexETL
  
  attr_accessor :test_support_dto
  
  def mplex(dto,context)
    nxt = nil
    dto = nil
    5.downto(1) { |i| dto = LazyDTO.new(i,nxt) ; nxt = dto }
    @test_support_dto = dto
    return dto
  end
  
end
