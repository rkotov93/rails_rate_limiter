module RailsRateLimiter
  # Provides results of rate limiting
  class Result
    attr_reader :time_left

    def initialize(time_left)
      @time_left = time_left
    end

    def limit_exceeded?
      time_left > 0
    end
  end
end
