module Hourglass
  class Application < Sinatra::Base
    set :root, Hourglass.root
    set :erb, :trim => '-'

    get '/' do
      @activities = Activity.filter(:started_at > Date.today).all
      erb :index
    end

    get '/activities/new' do
      @activity = Activity.new
      erb :form
    end
  end
end
