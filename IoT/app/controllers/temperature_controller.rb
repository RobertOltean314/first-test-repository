class TemperatureController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    render json: TemperatureReading.all.order(read_at: :desc)
  end

  def create
    reading = TemperatureReading.new(temperature_reading_params)
    if reading.save
      render json: { ok: true }, status: :created
    else
      render json: { errors: reading.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def temperature_reading_params
    params.permit(:temperature, :read_at)
  end
end
