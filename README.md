# Redis::Alerting

A tool that uses keys from redis to determine if a reading is out of range.  It then writes to a key in redis to indicate that the reading is out of range.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'redis-alerting'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install redis-alerting

## Usage

The gem uses specific key patterns to get the min and the max limits for a reading.

Given the config file below we will describe how the gem would check some limits and write back to redis to inidicate an out of range state.

```yaml
---
alerting:
  namespace: alerts
  sources:
    ph: readings.ph
    ec: readings.ec
    flow: readings.flow
```

With the example of `ph` above, the alerting system would check the redis key `readings.ph` and determine if it was outside the limits set in `alerts.ph.max` and `alerts.ph.min`.

When it finds that the value in `readings.ph` is outside the range, it will add "ph" to the redis set `alerts`.  When it comes back into range "ph" will be removed from the `alerts` set.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/redis-alerting/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
