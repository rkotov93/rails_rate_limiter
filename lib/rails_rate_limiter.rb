require 'active_support/concern'
require 'active_support/inflector'

require 'rails_rate_limiter/version'
require 'rails_rate_limiter/strategies'
require 'rails_rate_limiter/error'

module RailsRateLimiter
  extend ActiveSupport::Concern

  class_methods do
    # Sets callback that checks if rate limit was exceeded.
    #
    # == Arguments:
    #
    #   +&block+      - Executed if rate limit exceded. This argument is mandatory.
    #
    # == Options:
    #
    #   +limit+      - The number of allowed request per time period.
    #                  Supports lambda and proc. Default value is 100
    #   +per+        - Time period in seconds. Supports lambda and proc as well.
    #                  Default value is 1.hour
    #   +pattern+    - lambda or proc. Can be used if you want to use something
    #                  instead of IP as cache key identifier. For example
    #                  `->current_user.id`. Uses `request.remote_ip` by default.
    #   +client+     - Redis client. Uses `Redis.new` by default.
    #
    # Any option avaiable for `before_action` can be used.
    #
    # == Examples:
    #
    # rate_limit limit: 100, per: 1.hour, only: :index do |info|
    #   render plain: I18n.t('rate_limit_exceeded', seconds: info.time_left),
    #          status: :too_many_requests
    # end
    #
    def rate_limit(options = {}, &block)
      raise Error, 'Handling block was not provided' unless block_given?

      # Separate out options related only to rate limiting
      strategy = (options.delete(:strategy) || 'sliding_window_log').to_s
      limit = options.delete(:limit) || 100
      per = options.delete(:per) || 3600
      pattern = options.delete(:pattern)
      client = options.delete(:client)

      before_action(options) do
        check_rate_limits(strategy, limit, per, pattern, client, block)
      end
    end
  end

  private

  def check_rate_limits(strategy, limit, per, pattern, client, block)
    requester = pattern || request.remote_ip

    strategy_class = strategy.classify.constantize
    result = strategy_class.new(limit, per, requester, client).run
    return unless result.limit_exceeded?
    # instance_exec is using here because simple block.call executes block in
    # a wrong context that leads to not preventing action execution after render
    instance_exec result, &block
  end
end
