class TemperatureController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    render json: TemperatureReading.all.order(created_at: :desc)
  end

  def create
    payload = JSON.parse(request.body.read)
    TemperatureReading.create!(temperature: payload["temperature"].to_f)
    render json: { ok: true }, status: :created
  end
end
