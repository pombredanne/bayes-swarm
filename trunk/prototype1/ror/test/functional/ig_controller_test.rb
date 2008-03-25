require File.dirname(__FILE__) + '/../test_helper'
require 'ig_controller'

# Re-raise errors caught by the controller.
class IgController; def rescue_action(e) raise e end; end

class IgControllerTest < Test::Unit::TestCase
  def setup
    @controller = IgController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
