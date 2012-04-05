module Hourglass
  class Activity < Sequel::Model
    attr_accessor :tag_names
    plugin :json_serializer, :naked => true, :include => [:tags, :project]

    many_to_one :project
    many_to_many :tags

    def_dataset_method(:current) do
      filter(:ended_at => nil).eager(:tags, :project)
    end

    def_dataset_method(:today) do
      filter { started_at >= Date.today }.eager(:tags, :project)
    end

    def_dataset_method(:week) do
      today = Date.today
      sunday = today - today.wday
      filter { started_at >= sunday && started_at < (sunday + 7) }.eager(:tags, :project)
    end

    def self.stop_current_activities
      filter(:ended_at => nil).update(:ended_at => Time.now)
    end

    def start_day
      t = started_at
      Date.new(t.year, t.month, t.day)
    end

    def duration
      ((ended_at ? ended_at - started_at : Time.now - started_at) * 1000).floor
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
