require "redis_alerting/version"
require "redis_alerting/engine"
require "redis_alerting/config"
require "redis_alerting/faye_publisher"
require 'redis'
require 'logger'
require 'yaml'
require 'json'

module RedisAlerting
  class << self
    def run(opts)
      @config    = RedisAlerting::Config.new(opts).to_hash
      log       = Logger.new STDOUT
      log.level = @config[:log_level]
      @redis     = ::Redis.new
      engine    = RedisAlerting::Engine.new(@config, @redis, log, publisher)

      loop do
        engine.run
        sleep @config[:interval]
      end
    end
    
    def publisher
      if @config[:faye_url]
        return RedisAlerting::FayePublisher.new(@config[:faye_url])
      else
        return RedisAlerting::RedisPublisher.new(@redis)
      end
    end
  end
end
