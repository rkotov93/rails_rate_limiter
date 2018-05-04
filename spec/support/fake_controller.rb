class ApplicationController < ActionController::Base
  include Rails.application.routes.url_helpers

  def render(*attributes); end
end

class FakeController < ApplicationController
  include RailsRateLimiter

  rate_limit do |info|
    render json: info.time_left
  end

  def test
    render json: {}
  end
end
