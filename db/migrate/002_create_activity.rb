Sequel.migration do
  up do
    create_table(:activities) do
      primary_key :id
      foreign_key :project_id, :projects
      String :name
      DateTime :started_at
      DateTime :ended_at
    end
  end
end
