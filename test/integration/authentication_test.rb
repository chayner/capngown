require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  # Sweep over every protected route and confirm signed-out users are
  # redirected to the sign-in page.
  PROTECTED_GETS = %w[
    /start
    /list
    /print
    /get_print
    /show_bulk
    /welcome
    /graduates/stats
  ].freeze

  PROTECTED_GETS.each do |path|
    test "GET #{path} redirects to sign-in when signed out" do
      get path
      assert_redirected_to new_user_session_path,
        "Expected #{path} to require auth"
    end
  end

  test "PATCH /print redirects to sign-in when signed out" do
    patch "/print", params: { buid: graduates(:bob).buid }
    assert_redirected_to new_user_session_path
  end

  test "PATCH /bulk_print redirects to sign-in when signed out" do
    patch "/bulk_print", params: { buids: graduates(:bob).buid }
    assert_redirected_to new_user_session_path
  end

  test "valid sign-in succeeds and grants access" do
    post user_session_path, params: {
      user: { email: users(:volunteer).email, password: "password123" }
    }
    assert_redirected_to root_path

    get start_url
    assert_response :success
  end

  test "invalid sign-in is rejected" do
    post user_session_path, params: {
      user: { email: users(:volunteer).email, password: "wrong-password" }
    }
    assert_response :unprocessable_entity
  end

  test "sign-out clears session" do
    sign_in users(:volunteer)
    delete destroy_user_session_path
    # Sign-out -> /  ->  /start  ->  /users/sign_in (auth required).
    assert_redirected_to root_path

    get start_url
    assert_redirected_to new_user_session_path
  end

  test "require_admin! is defined as a private helper on ApplicationController" do
    assert_includes ApplicationController.private_instance_methods, :require_admin!
  end
end
