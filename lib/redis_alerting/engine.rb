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

        next if max.nil? or min.nil? or reading.nil?

        # check for alert conditions
        if reading < min
          add_alert_for(key)
          next
        end

        if reading > max
          add_alert_for(key)
          next
        end

        # if we got to here the alert conditions are not present anymore
        # so we should remove the alert if it exists
        remove_if_alert_exists key
      end
    end

    private

    def add_alert_for(key)
      return if @redis.sismember(@config[:namespace], key)
      @redis.sadd @config[:namespace], key
    end

    def remove_if_alert_exists(key)
      return unless @redis.sismember(@config[:namespace], key)
      @redis.srem @config[:namespace], key
    end

    def check_redis
      raise ArgumentError, "Invalid Redis instance given" unless @redis.is_a? Redis
      raise ArgumentError, "Could not connect to Redis" unless @redis.ping == "PONG"
    end
  end
end