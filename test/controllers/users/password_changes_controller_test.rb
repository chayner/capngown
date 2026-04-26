require "test_helper"

class Users::PasswordChangesControllerTest < ActionDispatch::IntegrationTest
  test "user with must_change_password is forced to password change page" do
    user = User.create!(email: "force@example.com", role: :volunteer,
                        password: "oldPass12", password_confirmation: "oldPass12",
                        active: true, must_change_password: true)
    sign_in user
    get start_url
    assert_redirected_to edit_password_change_path
  end

  test "successful password change clears the flag" do
    user = User.create!(email: "change@example.com", role: :volunteer,
                        password: "oldPass12", password_confirmation: "oldPass12",
                        active: true, must_change_password: true)
    sign_in user

    patch password_change_url, params: {
      user: { current_password: "oldPass12", password: "newPass1234", password_confirmation: "newPass1234" }
    }
    assert_redirected_to root_path
    assert_not user.reload.must_change_password?
  end

  test "wrong current password keeps user on page" do
    user = User.create!(email: "wrong@example.com", role: :volunteer,
                        password: "oldPass12", password_confirmation: "oldPass12",
                        active: true, must_change_password: true)
    sign_in user

    patch password_change_url, params: {
      user: { current_password: "WRONG", password: "newPass1234", password_confirmation: "newPass1234" }
    }
    assert_response :unprocessable_entity
    assert user.reload.must_change_password?
  end
end
