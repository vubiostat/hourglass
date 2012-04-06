module Hourglass
  class Activity < Sequel::Model
    attr_accessor :tag_names
    plugin :json_serializer, :naked => true, :include => [:tags, :project]

    many_to_one :project
    many_to_many :tags

    subset(:current, :ended_at => nil)
    def_dataset_method(:current_e) { current.eager(:tags, :project) }

    subset(:today) { started_at >= Date.today }
    def_dataset_method(:today_e) { today.eager(:tags, :project) }

    subset(:week) do
      today = Date.today
      sunday = today - today.wday
      started_at >= sunday && started_at < (sunday + 7)
    end
    def_dataset_method(:week_e) { week.eager(:tags, :project) }

    subset(:sub_minute) do
      ended_at != nil &&
        :datediff.sql_function("second", :started_at, :ended_at) < 60
    end

    def self.stop_current_activities
      current.update(:ended_at => Time.now)
      ids = sub_minute.select_map(:id)
      if !ids.empty?
        db[:activities_tags].filter(:activity_id => ids).delete
        sub_minute.delete
      end
    end

    def start_day
      t = started_at
      Date.new(t.year, t.month, t.day)
    end

    def duration
      (ended_at ? ended_at - started_at : Time.now - started_at).floor
    end

    def duration_in_words
      minutes = duration / 60
      hours = minutes / 60
      days = hours / 24

      strings = []
      strings << "#{days}d" if days > 0
      strings << "#{hours}h" if hours > 0
      strings << "#{minutes}min" if minutes > 0
      strings.join(" ")
    end

    def running?
      ended_at.nil?
    end

    def validate
      super
      validates_presence([:name])
    end

    def before_save
      super
      activity_name, project_name = name.split("@", 2)
      self.name = activity_name

      if !project_name.nil? && !project_name.empty?
        project = Project.filter(:name => project_name).first
        if project.nil?
          project = Project.create(:name => project_name)
        end
        self.project = project
      end
    end

    def after_save
      super
      if !tag_names.nil? && !tag_names.empty?
        remove_all_tags
        tag_names.split(/,\s*/).each do |tag_name|
          tag_name = tag_name.strip
          tag = Tag.filter(:name => tag_name).first
          if tag.nil?
            tag = Tag.create(:name => tag_name)
          end
          add_tag(tag)
        end
      end
    end
  end
end
