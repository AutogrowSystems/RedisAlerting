
module RedisAlerting
  class RedisPublisher

    def initialize(redis)
      @client = redis
    end

    def publish(channel, message)
      @client.publish(channel, message.to_json)
    end

  end
end