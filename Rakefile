require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/extensiontask"

RSpec::Core::RakeTask.new(:spec)
task :default => [:spec]

task :build => :compile

Rake::ExtensionTask.new("method_plus") do |ext|
  ext.lib_dir = "lib/method_plus"
end
