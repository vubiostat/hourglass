require 'pathname'
require 'rbconfig'
require 'sinatra/base'
require 'swt'
require 'sequel'
require 'sequel/extensions/migration'

module Hourglass
  def self.environment
    @environment ||= ENV['HOURGLASS_ENV'] || :production
  end

  def self.db_path
    File.join(data_path, 'db', environment.to_s)
  end

  def self.data_path
    if !defined? @data_path
      dir =
        if ENV['HOURGLASS_HOME']
          ENV['HOURGLASS_HOME']
        else
          case Config::CONFIG['host_os']
          when /mswin|windows/i
            # Windows
            File.join(ENV['APPDATA'], "hourglass")
          else
            if ENV['HOME']
              File.join(ENV['HOME'], ".hourglass")
            else
              raise "Can't figure out where Hourglass lives! Try setting the HOURGLASS_HOME environment variable"
            end
          end
        end
      if !File.exist?(dir)
        begin
          Dir.mkdir(dir)
        rescue SystemCallError
          raise "Can't create Hourglass directory (#{dir})! Is the parent directory accessible?"
        end
      end
      if !File.writable?(dir)
        raise "Hourglass directory (#{dir}) is not writable!"
      end
      @data_path = File.expand_path(dir)
    end
    @data_path
  end
end

path = Pathname.new(File.dirname(__FILE__)) + "hourglass"
require path + 'database'
require path + 'application'
require path + 'runner'
