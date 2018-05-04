require 'active_support/time'
require 'bundler/setup'
require 'rails_rate_limiter'
require 'byebug'

# Require files from support
path =
  File.expand_path(File.join(File.dirname(__FILE__), 'support', '**', '*.rb'))
Dir[path].each { |file| require_relative file }

Time.zone = 'Pacific Time (US & Canada)'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
