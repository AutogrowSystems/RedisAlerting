module RedisAlerting
  class Engine
    def initialize(config, redis, log, publisher)
      @config     = config
      @publisher  = publisher
      @active_set = "#{@config[:namespace]}#{@config[:separator]}active"
      @redis      = redis
      @log        = log
      @extrema    = {}

      check_redis
      build_extrema

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
      @config[:sources].each do |name, source|

        # get the readings and alert ranges
        min = @redis.get(@extrema[name][:min]).to_i
        max = @redis.get(@extrema[name][:max]).to_i
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
      return if @redis.sismember(@active_set, name) and @redis.get(condition_key(name)) == condition.to_s
      @redis.sadd @active_set, name
      @redis.set condition_key(name), condition

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
      @redis.set condition_key(name), "OK"

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
      @publisher.publish @config[:channel], message
      @log.info "Pushed message: #{message.inspect}"
    end

    def condition_key(name)
      "#{@config[:namespace]}#{@config[:separator]}#{name}#{@config[:separator]}condition"
    end

    def check_redis
      raise ArgumentError, "Invalid Redis instance given" unless @redis.is_a? Redis
      raise ArgumentError, "Could not connect to Redis" unless @redis.ping == "PONG"
    end

    def build_extrema
      @config[:sources].each do |source, redis_key|
        @extrema[source] = {
          min: @config[:extrema][:pattern].gsub("$source", source.to_s).gsub("$extrema", @config[:extrema][:min]),
          max: @config[:extrema][:pattern].gsub("$source", source.to_s).gsub("$extrema", @config[:extrema][:max])
        }
      end
    end
  end
end