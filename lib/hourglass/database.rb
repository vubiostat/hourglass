module Hourglass
  if Hourglass.environment.to_s != "test"
    options = {:logger => Logger.new(File.join(Hourglass.root, "log", "database.log"))}
  else
    options = {}
  end

  Database = Sequel.connect("jdbc:h2:#{Hourglass.db_path};IGNORECASE=TRUE", options)
  class << Database
    def rollback!
      version = self[:schema_info].first[:version]
      migrate!(version - 1)
    end

    def migrate!(to = nil, from = nil)
      dir = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'db', 'migrate'))
      args = [self, dir]
      if to
        args << to
        args << from  if from
      end
      Sequel::Migrator.run(*args)
    end
  end
end
