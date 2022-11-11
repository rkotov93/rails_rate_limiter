
class FakeLimitProcController < ApplicationController
  include RailsRateLimiter

  rate_limit limit: -> { instance_method_limit }, per: 56.minutes, pattern: -> { current_user_id } do |info|
    render json: info.time_left
  end

  def test
    render json: {}
  end

  private

  def instance_method_limit
    99
  end 

  def current_user_id
    'current-user-id'
  end
end