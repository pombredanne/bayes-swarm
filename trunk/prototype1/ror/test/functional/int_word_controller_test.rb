require File.dirname(__FILE__) + '/../test_helper'
require 'int_word_controller'

# Re-raise errors caught by the controller.
class IntWordController; def rescue_action(e) raise e end; end

class IntWordControllerTest < Test::Unit::TestCase
  def setup
    @controller = IntWordController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
