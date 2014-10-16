module RedisAlerting
  class Engine
    def initialize(config, redis)
      @config = config
      @redis = redis
      check_redis
    end

    def run
      ns = @config[:namespace]
      @config[:sources].each do |key, source|

        # get the readings and alert ranges
        min = @redis.get "#{ns}.#{key}.min"
        max = @redis.get "#{ns}.#{key}.max"
        reading = @redis.get source

        # check for alert conditions
        add_alert_for key and next if reading < min
        add_alert_for key and next if reading > max

        # if we got to here the alert conditions are not present anymore
        # so we should remove the alert if it exists
        remove_if_alert_exists key
      end
    end

    private

    def add_alert_for(key)
      @redis.sadd @config[:namespace], key
    end

    def remove_if_alert_exists(key)
      return unless @redis.sismember @config[:namespace], key
      @redis.srem @config[:namespace], key
    end

    def check_redis
      raise ArgumentError, "Invalid Redis instance given" unless @redis.is_a? Redis
      raise ArgumentError, "Could not connect to Redis" unless @redis.ping == "PONG"
    end
  end
end