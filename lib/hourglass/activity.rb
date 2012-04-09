module Hourglass
  class Activity < Sequel::Model
    plugin :json_serializer, :naked => true, :include => [:tags, :project]

    many_to_one :project
    many_to_many :tags

    attr_writer :tag_names, :running, :started_at_mdy, :started_at_hm,
      :ended_at_mdy, :ended_at_hm

    subset(:current, :ended_at => nil)
    def_dataset_method(:current_e) { current.eager(:tags, :project) }

    subset(:today) { started_at >= Date.today }
    def_dataset_method(:today_e) { today.eager(:tags, :project) }

    subset(:week) do
      today = Date.today
      sunday = today - today.wday
      (started_at >= sunday) & (started_at < (sunday + 7))
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

    def started_at_date
      t = started_at
      Date.new(t.year, t.month, t.day)
    end

    def started_at_mdy
      started_at ? started_at.strftime("%m/%d/%Y") : ""
    end

    def started_at_hm
      started_at ? started_at.strftime("%H:%M") : ""
    end

    def ended_at_mdy
      ended_at ? ended_at.strftime("%m/%d/%Y") : ""
    end

    def ended_at_hm
      ended_at ? ended_at.strftime("%H:%M") : ""
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
      if !@tag_names.nil? && !@tag_names.empty?
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
      @tag_names = @started_at_mdy = @started_at_hm = @ended_at_mdy =
        @ended_at_hm = @running = nil
    end
  end
end
