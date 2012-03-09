Sequel.migration do
  up do
    create_table(:tags) do
      primary_key :id
      String :name
    end
    create_table(:activities_tags) do
      foreign_key :activity_id, :activities
      foreign_key :tag_id, :tags
    end
  end
end
