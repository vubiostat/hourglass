# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "hourglass"
  gem.homepage = "http://github.com/vubiostat/hourglass"
  gem.license = "MIT"
  gem.summary = %Q{Simple GUI for tracking time spent on activities}
  gem.description = %Q{Hourglass is a simple GUI application for tracking time spent on activities.}
  gem.email = "jeremy.f.stephens@vanderbilt.edu"
  gem.authors = ["Jeremy Stephens"]
  gem.platform = 'java'
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "hourglass #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :environment do
  ENV['HOURGLASS_ENV'] ||= 'development'
  ENV['HOURGLASS_HOME'] = File.expand_path(File.join(File.dirname(__FILE__)))
  require File.join(File.dirname(__FILE__), 'lib', 'hourglass')
end

namespace :environment do
  task :test do
    ENV['HOURGLASS_ENV'] = "test"
    Rake::Task["environment"].execute
  end
end

namespace :db do
  desc "Obliterate the local database"
  task :nuke => :environment do
    confirm("This will delete all of Hourglass's databases.")

    require 'fileutils'
    files = Dir.glob(File.join(Hourglass.data_path, "db", "**", "*.db"))
    FileUtils.rm_rf(files, :verbose => true)
  end

  desc "Purge the database"
  task :purge => :environment do
    FileUtils.rm(Dir[Hourglass.db_path+".*"])
  end

  desc "Run migrations"
  task :migrate => :environment do
    version = ENV['VERSION']
    Hourglass::Database.migrate!(version ? version.to_i : nil)
  end

  namespace :migrate do
    desc "Reset the database"
    task :reset => ['db:purge', 'db:migrate']
  end

  desc "Roll the database back a version"
  task :rollback => [:start, :environment] do
    Hourglass::Database.rollback!
  end
end

desc "Run Hourglass from the project directory"
task :run do
  ENV['HOURGLASS_ENV'] ||= 'development'
  ENV['HOURGLASS_HOME'] = File.expand_path(File.join(File.dirname(__FILE__)))
  load File.join(File.dirname(__FILE__), 'bin', 'hourglass')
end

namespace :run do
  desc "Run only the web server"
  task :server do
    ENV['HOURGLASS_ENV'] ||= 'development'
    ENV['HOURGLASS_HOME'] = File.expand_path(File.join(File.dirname(__FILE__)))
    ARGV.clear
    ARGV << "-s"
    load File.join(File.dirname(__FILE__), 'bin', 'hourglass')
  end
end

task :build => :gemspec
