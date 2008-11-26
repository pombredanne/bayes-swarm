require File.dirname(__FILE__) + '/../test_helper'
require 'featured_controller'

# Re-raise errors caught by the controller.
class FeaturedController; def rescue_action(e) raise e end; end

class FeaturedControllerTest < Test::Unit::TestCase
  def setup
    @controller = FeaturedController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
