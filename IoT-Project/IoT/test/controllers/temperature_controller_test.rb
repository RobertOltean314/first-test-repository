require "test_helper"

class TemperatureControllerTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end
  #
  test "returns 201 when a new entry is saved" do
    post "/data",
        params: { temperature: "24.5" }.to_json,
        headers: { "Content-Type" => "application/json" }

    assert_response :created
  end

  test "GET returns all readings as JSON" do
    TemperatureReading.delete_all

    TemperatureReading.create!(temperature: 22.0)
    TemperatureReading.create!(temperature: 25.0)

    get "/data"

    assert_response :ok

    body = JSON.parse(response.body)
    assert_equal 2, body.length
  end
end
