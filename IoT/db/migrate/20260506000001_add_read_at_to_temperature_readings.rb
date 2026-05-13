class AddReadAtToTemperatureReadings < ActiveRecord::Migration[8.1]
  def change
    add_column :temperature_readings, :read_at, :datetime
    execute "UPDATE temperature_readings SET read_at = created_at WHERE read_at IS NULL"
    change_column_null :temperature_readings, :read_at, false
  end
end
