module Hourglass
  class Activity < Sequel::Model
    attr_accessor :tag_names
    many_to_one :project
    many_to_many :tags

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
