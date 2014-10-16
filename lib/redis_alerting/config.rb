module RedisAlerting
  class Config
    def initialize(opts)
      @config = opts
      parse_config
    end

    def to_hash
      @config
    end
    
    private

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