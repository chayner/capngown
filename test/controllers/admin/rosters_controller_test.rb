require "test_helper"

class Admin::RostersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
    Graduate.update_all(graduation_term: "TERMA")
    @grad = graduates(:alice)
    @grad.update!(graduation_term: "TERMA")
    Brag.create!(buid: @grad.buid, name: "Brag")
    Cord.insert_all([{ buid: @grad.buid, cord_type: "Honors" }])
  end

  test "wrong confirmation cancels reset" do
    initial = Graduate.count
    delete admin_roster_url, params: { scope: "all", confirmation: "nope" }
    assert_redirected_to admin_imports_path
    assert_equal initial, Graduate.count
  end

  test "scope=term deletes only matching graduates and dependents" do
    other = Graduate.create!(buid: "B99999998", graduation_term: "TERMB", firstname: "Other")
    delete admin_roster_url,
      params: { scope: "term", graduation_term: "TERMA", confirmation: "RESET ROSTER" }
    assert_redirected_to admin_imports_path
    assert_not Graduate.exists?(buid: @grad.buid)
    assert Graduate.exists?(buid: other.buid)
    assert_equal 0, Brag.where(buid: @grad.buid).count
    assert_equal 0, Cord.where(buid: @grad.buid).count
  end

  test "scope=all deletes everything and logs" do
    assert_difference "ImportLog.count", 1 do
      delete admin_roster_url, params: { scope: "all", confirmation: "RESET ROSTER" }
    end
    assert_equal 0, Graduate.count
    assert_equal 0, Brag.count
    assert_equal 0, Cord.count
    log = ImportLog.last
    assert_equal "reset", log.import_type
  end

  test "non-admin cannot reset" do
    sign_in users(:volunteer)
    delete admin_roster_url, params: { scope: "all", confirmation: "RESET ROSTER" }
    assert_redirected_to root_path
    assert Graduate.exists?(buid: @grad.buid)
  end
end
