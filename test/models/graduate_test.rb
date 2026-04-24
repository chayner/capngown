require "test_helper"

class GraduateTest < ActiveSupport::TestCase
  test "uses buid as primary key" do
    assert_equal "buid", Graduate.primary_key
  end

  test "find_by buid returns the right graduate" do
    g = Graduate.find_by(buid: "B00100001")
    assert_equal "Alice", g.firstname
  end

  test "has_many brags through buid" do
    g = graduates(:alice)
    assert_equal 1, g.brags.count
    assert_equal "Alice's Award", g.brags.first.name
  end

  test "has_many cords through buid (none in fixtures)" do
    assert_equal 0, graduates(:alice).cords.count
  end
end
