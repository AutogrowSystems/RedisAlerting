require 'redis'
require 'pry'
require 'redis_alerting'

def test_config
  {
    namespace: "test.alerts",
    sources: {
      ph: "test.readings.ph"
    }
  }
end