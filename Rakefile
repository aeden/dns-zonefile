require "bundler/gem_tasks"

require 'rake'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task :default => [ :spec ]

task :build do
  puts %x[gem build dns-zonefile.gemspec]
end
