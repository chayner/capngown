require "test_helper"

class GraduatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @graduate = graduates(:alice)
    @checked_in = graduates(:bob)
    @printed = graduates(:carol)
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
end
