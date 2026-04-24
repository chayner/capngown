require "test_helper"

class BragTest < ActiveSupport::TestCase
  test "belongs_to graduate via buid" do
    brag = brags(:alice_brag)
    assert_equal "Alice", brag.graduate.firstname
  end
end
