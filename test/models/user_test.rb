require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "fixture volunteer is valid" do
    assert users(:volunteer).valid?
  end

  test "fixture admin is valid" do
    assert users(:admin).valid?
  end

  test "default role for new user is volunteer" do
    u = User.new(email: "new@example.com", password: "password123")
    assert u.valid?
    assert_equal "volunteer", u.role
    assert u.volunteer?
    assert_not u.admin?
  end

  test "admin? is true only for admin role" do
    assert users(:admin).admin?
    assert_not users(:volunteer).admin?
  end

  test "volunteer? returns true for both volunteers and admins (hierarchy)" do
    assert users(:volunteer).volunteer?, "volunteer should be a volunteer"
    assert users(:admin).volunteer?, "admin should also be considered a volunteer"
  end

  test "email must be present and unique" do
    u = User.new(password: "password123")
    assert_not u.valid?
    assert_includes u.errors[:email], "can't be blank"

    dup = User.new(email: users(:volunteer).email, password: "password123")
    assert_not dup.valid?
    assert_includes dup.errors[:email], "has already been taken"
  end

  test "password must be at least 8 chars" do
    u = User.new(email: "short@example.com", password: "short")
    assert_not u.valid?
    assert(u.errors[:password].any? { |e| e.include?("too short") })
  end

  test "role enum maps integers correctly" do
    assert_equal 0, User.roles[:volunteer]
    assert_equal 1, User.roles[:admin]
  end
end
