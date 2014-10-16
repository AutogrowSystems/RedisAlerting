# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'redis_alerting/version'

Gem::Specification.new do |spec|
  spec.name          = "redis_alerting"
  spec.version       = RedisAlerting::VERSION
  spec.authors       = ["Robert McLeod"]
  spec.email         = ["robert@autogrow.com"]
  spec.summary       = %q{Checks redis for alert conditions}
  spec.description   = %q{Checks redis for alert conditions and adds keys to a set when a value is round to be out of range}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "redis"
  spec.add_dependency "slop"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "pry"
end
