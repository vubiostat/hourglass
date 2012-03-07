Sequel.migration do
  up do
    create_table(:settings) do
      primary_key :id
      String :name
      String :value
    end
    self[:settings].insert({:name => "theme", :value => "smoothness"})
  end
end
