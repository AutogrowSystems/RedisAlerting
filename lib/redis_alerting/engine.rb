module RedisAlerting
  class Engine
    def initialize(config, redis)
      @config = config
      @redis = redis
      check_redis
    end

    def run
      ns = @config[:namespace]
      @config[:sources].each do |name, source|

        # get the readings and alert ranges
        min = @redis.get("#{ns}.#{name}.min").to_i
        max = @redis.get("#{ns}.#{name}.max").to_i
        value = @redis.get(source).to_i

        # silently ignore
        next if max.nil? or min.nil? or value.nil?

        # check for alert conditions
        if condition = out_of_range?(value, min, max)
          add_alert_for(name, condition, value, min, max)
          next
        end

        # if we got to here the alert conditions are not present anymore
        # so we should remove the alert if it exists
        remove_if_alert_exists name, value, min, max
      end
    end

    private

    def out_of_range?(value, min, max)
      return :high if value > max
      return :low if value < min
      return false
    end

    def add_alert_for(name, condition, value, min, max)
      return if @redis.sismember(@config[:namespace], name)
      @redis.sadd @config[:namespace], name
      
      publish({
        action: :add, 
        name: name,
        condition: condition,
        value: value,
        min: min,
        max: max
      })
    end

    def remove_if_alert_exists(name, value, min, max)
      return unless @redis.sismember(@config[:namespace], name)
      @redis.srem @config[:namespace], name
      
      publish({
        action: :remove,
        name: name,
        value: value,
        min: min,
        max: max
      })
    end

    def publish(message)
      @redis.publish @config[:channel], message.to_json
      puts "pushed message: #{message.inspect}"
    end

    def check_redis
      raise ArgumentError, "Invalid Redis instance given" unless @redis.is_a? Redis
      raise ArgumentError, "Could not connect to Redis" unless @redis.ping == "PONG"
    end
  end
end