require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @volunteer = users(:volunteer)
  end

  test "volunteer cannot access admin users" do
    sign_in @volunteer
    get admin_users_url
    assert_redirected_to root_path
    assert_match(/Admins only/, flash[:alert])
  end

  test "admin can list users" do
    sign_in @admin
    get admin_users_url
    assert_response :success
    assert_match @admin.email, response.body
  end

  test "admin can create a user with temp password and must_change_password true" do
    sign_in @admin
    assert_difference "User.count", 1 do
      post admin_users_url, params: {
        user: { email: "new.volunteer@example.com", role: "volunteer", active: "1",
                password: "tempPass1", password_confirmation: "tempPass1" }
      }
    end
    assert_redirected_to admin_users_path
    user = User.find_by(email: "new.volunteer@example.com")
    assert user.must_change_password?
    assert user.active?
    assert user.volunteer?
  end

  test "admin update with new password forces password change" do
    sign_in @admin
    user = User.create!(email: "existing@example.com", role: :volunteer,
                        password: "oldPass12", password_confirmation: "oldPass12",
                        active: true, must_change_password: false)

    patch admin_user_url(user), params: {
      user: { password: "newPass12", password_confirmation: "newPass12" }
    }
    assert_redirected_to admin_users_path
    assert user.reload.must_change_password?
  end

  test "admin update without password change does not force password change" do
    sign_in @admin
    user = User.create!(email: "existing2@example.com", role: :volunteer,
                        password: "oldPass12", password_confirmation: "oldPass12",
                        active: true, must_change_password: false)

    patch admin_user_url(user), params: { user: { role: "admin", password: "", password_confirmation: "" } }
    assert_redirected_to admin_users_path
    assert_not user.reload.must_change_password?
    assert user.admin?
  end

  test "deactivating user sets active=false" do
    sign_in @admin
    delete admin_user_url(@volunteer)
    assert_redirected_to admin_users_path
    assert_not @volunteer.reload.active?
  end

  test "admin cannot deactivate themselves" do
    sign_in @admin
    delete admin_user_url(@admin)
    assert_redirected_to admin_users_path
    assert @admin.reload.active?
    assert_match(/can't deactivate yourself/, flash[:alert])
  end

  test "deactivated user cannot sign in" do
    @volunteer.update!(active: false)
    post user_session_path, params: { user: { email: @volunteer.email, password: "password123" } }
    follow_redirect! if response.redirect?
    assert_match(/account has been deactivated/i, response.body)
  end
end
