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
            all_partials.merge('changes' => activity.changes).to_json
          else
            redirect '/'
          end
        else
          if request.xhr?
            {'errors' => activity.errors}.to_json
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
        :name_with_project, :tag_names, :running,
        :started_at_mdy, :started_at_hm,
        :ended_at_mdy, :ended_at_hm
      ])
      validate_and_save_activity(@activity, was_running)
    end

    get '/activities/:id/delete' do
      activity = Activity[params[:id]]
      activity.destroy
      all_partials.merge('changes' => activity.changes).to_json
    end

    post '/activities/:id/restart' do
      activity = Activity[params[:id]]
      new_activity = Activity.start_like(activity)
      if new_activity
        all_partials.merge("success" => true).to_json
      else
        {"success" => false}.to_json
      end
    end

    get '/activities' do
      ds = Activity.naked.distinct.
        select(:activities__name.as(:activity_name), :projects__name.as(:project_name)).
        left_join(:projects, :id => :project_id).
        order(:activities__name, :projects__name)
      ds.collect do |row|
        if row[:project_name]
          "#{row[:activity_name]}@#{row[:project_name]}"
        else
          row[:activity_name]
        end
      end.to_json
    end

    get '/activities/current/stop' do
      Activity.stop_current_activities
      all_partials.to_json
    end

    get '/tags' do
      Tag.naked.distinct.order(:name).select_map(:name).to_json
    end

    get '/projects' do
      Project.naked.distinct.order(:name).select_map(:name).to_json
    end
  end
end
