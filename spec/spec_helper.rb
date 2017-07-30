$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rollout'
require 'rspec'
require 'bourne'
require 'redis'

RSpec.configure do |config|
    config.mock_with :mocha
    config.before { Redis.new.flushdb }
    config.expect_with(:rspec) { |c| c.syntax  = :should }
end