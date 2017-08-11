$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'rollout'
require 'rspec'
require 'bourne'
require 'redis'
require 'pry'

RSpec.configure do |config|
    config.before { Redis.new.flushdb }
end