require "redis_alerting/version"
require "redis_alerting/engine"
require "redis_alerting/config"
require 'redis'
require 'yaml'
require 'json'

module RedisAlerting
  class << self
    def run(opts)
      config = RedisAlerting::Config.new(opts).to_hash
      engine = RedisAlerting::Engine.new(config, ::Redis.new)

      loop do
        engine.run
        sleep config[:interval]
      end
    end
  end
end
