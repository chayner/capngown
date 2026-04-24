require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "GET /welcome renders when signed in" do
    sign_in users(:volunteer)
    get welcome_url
    assert_response :success
  end

  test "root redirects to /start" do
    # Root is a redirect, so it doesn't go through authenticate_user!.
    get root_url
    assert_redirected_to "/start"
  end

  test "GET /welcome redirects to sign-in when signed out" do
    get welcome_url
    assert_redirected_to new_user_session_path
  end
end
