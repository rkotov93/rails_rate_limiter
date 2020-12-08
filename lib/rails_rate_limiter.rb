require 'active_support/inflector'

require 'rails_rate_limiter/version'
require 'rails_rate_limiter/strategies'
require 'rails_rate_limiter/error'

# Provides `rate_limit` callback to limit amount of requests
# and handle rate limit exceeding
module RailsRateLimiter
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    # Sets callback that handles rate limit exceeding. Additionally to
    # described options supports all the `before_action` options.
    #
    # @example Renders text with time left in case of rate limit exceeding.
    #   rate_limit limit: 100, per: 1.hour, only: :index do |info|
    #     render plain: "Next request can be done in #{info.time_left} seconds",
    #            status: :too_many_requests
    #   end
    #
    # @param [Hash] options
    # @option options [Symbol] :strategy Rate limiting strategy.
    #   Default value is :sliding_window_log
    # @option options [Fixnum, Lambda, Proc] :limit The number of allowed
    #   requests per time period. Default value is 100
    # @option options [Fixnum, Lambda, Proc] :per Time period in seconds.
    #   Default value is 1.hour
    # @option options [Lambda, Proc] :pattern Can be used if you want to use
    #   something instead of IP as cache key identifier. For example
    #   `-> { current_user.id }`. Default value is `request.remote_ip`
    # @option options [Object] :cient Redis client.
    #   Uses `Redis.new` if not specified
    #
    # @yield [info] Executed if rate limit exceded. This argument is mandatory.
    # @yieldparam [RailsRateLimiter::Result] Represent information about
    #   rate limiting
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
    requester = compute_requester_pattern(pattern || request.remote_ip)

    strategy_class =
      "RailsRateLimiter::Strategies::#{strategy.classify}".constantize
    result = strategy_class.new(limit, per, requester, client).run
    return unless result.limit_exceeded?
    # instance_exec is using here because simple block.call executes block in
    # a wrong context that leads to not preventing action execution after render
    instance_exec result, &block
  end

  def compute_requester_pattern(requester)
    return "ip_#{requester}" unless requester.respond_to?(:call)
    # instance_exec is using here because simple block.call executes block in
    # a wrong context that leads to not preventing action execution after render
    "custom_#{instance_exec(&requester)}"
  end
end
