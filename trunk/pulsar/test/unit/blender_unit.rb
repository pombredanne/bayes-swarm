# = Test : Blender
# A unit test for the BayesBlender, which is complex enough to
# require a dedicated effort to get it right.
#
# Refer to test/unittests.rb on how to run unit tests.
#
# == Author
# Riccardo Govoni [battlehorse@gmail.com]
#
# == Copyright
# Copyright(c) 2008 - bayes-swarm project.
# Licensed under the GNU General Public License v2.

require 'test/unit'

require 'bayes/blender'

class BayesBlenderTest < Test::Unit::TestCase
  
  def setup
    @intword_hash = { "use" => 1 }      # stemming of 'USEFUL'
  end
  
  # Verifies that the main blender functions works properly, by trying
  # the whole system. This test excludes popular words
  def test_dismember_no_popular
    b = Pulsar::BayesBlender.new(@intword_hash)
    
    b.dismember("USEFUL " * 2, :en, :body, 5)
    
    interesting = b.get_interesting_stems
    assert interesting.size == 1
    assert interesting[0].stem = 'use'
    assert interesting[0].id = 1
    assert interesting[0].count = 2
    assert interesting[0].page_area.include?(:body)
    assert interesting[0].area_count[:body] == 2
    
    assert b.get_popular_stems.size == 0
  end
  
  # Verifies that the main blender functions works properly, by trying
  # the whole system and including popular words
  def test_dismember_no_popular
    b = Pulsar::BayesBlender.new(@intword_hash)
    
    b.dismember("Language " * 10, :en, :body, 5)
    
    assert b.get_interesting_stems.size == 0

    popular = b.get_popular_stems
    assert popular.size == 1
    assert popular[0].stem = 'languag'
    assert_nil popular[0].id
    assert popular[0].count = 10
    assert popular[0].page_area.size == 0
    assert popular[0].area_count.size == 0    
  end
  
  # Verifies two differents StemData objects are not blended together
  def test_blend_different_keys
    b =  Pulsar::BayesBlender.new(nil)
    
    global_hash = Hash.new
    sd1 = create_stemdata("hello", 10, 1, :title)
    sd2 = create_stemdata("another", 20, 2, :title)
    
    b.blend(global_hash, [ sd1, sd2 ]) { |stemdata| stemdata.id }
    
    assert global_hash.size == 2
    
    assert_not_nil global_hash[1]
    assert_not_same global_hash[1], sd1
    
    assert_not_nil global_hash[2]
    assert_not_same global_hash[2], sd2    

    assert global_hash[1].page_area.include?(:title)
    assert global_hash[1].count == 10
    assert global_hash[1].area_count[:title] == 10
    
    assert global_hash[2].page_area.include?(:title)
    assert global_hash[2].count == 20
    assert global_hash[2].area_count[:title] = 20
  end
  
  # Verifies that when two StemData objects share the same key, they
  # are blended together and their counters are summed.
  def test_blend_same_keys_merge_counters
    b =  Pulsar::BayesBlender.new(nil)
    
    global_hash = Hash.new
    sd1 = create_stemdata("hello", 10, 1, :title)
    sd2 = create_stemdata("hello", 20, 1, :anchors)
    
    b.blend(global_hash, [ sd1, sd2 ]) { |stemdata| stemdata.id }
    
    assert global_hash.size == 1
    
    assert_not_nil global_hash[1]
    assert_not_same global_hash[1], sd1
    assert_not_same global_hash[1], sd2    

    assert global_hash[1].page_area.include?(:title)
    assert global_hash[1].page_area.include?(:anchors)    
    assert global_hash[1].count == 30
    assert global_hash[1].area_count[:title] = 10
    assert global_hash[1].area_count[:anchors] = 20  
  end
  
  # Verifies that it is possible to customize the stem key
  def test_blend_use_stem_as_key
    b =  Pulsar::BayesBlender.new(nil)
    
    global_hash = Hash.new
    sd1 = create_stemdata("hello", 10, 1, :title)
    sd2 = create_stemdata("hello", 20, 1, :anchors)
    
    b.blend(global_hash, [ sd1, sd2 ]) { |stemdata| stemdata.stem }
    
    assert global_hash.size == 1
    
    assert_not_nil global_hash["hello"]
    assert global_hash["hello"].page_area.include?(:title)
    assert global_hash["hello"].page_area.include?(:anchors)    
    assert global_hash["hello"].count == 30
    assert global_hash["hello"].area_count[:title] = 10
    assert global_hash["hello"].area_count[:anchors] = 20
  end
  
  # Verifies that it is possible to use the blender even with plain
  # StemData ( without area counts and divisions )
  def test_blend_use_stemdata_without_areas
    b =  Pulsar::BayesBlender.new(nil)
    
    global_hash = Hash.new
    sd1 = Pulsar::StemData.new("hello", 10, 1)
    
    b.blend(global_hash, [ sd1 ]) { |stemdata| stemdata.id }
    
    assert global_hash.size == 1
    
    assert_not_nil global_hash[1]
    assert global_hash[1].page_area.size == 0
    assert global_hash[1].count == 10
    assert global_hash[1].area_count.size == 0
  end
    
  def create_stemdata(stem, count, id, area)
    sd = Pulsar::StemData.new(stem, count, id)
    sd.page_area = Set.new
    sd.page_area << area
    sd.area_count = { area => count}
    return sd
  end
  
end
