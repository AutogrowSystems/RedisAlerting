require "bundler/gem_tasks"

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec) do |task|
    task.rspec_opts = "--color"
  end

  task :test => :spec
rescue LoadError
  # no rspec available
end