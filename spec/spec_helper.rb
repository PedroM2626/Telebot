ENV['RUN_BOT'] = 'false'
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'dotenv/load'
require 'rspec'
require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.mock_with :rspec do |m|
    m.verify_partial_doubles = true
  end
  config.filter_run_when_matching :focus
  config.order = :random
  Kernel.srand config.seed
end


