require "redis_alerting/version"
require "redis_alerting/engine"
require "redis_alerting/config"
require 'redis'
require 'logger'
require 'yaml'
require 'json'

module RedisAlerting
  class << self
    def run(opts)
      config    = RedisAlerting::Config.new(opts).to_hash
      log       = Logger.new STDOUT
      log.level = config[:log_level]
      engine    = RedisAlerting::Engine.new(config, ::Redis.new, log)

      loop do
        engine.run
        sleep config[:interval]
      end
    end
  end
end
