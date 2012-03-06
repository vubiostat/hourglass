Sequel.migration do
  up do
    create_table(:projects) do
      primary_key :id
      String :name
    end
  end
end
