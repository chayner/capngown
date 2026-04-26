require "application_system_test_case"

class Admin::ImportsTest < ApplicationSystemTestCase
  setup do
    sign_in users(:admin)
    Graduate.update_all(graduation_term: "202520")
  end

  test "selecting an import type reveals the matching fieldsets" do
    visit admin_imports_path

    # Initially, term/file/cords-only sections are hidden
    assert_no_selector ".needs-term", visible: true
    assert_no_selector ".needs-file", visible: true
    assert_no_selector ".cords-only", visible: true

    find("label.import-type-option", text: "Graduate roster").click
    assert_selector ".needs-term", visible: true
    assert_selector ".needs-file", visible: true
    assert_no_selector ".cords-only", visible: true

    find("label.import-type-option", text: "Honor cords").click
    assert_no_selector ".needs-term", visible: true
    assert_selector ".cords-only", visible: true
    assert_selector ".needs-file", visible: true
  end

  test "new-term input only appears when '+ New term…' is selected" do
    visit admin_imports_path
    find("label.import-type-option", text: "Graduate roster").click

    within(".imports-form") do
      assert_no_selector "input[name='graduation_term_new']", visible: true
      select "+ New term…", from: "graduation_term"
      assert_selector "input[name='graduation_term_new']", visible: true
      select "202520", from: "graduation_term"
      assert_no_selector "input[name='graduation_term_new']", visible: true
    end
  end

  test "submitting without a file produces a flash alert" do
    visit admin_imports_path
    find("label.import-type-option", text: "Graduate roster").click
    # Bypass the HTML5 file-required validation by submitting via JS
    page.execute_script("document.querySelector('.imports-form').submit()")
    assert_text(/Choose a file to upload|Choose a graduation term|Choose an import type/i)
  end
end
