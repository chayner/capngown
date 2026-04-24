require "test_helper"

class CordTest < ActiveSupport::TestCase
  test "validates buid and cord_type presence" do
    cord = Cord.new
    assert_not cord.valid?
    assert_includes cord.errors[:buid], "can't be blank"
    assert_includes cord.errors[:cord_type], "can't be blank"
  end

  test "creates a cord linked to a graduate" do
    cord = Cord.new(buid: graduates(:alice).buid, cord_type: "Honor")
    assert cord.save
    assert_equal 1, graduates(:alice).cords.count
  end
end
