class TemperatureReading < ApplicationRecord
  validates :temperature, presence: true
  validates :read_at, presence: true

  before_validation { self.read_at ||= Time.current }
end
