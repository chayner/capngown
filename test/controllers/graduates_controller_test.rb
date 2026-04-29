require "test_helper"

class GraduatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @graduate = graduates(:alice)
    @checked_in = graduates(:bob)
    @printed = graduates(:carol)
    sign_in users(:volunteer)
  end

  # --- Lookup / list ---

  test "GET /start renders" do
    get start_url
    assert_response :success
  end

  test "GET /list renders without filters" do
    get list_url
    assert_response :success
  end

  test "GET /list filters by fullname" do
    get list_url, params: { fullname: "Alice" }
    assert_response :success
    assert_match @graduate.buid, response.body
  end

  test "GET /list filters by college" do
    get list_url, params: { college: "MB", checkedin: "show" }
    assert_response :success
    assert_match @checked_in.buid, response.body
  end

  test "GET /list filters by has_brag" do
    get list_url, params: { has_brag: "true" }
    assert_response :success
    assert_match @graduate.buid, response.body
  end

  # --- Show / update ---

  test "GET /graduates/:buid renders" do
    get graduate_url(buid: @graduate.buid)
    assert_response :success
  end

  test "PATCH /graduates/:buid updates height" do
    patch graduate_url(buid: @graduate.buid), params: { graduate: { height: 70 } }
    assert_redirected_to graduate_path(buid: @graduate.buid)
    assert_equal 70, @graduate.reload.height
  end

  test "GET /graduates/:buid/edit renders edit form" do
    get edit_graduate_url(buid: @graduate.buid)
    assert_response :success
    assert_match "Edit Graduate Names", response.body
  end

  test "PATCH /graduates/:buid updates name fields" do
    patch graduate_url(buid: @graduate.buid), params: {
      graduate: {
        firstname: "Alicia",
        lastname: "Smithson",
        preferredfirst: "Allie",
        preferredlast: "Smithson"
      }
    }
    assert_redirected_to graduate_path(buid: @graduate.buid)
    @graduate.reload
    assert_equal "Alicia", @graduate.firstname
    assert_equal "Smithson", @graduate.lastname
    assert_equal "Allie", @graduate.preferredfirst
    assert_equal "Smithson", @graduate.preferredlast
  end

  test "PATCH /graduates/:buid does not allow editing buid via mass assignment" do
    original_buid = @graduate.buid
    patch graduate_url(buid: original_buid), params: {
      graduate: { buid: "B99999999", firstname: "Renamed" }
    }
    assert_redirected_to graduate_path(buid: original_buid)
    assert Graduate.exists?(buid: original_buid)
    assert_not Graduate.exists?(buid: "B99999999")
  end

  test "PATCH /graduates/:buid updates staff notes" do
    patch graduate_url(buid: @graduate.buid), params: {
      graduate: { notes: "Needs a second hood. See Chip." }
    }
    assert_redirected_to graduate_path(buid: @graduate.buid)
    assert_equal "Needs a second hood. See Chip.", @graduate.reload.notes
    assert @graduate.notes?
  end

  test "GET /graduates/:buid shows staff note callout when notes are present" do
    @graduate.update!(notes: "Custom order — pick up at the table.")
    get graduate_url(buid: @graduate.buid)
    assert_response :success
    assert_match "Staff note", response.body
    assert_match "Custom order", response.body
    assert_match "See Staff", response.body
  end

  test "GET /graduates/:buid does not show See Staff indicator when notes are blank" do
    @graduate.update!(notes: nil)
    get graduate_url(buid: @graduate.buid)
    assert_response :success
    assert_no_match "See Staff", response.body
  end

  # --- Check-in ---

  test "PATCH checkin marks checked_in" do
    patch checkin_graduate_url(buid: @graduate.buid)
    assert_redirected_to graduate_path(@graduate)
    assert_not_nil @graduate.reload.checked_in
  end

  test "PATCH checkin with clear unsets checked_in" do
    patch checkin_graduate_url(buid: @checked_in.buid), params: { checkin: "clear" }
    assert_redirected_to graduate_path(@checked_in)
    assert_nil @checked_in.reload.checked_in
  end

  # --- Print queue ---

  test "GET /print renders to-print queue" do
    get print_url
    assert_response :success
    assert_match @checked_in.buid, response.body
  end

  test "GET /print with printed=show includes printed graduates" do
    get print_url, params: { printed: "show" }
    assert_response :success
    assert_match @printed.buid, response.body
  end

  test "GET /get_print returns rendered HTML" do
    get get_print_url
    assert_response :success
  end

  test "PATCH /print marks graduate printed" do
    patch print_graduate_url, params: { buid: @checked_in.buid }
    assert_redirected_to graduate_path(@checked_in, print: true)
    assert_not_nil @checked_in.reload.printed
  end

  test "PATCH /print with clear unsets printed" do
    patch print_graduate_url, params: { buid: @printed.buid, print: "clear" }
    assert_redirected_to graduate_path(@printed, print: true)
    assert_nil @printed.reload.printed
  end

  # --- Bulk ---

  test "GET /show_bulk renders for given buids" do
    get show_bulk_url, params: { buids: "#{@graduate.buid},#{@checked_in.buid}" }
    assert_response :success
    assert_match @graduate.buid, response.body
    assert_match @checked_in.buid, response.body
  end

  test "PATCH /bulk_print marks all printed" do
    patch bulk_print_url, params: { buids: "#{@graduate.buid},#{@checked_in.buid}" }
    assert_redirected_to show_bulk_path(buids: "#{@graduate.buid},#{@checked_in.buid}")
    assert_not_nil @graduate.reload.printed
    assert_not_nil @checked_in.reload.printed
  end

  test "PATCH /bulk_print with clear unsets printed" do
    patch bulk_print_url, params: { buids: @printed.buid, print: "clear" }
    assert_redirected_to show_bulk_path(buids: @printed.buid)
    assert_nil @printed.reload.printed
  end

  # --- Stats ---

  test "GET stats renders" do
    get stats_graduates_url
    assert_response :success
  end

  test "GET stats with 15min interval renders" do
    get stats_graduates_url, params: { interval: "15min" }
    assert_response :success
  end

  test "stats classifies GR levelcode by degree1 (regression: production uses bare GR)" do
    # Production rosters use levelcode = "GR" for both master's and doctorate
    # graduates; the master/doctorate split must come from degree1.
    Graduate.create!(buid: "B0099GRMA", firstname: "Grad", lastname: "Master",
                     fullname: "Grad Master", levelcode: "GR", degree1: "MBA",
                     printed: 1.hour.ago)
    Graduate.create!(buid: "B0099GRDR", firstname: "Grad", lastname: "Doc",
                     fullname: "Grad Doc", levelcode: "GR", degree1: "PHD",
                     printed: 1.hour.ago)

    assert_operator Graduate.master.where.not(printed: nil).count, :>=, 1,
      "Master scope should pick up GR levelcode + master degree code"
    assert_operator Graduate.doctorate.where.not(printed: nil).count, :>=, 1,
      "Doctorate scope should pick up GR levelcode + doctorate degree code"

    get stats_graduates_url
    assert_response :success
  end
end
