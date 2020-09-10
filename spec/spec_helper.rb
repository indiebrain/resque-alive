require "bundler/setup"
require "resque/plugins/alive"

require "bundler/setup"
require "resque_spec"
require "resque_spec/scheduler"
require "mock_redis"
require "byebug"

ENV['RACK_ENV'] = 'test'
ENV['HOSTNAME'] = 'test-hostname'

Dir[File.expand_path("support/**/*.rb", __dir__)].each(&method(:require))

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    ResqueSpec.reset!

    Resque::Plugins::Alive.redis.flushall
    Resque::Plugins::Alive.config.set_defaults
  end
end
