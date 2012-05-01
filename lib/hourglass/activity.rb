module Hourglass
  class Activity < Sequel::Model
    many_to_one :project
    many_to_many :tags

    plugin :json_serializer, :naked => true, :include => [:tags, :project]
    plugin :nested_attributes
    nested_attributes :project
    plugin :dirty

    def_dataset_method(:full) { eager(:tags, :project) }

    subset(:current, :ended_at => nil)
    def_dataset_method(:current_e) { current.full.order(:started_at) }

    subset(:today) { started_at >= Date.today }
    def_dataset_method(:today_e) { today.full.order(:started_at) }

    subset(:week) do
      today = Date.today
      sunday = today - today.wday
      (started_at >= sunday) & (started_at < (sunday + 7))
    end
    def_dataset_method(:week_e) { week.full.order(:started_at) }

    subset(:sub_minute) do
      ended_at != nil &&
        :datediff.sql_function("second", :started_at, :ended_at) < 60
    end

    def_dataset_method(:uniq) do
      # figure out if the projects table has already been joined
      ds =
        if (opts[:join] || []).collect(&:table).include?(:projects)
          self
        else
          join(:projects, :id => :project_id)
        end
      ds = ds.naked.
        select(:min.sql_function(:activities__id).as(:id)).
        group(:activities__name, :projects__name)

      ids = ds.collect { |row| row[:id] }
      filter(:activities__id => ids)
    end

    def self.stop_current_activities
      current.update(:ended_at => Time.now)
      ids = sub_minute.select_map(:id)
      if !ids.empty?
        db[:activities_tags].filter(:activity_id => ids).delete
        sub_minute.delete
      end
    end

    def running=(value)
      modified!
      @running = value
    end

    def started_at_date
      t = started_at
      Date.new(t.year, t.month, t.day)
    end

    def started_at_mdy
      started_at ? started_at.strftime("%m/%d/%Y") : ""
    end

    def started_at_mdy=(value)
      modified!
      @started_at_mdy = value
    end

    def started_at_hm
      started_at ? started_at.strftime("%H:%M") : ""
    end

    def started_at_hm=(value)
      modified!
      @started_at_hm = value
    end

    def ended_at_mdy
      ended_at ? ended_at.strftime("%m/%d/%Y") : ""
    end

    def ended_at_mdy=(value)
      modified!
      @ended_at_mdy = value
    end

    def ended_at_hm
      ended_at ? ended_at.strftime("%H:%M") : ""
    end

    def ended_at_hm=(value)
      modified!
      @ended_at_hm = value
    end

    def duration
      (ended_at ? ended_at - started_at : Time.now - started_at).floor
    end

    def duration_in_words
      total_minutes = duration / 60
      if total_minutes == 0
        "0min"
      else
        minutes = total_minutes % 60
        total_hours = total_minutes / 60
        hours = total_hours % 24
        days = total_hours / 24

        strings = []
        strings << "#{days}d" if days > 0
        strings << "#{hours}h" if hours > 0
        strings << "#{minutes}min" if minutes > 0
        strings.join(" ")
      end
    end

    def running?
      if new?
        @running
      else
        ended_at.nil?
      end
    end

    def tag_names
      if @tag_names
        @tag_names
      else
        new? ? "" : tags_dataset.select_map(:name).join(", ")
      end
    end

    def tag_names=(value)
      modified!
      @tag_names = value
    end

    def name_with_project
      if project
        "#{name}@#{project.name}"
      else
        name
      end
    end

    def name_with_project=(value)
      activity_name, project_name = value ? value.strip.split("@", 2) : [nil, nil]
      self.name = activity_name

      if !project_name.nil? && !project_name.empty?
        project = Project.filter(:name => project_name).first
        if project.nil?
          self.project_attributes = {:name => project_name}
        else
          self.project = project
        end
      end
    end

    def changes
      @changes || {}
    end

    private

    def before_validation
      super
      if @started_at_mdy && @started_at_hm
        md_1 = @started_at_mdy.match(%r{^(\d{1,2})/(\d{1,2})/(\d{4})$})
        md_2 = @started_at_hm.match(%r{^(\d{1,2}):(\d{2})$})
        if md_1 && md_2
          self.started_at = Time.local(md_1[3].to_i, md_1[1].to_i, md_1[2].to_i, md_2[1].to_i, md_2[2].to_i)
        end
      end

      if @ended_at_mdy && @ended_at_hm
        md_1 = @ended_at_mdy.match(%r{^(\d{1,2})/(\d{1,2})/(\d{4})$})
        md_2 = @ended_at_hm.match(%r{^(\d{1,2}):(\d{2})$})
        if md_1 && md_2
          self.ended_at = Time.local(md_1[3].to_i, md_1[1].to_i, md_1[2].to_i, md_2[1].to_i, md_2[2].to_i)
        end
      end
    end

    def validate
      super
      validates_presence([:name, :started_at])
      if (new? && !@running)
        validates_presence([:ended_at])
      end
    end

    def before_save
      @changes = {}

      if project && project.new?
        @changes['new_project'] = project.name
      end

      super

      if @running
        self.ended_at = nil
      end

      if Activity.filter(:name => name, :project_id => project_id).count == 0
        @changes['new_activity'] = name_with_project
      end

      if !new?
        name_changed = changed_columns.include?(:name)
        project_changed =
          changed_columns.include?(:project_id) ||
          (project && project.id != project_id)

        if name_changed || project_changed
          # check to see if this was the last activity named this
          previous_name = initial_value(:name)
          previous_project_id = initial_value(:project_id)
          ds = Activity.
            filter(:name => previous_name).
            filter(:project_id => previous_project_id).
            filter(~{:id => id})

          if ds.count == 0
            @changes['delete_activity'] =
              if previous_project_id
                previous_name + "@" + Project[previous_project_id].name
              else
                previous_name
              end
          end
        end
      end
    end

    def after_save
      super
      new_tags = []
      if !@tag_names.nil? && !@tag_names.empty?
        remove_all_tags
        tag_names.split(/,\s*/).each do |tag_name|
          tag_name = tag_name.strip
          tag = Tag.filter(:name => tag_name).first
          if tag.nil?
            tag = Tag.create(:name => tag_name)
            new_tags << tag_name
          end
          add_tag(tag)
        end
      end
      if !new_tags.empty?
        @changes['new_tags'] = new_tags
      end

      @tag_names = @started_at_mdy = @started_at_hm = @ended_at_mdy =
        @ended_at_hm = @running = nil
    end

    def before_destroy
      super
      remove_all_tags

      @changes = {}
    end

    def after_destroy
      super

      # NOTE: this doesn't work if someone changes an activity, then
      # deletes it without saving, but this isn't really that critical.
      if Activity.filter(:name => name, :project_id => project_id).count == 0
        @changes['delete_activity'] = name_with_project
      end

      # TODO: Project.prune
    end
  end
end
