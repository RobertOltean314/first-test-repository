class TemperatureReading < ApplicationRecord
  validates :temperature, presence: true
  validates :read_at, presence: true
  validate :temperature_must_be_numeric

  before_validation { self.read_at ||= Time.current }

  private

  def temperature_must_be_numeric
    raw = temperature_before_type_cast
    return if raw.nil? || raw.is_a?(Numeric)

    Float(raw.to_s)
  rescue ArgumentError, TypeError
    errors.add(:temperature, "is not a number")
  end
end
