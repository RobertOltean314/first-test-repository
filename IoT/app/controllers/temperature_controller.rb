class TemperatureController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate_board!, only: [:create]

  def index
    @readings = TemperatureReading.all.order(read_at: :desc)
    respond_to do |format|
      format.html
      format.json { render json: @readings }
    end
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

  def authenticate_board!
    expected = ENV.fetch("BOARD_API_KEY", "iot-board-secret-2026")
    provided  = request.headers["X-Api-Key"]
    render json: { error: "Unauthorized" }, status: :unauthorized unless provided == expected
  end

  def temperature_reading_params
    params.permit(:temperature, :read_at)
  end
end
