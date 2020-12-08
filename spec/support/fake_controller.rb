class ApplicationController < ActionController::Base
  include Rails.application.routes.url_helpers

  def render(*attributes); end
end

class FakeController < ApplicationController
  include RailsRateLimiter

  rate_limit limit: 123, per: 56.minutes, pattern: -> { current_user_id } do |info|
    render json: info.time_left
  end

  def test
    render json: {}
  end

  private

  def current_user_id
    'current-user-id'
  end
end
