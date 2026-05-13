require "test_helper"

class TemperatureReadingTest < ActiveSupport::TestCase
  test "valid with temperature and read_at" do
    reading = TemperatureReading.new(temperature: 23.5, read_at: Time.current)
    assert reading.valid?
  end

  test "invalid without temperature" do
    reading = TemperatureReading.new(read_at: Time.current)
    assert_not reading.valid?
    assert_includes reading.errors[:temperature], "can't be blank"
  end

  test "invalid without read_at" do
    reading = TemperatureReading.new(temperature: 23.5)
    assert_not reading.valid?
    assert_includes reading.errors[:read_at], "can't be blank"
  end
end
