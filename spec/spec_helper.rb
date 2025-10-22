# frozen_string_literal: true

require 'simplecov'

# Configure SimpleCov
SimpleCov.start do
  enable_coverage :branch
  add_filter '/spec/'
  add_filter '/bin/'

  # SimpleCov automatically generates .resultset.json which we use for the badge
  # No need for additional formatters
end

require 'zai_payment'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
