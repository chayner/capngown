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

  test "preferred_first_from_email derives nickname from belmont email local part" do
    assert_equal "Chris",
                 Graduate.preferred_first_from_email("chris.smith@bruins.belmont.edu", "Christopher")
  end

  test "preferred_first_from_email returns nil when email matches firstname" do
    assert_nil Graduate.preferred_first_from_email("alice.smith@bruins.belmont.edu", "Alice")
    assert_nil Graduate.preferred_first_from_email("ALICE.smith@bruins.belmont.edu", "alice")
  end

  test "preferred_first_from_email returns nil for blank or initial-only local parts" do
    assert_nil Graduate.preferred_first_from_email(nil, "Chris")
    assert_nil Graduate.preferred_first_from_email("", "Chris")
    assert_nil Graduate.preferred_first_from_email("j.smith@bruins.belmont.edu", "John")
  end

  test "preferred_first_from_email handles hyphenated nicknames" do
    assert_equal "Mary-Ann",
                 Graduate.preferred_first_from_email("mary-ann.jones@bruins.belmont.edu", "Maryann")
  end

  test "formal_name_differs_from_preferred? false when preferred matches formal" do
    g = Graduate.new(firstname: "Alice", lastname: "Smith",
                     preferredfirst: "Alice", preferredlast: "Smith")
    refute g.formal_name_differs_from_preferred?
  end

  test "formal_name_differs_from_preferred? false when preferred values are blank" do
    g = Graduate.new(firstname: "Alice", lastname: "Smith",
                     preferredfirst: nil, preferredlast: nil)
    refute g.formal_name_differs_from_preferred?
  end

  test "formal_name_differs_from_preferred? true when preferred first differs" do
    g = Graduate.new(firstname: "Christopher", lastname: "Smith",
                     preferredfirst: "Chris", preferredlast: "Smith")
    assert g.formal_name_differs_from_preferred?
  end

  test "formal_name_differs_from_preferred? true when preferred last differs" do
    g = Graduate.new(firstname: "Alice", lastname: "Johnson",
                     preferredfirst: "Alice", preferredlast: "Smith")
    assert g.formal_name_differs_from_preferred?
  end

  test "formal_name_differs_from_preferred? case-insensitive" do
    g = Graduate.new(firstname: "alice", lastname: "smith",
                     preferredfirst: "ALICE", preferredlast: "SMITH")
    refute g.formal_name_differs_from_preferred?
  end

  test "sanitize_preferred_first strips trailing surname" do
    assert_equal "Cameron",
                 Graduate.sanitize_preferred_first("Cameron Bateman", "Bateman")
    assert_equal "Cameron",
                 Graduate.sanitize_preferred_first("Cameron BATEMAN", "Bateman")
    # Trailing punctuation
    assert_equal "Cameron",
                 Graduate.sanitize_preferred_first("Cameron Bateman.", "Bateman")
    # Falls through to preferredlast when lastname doesn't match
    assert_equal "Cameron",
                 Graduate.sanitize_preferred_first("Cameron Smith", "Bateman", "Smith")
  end

  test "sanitize_preferred_first leaves clean values alone" do
    assert_equal "Cameron",   Graduate.sanitize_preferred_first("Cameron", "Bateman")
    assert_equal "Mary Jane", Graduate.sanitize_preferred_first("Mary Jane", "Smith")
    assert_nil   Graduate.sanitize_preferred_first(nil, "Bateman")
    assert_nil   Graduate.sanitize_preferred_first("  ", "Bateman")
  end

  test "sanitize_preferred_first returns original when stripping would empty it" do
    # Edge case: preferredfirst is just the surname
    assert_equal "Bateman", Graduate.sanitize_preferred_first("Bateman", "Bateman")
  end

  test "sanitize_preferred_last strips leading given name" do
    assert_equal "Bateman",
                 Graduate.sanitize_preferred_last("Cameron Bateman", "Cameron")
    assert_equal "Bateman",
                 Graduate.sanitize_preferred_last("CAMERON Bateman", "Cameron")
  end

  test "display_preferred_first/last route through sanitizers" do
    g = Graduate.new(firstname: "Cameron", lastname: "Bateman",
                     preferredfirst: "Cameron Bateman", preferredlast: "Bateman")
    assert_equal "Cameron", g.display_preferred_first
    assert_equal "Bateman", g.display_preferred_last
    refute g.formal_name_differs_from_preferred?,
           "after sanitizing, the duplicated-surname row should match the formal name"
  end
end
