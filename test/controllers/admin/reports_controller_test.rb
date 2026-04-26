require "test_helper"

class Admin::ReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "GET reports/graduates renders HTML" do
    get admin_reports_graduates_url
    assert_response :success
    assert_match(/Download CSV/, response.body)
  end

  test "CSV download for all graduates" do
    get admin_reports_graduates_url(format: :csv)
    assert_response :success
    assert_equal "text/csv", response.media_type
    assert_match(/^buid,/, response.body)
    assert_match graduates(:alice).buid, response.body
  end

  test "CSV download for checked_in only" do
    get admin_reports_graduates_url(format: :csv, scope: "checked_in")
    assert_response :success
    body = response.body
    assert_match graduates(:bob).buid, body
    assert_no_match Regexp.new(graduates(:alice).buid), body
  end

  test "CSV download for not_checked_in" do
    get admin_reports_graduates_url(format: :csv, scope: "not_checked_in")
    assert_match graduates(:alice).buid, response.body
    assert_no_match Regexp.new(graduates(:bob).buid), response.body
  end

  test "filters by graduation_term" do
    graduates(:alice).update!(graduation_term: "TERMX")
    get admin_reports_graduates_url(format: :csv, graduation_term: "TERMX")
    body = response.body
    assert_match graduates(:alice).buid, body
    assert_no_match Regexp.new(graduates(:bob).buid), body
  end

  test "non-admin denied" do
    sign_in users(:volunteer)
    get admin_reports_graduates_url
    assert_redirected_to root_path
  end
end
