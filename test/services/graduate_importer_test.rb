require "test_helper"

class GraduateImporterTest < ActiveSupport::TestCase
  MAIN     = Rails.root.join("test/fixtures/files/SAMPLE - May 2026.csv").to_s
  THREE    = Rails.root.join("test/fixtures/files/SAMPLE - 3 PLUS 3 UG.csv").to_s
  LATE_ADD = Rails.root.join("test/fixtures/files/SAMPLE - Late Add May 2026.csv").to_s

  test "preview parses main term roster and counts inserts" do
    p = GraduateImporter.new(file: MAIN, graduation_term: "202620").preview
    assert p[:row_count] > 0
    assert p[:inserts].positive?
    assert_equal 0, p[:warnings].size, "did not expect warnings on main file"
  end

  test "preview parses 3+3 UG roster" do
    p = GraduateImporter.new(file: THREE, graduation_term: "202620").preview
    assert_equal 0, p[:warnings].size
    assert p[:inserts].positive?
    sample = p[:sample_rows].first
    assert_equal "UG", sample[:levelcode]
    assert_equal "CL", sample[:college1]
  end

  test "preview parses late-add roster (full college names resolve to codes)" do
    p = GraduateImporter.new(file: LATE_ADD, graduation_term: "202620").preview
    assert_equal 0, p[:warnings].size, p[:warnings].inspect
    assert p[:inserts].positive?
    sample = p[:sample_rows].first
    assert_match(/[A-Z]{2}/, sample[:college1])
  end

  test "import! upserts rows and stamps graduation_term" do
    Graduate.where(graduation_term: "TEST20").delete_all
    importer = GraduateImporter.new(file: THREE, graduation_term: "TEST20")
    user = users(:admin)
    result = importer.import!(user: user)
    assert result.succeeded
    assert result.inserts.positive?
    grads = Graduate.where(graduation_term: "TEST20")
    assert grads.exists?
    assert_equal "TEST20", grads.first.graduation_term

    # Re-import: should be all updates
    importer2 = GraduateImporter.new(file: THREE, graduation_term: "TEST20")
    result2 = importer2.import!(user: user)
    assert result2.succeeded
    assert_equal 0, result2.inserts
    assert_equal grads.count, result2.updates
  end

  test "import! creates an ImportLog entry" do
    Graduate.where(graduation_term: "TEST21").delete_all
    user = users(:admin)
    assert_difference "ImportLog.count", 1 do
      GraduateImporter.new(file: THREE, graduation_term: "TEST21").import!(user: user)
    end
    log = ImportLog.last
    assert_equal "graduates", log.import_type
    assert_equal "TEST21", log.graduation_term
    assert log.succeeded?
  end

  test "files over 2500 rows are rejected at preview" do
    big = Tempfile.new(["big", ".csv"])
    big.write("BUID,LevelCode\n")
    2_501.times { |i| big.write("B0010#{i.to_s.rjust(4, '0')},UG\n") }
    big.flush
    p = GraduateImporter.new(file: big.path).preview
    assert p[:error].present?
    assert_match(/2500/, p[:error])
  ensure
    big&.close!
  end

  test "import! tolerates legacy long values (collegedesc, fullname, campusemail)" do
    Graduate.where(graduation_term: "LONG20").delete_all
    long_college = "Mike Curb College of Entertainment and Music Business"
    long_full    = "A Very Long Diploma Name With Multiple Middle Names And Suffix III"
    long_email   = "very.long.first.middle.last.name+grad2026@bruins.belmont.edu"
    assert long_college.length > 50
    assert long_full.length    > 50
    assert long_email.length   > 50

    csv = Tempfile.new(["long", ".csv"])
    csv.write("BUID,SHBGAPP_FirstName,SHBGAPP_LastName,Diploma_Name,Degree1,College1,CollegeDesc,CAMP_Email,LevelCode\n")
    csv.write(%(B00999001,Long,Name,"#{long_full}",DNP,CE,"#{long_college}",#{long_email},GR\n))
    csv.flush
    result = GraduateImporter.new(file: csv.path, graduation_term: "LONG20").import!(user: users(:admin))
    assert result.succeeded, "expected import to succeed, got: #{result.error_message}"
    g = Graduate.find_by(buid: "B00999001")
    assert_equal long_college, g.collegedesc
    assert_equal long_full,    g.fullname
    assert_equal long_email,   g.campusemail
  ensure
    csv&.close!
  end

  test "import! generates orderid from BUID + Jostens Height when present" do
    Graduate.where(graduation_term: "ORD20").delete_all
    csv = Tempfile.new(["orderid", ".csv"])
    csv.write("BUID,SHBGAPP_FirstName,SHBGAPP_LastName,LevelCode,Jostens Height\n")
    csv.write("B00665354,Has,Order,UG,507\n")
    csv.write("B00665355,No,Order,UG,\n")
    csv.flush
    result = GraduateImporter.new(file: csv.path, graduation_term: "ORD20").import!(user: users(:admin))
    assert result.succeeded, "expected import to succeed, got: #{result.error_message}"

    with_order    = Graduate.find_by(buid: "B00665354")
    without_order = Graduate.find_by(buid: "B00665355")
    assert_equal "665354-507", with_order.orderid, "orderid should be last 6 BUID digits + Jostens height"
    assert_equal 507, with_order.height, "Jostens height should populate height when no TOTALHEIGHT"
    assert_nil without_order.orderid, "orderid should be nil when Jostens Height is blank"
  ensure
    csv&.close!
  end

  test "import! backfills preferredfirst from campus email when missing" do
    Graduate.where(graduation_term: "NICK20").delete_all
    csv = Tempfile.new(["nick", ".csv"])
    csv.write("BUID,SHBGAPP_FirstName,SHBGAPP_LastName,Preferred Name,LevelCode,CAMP_Email\n")
    # Row 1: no preferred, email-derived nickname differs from formal -> backfilled
    csv.write("B00777001,Christopher,Adams,,UG,chris.adams@bruins.belmont.edu\n")
    # Row 2: no preferred, email matches firstname -> stays nil
    csv.write("B00777002,Alice,Brown,,UG,alice.brown@bruins.belmont.edu\n")
    # Row 3: explicit preferred wins over email
    csv.write("B00777003,Robert,Carter,Bobby,UG,robert.carter@bruins.belmont.edu\n")
    csv.flush
    result = GraduateImporter.new(file: csv.path, graduation_term: "NICK20").import!(user: users(:admin))
    assert result.succeeded, "expected import to succeed, got: #{result.error_message}"

    assert_equal "Chris", Graduate.find_by(buid: "B00777001").preferredfirst
    assert_nil   Graduate.find_by(buid: "B00777002").preferredfirst
    assert_equal "Bobby", Graduate.find_by(buid: "B00777003").preferredfirst
  ensure
    csv&.close!
  end

  test "import! strips duplicated surname from preferredfirst" do
    Graduate.where(graduation_term: "DUP20").delete_all
    csv = Tempfile.new(["dup", ".csv"])
    csv.write("BUID,SHBGAPP_FirstName,SHBGAPP_LastName,Preferred Name,Preferred Last,LevelCode\n")
    csv.write("B00888001,Cameron,Bateman,Cameron Bateman,,UG\n")
    csv.write("B00888002,Cameron,Bateman,Cam Bateman,,UG\n")
    csv.write("B00888003,Cameron,Bateman,Cameron,Bateman,UG\n")
    csv.flush
    result = GraduateImporter.new(file: csv.path, graduation_term: "DUP20").import!(user: users(:admin))
    assert result.succeeded, "expected import to succeed, got: #{result.error_message}"

    assert_equal "Cameron", Graduate.find_by(buid: "B00888001").preferredfirst,
                 "trailing surname should be stripped"
    assert_equal "Cam",     Graduate.find_by(buid: "B00888002").preferredfirst,
                 "trailing surname should be stripped from a real nickname"
    assert_equal "Cameron", Graduate.find_by(buid: "B00888003").preferredfirst,
                 "clean values should be preserved"
  ensure
    csv&.close!
  end
end
