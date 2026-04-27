require "test_helper"

class BragImporterTest < ActiveSupport::TestCase
  test "skips rows whose buid is not in graduates and reports gaps" do
    Brag.where(buid: graduates(:alice).buid).delete_all # clear pre-existing brag fixture so this row counts as an insert
    file = Tempfile.new(["brags", ".csv"])
    file.write("Student First,Student Last,Student BUID,Note,Transaction ID\n")
    file.write("Alice,Smith,B00100001,Great work,1001\n")
    file.write("Missing,Person,B99999999,Whoops,1002\n")
    file.flush

    p = BragImporter.new(file: file.path).preview
    assert_equal 2, p[:row_count]
    assert_equal 1, p[:inserts]
    assert_equal 1, p[:skipped]
    assert_includes p[:gaps], "B99999999"
  ensure
    file&.close!
  end

  test "import! upserts by transaction_id (re-import is all updates)" do
    Brag.where(buid: graduates(:alice).buid).delete_all

    file = Tempfile.new(["brags", ".csv"])
    file.write("Student First,Student Last,Student BUID,Note,Transaction ID\n")
    file.write("Alice,Smith,B00100001,First note,2001\n")
    file.flush

    result = BragImporter.new(file: file.path).import!(user: users(:admin))
    assert result.succeeded
    assert_equal 1, result.inserts
    brag = Brag.find_by(transaction_id: "2001")
    assert_equal "Alice Smith", brag.name
    assert_equal "First note",  brag.message

    # Re-import same Transaction ID with edited note -> update, not duplicate
    file2 = Tempfile.new(["brags2", ".csv"])
    file2.write("Student First,Student Last,Student BUID,Note,Transaction ID\n")
    file2.write("Alice,Smith,B00100001,Edited note,2001\n")
    file2.flush
    result2 = BragImporter.new(file: file2.path).import!(user: users(:admin))
    assert result2.succeeded
    assert_equal 0, result2.inserts
    assert_equal 1, result2.updates
    assert_equal 1, Brag.where(transaction_id: "2001").count
    assert_equal "Edited note", Brag.find_by(transaction_id: "2001").message
  ensure
    file&.close!
    file2&.close!
  end

  test "import! preserves brags from previous uploads when re-importing a smaller file" do
    Brag.where(buid: graduates(:alice).buid).delete_all
    Brag.create!(buid: graduates(:alice).buid, name: "Old", message: "old", transaction_id: "OLD-1")

    file = Tempfile.new(["brags", ".csv"])
    file.write("Student First,Student Last,Student BUID,Note,Transaction ID\n")
    file.write("Alice,Smith,B00100001,New brag,3001\n")
    file.flush

    BragImporter.new(file: file.path).import!(user: users(:admin))

    # Old brag with a different transaction_id is NOT deleted (no more delete-by-buid).
    assert Brag.exists?(transaction_id: "OLD-1"),
           "previous brag should survive a new import that doesn't include its Transaction ID"
    assert Brag.exists?(transaction_id: "3001")
  ensure
    file&.close!
  end

  test "import! skips rows missing Transaction ID with a warning" do
    Brag.where(buid: graduates(:alice).buid).delete_all
    file = Tempfile.new(["brags", ".csv"])
    file.write("Student First,Student Last,Student BUID,Note,Transaction ID\n")
    file.write("Alice,Smith,B00100001,No txn,\n")
    file.flush

    p = BragImporter.new(file: file.path).preview
    assert_equal 0, p[:inserts]
    assert_equal 1, p[:skipped]
    assert(p[:warnings].any? { |w| w.include?("Transaction ID") })
  ensure
    file&.close!
  end

  test "import! deduplicates Transaction IDs within a single file" do
    Brag.where(buid: graduates(:alice).buid).delete_all
    file = Tempfile.new(["brags", ".csv"])
    file.write("Student First,Student Last,Student BUID,Note,Transaction ID\n")
    file.write("Alice,Smith,B00100001,First,4001\n")
    file.write("Alice,Smith,B00100001,Dup,4001\n")
    file.flush

    p = BragImporter.new(file: file.path).preview
    assert_equal 1, p[:inserts]
    assert_equal 1, p[:skipped]
    assert(p[:warnings].any? { |w| w.include?("duplicate Transaction ID") })
  ensure
    file&.close!
  end

  test "parses real Bruin Brag sample export without fatal errors" do
    sample = Rails.root.join("test/fixtures/files/SAMPLE - Brag.xlsx").to_s
    skip "sample brag file not found" unless File.exist?(sample)

    p = BragImporter.new(file: sample).preview
    assert_nil p[:error], "sample file should parse without fatal error"
    assert p[:row_count] > 0, "sample file should have rows"
    # Sample BUIDs aren't in our test graduate fixtures, so all rows become gaps.
    assert p[:gaps].any?, "expected gaps because sample BUIDs aren't in fixtures"
  end
end
