require "test_helper"

class Admin::ImportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "GET index renders" do
    get admin_imports_url
    assert_response :success
  end

  test "preview without file redirects" do
    post preview_admin_imports_url, params: { import_type: "graduates", graduation_term: "202620" }
    assert_redirected_to admin_imports_path
  end

  test "preview with valid graduate file renders" do
    file = fixture_file_upload("SAMPLE - 3 PLUS 3 UG.csv", "text/csv")
    post preview_admin_imports_url,
      params: { import_type: "graduates", graduation_term: "202620", file: file }
    assert_response :success
    assert_match(/Will insert/, response.body)
  end

  test "non-admin cannot access" do
    sign_in users(:volunteer)
    get admin_imports_url
    assert_redirected_to root_path
  end
end
