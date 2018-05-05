# RailsRateLimiter

This is a high level rate limiting gem for Ruby on Rails using Redis. It limits amount of requests on controllers level, that allows you to customize rate limiting options using everything that available in your action, e.g. `current_user`.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails_rate_limiter'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rails_rate_limiter

## Usage

Add `include RateLimiter` to the controller you want to rate limit. It allows you to use `rate_limit` class method.

### Example

```ruby
class Posts < ApplicationController
  include RailsRateLimiter

  rate_limit limit: 100, per: 1.hour, only: :index do |info|
    render plain: I18n.t('rate_limit_exceeded', seconds: info.time_left),
           status: :too_many_requests
  end

  def index
    # ...
  end
end
```

### `rate_limit` arguments
* `&block` - executes if rate limit was exceeded. This argument is mandatory. `RateLimiter::Error` is raising if not passed.

### `rate_limit` options
* `strategy` - rate limiting strategy. Default value is :sliding_window_log
* `limit` - the number of allowed request per time period. Supports lambda and proc. Default value is 100
* `per` - time period in seconds. Supports lambda and proc as well. Default value is `1.hour`
* `pattern` - lambda or proc. Can be used if you want to use something instead of IP as cache key identifier. For example `-> current_user.id`. Uses `request.remote_ip` by default.
* `client` - Redis client. Uses `Redis.new` by default.

You can also use any options which are available for `before_action` callback because `rate_limiter` uses it under the hood.

## Strategies

At this moment gem supports only Sliding Window Log strategy to rate limit requests. You can read more about different strategies [here](https://blog.figma.com/an-alternative-approach-to-rate-limiting-f8a06cf7c94c).

### Sliding Window Log

![](https://cdn-images-1.medium.com/max/1600/1*u_xRdZnWUlQFf0wrp0acrw.png)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rails_rate_limiter.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
