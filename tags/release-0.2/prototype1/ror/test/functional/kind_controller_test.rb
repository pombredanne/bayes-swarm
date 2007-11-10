require File.dirname(__FILE__) + '/../test_helper'
require 'kind_controller'

# Re-raise errors caught by the controller.
class KindController; def rescue_action(e) raise e end; end

class KindControllerTest < Test::Unit::TestCase
  def setup
    @controller = KindController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
