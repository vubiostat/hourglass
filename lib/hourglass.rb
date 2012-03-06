require 'sinatra/base'
require 'swt'
require 'pathname'

module Hourglass
end

path = Pathname.new(File.dirname(__FILE__)) + "hourglass"
require path + 'application'
require path + 'runner'
