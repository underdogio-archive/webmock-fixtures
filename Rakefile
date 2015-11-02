require "rspec/core/rake_task"
require "rubocop/rake_task"

task :default => :test

desc "Run RSpec on the source"
task :spec do
  RSpec::Core::RakeTask.new(:spec)
end

desc "Run RuboCop on the source"
task :lint do
  RuboCop::RakeTask.new(:lint) do |task|
    task.options = ["--config", ".rubocop.yml"]
  end
end

desc "Run RSpec and RuboCop on the source"
task :test do
  Rake::Task[:lint].invoke
  Rake::Task[:spec].invoke
end
