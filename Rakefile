require 'rake/clean'
require 'rake/testtask'

CLEAN << "*.gem"

desc "Build the gem"
task :gem do
  sh "gem build excession.gemspec"
end

task :bundler do
  # Install bundler if it's not present
  unless Gem.source_index.find_name("bundler").first
    sh "gem install bundler --no-rdoc --no-ri"
  end
end

desc "Install the dependencies with bundler"
task :install_deps => :bundler do
  sh "bundle install"
end

Rake::TestTask.new do |t|
  t.libs << "lib"
  t.libs << "."
  t.test_files = FileList["test/**/test_*.rb"]
end
