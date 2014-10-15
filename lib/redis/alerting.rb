require "redis/alerting/version"
require "redis/alerting/engine"
require "redis/alerting/config"
require 'redis'
require 'yaml'

module Redis
  module Alertings
    def run(opts)
      config = Redis::Alerting::Config.new(opts).to_hash
      engine = Redis::Alerting::Engine.new(config, Redis.new)

      loop do
        engine.run
        sleep config[:interval]
      end
    end
  end
end
