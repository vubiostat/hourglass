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

      def validate_and_save_activity(activity, was_running = false)
        if activity.valid?
          if !was_running && activity.running?
            Activity.stop_current_activities
          end
          activity.save
          if request.xhr?
            all_partials.merge('activity' => activity).to_json
          else
            redirect '/'
          end
        else
          if request.xhr?
            'false'
          else
            erb :popup
          end
        end
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
      erb :popup
    end

    post '/activities' do
      @activity = Activity.new(params['activity'] || {})
      @activity.started_at ||= Time.now
      validate_and_save_activity(@activity)
    end

    get '/activities/:id/edit' do
      @activity = Activity[params[:id]]
      erb :popup
    end

    post '/activities/:id' do
      @activity = Activity[params[:id]]
      was_running = @activity.running?
      @activity.set_fields(params[:activity], [
        :name, :tag_names, :running,
        :started_at_mdy, :started_at_hm,
        :ended_at_mdy, :ended_at_hm
      ])
      validate_and_save_activity(@activity, was_running)
    end

    get '/activities/:id/delete' do
      activity = Activity[params[:id]]
      activity.destroy
      all_partials.merge('activity' => activity).to_json
    end

    get '/activities' do
      ds = Activity.naked.distinct.
        select(:activities__name.as(:activity_name), :projects__name.as(:project_name)).
        left_join(:projects, :id => :project_id).
        order(:activities__name, :projects__name)

      term = params['term']
      if term && !term.empty?
        md = term.match(/^([^@]+)(?:@(.+)?)?$/)
        if md
          ds = ds.filter(:activities__name.like("#{md[1]}%"))
          if md[2]
            ds = ds.filter(:projects__name.like("#{md[2]}%"))
          end
        else
          return("[]")
        end
      end
      ds.all.to_json
    end

    get '/activities/current/stop' do
      Activity.stop_current_activities
      all_partials.to_json
    end

    get '/tags' do
      Tag.naked.distinct.order(:name).select_map(:name).to_json
    end
  end
end
