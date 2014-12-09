module RedisAlerting
  class Engine
      @config = config
      @active_set = "#{@config[:namespace]}.active"
      @redis = redis
    def initialize(config, redis, log)
      @log        = log
      check_redis
      @log.info "Redis Alerting Engine Initialized"
      @log.info "Publishing alert information on channel: #{@config[:channel]}"
      @log.info "Currently active alerts are in the key: #{@active_set}"

      @log.info "Working with sources:"
      @config[:sources].each do |name, source|
        @log.info "  #{name}: #{source}"
      end

      @log.info "Working with extrema:"
      @extrema.each do |name, ex|
        @log.info "  #{name}:"
        @log.info "    min: #{ex[:min]}"
        @log.info "    max: #{ex[:max]}"
      end

    end

    def run
      ns = @config[:namespace]
      @config[:sources].each do |name, source|

        # get the readings and alert ranges
        min = @redis.get("#{ns}.#{name}.min").to_i
        max = @redis.get("#{ns}.#{name}.max").to_i
        value = @redis.get(source).to_i

        @log.debug "Checking #{name} (min #{min}) (max #{max}): #{value}"

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
      return if @redis.sismember(@active_set, name)
      @redis.sadd @active_set, name

      @log.info "Added #{name} to active set"
      
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
      return unless @redis.sismember(@active_set, name)
      @redis.srem @active_set, name
      

      @log.info "Removed #{name} from active set"

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
      @log.info "Pushed message: #{message.inspect}"
    end

    def check_redis
      raise ArgumentError, "Invalid Redis instance given" unless @redis.is_a? Redis
      raise ArgumentError, "Could not connect to Redis" unless @redis.ping == "PONG"
    end
  end
end