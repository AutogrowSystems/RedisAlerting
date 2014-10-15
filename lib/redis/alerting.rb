require "redis/alerting/version"
require 'redis'
require 'yaml'

module Redis
  module Alerting
    def run(opts)
      engine = Redis::Alerting::Engine.new(opts, Redis.new)
      engine.run
    end
  end
end
