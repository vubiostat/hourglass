module Hourglass
  class Application < Sinatra::Base
    set :root, Hourglass.root
    set :erb, :trim => '-'

    helpers do
      def activity_tags(activity)
        result = "<ul>"
        activity.tags.each do |tag|
          result << %{<li class="tag-#{tag.id}">#{tag.name}</li>}
        end
        result + "</ul>"
      end

      def all_partials
        {
          'today' => erb(:_today, {
            :layout => false,
            :locals => {:activities => Activity.today_e.all}
          }),
          'week' => erb(:_week, {
            :layout => false,
            :locals => {:activities => Activity.week_e.all}
          }),
          'current' => erb(:_current, {
            :layout => false,
            :locals => {:activity => Activity.current_e.first}
          })
        }
      end
    end

    get '/' do
      @activities = {
        'today' => Activity.today_e.all,
        'week' => Activity.week_e.all,
        'current' => Activity.current_e.first
      }
      erb :index
    end

    get '/activities/new' do
      @activity = Activity.new
      erb :form
    end

    post '/activities' do
      @activity = Activity.new(params['activity'] || {})
      @activity.started_at ||= Time.now
      if @activity.valid?
        # stop running activities
        Activity.filter(:ended_at => nil).update(:ended_at => Time.now)
        @activity.save
        if request.xhr?
          all_partials.merge('activity' => @activity).to_json
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

    get '/activities' do
      day = DateTime.strptime(params[:d], "%Y%m%d")
      Activity.filter(:started_at >= day, :started_at < (day + 24 * 60 * 60)).to_json(:include => [:tags, :project])
    end

    get '/activities/current/stop' do
      Activity.stop_current_activities
      all_partials.to_json
    end

    configure do
      Activity.stop_current_activities
    end
  end
end
