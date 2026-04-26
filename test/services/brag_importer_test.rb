require "test_helper"

class BragImporterTest < ActiveSupport::TestCase
  test "skips rows whose buid is not in graduates and reports gaps" do
    Brag.where(buid: graduates(:alice).buid).delete_all # clear pre-existing brag fixture so this row counts as an insert
    file = Tempfile.new(["brags", ".csv"])
    file.write("Student First,Student Last,Student BUID\nAlice,Smith,B00100001\nMissing,Person,B99999999\n")
    file.flush

    p = BragImporter.new(file: file.path).preview
    assert_equal 2, p[:row_count]
    assert_equal 1, p[:inserts]
    assert_equal 1, p[:skipped]
    assert_includes p[:gaps], "B99999999"
  ensure
    file&.close!
  end

  test "import! deletes existing brags for buid and inserts new ones" do
    Brag.where(buid: graduates(:alice).buid).delete_all
    Brag.create!(buid: graduates(:alice).buid, name: "Old", message: "old")

    file = Tempfile.new(["brags", ".csv"])
    file.write("Student First,Student Last,Student BUID\nAlice,Smith,B00100001\n")
    file.flush

    result = BragImporter.new(file: file.path).import!(user: users(:admin))
    assert result.succeeded
    brags = Brag.where(buid: graduates(:alice).buid)
    assert_equal 1, brags.count
    assert_equal "Alice Smith", brags.first.name
    assert_nil brags.first.message
  ensure
    file&.close!
  end
end
