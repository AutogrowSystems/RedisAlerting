module Redis
  module Alerting
    class Engine
      def initialize(config, redis)
        @config = config
        @redis = redis
        check_redis
        parse_config
      end

      def run
        loop do
          ns = @config[:namespace]
          @config[:sources].each do |key, source|
            min = @redis.get "#{ns}.#{key}.min"
            max = @redis.get "#{ns}.#{key}.max"
            reading = @redis.get source

            add_alert_for key and next if reading < min
            add_alert_for key and next if reading > max

            remove_if_alert_exists key
          end

          sleep @config[:interval]
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

      def parse_config
        raise ArgumentError, "Invalid config file: #{config[:config]}" unless File.exists? @config[:config]
        @config.merge(YAML.load_file(@config[:config])["alerting"])
        raise ArgumentError, "Incomplete configuration" unless valid_config?
      end

      # TODO: check we have all the needed options
      def valid_config?
        true
      end
    end
  end
end