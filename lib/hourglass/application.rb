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

    post '/activities' do
      @activity = Activity.new(params['activity'])
      if @activity.valid?
        @activity.save
        if request.xhr?
          @activity.values.to_json
        else
          redirect '/'
        end
      else
        if request.xhr?
          'false'
        else
          erb :form
        end
      end
    end
  end
end
