require 'test_helper'

class PricesControllerTest < ActionDispatch::IntegrationTest
  test "should get edit" do
    get prices_edit_url
    assert_response :success
  end

end
