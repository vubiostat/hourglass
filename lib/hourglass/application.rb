module Hourglass
  class Application < Sinatra::Base
    set :root, Hourglass.root
    set :erb, :trim => '-'

    if development?
      use Rack::CommonLogger
    end

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

    before do
      @user_agent = request.user_agent
    end

    get '/' do
      if request.xhr?
        all_partials.to_json
      else
        @activities = {
          'today' => Activity.today_e.all,
          'week' => Activity.week_e.all,
          'current' => Activity.current_e.first
        }
        erb :index
      end
    end

    get '/activities/new' do
      @activity = Activity.new(:started_at => Time.now, :running => true)
      erb :new
    end

    post '/activities' do
      @activity = Activity.new(params['activity'] || {})
      @activity.started_at ||= Time.now
      if @activity.valid?
        if @activity.running?
          # TODO: This should be different if we're editing an already
          # running activity.
          Activity.stop_current_activities
        end
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
          erb :new
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
