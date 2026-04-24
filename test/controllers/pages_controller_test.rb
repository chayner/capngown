require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "GET /welcome renders" do
    get welcome_url
    assert_response :success
  end

  test "root redirects to /start" do
    get root_url
    assert_redirected_to "/start"
  end
end
