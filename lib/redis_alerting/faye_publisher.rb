require 'faye'
require 'faye/redis'
require 'eventmachine'

module RedisAlerting
  class FayePublisher

    def initialize(url)
      Thread.new { EventMachine.run } unless EventMachine.reactor_running? && EventMachine.reactor_thread.alive?
      @client = Faye::Client.new(url)
    end

    def publish(channel, message)
      channel = "/#{channel}" unless channel.start_with?("/")
      @client.publish(channel, message)
    end

  end
end