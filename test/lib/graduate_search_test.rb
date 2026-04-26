require "test_helper"

class GraduateSearchTest < ActiveSupport::TestCase
  setup do
    Graduate.delete_all
    @robert = Graduate.create!(buid: "B00200001", firstname: "Robert",  lastname: "Mancini",
                               fullname: "Robert Mancini", preferredfirst: "Bob",
                               preferredlast: "Mancini", campusemail: "rob@example.edu")
    @jose   = Graduate.create!(buid: "B00200002", firstname: "José",    lastname: "García",
                               fullname: "José García", campusemail: "jose@example.edu")
    @jen    = Graduate.create!(buid: "B00200003", firstname: "Jennifer", lastname: "O'Brien",
                               fullname: "Jennifer O'Brien", preferredfirst: "Jen",
                               preferredlast: "O'Brien", campusemail: "jen@example.edu")
    @other  = Graduate.create!(buid: "B00200004", firstname: "Steven",   lastname: "Smith",
                               fullname: "Steven Smith", campusemail: "steve@example.edu")
  end

  test "exact BUID match returns one graduate" do
    results = GraduateSearch.search(Graduate.all, "B00200001")
    assert_equal [@robert.buid], results.pluck(:buid)
  end

  test "BUID match is case-insensitive and tolerates lowercase b prefix" do
    results = GraduateSearch.search(Graduate.all, "b00200001")
    assert_equal [@robert.buid], results.pluck(:buid)
  end

  test "email substring matches campus email" do
    results = GraduateSearch.search(Graduate.all, "jose@")
    assert_equal [@jose.buid], results.pluck(:buid)
  end

  test "nickname expands to formal name (Bob -> Robert)" do
    results = GraduateSearch.search(Graduate.all, "bob mancini")
    assert_includes results.pluck(:buid), @robert.buid
  end

  test "formal name expands to nickname (Robert -> Bob/Robert)" do
    # Direct match still works first
    results = GraduateSearch.search(Graduate.all, "robert mancini")
    assert_includes results.pluck(:buid), @robert.buid
  end

  test "accent-insensitive search finds Garcia from 'garcia'" do
    results = GraduateSearch.search(Graduate.all, "garcia")
    assert_includes results.pluck(:buid), @jose.buid
  end

  test "accent-insensitive search finds José from 'jose'" do
    results = GraduateSearch.search(Graduate.all, "jose")
    assert_includes results.pluck(:buid), @jose.buid
  end

  test "trigram fallback handles minor typo" do
    # 'Mancinni' (extra n) — no exact ILIKE match, trigram should catch it
    results = GraduateSearch.search(Graduate.all, "mancinni")
    assert_includes results.pluck(:buid), @robert.buid
  end

  test "soundex fallback handles sounds-like surname" do
    # 'Garsia' sounds like 'Garcia'
    results = GraduateSearch.search(Graduate.all, "garsia")
    assert_includes results.pluck(:buid), @jose.buid
  end

  test "preferred name match works (Jen -> Jennifer)" do
    results = GraduateSearch.search(Graduate.all, "jen")
    assert_includes results.pluck(:buid), @jen.buid
  end

  test "exact full-name match outranks fuzzy matches" do
    Graduate.create!(buid: "B00200099", firstname: "Roberta", lastname: "Mancini-Smith",
                     fullname: "Roberta Mancini-Smith")
    results = GraduateSearch.search(Graduate.all, "robert mancini")
    # Robert Mancini (tier 1 exact) should be first; Roberta Mancini-Smith (tier 3) after.
    assert_equal "B00200001", results.first.buid
  end

  test "blank query returns scope unchanged" do
    results = GraduateSearch.search(Graduate.all, "  ")
    assert_equal Graduate.count, results.count
  end

  test "fuzzy fallback does not fire when precise matches exist" do
    # Add a name whose soundex matches 'bob' (B100). 'Bobo' starts with 'bob' so
    # it's a legit precise match, but 'Pope' (P100) and 'Pavo' would be soundex
    # noise. Confirm we get only the precise hits.
    Graduate.create!(buid: "B00200090", firstname: "Pope", lastname: "Smith",  fullname: "Pope Smith")
    Graduate.create!(buid: "B00200091", firstname: "Pavo", lastname: "Jones",  fullname: "Pavo Jones")
    Graduate.create!(buid: "B00200092", firstname: "Bobo", lastname: "Allen",  fullname: "Bobo Allen")

    results = GraduateSearch.search(Graduate.all, "bob").pluck(:buid)
    # Includes ILIKE matches: 'bob' substring (Bobo) and nickname Bob → Robert (Robert Mancini)
    assert_includes results, "B00200001", "expected nickname expansion to find Robert"
    assert_includes results, "B00200092", "expected substring match to find Bobo"
    # Excludes soundex-only false positives
    refute_includes results, "B00200090", "Pope is soundex-only noise"
    refute_includes results, "B00200091", "Pavo is soundex-only noise"
  end

  test "very short queries (< 4 chars) skip fuzzy fallback when precise pass is empty" do
    # 'xyz' won't match anything precisely; with a short query we should NOT
    # fall back to soundex/trigram (would surface random noise).
    results = GraduateSearch.search(Graduate.all, "xyz")
    assert_equal 0, results.count
  end

  test "single-term name search ignores middle names in fullname" do
    # The fullname column is the diploma name and contains middle names.
    # Searching 'bob' must NOT match someone whose middle name is Robert.
    Graduate.create!(buid: "B00200080", firstname: "Jake", lastname: "Aurigema",
                     fullname: "Jake Robert Aurigema")
    results = GraduateSearch.search(Graduate.all, "bob").pluck(:buid)
    refute_includes results, "B00200080",
                    "single-term search must not match middle name in fullname"
  end

  test "Kris matches Chris/Christopher/Christina/Christian via prefix substitution" do
    chris  = Graduate.create!(buid: "B00200070", firstname: "Chris",        lastname: "Walker", fullname: "Chris Walker")
    topher = Graduate.create!(buid: "B00200071", firstname: "Christopher",  lastname: "Lee",    fullname: "Christopher Lee")
    tina   = Graduate.create!(buid: "B00200072", firstname: "Christina",    lastname: "Park",   fullname: "Christina Park")
    tian   = Graduate.create!(buid: "B00200073", firstname: "Christian",    lastname: "Reyes",  fullname: "Christian Reyes")

    results = GraduateSearch.search(Graduate.all, "kris").pluck(:buid)
    assert_includes results, chris.buid,  "expected Kris→Chris substitution"
    assert_includes results, topher.buid, "expected Kris→Chris→Christopher chain"
    assert_includes results, tina.buid,   "expected Kris→Chris→Christina chain"
    assert_includes results, tian.buid,   "expected Kris→Chris→Christian chain"
  end

  test "Cathy matches Kathy and Catherine/Katherine via prefix substitution" do
    kathy = Graduate.create!(buid: "B00200060", firstname: "Kathy",      lastname: "Long", fullname: "Kathy Long")
    kate  = Graduate.create!(buid: "B00200061", firstname: "Katherine",  lastname: "Hall", fullname: "Katherine Hall")
    results = GraduateSearch.search(Graduate.all, "cathy").pluck(:buid)
    assert_includes results, kathy.buid
    assert_includes results, kate.buid
  end
end
