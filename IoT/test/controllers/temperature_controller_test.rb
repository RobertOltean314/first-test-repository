require "test_helper"

class TemperatureControllerTest < ActionDispatch::IntegrationTest
  VALID_KEY = "iot-board-secret-2026"

  def auth_headers(extra = {})
    { "Content-Type" => "application/json", "X-Api-Key" => VALID_KEY }.merge(extra)
  end

  # --- Authentication ---

  test "returns 401 when X-Api-Key header is missing" do
    post "/data",
         params: { temperature: "24.5", read_at: "2026-05-06T10:00:00Z" }.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :unauthorized
  end

  test "returns 401 when X-Api-Key is wrong" do
    post "/data",
         params: { temperature: "24.5", read_at: "2026-05-06T10:00:00Z" }.to_json,
         headers: { "Content-Type" => "application/json", "X-Api-Key" => "wrong-key" }

    assert_response :unauthorized
  end

  # --- Valid / invalid data (board authenticated) ---

  test "returns 201 for valid temperature and read_at" do
    post "/data",
         params: { temperature: "24.5", read_at: "2026-05-06T10:00:00Z" }.to_json,
         headers: auth_headers

    assert_response :created
    assert JSON.parse(response.body)["ok"]
  end

  test "returns 422 when temperature is a non-numeric string" do
    post "/data",
         params: { temperature: "abc", read_at: "2026-05-06T10:00:00Z" }.to_json,
         headers: auth_headers

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["errors"].join, "not a number"
  end

  test "returns 422 when temperature is missing" do
    post "/data",
         params: { read_at: "2026-05-06T10:00:00Z" }.to_json,
         headers: auth_headers

    assert_response :unprocessable_entity
    assert_includes JSON.parse(response.body)["errors"].join, "Temperature"
  end

  test "uses current time when read_at is missing" do
    post "/data",
         params: { temperature: "24.5" }.to_json,
         headers: auth_headers

    assert_response :created
  end

  # --- GET (public, no auth needed) ---

  test "GET returns all readings ordered by read_at descending" do
    TemperatureReading.delete_all

    older = TemperatureReading.create!(temperature: 22.0, read_at: 2.hours.ago)
    newer = TemperatureReading.create!(temperature: 25.0, read_at: 1.hour.ago)

    get "/data", headers: { "Accept" => "application/json" }

    assert_response :ok

    body = JSON.parse(response.body)
    assert_equal 2, body.length
    assert_equal newer.id, body.first["id"]
    assert_equal older.id, body.last["id"]
  end
end
