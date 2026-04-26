require "test_helper"

class CordImporterTest < ActiveSupport::TestCase
  class FakeUpload
    attr_reader :original_filename, :tempfile
    def initialize(path, original_filename: nil)
      @original_filename = original_filename || File.basename(path)
      @tempfile = File.open(path)
    end
  end

  setup do
    @alice = graduates(:alice)
    @alice.update!(campusemail: "alice@example.edu", firstname: "Alice", lastname: "Smith")
  end

  test "derives cord_type from filename and looks up BUID by email" do
    file = Tempfile.new(["honors_cords", ".csv"])
    file.write("Last Name,First Name,Email\nSmith,Alice,alice@example.edu\nGhost,Person,no@example.edu\n")
    file.flush

    upload = FakeUpload.new(file.path, original_filename: "Honors Cords.csv")
    importer = CordImporter.new(file: upload)
    p = importer.preview
    assert_equal "Honors", importer.send(:cord_type)
    assert_equal 1, p[:inserts]
    assert_equal 1, p[:skipped]
    assert p[:gaps].any?
  ensure
    file&.close!
  end

  test "cord_type override wins over filename" do
    file = Tempfile.new(["x", ".csv"])
    file.write("Last Name,First Name,Email\nSmith,Alice,alice@example.edu\n")
    file.flush

    upload = FakeUpload.new(file.path, original_filename: "Mystery.csv")
    importer = CordImporter.new(file: upload, cord_type_override: "Veterans")
    p = importer.preview
    assert_equal "Veterans", importer.send(:cord_type)
    assert_equal 1, p[:inserts]
  ensure
    file&.close!
  end

  test "import! upserts cord rows" do
    file = Tempfile.new(["honors", ".csv"])
    file.write("Last Name,First Name,Email\nSmith,Alice,alice@example.edu\n")
    file.flush
    upload = FakeUpload.new(file.path, original_filename: "Honors Cords.csv")

    Cord.where(buid: @alice.buid).delete_all
    result = CordImporter.new(file: upload).import!(user: users(:admin))
    assert result.succeeded
    cord = Cord.where(buid: @alice.buid, cord_type: "Honors").first
    assert cord
  ensure
    file&.close!
  end
end
