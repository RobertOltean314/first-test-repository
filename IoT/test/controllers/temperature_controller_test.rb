require "test_helper"

class TemperatureControllerTest < ActionDispatch::IntegrationTest

  test "returns 201 when a new entry is saved" do
    post "/data",
         params: { temperature: "24.5", read_at: "2026-05-06T10:00:00Z" }.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :created
  end

  test "returns 422 when read_at is missing" do
    post "/data",
         params: { temperature: "24.5" }.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :unprocessable_entity
  end

  test "GET returns all readings ordered by read_at descending" do
    TemperatureReading.delete_all

    older = TemperatureReading.create!(temperature: 22.0, read_at: 2.hours.ago)
    newer = TemperatureReading.create!(temperature: 25.0, read_at: 1.hour.ago)

    get "/data"

    assert_response :ok

    body = JSON.parse(response.body)
    assert_equal 2, body.length
    assert_equal newer.id, body.first["id"]
    assert_equal older.id, body.last["id"]
  end
end
